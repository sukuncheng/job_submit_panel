function [] = main_settings()
    format short g
%% ----------------directory settings -----------------
    Ne = 40;      
    Radius = 6378.273; % radius of earth
    % mnt_dir = '/Users/sukeng/Desktop/fram';
%     mnt_dir = '/Users/sukeng/Desktop/nird';
    mnt_dir='/cluster/work/users/chengsukun/simulations'; 
    % mnt_dir='/nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun';
    %%
    exp=5; 
    if exp==5
        Exp_ID = 'Exp_sic1sit7';
        start_date = '2019-10-18';
        N_periods = 154;
        Duration = 1;
        simul_dir = '/test_sic1sit7_2019-10-18_1days_x_182cycles_memsize40';
    elseif exp==4
        Exp_ID = 'Exp_sic7sit7';
        start_date = '2019-10-18';
        N_periods = 26;
        Duration = 7; % duration days set in nextsim.cfg         
        simul_dir = '/test_sic7sit7_2019-10-18_7days_x_26cycles_memsize40';        
    elseif exp==3
        Exp_ID = 'Exp_sic7';
        start_date = '2019-10-18';
        N_periods = 26;
        Duration = 7; % duration days set in nextsim.cfg         
        simul_dir = '/test_sic7_2019-10-18_7days_x_26cycles_memsize40_d15'; %'/test_sic7_2019-10-18_7days_x_26cycles_memsize40';        
    elseif exp==2
        Exp_ID = 'Exp_sit7';
        start_date = '2019-10-18';
        N_periods = 26;
        Duration = 7; % duration days set in nextsim.cfg         
        simul_dir = '/test_sit7_2019-10-18_7days_x_26cycles_memsize40';
    elseif exp==1
        Exp_ID = 'Exp_FreeRun_D5';
        start_date = "2019-10-18";
        N_periods = 26;                                         
        Duration = 7; % duration days set in nextsim.cfg
        simul_dir = '/test_FreeRun_2019-10-18_7days_x_26cycles_memsize40_OceanNudgingDd5';
    elseif exp==0
        Exp_ID = 'Spinup_D5';
        start_date = "2019-09-03"; 
        N_periods = 1; 
        Duration = 45;
        simul_dir = '/test_spinup_2019-09-03_45days_x_1cycles_memsize40_OceanNudgingDd5';
    end    
    for i = 1:N_periods
        for j = 1:Duration
            n = (i-1)*Duration +j;
            dates(n) = datetime(start_date) + n - 1;    
            dates_num(n) = datenum(dates(n));
        end
    end    
    simul_dir = [mnt_dir simul_dir];   
    save('test_inform.mat','Exp_ID','dates','N_periods','dates_num','Ne','simul_dir','Duration','Radius')
%%
%     main_ensemblesize
% main_moorings_animation
% 
% % main_enkf_observationsnc  % compare cs2smos data and interpolated data
% main_observationnc_statstics
% main_enkf_diagnc  % dfs,srf, nlobs
% main_enkf_spreadnc
% main_enkf_background_analysis_field
% main_enkfcalc_statistics
