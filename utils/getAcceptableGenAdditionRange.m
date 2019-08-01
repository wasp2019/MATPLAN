function additionRange = getAcceptableGenAdditionRange(year,system_info)
% Return the minimum and maximum additional MW acceptable for each period to meet the
% reserve margin.
%return [lowerBoundMW_period1 lowerBoundMW_period 2;  UpperBoundMW_period1, UpperBoundMW_period2 ...] of range of new candidate generator
%capacity that needs to be added to meet the reserve requirement
%
reserve_range = getReserveRange(year,system_info);
generations = getFixGenTotalCapacities(year,system_info);
additionRange = reserve_range - generations;
end

function reserve_range = getReserveRange(year,system_info)
    %return something like Example: [1000,11000,minum_for_period3; 12000, 13000,
    %maximum_for_period3]
    %1st row, minimum. 2nd row maximum. Columns are the periods
    loads = getPeakLoads(year,system_info);
    reserve_margin = getReserveMargin(year,system_info);
    reserve_range = [loads'*(1+reserve_margin(1)); loads'*(1+reserve_margin(2))];
end





function least_margin_period = getCriticalPeriod(generations,loads)
[~,index] =  min(generations-loads);
least_margin_period = index;
end

function reserveMargin = getReserveMargin(year,system_info)
% margins = [[10,30],[15,45]]
% years = [startingYear,2008]
    %assume that the reserve margins in the cand_gen.json is sorted
   reserveMargin = system_info.candi_gen_conf.reserve_margins.margins(1,:)/100;
   for i = 1: length(system_info.candi_gen_conf.reserve_margins.year)
       current_year = system_info.candi_gen_conf.reserve_margins.year(i);
       if current_year <= year
           reserveMargin = system_info.candi_gen_conf.reserve_margins.margins(i,:)/100;
       else
           break
       end
   end
end


