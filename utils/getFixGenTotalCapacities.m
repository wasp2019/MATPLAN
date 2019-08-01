function genCapacities = getFixGenTotalCapacities(year,system_info)

%return the total existing generator capacities for the periods for this year
 
starting_year = system_info.settings.study_period(1);
offset = year-starting_year + 1;

number_of_units = system_info.existing_gen_info.yearly_number_of_units(offset,:);

capacities_of_units = system_info.existing_gen_info.capacities; %Matrix. rows = capacity for different periods. Columns = different generators
totalCapacity = number_of_units*capacities_of_units';
genCapacities = totalCapacity; 
end