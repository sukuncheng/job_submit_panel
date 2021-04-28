function [] = main_settings()
    format short g
%% ----------------directory settings -----------------
    Ne = 40;      
    Radius = 6378.273; % radius of earth
    % mnt_dir = '/Users/sukeng/Desktop/fram';
%     mnt_dir = '/Users/sukeng/Desktop/nird';
    mnt_dir='/cluster/work/users/chengsukun/simulations'; 
%     mnt_dir='/nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun';
    %%
    
    if 0
        Exp_ID = 'Spinup';
        start_date = "2019-09-03"; N_periods = 1; Duration = 42;
        for i = 1:Duration
            dates(i) = datetime(start_date) + i;    
            dates_num(i) = datenum(dates(i));
        end
        simul_dir = '/test_windcohesion_2019-09-03_42days_x_1cycles_memsize40';
    else
        %%
        Exp_ID = 'Exp_15Oct2019';
        start_date = "2019-10-15";
        N_periods = 12;
        Duration = 7; % duration days set in nextsim.cfg 
        
        for i = 1:N_periods
            for j = 1:Duration
                n = (i-1)*Duration +j;
                dates(n) = datetime(start_date) + n - 1;    
                dates_num(n) = datenum(dates(n));
            end
        end
        simul_dir = '/test_windcohesion_2019-10-15_7days_x_12cycles_memsize40';
    end
        
    simul_dir = [mnt_dir simul_dir];   
    save('test_inform.mat','Exp_ID','dates','N_periods','dates_num','Ne','simul_dir','Duration','Radius')
%%
%     main_ensemblesize
%     main_moorings_spinup
%     main_moorings   % plot temporal average and spatial averages of spread of sit 
%     main_observation_RCRV