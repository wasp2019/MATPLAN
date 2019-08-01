function [LOLP, EENS, baseEnergy, energy] = getEnergy(year,periodHours,system_info,loadingOrder,configuration)
    %% Get energy (expected generation for each plant feeding to cost calculation)
    
    ratios = system_info.ldc_ratio(1,:);
    starting_year = system_info.settings.study_period(1);
    offset = year-starting_year + 1;
    number_of_units = system_info.existing_gen_info.yearly_number_of_units(offset,:);
    
    total_generators = length(number_of_units)+length(configuration); %both existing and candidate
    
    %baseEnergy = zeros(system_info.system_period_num, total_generators);
    %peakEnergy = zeros(system_info.system_period_num, total_generators);
    
    LOLP = zeros(1,system_info.system_period_num);
    EENS = zeros(1,system_info.system_period_num);
    
    [capacities, probabilities] = getCapacityAndProbability(system_info,year,configuration);
    
    availability = getAvailability(year, configuration, system_info);
      
    peakLoad = max(getPeakLoads(year,system_info));
    normalized_capacities = cellfun(@(x) x/peakLoad, capacities, 'UniformOutput',false);
    %%
    
    baseCapExi = cellfun(@(x) x.para(1),system_info.existing_gen_conf, 'UniformOutput',false); 
    baseCapCandi = cellfun(@(x) x.para(1),system_info.candi_gen_conf.generators, 'UniformOutput',false);
   
    normalized_baseCapacities = [cell2mat(baseCapExi); cell2mat(baseCapCandi)]/peakLoad;
    
    peakCapExi = cellfun(@(x) x.para(2)-x.para(1), system_info.existing_gen_conf, 'UniformOutput',false); 
    peakCapCandi = cellfun(@(x) x.para(2)-x.para(1), system_info.candi_gen_conf.generators, 'UniformOutput',false);
   
    normalized_peakCapacities = [cell2mat(peakCapExi); cell2mat(peakCapCandi)]/peakLoad;
    

    % --- Renewable units are combined as a single giant unit -------------------------
    existing_types = cellfun(@(x) x.type,system_info.existing_gen_conf, 'UniformOutput',false);
    candi_types = cellfun(@(x) x.type,system_info.candi_gen_conf.generators, 'UniformOutput',false);
    
    types = [existing_types; candi_types];
    
    renewables_wind = cellfun(@(x)strcmp(x,'wind'),candi_types);
    renewables_solar = cellfun(@(x)strcmp(x,'solar'),candi_types);
    configuration_modified = configuration;
    
    if configuration_modified(renewables_wind)~=0
        configuration_modified(renewables_wind) = 1;
    end
    
    if configuration_modified(renewables_solar)~=0
        configuration_modified(renewables_solar) = 1;
    end
    
    number_of_gens_unmodified = [number_of_units, configuration];
    number_of_gens = [number_of_units, configuration_modified];
    accum_number_of_gens = cumsum(number_of_gens);
    % ---------------------------------------------------------------------------------

    % first consider conventional generators
    STEP = 0.0005;

    
    priority = cellfun(@(x) x.priority, loadingOrder, 'UniformOutput', false);
    priority = cell2mat(priority);
    [~,indexP] = sort(priority);
   

    parfor period = 1:system_info.system_period_num
        baseEnergy_period = zeros(1,total_generators);
        peakEnergy_period = zeros(1,total_generators);
        
        x = system_info.ldc_data.x;
        y = system_info.ldc_data.y;
        ldccurves{period} = LDCCURVE(x{period},y{period});
        
        capacityBeforeAdding = 0;
        for jj = 1:length(indexP)
                      
            if number_of_gens(indexP(jj)) == 0
                baseEnergy_period(indexP(jj)) = 0;
            else          
            
            columnBegin = accum_number_of_gens(indexP(jj))-number_of_gens(indexP(jj))+1;
            columnEnd = accum_number_of_gens(indexP(jj));
            
            each_normalized_capacities = normalized_capacities(period,columnBegin:columnEnd);
            maxUnitCapacity = cellfun(@max,each_normalized_capacities);
            eachPlantCapacity = sum(maxUnitCapacity);
            
            eachPlantBaseCapacity = normalized_baseCapacities(indexP(jj))*number_of_gens_unmodified(indexP(jj));
            
            if ~strcmp(types(indexP(jj)),'thermal')
                eachPlantBaseCapacity = eachPlantCapacity;
            end
            
            % discounting by maintenance
            eachPlantCapacity = availability(period, indexP(jj)) * eachPlantCapacity / ratios(period);
            eachPlantBaseCapacity = availability(period, indexP(jj)) * eachPlantBaseCapacity / ratios(period);
            % discounting by maintenance
            
            normalized_energy_base = ldccurves{period}.area(capacityBeforeAdding, capacityBeforeAdding + eachPlantBaseCapacity);
              
            baseEnergy_period(indexP(jj)) = max(cell2mat(probabilities(period,columnEnd))) * periodHours(period) * peakLoad * normalized_energy_base * ratios(period);            
            baseEnergy(period,:) = baseEnergy_period;
            
            % After doing the integral for LDC   
            EL_normalized = cellfun(@(x) x*(eachPlantBaseCapacity/eachPlantCapacity)/ratios(period), normalized_capacities(period,columnBegin:columnEnd), 'UniformOutput',false);
            EL_probabilities = probabilities(period,columnBegin:columnEnd);
            
    
            
            
            for k = 1:columnEnd-columnBegin+1
                ldccurves{period} = ldccurves{period}.process(EL_normalized{k}, EL_probabilities{k}, STEP);
            end

            capacityBeforeAdding = capacityBeforeAdding + eachPlantBaseCapacity;
                
            end        
        end 
        
        %Peak capacity dispatched after the schedule of base capacity
        
        for jj = 1:length(indexP)
                      
            if number_of_gens(indexP(jj)) == 0
                peakEnergy_period(indexP(jj)) = 0;
            else          
            
            columnBegin = accum_number_of_gens(indexP(jj))-number_of_gens(indexP(jj))+1;
            columnEnd = accum_number_of_gens(indexP(jj));
            
            each_normalized_capacities = normalized_capacities(period,columnBegin:columnEnd);
            maxUnitCapacity = cellfun(@max,each_normalized_capacities);
            eachPlantCapacity = sum(maxUnitCapacity);
            
            eachPlantPeakCapacity = normalized_peakCapacities(indexP(jj))*number_of_gens_unmodified(indexP(jj));
            
            % discounting by maintenance
            eachPlantCapacity =  availability(period, indexP(jj)) * eachPlantCapacity / ratios(period);
            eachPlantPeakCapacity = availability(period, indexP(jj)) * eachPlantPeakCapacity / ratios(period);
            % discounting by maintenance
            
            normalized_energy_peak = ldccurves{period}.area(capacityBeforeAdding, capacityBeforeAdding + eachPlantPeakCapacity);
                
            peakEnergy_period(indexP(jj)) = max(cell2mat(probabilities(period,columnEnd))) * periodHours(period) * peakLoad * normalized_energy_peak * ratios(period);
            peakEnergy(period,:) = peakEnergy_period;
  
            % After doing the integral for LDC   
            EL_normalized = cellfun(@(x) x*(eachPlantPeakCapacity/eachPlantCapacity)/ratios(period), normalized_capacities(period,columnBegin:columnEnd), 'UniformOutput',false);
            EL_probabilities = probabilities(period,columnBegin:columnEnd);
            
            %if types(indexP(jj))=="thermal"
            %    cellfun(@(x) x*availability(period, indexP(jj)), EL_probabilities, 'UniformOutput',false);
            %end
            
            for k = 1:columnEnd-columnBegin+1
                ldccurves{period} = ldccurves{period}.process(EL_normalized{k}, EL_probabilities{k}, STEP);
            end

            capacityBeforeAdding = capacityBeforeAdding + eachPlantPeakCapacity;
                
            end        
        end 
        
        LOLP(period) = ldccurves{period}.eval(capacityBeforeAdding);
        EENS(period) = ldccurves{period}.area(capacityBeforeAdding, ldccurves{period}.xend) * periodHours(period) * peakLoad * ratios(period);          
    end
    
    energy = baseEnergy + peakEnergy;
end