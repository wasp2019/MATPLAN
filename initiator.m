clear all
clc

if ispc
    filesep = '\';
else
    filesep = '/';
end

system_info.filesep = filesep;

% get project name
project_setting = fopen('settings.json', 'r');
str = fread(project_setting, '*char').';
fclose(project_setting);
settings = jsondecode(str);
system_info.settings = settings;

%system_period_num is the total periods in a year. 4 seasons and 2 periods
%in a day (night and day) would give 8 periods in a year
system_period_num = length(system_info.settings.year_divisions_days)*length(system_info.settings.day_divisions_hours(1,:));
system_info.system_period_num = system_period_num;
system_info.study_length = diff(system_info.settings.study_period)+1;

% add path to locate the utils functions
project_path = pwd;
util_func = [project_path, filesep, 'utils'];
cartprod = [project_path, filesep, 'cartprod'];
addpath(util_func, '-end');
addpath(cartprod,'-end');
system_info.project_path = project_path;
clearvars -except system_info


%The modules order matter
LOAD_CALC %load the LOAD_CALC.json file to process load information
EXIST_GEN %load the EXIST_GEN.json file to prcess existing generations
CANDI_GEN %load the CANDI_GEN.json file to prcess the candidate generators
CONFIG %Generates the configuration tree, with all the valid (which meets 
%reserve requirement) permutations of candidate generators

%OPTIMIZE %Generate the optimal solution for generation expansion plan based on various cost calculation