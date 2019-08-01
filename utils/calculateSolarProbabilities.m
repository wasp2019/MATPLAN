function [capacities, probabilities] = calculateSolarProbabilities(system_info,solar_conf)
    full_solar_data = csvread([system_info.project_path, system_info.filesep, solar_conf.feature.path]);
    start_day = 1;
    probabilities = {};
    capacities = {};
    for p = 1:system_info.system_period_num/2 %
        
        end_day = system_info.settings.year_divisions_days(p);
        start_5minute = (start_day-1)*288 + 1; %288 many 5 minutes in a day
        end_5minute = end_day*288;

        solar_data = full_solar_data(start_5minute:end_5minute);
        start_day = end_day+1;
        solar_data(solar_data<=0) = []; %The data when power production is 0 corresponds to night time and are not considered 
        
        pv_capacity = solar_conf.capacity(p);
        
        if max(solar_data) > 1 || min(solar_data)<0
            error('Solar CSV data must be normalized')
        end
        
        N = solar_conf.state_number(1);
        Pr = zeros(1,N+1);
        for j = 1:length(solar_data)
            bin = floor(solar_data(j)*N)+1;
            Pr(bin) = Pr(bin) + 1;
        end
        Pr = Pr/length(solar_data);
        
        gap = 1-sum(Pr);
        Pr(1) = Pr(1) + gap;
        probabilities{p} = Pr;
        capacities{p} = solar_conf.capacity(p)*[1:-1/N:0];
    end
    
    %adding the night time
    %For night time, the capacities are always zero with a probability of 1
    probabilities = [probabilities, {[1],[1],[1],[1]}];
    capacities = [capacities, {[0],[0],[0],[0]}];
    
end