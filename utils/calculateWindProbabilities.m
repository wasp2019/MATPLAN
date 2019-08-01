function [capacities, probabilities] = calculateWindProbabilities(system_info,wind_conf)
    full_wind_data = csvread([system_info.project_path, system_info.filesep, wind_conf.feature.path]);
    
    start_day = 1;
    probabilities = {};
    capacities = {};
    for p = 1:system_info.system_period_num/2 %We don't care about day and night, so only half the periods
        end_day = system_info.settings.year_divisions_days(p);
        start_5minute = (start_day-1)*288 + 1; %288 many 5 minutes in a day
        end_5minute = end_day*288;

        wind_data = full_wind_data(start_5minute:end_5minute,:);
        start_day = end_day+1;

        ksigma = flip(wblfit(wind_data(:,1)));
               
        if max(wind_data(:,2)) > 1 || min(wind_data(:,2))<0
            error('WIND CSV data must be normalized')
        end
        
        vp_sorted = flip(sortrows(wind_data));
        start = 1;
        over = length(vp_sorted);
        while vp_sorted(start, 2) >= 0.99
            start = start + 1;
        end
        while vp_sorted(over,2) <= 0.01
            over = over - 1;
        end
        g_fit = polyfit(vp_sorted(start:over,2), vp_sorted(start:over,1), 10);

        shape = ksigma(1);
        scale = ksigma(2);

        key_speeds = wind_conf.speed;
        N = wind_conf.state_number(1);
        vin = key_speeds(1);
        vrated = key_speeds(2);
        vout = key_speeds(3);
        Pr = zeros(1,N+1);
        % Power = 0 probability
        Pr(1) = exp_helper(shape,scale,vout) + 1 - exp_helper(shape,scale,vin);
        % Power = Pmax probability
        Pr(N+1) = exp_helper(shape,scale,vrated) - exp_helper(shape,scale,vout);
        % Power in between
        for j=1:N-1
            v1 = polyval(g_fit, j/N);
            v2 = polyval(g_fit, (j+1)/N);
            Pr(j+1) = exp_helper(shape,scale,v1) - exp_helper(shape,scale,v2);
        end
        % Validate probability sum
        gap = 1-sum(Pr);
        Pr(1) = Pr(1) + gap;
        probabilities{p} = Pr;
        capacities{p} = wind_conf.capacity(p)*[1:-1/N:0];
    end
    
    %day and night are the same for wind
    probabilities = [probabilities, probabilities];
    capacities = [capacities, capacities];
    
end