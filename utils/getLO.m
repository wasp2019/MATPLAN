function LO = getLO(system_info,totalExType,totalCandiType)
    LO={};
    for i = 1:totalExType
        LO{i} = struct;
        LO{i}.name = system_info.existing_gen_conf{i}.code;
        
        MWB = system_info.existing_gen_conf{i}.para(1);
        MWC = system_info.existing_gen_conf{i}.para(2);
        BH = system_info.existing_gen_conf{i}.para(4);
        IH = system_info.existing_gen_conf{i}.para(5);
        DMSTC = system_info.existing_gen_conf{i}.para(10)+system_info.existing_gen_conf{i}.para(11);
        OMF = system_info.existing_gen_conf{i}.para(13);
        
        LO{i}.FTD = DMSTC/100*(MWB*BH + (MWC-MWB)*IH)/MWC/1000 + OMF;
    end
    
    for i = 1:totalCandiType
        LO{totalExType+i} = struct;
        LO{totalExType+i}.name = system_info.candi_gen_conf.generators{i}.code;
        MWB = system_info.candi_gen_conf.generators{i}.para(1);
        MWC = system_info.candi_gen_conf.generators{i}.para(2);
        BH = system_info.candi_gen_conf.generators{i}.para(4);
        IH = system_info.candi_gen_conf.generators{i}.para(5);
        DMSTC = system_info.candi_gen_conf.generators{i}.para(10)+system_info.candi_gen_conf.generators{i}.para(11);
        OMF = system_info.candi_gen_conf.generators{i}.para(13);
        
        LO{totalExType+i}.FTD = DMSTC/100*(MWB*BH + (MWC-MWB)*IH)/MWC/1000 + OMF;
    end
    
    % Assign priority to each generation plant, small number has more priority
    FTDv = cellfun(@(x) x.FTD,LO);
    [~,index] = sort(FTDv); 
    
    for p = 1:length(index)
        LO{index(p)}.priority = p;
    end
end