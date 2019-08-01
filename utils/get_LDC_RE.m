function [ new_peak, LDC ] = get_LDC_RE(load_file, re_file, penetration, type)
%GET_LDC Summary of this function goes here
%   Detailed explanation goes here

data = xlsread(load_file);
load = data(:);
load = load./max(load);

re_power = xlsread(re_file);
re_power = re_power./max(re_power);

%% Small tweak on the historical data to see if sequence maters or not
% Usually this part of code should be commented.

if type == 1
% Approach 1: swap head and tail
l = length(re_power);
split_point = floor(l/2/24)*24;
re_power = [re_power(split_point:l);re_power(1:split_point-1)];
elseif type == 2
% Approach 2: reverse the curve
re_power = fliplr(re_power')';
elseif type == 3
% Approach 3: randomize the data (only suitable for wind)
re_power = re_power(randperm(length(re_power)));
end

%% Get LDC
power = load - penetration.*re_power;
new_peak = max(power);

power_sort = sort(power, 'descend');

x = (1:length(power_sort))';
LDC = [x power_sort];
LDC(:,2) = LDC(:,2)/LDC(1,2);
LDC(:,1)=LDC(:,1)/length(power_sort);

LDC(:,[1,2]) = LDC(:,[2,1]);

end

