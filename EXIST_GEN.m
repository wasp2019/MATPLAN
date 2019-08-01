%This module is equivalent to FIXSYS in WASP

% get generator data from json configuration file

filesep = system_info.filesep;

config_file = fopen(['projects',filesep, system_info.settings.project_name, filesep, 'user_input', filesep, 'EXIST-GEN-NH.json'], 'r');
str = fread(config_file, '*char').';
fclose(config_file);
gen_conf = jsondecode(str);
system_info.existing_gen_conf = gen_conf;

number_of_generators = length(gen_conf);

existing_gen_info.capacities = zeros(system_info.system_period_num,number_of_generators);  
existing_gen_info.yearly_number_of_units = zeros(system_info.study_length,number_of_generators);

% fill the gen.capacities, gen.outage_rate and initilize all the
% gen.yearl_number_of_units to the initial number of units
for i = 1:number_of_generators
    gen_info = gen_conf{i};
    existing_gen_info.capacities(:,i) = gen_info.capacity;
    existing_gen_info.outage_rate(i) = gen_info.forced_outage_rate;
    existing_gen_info.yearly_number_of_units(:,i) = gen_info.unit_number;

end

%go through each year entry in the EXIST_GEN.json and fill in the number of
%units of each generator types (into yearly_number_of_units), for each year, 
%taking into account planned additions and retirements
starting_year = system_info.settings.study_period(1);
for i = 1:number_of_generators
    gen_info = gen_conf{i};
    if isfield(gen_info.existing_plan,'year')
        offsets = gen_info.existing_plan.year - starting_year + 1;
        for j = 1:length(offsets)
            offset = offsets(j);
            retirement = gen_info.existing_plan.number(j);
            existing_gen_info.yearly_number_of_units(offset:end,i) = existing_gen_info.yearly_number_of_units(offset:end,i) + retirement;
        end
    end
end

system_info.existing_gen_info = existing_gen_info;
clearvars -except system_info
