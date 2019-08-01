
function [eens,lolp] = calculateLOLP(system_info,year,configuration)
    %% Get load info and plot original
    % load data

    [capacities, probabilities] = getCapacityAndProbability(system_info,year,configuration);
    peakLoad = max(getPeakLoads(year,system_info));
    normalized_capacities = cellfun(@(x) x/peakLoad,capacities, 'UniformOutput',false);
    %%
    
    idx = sum(year >= system_info.ldc_year);

    x = system_info.ldc_data(idx).x;
    y = system_info.ldc_data(idx).y;

    %% Recursively

    % first consider conventional generators
    STEP = 0.0005;

    for period = 1:system_info.system_period_num
       ldccurves{period} = LDCCURVE(x{period},y{period});
    end

    for period = 1:system_info.system_period_num
        for i=1:size(normalized_capacities,2)

            %capacities should be a vector of different level of capacity of
            %the plant under consideration
            %probabilites is a corresponding vector of probability of the plant
            %having that much capacity

            %For example, for a thermal plant of rated capacity of 1 (normalzed), capacities would be
            %[1, 0] and probabilities would be [1-FOR, FOR] where FOR is
            %forced outage rate

            ldccurves{period} = ldccurves{period}.process(normalized_capacities{period,i}, probabilities{period,i}, STEP);
        end
    end

    %% Calculating LOLP (loss of load probability) and eens (equivalent energy not served)
    maxCapacities = cellfun(@max,normalized_capacities);
    totalCapacity = sum(maxCapacities,2);
    lolp = [];
    eens = [];
    for period = 1:system_info.system_period_num
        lolp(period) = ldccurves{period}.eval(totalCapacity(period));
        eens(period) = ldccurves{period}.area(totalCapacity(period),ldccurves{period}.xend);
        %fprintf("The LOLP for period %d is %d\n",period,lolp);
        %fprintf("The EENS for period %d is %d\n",period,eens);
    end
end
