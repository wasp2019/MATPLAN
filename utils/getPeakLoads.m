function peakLoads = getPeakLoads(year,system_info)
    starting_year = system_info.settings.study_period(1);
    offset = year-starting_year + 1;
    peakLoad = system_info.annual_load_peak(offset);

    %get the peak load ratio for this year which is the ratio from the largest year
    % less than the supplied year
    closest_year = -1;
    ratios = -1;
    for i = 1:length(system_info.load_conf.ldc_data)
        ldc_data = system_info.load_conf.ldc_data(i);
        if ldc_data.year <= year
            if ldc_data.year > closest_year
                closest_year = ldc_data.year;
                ratios = ldc_data.ratios;
            end
        end
    end
    if ratios == -1
        error(sprintf('getPeakLoads function: LDC data do not have ratio for the supplied year: %d. Check LDC_data.json file',year))
    end
    peakLoads = ratios*peakLoad;
end