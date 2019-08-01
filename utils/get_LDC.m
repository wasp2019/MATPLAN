function [ LDC ] = get_LDC(filename)
%GET_LDC Summary of this function goes here
%   The input file should be MS Excel file, with data of a whole year's
%   profile: can be a 365*24 matrix.
data = csvread(filename);
power = data(:);
power_sort = sort(power, 'descend');

x = (1:length(power_sort))';
LDC = [x power_sort];
LDC(:,2) = LDC(:,2)/LDC(1,2);
LDC(:,1)=LDC(:,1)/length(power_sort);

LDC(:,[1,2]) = LDC(:,[2,1]);

end

