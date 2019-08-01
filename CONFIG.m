%This is equivalent to CONGEN module in WASP
%Fill the Configuration Tree with all the different permisible (meets the
%reserve requirement, and the configurations in the subsequent years can be
%reached from previous year's)configurations

clearvars -except system_info
tic
starting_year = system_info.settings.study_period(1);
ending_year = system_info.settings.study_period(2);
study_years = starting_year:ending_year;
totalCandiGenerators = length(system_info.candi_gen_conf.generators);
CT = ConfigurationTree(study_years,totalCandiGenerators); 


for year = study_years
    fprintf('Year: %d\n',year);
    %Fill the configuration for this year   
    prev_year = year-1;
    %Find the configurations for the previous_year
    prevConfigs = CT.yearlyConfigurationsMap(num2str(prev_year));
    
    candiGenRanges = getCandiGeneratorsRanges(year,system_info.candi_gen_conf); %how many units of each generators are you considering
    valid_config_count = 0;
    config_count = 0;
    for prevConfigId = prevConfigs
        config_count = config_count + 1;
        fprintf('Considering parent config %d ',config_count);
        %for each configuration in previous year, trim down the
        %candiGenRanges so that it can be reached from that configuration
        %in previous year %If in previous year, you already have 3 units of
        %a certain candidate generator, you cannot have 2 units this year.
        
        copyCandiGenRanges = candiGenRanges; %
        prevYearConfig = CT.pStore(prevConfigId,:);
        for i = 1:totalCandiGenerators
            %remove all the entries in copyCandiGenRanges for this
            %generator where the number is smaller than previousnumber,
            %since we cannot reduce the candidate generator number in
            %subsequent year
            copyCandiGenRanges{i}(copyCandiGenRanges{i}<prevYearConfig(i))=[];
        end
        
        % Generate all perumations of configurations with the available 
        %ranges for the generators. matrix. Row = different configuration, 
        %columns is unit numbers for each generator type
        possibleChildrenConfiguration = cartprod(copyCandiGenRanges); 
        
        additionRange = getAcceptableGenAdditionRange(year, system_info);
        
        %The total MW capacity of all the condidate generators for each
        %period. Dimension: Number_of_configurations X periods
        configCapacities = possibleChildrenConfiguration*system_info.candi_gen_info.capacities';
        
        validChildrenConfiguration = possibleChildrenConfiguration;
        %Make sure all the capacities are greater than the minimum
        %additionRange (additionRange(1,:)) for each periods
        validRowsSatisfyingLowerBound = all(configCapacities>=max(additionRange(1,:)),2);
        
         %Make sure all the capacities are less than the maximum
        %additionRange (additionRange(2,:)) for each periods
        validRowsSatisfyingUpperBound = all(configCapacities<=max(additionRange(2,:)),2);
        
        validRows = validRowsSatisfyingLowerBound & validRowsSatisfyingUpperBound;
        %validRows = validRowsSatisfyingLowerBound; %We only consider lower bound. Configurations exceeding upper bound (too much reserve margin) will be handled by cost based optimization later
        
        validChildrenConfiguration(~validRows,:) = [];      
 
        if ~isempty(validChildrenConfiguration)
            valid_config_count = 1;
        else
            validChildrenConfiguration = prevYearConfig;
        end
            
        fprintf('. %d Configurations being added\n', size(validChildrenConfiguration,1));
        CT.addConfigurationList(year, prevConfigId, validChildrenConfiguration);

    end
    if valid_config_count == 0
        fprintf('Year %d: No valid configs \n',year);
    end
    
    
end
toc
system_info.CT = CT;

%system_info.CT.calculateAllLOLP(system_info) %calculates the LOLP for all the configurations