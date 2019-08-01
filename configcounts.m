%helper script to print the number of configuration for each year
%only run this once the CONFIG.m module has been run

cumsum = 0;
for i = 1998:2017
    count = length(CT.yearlyConfigurationsMap(num2str(i)));
    cumsum = cumsum + count;
    fprintf('%s    %d    %d\n',num2str(i), count, cumsum);
end