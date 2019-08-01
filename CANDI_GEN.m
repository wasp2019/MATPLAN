filesep = system_info.filesep;

config_file = fopen(['projects', filesep, system_info.settings.project_name, filesep, 'user_input', filesep, 'CANDI-GEN-RE.json'], 'r');
str = fread(config_file, '*char').';
fclose(config_file);
gen_conf = jsondecode(str);
system_info.candi_gen_conf = gen_conf;

number_of_generators = length(gen_conf.generators);
candi_gen_info.capacities = zeros(system_info.system_period_num,number_of_generators);  

% fill the gen.capacities, gen.outage_rate and initilize all the
% gen.yearl_number_of_units to the initial number of units

for i = 1:number_of_generators
    gen_info = gen_conf.generators{i};
    candi_gen_info.capacities(:,i) = gen_info.capacity;
    candi_gen_info.outage_rate(i) = gen_info.forced_outage_rate;
end

system_info.candi_gen_info = candi_gen_info;
clearvars -except system_info
