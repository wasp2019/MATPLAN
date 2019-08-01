function [capacities, probabilities] = getCapacityAndProbability(system_info,year,configuration)
    starting_year = system_info.settings.study_period(1);
    offset = year-starting_year + 1;
    number_of_units = system_info.existing_gen_info.yearly_number_of_units(offset,:);
    
    total_generators = length(number_of_units)+length(configuration); %both existing and candidate
    
    total_units = 0;
    number_of_gens = [number_of_units, configuration];
    capacities = {};
    probabilities = {};
    
    ucs = 1; %unit_count_start
    for i = 1:total_generators
        
        %%
        unit_number = number_of_gens(i);       
        %get plant_info from exist_gen or candi_gen as appropriate
        if i > length(number_of_units)
            plant_info = system_info.candi_gen_conf.generators{i-length(number_of_units)};
        else
            plant_info = system_info.existing_gen_conf{i};
        end
        %%
        if strcmp(plant_info.type, 'thermal') || strcmp(plant_info.type, 'hydro')
            uce = ucs + unit_number - 1; %'uce' means unit_count_end
            for p = 1:system_info.system_period_num
                capacities(p,ucs:uce) = {[plant_info.capacity(p), 0]};
                probabilities(p,ucs:uce) = {[plant_info.forced_outage_rate/100,1-plant_info.forced_outage_rate/100]};
            end
        else
            %for wind and solar, all the units of a farm are treated as one single giant unit 
            %because their power production variation are fully corelated
            if strcmp(plant_info.type, 'wind') && unit_number~=0
                uce = ucs;
                [c, p] = calculateWindProbabilities(system_info,plant_info);
                c = cellfun(@(x) x*unit_number,c, 'UniformOutput',false); %Make this a single giant unit by mulitplying the capacity by number of units
                capacities(:,ucs:uce) = c';
                probabilities(:,ucs:uce) = p';
            elseif strcmp(plant_info.type, 'solar') && unit_number~=0
                uce = ucs;
                [c, p] = calculateSolarProbabilities(system_info,plant_info);
                c = cellfun(@(x) x*unit_number,c, 'UniformOutput',false); %Make this a single giant unit by mulitplying the capacity by number of units
                capacities(:,ucs:uce) = c';
                probabilities(:,ucs:uce) = p';
            end

        end
        ucs = uce + 1;
    end
    
end