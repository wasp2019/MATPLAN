function [ val ] = exp_helper( ksi,sigma,para )
%This exponential function helps to calculate the exponential part of the 
%Weibull CDF.
base = para/sigma;
temp = -1.0 * power(base, ksi);
val = exp(temp);

end

