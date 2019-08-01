function availability = getAvailability(year, configuration, system_info)
%   getAvailability Summary of this function goes here
%   The calculation procedure follows the mechanism described in pp.43-49
%   https://www.osti.gov/servlets/purl/5208341 to consider maintenance schedule.

    starting_year = system_info.settings.study_period(1);
    offset = year-starting_year + 1;
    
    paraExi = cellfun(@(x) x.para,system_info.existing_gen_conf, 'UniformOutput',false); 
    paraCandi = cellfun(@(x) x.para,system_info.candi_gen_conf.generators, 'UniformOutput',false); 
    para = [cell2mat(paraExi') cell2mat(paraCandi')];

    number_periods = system_info.system_period_num/2;
    days = diff(system_info.settings.year_divisions_days);
    days = [system_info.settings.year_divisions_days(1); days]';
    
    number_of_units = system_info.existing_gen_info.yearly_number_of_units(offset,:);
    number_of_gens = [number_of_units, configuration];

    availability = zeros(number_periods,length(number_of_gens));
    
    
    installedCapacity = para(2,:) * number_of_gens';
    installedCapacity = repmat(installedCapacity,1,number_periods);
    ratios = system_info.ldc_ratio(year>=system_info.ldc_year, 1:number_periods);
    maxLoad = ratios(end,:) .* system_info.annual_load_peak(offset);
    
    mainSpace = installedCapacity - maxLoad;
    
    mainSize = para(9,:);
    [class,~,ic] = unique(mainSize);
    
    for i = 1:length(class)
        largest = length(class)-i+1;
        classSize = class(largest);
        
        MWDAYS = sum(para(2,ic==largest).*para(8,ic==largest).*number_of_gens(ic==largest)); 
        MAINBK = classSize * 91;
        NO = MWDAYS/MAINBK;
        NO_periods = zeros(1,number_periods);
        
        REMAIN = MWDAYS;
        while REMAIN > MAINBK
            [~, idx] = max(mainSpace);
            NO_periods(idx) = NO_periods(idx)+1;
            
            mainSpace(idx) = mainSpace(idx)- MAINBK/days(idx);
            REMAIN = REMAIN - MAINBK;
        end
        
        [~, idx] = max(mainSpace);
        NO_periods(idx) = NO_periods(idx) + REMAIN/MAINBK;
        mainSpace(idx) = mainSpace(idx)- REMAIN/days(idx);
        
        main_prob = NO_periods / NO;
        
        units = find(ic==largest);
        for k = 1:length(units)
            main_days = main_prob * para(8,units(k));
            main_rate = main_days ./ days;
            %availability(:,units(k)) = (1-para(7,units(k))/100) * (1-main_rate)';
            availability(:,units(k)) = (1-main_rate)';
        end
        
    end
    
    availability = repmat(availability,2,1);
    
    existing_types = cellfun(@(x) x.type,system_info.existing_gen_conf, 'UniformOutput',false);
    candi_types = cellfun(@(x) x.type,system_info.candi_gen_conf.generators, 'UniformOutput',false);
    types = [existing_types; candi_types];
    renewables = cellfun(@(x) ~strcmp(x,'thermal'),types);
    availability(:,renewables) = 1.0;
end