%This is the ELCC module 
%Do the calculation to determine effective load carrying capability
%
% Tao Chen, 4/4/2019

tic

ratios = system_info.ldc_ratio(1,:);
starting_year = system_info.settings.study_period(1);
ending_year = system_info.settings.study_period(2);
study_years = starting_year:ending_year;

optimal_configuration = system_info.optimal_configuration;

ELCC_yearly = zeros([size(optimal_configuration) system_info.system_period_num]);

for year = study_years
    offset = year - starting_year + 1;
    
    number_of_units = system_info.existing_gen_info.yearly_number_of_units(offset,:);
    
    configuration = optimal_configuration(offset,:);
    
    % --- Renewable units are combined as a single giant unit -------------------------
    candi_types = cellfun(@(x) x.type,system_info.candi_gen_conf.generators, 'UniformOutput',false);
    renewables_wind = cellfun(@(x)x=="wind",candi_types);
    renewables_solar = cellfun(@(x)x=="solar",candi_types);
    configuration_modified = configuration;
    
    renewables = renewables_wind | renewables_solar;
    
    if configuration_modified(renewables_wind)~=0
        configuration_modified(renewables_wind) = 1;
    end
    
    if configuration_modified(renewables_solar)~=0
        configuration_modified(renewables_solar) = 1;
    end
    
    number_of_gens = [number_of_units, configuration_modified];
    accum_number_of_gens = cumsum(number_of_gens);
    
    [capacities, probabilities] = getCapacityAndProbability(system_info,year,optimal_configuration(offset,:)); 
    peakLoad = max(getPeakLoads(year,system_info));
    normalized_capacities = cellfun(@(x) x/peakLoad,capacities, 'UniformOutput',false);
    maxCapacities = cellfun(@max,normalized_capacities);
    
    
    idx = sum(year >= system_info.ldc_year);
    x = system_info.ldc_data(idx).x;
    y = system_info.ldc_data(idx).y;
    
    STEP = 0.0005;
    
    for k = 1:size(optimal_configuration,2)
        
        if optimal_configuration(offset,k) == 0
            continue
        end
        
        columnEnd = accum_number_of_gens(length(number_of_units)+k);
        
        ELCC_periods = zeros(1,system_info.system_period_num);
        
        for period = 1:system_info.system_period_num
            ldccurves{period} = LDCCURVE(x{period},y{period});
            
            for i=1:size(normalized_capacities,2)
                
                %capacities should be a vector of different level of capacity of
                %the plant under consideration
                %probabilites is a corresponding vector of probability of the plant
                %having that much capacity
                
                %For example, for a thermal plant of rated capacity of 1 (normalzed), capacities would be
                %[1, 0] and probabilities would be [1-FOR, FOR] where FOR is
                %forced outage rate
                
                if i ~= columnEnd
                    ldccurves{period} = ldccurves{period}.process(normalized_capacities{period,i}/ratios(period), probabilities{period,i}, STEP);
                end
            end 
            
            totalCapacity = sum(maxCapacities(period,:));
            lolp = ldccurves{period}.eval(totalCapacity-maxCapacities(period,columnEnd));
            
            ldccurves{period} = ldccurves{period}.process(normalized_capacities{period,columnEnd}/ratios(period),...
                probabilities{period,columnEnd}, STEP);
            xi = 0:STEP:2;
            [yi, index] = unique(ldccurves{period}.poly(xi));
            newCap = interp1(yi,xi(index),lolp,'spline');
            ELCC_periods(period) = totalCapacity - newCap;
        end
        
        ELCC_yearly(offset,k,:) = ELCC_periods .* ratios * peakLoad;
    
    end
    
end

%seperate single giant renewable units for each unit ELCC, 1e-9 is used to
%avoid divided by 0
ELCC_yearly(:,renewables,:) = ELCC_yearly(:,renewables,:)./(optimal_configuration(:,renewables)+1e-9);

toc
