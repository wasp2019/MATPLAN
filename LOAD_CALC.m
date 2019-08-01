%Equivalent to LOAD_CALC moudle in WASP

clearvars -except system_info;

project_name = system_info.settings.project_name;

% get load data from json configuration file
config_file = fopen(['projects', filesep, project_name, filesep, 'user_input', filesep, 'LOAD-CALC.json'], 'r');
str = fread(config_file, '*char').';
fclose(config_file);
load_conf = jsondecode(str);

% validate dimension is matching
study_year_length = diff(system_info.settings.study_period)+1;
annual_load_peaks = load_conf.peak;
if study_year_length ~= length(annual_load_peaks)
    error('Year number and annual load peak configuration do not match!')
end


ldc_ratio = [];
ldc_year = [];
% transforming LDC data into X,Y form if not in this form
ldc_data = []; %initialzing

for i = 1:length(load_conf.ldc_data)
    ldc_info = load_conf.ldc_data(i);
    ldc_year = [ldc_year, ldc_info.year];
    ldc_ratio = [ldc_ratio; ldc_info.ratios'];
    if ldc_info.type == 0
        % Type 0: Time series load profile
        %TODO 
        error('Not implemented yet.')
        %ldc = get_LDC(ldc_info.path);
        %ldc_data(i).x{1} = ldc(:,1);
        %ldc_data(i).y{1} = ldc(:,2);
    elseif ldc_info.type == 1
        % Type 1: LDC data points
        data_period_num = length(ldc_info.data);
        
        if data_period_num ~= system_info.system_period_num
            error('Error reading type 1 load. Data periods should match system periods')
        end
        
        
        for period_id = 1:data_period_num
            data_path = ldc_info.data{period_id};
            ldc = csvread(data_path);
            %Need to scale the LDC data according to the period load ratios
            
            %ldc_data(i).x{period_id} = ldc(:,1)' * ldc_info.ratios(period_id);
            ldc_data(i).x{period_id} = ldc(:,1)';
            
            ldc_data(i).y{period_id} = ldc(:,2)';
        end
    else
        % Type 2: LDC represented in coefficient
        data_period_num = length(ldc_info.data);
       
        if data_period_num ~= system_info.system_period_num
            error('Error reading type 2 load. Data periods should match system periods')
        end
        
        for period_id = 1:data_period_num
            ldc_coe = ldc_info.data(period_id,:);
            ldc_coe = fliplr(ldc_coe);
            x = [0:0.01:1.0];
            y = polyval(ldc_coe, x);
            y(end) = 0.0;
            %Need to scale the LDC data according to the period load ratios
            %for each period of the year
            
            %ldc_data(i).x{period_id} = y' * ldc_info.ratios(period_id);
            ldc_data(i).x{period_id} = y';
            
            ldc_data(i).y{period_id} = x';
        end
    end
end
%%
system_info.ldc_data = ldc_data;
system_info.annual_load_peak = annual_load_peaks;
system_info.ldc_year = ldc_year;
system_info.ldc_ratio = ldc_ratio;
system_info.load_conf = load_conf;
clearvars -except system_info;
