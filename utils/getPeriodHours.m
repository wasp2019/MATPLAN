function periodHours = getPeriodHours(system_info)
    days = diff(system_info.settings.year_divisions_days);
    days = [system_info.settings.year_divisions_days(1); days];
    
    DayHours = system_info.settings.day_divisions_hours(:,2)-system_info.settings.day_divisions_hours(:,1);
    NightHours = 24 - DayHours;
    
    periodHours = [days; days].*[DayHours; NightHours];
end