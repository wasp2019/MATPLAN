function rangeOfCandiGens = getCandiGeneratorsRanges(year, candi_conf)
%for a give year, it returns cell array of ranges for each candidate
%generators like {[2,3,4],[4,5,6],[6,7,8]} (length = number of candi-gen)


rangeOfCandiGens = cell(1,length(candi_conf.generators));
for i = 1:length(candi_conf.generators)
    plan = candi_conf.generators{i}.plans;
    range = [0, 0];
    for idx = 1:length(plan.year)
        if year >= plan.year(idx)
            range = plan.number(idx,:);
        else
            break
        end
    end
    
    possible_installation = [range(1):range(1)+range(2)];
    rangeOfCandiGens{i} = possible_installation;

end

