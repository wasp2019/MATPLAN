%This is equivalent to MERSIM & DYNPRO module in WASP
%Do the cost calculation to determine the optimal configuration
%
% Tao Chen, 3/18/2019

clearvars -except system_info
tic

discount = 0.1;
starting_year = system_info.settings.study_period(1);
ending_year = system_info.settings.study_period(2);
study_years = starting_year:ending_year;
totalExType = size(system_info.existing_gen_info.capacities,2);
totalCandiType = size(system_info.candi_gen_info.capacities,2);
number_periods = system_info.system_period_num;
Nconfig = size(system_info.CT.pStore,1)-1;

%Getting loading order to determine which unit will be calculated earlier,
%which may affect the energy result and cost result
loadingOrder = getLO(system_info,totalExType,totalCandiType);

periodHours = getPeriodHours(system_info);

paraExi = cellfun(@(x) x.para,system_info.existing_gen_conf, 'UniformOutput',false); 
paraCandi = cellfun(@(x) x.para,system_info.candi_gen_conf.generators, 'UniformOutput',false); 
para = [cell2mat(paraExi') cell2mat(paraCandi')];

maintenance_days = para(8,:);





countConfig = 0;

fprintf('... Doing optimization ... '); 

%%
for year = study_years
    offset = year-starting_year+1;
    
    energy_config_year = {};
    baseEnergy_config_year = {};
    LOLP_config_year = {};
    EENS_config_year = {};
    
    pStoreIndex = system_info.CT.yearlyConfigurationsMap(num2str(year));
    yearlyConfig = system_info.CT.pStore(pStoreIndex,:);
    parfor iConfig = 1:length(pStoreIndex)
        %countConfig = countConfig+1;
        configuration = yearlyConfig(iConfig,:);
        [LOLP, EENS, baseEnergy, energy] = getEnergy(year,periodHours,system_info,loadingOrder,configuration);
       
        energy_config_year{iConfig} = energy / 1000;  % MWh --> GWh
        baseEnergy_config_year{iConfig} = baseEnergy / 1000;  % MWh --> GWh
        LOLP_config_year{iConfig} = LOLP; 
        EENS_config_year{iConfig} = EENS;  % MWh
    end
    
    energy_config_temp{offset} = energy_config_year;
    baseEnergy_config_temp{offset} = baseEnergy_config_year;
    LOLP_config_temp{offset} = LOLP_config_year;
    EENS_config_temp{offset} = EENS_config_year;
end


energy_config = [energy_config_temp{:}];
baseEnergy_config = [baseEnergy_config_temp{:}];
LOLP_config = [LOLP_config_temp{:}];
EENS_config = [EENS_config_temp{:}];

%% Fuel cost 
COST_FUEL = zeros(size(system_info.CT.pStore,1)-1, 1);
 
heatRate = para(4,:);
heatRate_increase = para(5,:);
fuelCost_domestic = para(10,:);
fuelCost_foreign = para(11,:);
fuelCost = fuelCost_domestic + fuelCost_foreign;
fuelCost = fuelCost/100; % cent --> dollar


%% O&M cost
COST_OM = zeros(size(system_info.CT.pStore,1)-1, 1);

unitCapacity = para(2,:);
FOM = para(12,:);
VOM = para(13,:);

%% Construction cost
COST_CON = cell(size(system_info.CT.pStore,1)-1, 1);

construction_cost_para = cellfun(@(x) x.depreciable_capital_cost,system_info.candi_gen_conf.generators, 'UniformOutput',false);
construction_cost_para = cell2mat(construction_cost_para');
UI = (construction_cost_para(1,:) + construction_cost_para(2,:))*1000; %Captital investment (domestic + foreign), $/kW --> $/MW
IDC = construction_cost_para(3,:);
unitCapacity_candi = unitCapacity(totalExType+1:end);

RE_solar = cellfun(@(x) strcmp(x.type, 'solar'),system_info.candi_gen_conf.generators, 'UniformOutput',false);
RE_wind = cellfun(@(x) strcmp(x.type, 'wind'),system_info.candi_gen_conf.generators, 'UniformOutput',false);
RE_solar = cell2mat(RE_solar);
RE_wind = cell2mat(RE_wind);
RE_index = RE_solar | RE_wind;

construction_cost_yearly_specific = cellfun(@(x) x.construction_cost_yearly_specific,system_info.candi_gen_conf.generators(RE_index), 'UniformOutput',false);
construction_cost_yearly_specific = cell2mat(construction_cost_yearly_specific');


%% Salvage value
COST_SAL = cell(size(system_info.CT.pStore,1)-1, 1);

plant_life = construction_cost_para(4,:);
salvageFactor = zeros(1,length(plant_life));


%% Energy-not-served cost
COST_ENS = zeros(size(system_info.CT.pStore,1)-1, 1);
CF1 = 10.0; %ENS parameter, 1 with normal constraint, 100 restrics LOLP



%%

countConfig = 0;
for year = study_years
    offset = year-starting_year+1;
    UI(RE_index) = construction_cost_yearly_specific(offset,:)*1000;
    
    tt = offset-1;
    number_of_units = system_info.existing_gen_info.yearly_number_of_units(offset,:);
    pStoreIndex = system_info.CT.yearlyConfigurationsMap(num2str(year));
    yearlyConfig = system_info.CT.pStore(pStoreIndex,:);
    for iConfig = 1:length(pStoreIndex)
        countConfig = countConfig+1;
        configuration = yearlyConfig(iConfig,:);
        
        COST_FUEL_vector = (heatRate .* sum(baseEnergy_config{countConfig}) + heatRate_increase .* sum(energy_config{countConfig}-baseEnergy_config{countConfig})) .* fuelCost; 
        
        COST_FUEL(countConfig) =  (1+discount)^(-tt-0.5) * sum(COST_FUEL_vector);  % Discounting by year
        
        totalCapacity = [number_of_units  configuration] .* unitCapacity;
        COST_OM_vector = FOM .* totalCapacity *12*1000 + VOM .* sum(energy_config{countConfig})*1000;
        COST_OM(countConfig) = (1+discount)^(-tt-0.5) * sum(COST_OM_vector);
       
        COST_ENS_vector = CF1 .* EENS_config{countConfig}; 
        COST_ENS(countConfig) = (1+discount)^(-tt-0.5) * sum(COST_ENS_vector) * 10^3;   % $/kWh --> $/MWh
        
        for k = 1:length(plant_life)
            salvageFactor(k) = (1-(1+discount)^(-plant_life(k)+(length(study_years)-offset+1)))/(1-(1+discount)^(-plant_life(k)));
        end
        
        % The constrcution cost and salvage value is determined by newly
        % added units, which implies the parent configuration does matter
        parents = find(system_info.CT.connections(:,countConfig+1)==1);
        for k = 1:length(parents)
            configuration_parent = system_info.CT.pStore(parents(k),:);
            new_added = configuration - configuration_parent;
            COST_CON_vector = new_added .* unitCapacity_candi .* UI;
            COST_CON{countConfig}(k) = (1+discount)^(-tt) * sum(COST_CON_vector);
            
            COST_SAL_vector = salvageFactor .* COST_CON_vector;
            COST_SAL{countConfig}(k) = (1+discount)^(-length(study_years)) * sum(COST_SAL_vector);
        end
        
        
    end   
end



%% Print the cost calculation results & build graph of the configuration tree
G = digraph;

countConfig = 0;
for year = study_years
    offset = year-starting_year+1;
    pStoreIndex = system_info.CT.yearlyConfigurationsMap(num2str(year));
    yearlyConfig = system_info.CT.pStore(pStoreIndex,:);
    
    
    for iConfig = 1:length(pStoreIndex)
        countConfig = countConfig+1;
        configuration = yearlyConfig(iConfig,:);
        
        fprintf('YEAR %d: PRESENT WORTH COST ( K$ ) FOR CONFIGURATION: ',year);
        disp(configuration);
        
        parents = find(system_info.CT.connections(:,countConfig+1)==1);
        for k = 1:length(parents)
            configuration_parent = system_info.CT.pStore(parents(k),:);
            fprintf('If evolving from configuration: '); 
            disp(configuration_parent);
            fprintf('CONCST %.0f, SALVAL %.0f, OPCOST %.0f, ENSCST %.0f, TOTAL %.0f \n\n',...
                COST_CON{countConfig}(k)/1000,...
                COST_SAL{countConfig}(k)/1000,...
                (COST_FUEL(countConfig)+COST_OM(countConfig))/1000,...
                COST_ENS(countConfig)/1000,...
                (COST_CON{countConfig}(k)-COST_SAL{countConfig}(k)...
				+COST_FUEL(countConfig)+COST_OM(countConfig)+COST_ENS(countConfig))/1000);
            
            G = addedge(G,parents(k),countConfig+1,...
                (COST_CON{countConfig}(k)-COST_SAL{countConfig}(k)...
				+COST_FUEL(countConfig)+COST_OM(countConfig)+COST_ENS(countConfig))/1000);
        end
        
        % Add the virtual ending node to facilitate the tree search
        if year == ending_year
            G = addedge(G,countConfig+1,size(system_info.CT.pStore,1)+1,1);
        end     
    end   
end

%% Tree search

%figure(1)
%p = plot(G,'Layout','layered');

% Use the graph structure and MATLAB built-in function to find the optimal
% solution mapping analogous to searching the shortest path
[TR, D] = shortestpathtree(G,1,size(system_info.CT.pStore,1)+1);
%figure(2)
%pTR = plot(TR,'Layout','layered');


disp('----------------------------------------------------------------------------');
disp('---------------**********************************************---------------');
disp('---------------* OPTIMAL GENERATION EXPANSION PLAN GNERATED *---------------');
disp('---------------**********************************************---------------');
disp('----------------------------------------------------------------------------');

optimal_configuration = zeros(length(study_years),totalCandiType);
sucID = 2;
optIDs = zeros(1,length(study_years));
for year = study_years
    offset = year-starting_year+1;
    optIDs(offset) = sucID;
    
    fprintf('THE OPTIMAL CONFIGURATION FOR YEAR %d: with LOLP %.3f %%',year,mean(LOLP_config{sucID-1})*100);
    disp(system_info.CT.pStore(sucID,:));
    optimal_configuration(year-starting_year+1,:) = system_info.CT.pStore(sucID,:);
    sucID = successors(TR,sucID);
end

%%
disp('-------- PRESENT WORTH COST OF THE YEAR ( K$ )--------');
disp('YEAR    OPCOST      ENSCST    LOLP             CONFIGURATION'); 
for year = fliplr(study_years)
    offset = year-starting_year+1;
    countConfig = optIDs(offset)-1;
    fprintf('%d    %6.0f    %6.0f    %6.3f%%',...
        year,(COST_FUEL(countConfig)+COST_OM(countConfig))/1000, COST_ENS(countConfig)/1000, 100*mean(LOLP_config{countConfig}));
    disp(optimal_configuration(offset,:));
end


system_info.optimal_configuration = optimal_configuration;

toc