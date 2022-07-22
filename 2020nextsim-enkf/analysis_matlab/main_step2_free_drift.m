% purpose: compare OSISAF (measured) and simulated ice drift to tune ASR air drag
% coefficient.
% measurement dataset /Data/sim/data/OSISAF_ice_drift/2019,2020
%   data of second time stamp are NaN when first time stamp is in Sep. 
% modified from main_step3_optimal_air_drag_coef_test09_01
% modified from main_OSISAF.m used in Cheng et al (2020) wind/cohesion perturbations on neXtSIM
% purpose: tune air_drag_coef based on the method first presented by Rampel et al . (2016)

function [] = main_free_drift()
    clc
    clear
    close all
    dbstop if error
    format short g

    % ---------------------- settings ---------------------------
    Exp_ID='free drift OSISAF';
    start_date = "2019-10-09";  
    N_periods = 1; % number of DA cycles.          
    Duration = 9; % duration days set in nextsim.cfg    
    for i = 1:N_periods
        periods_list(i)=datetime(start_date)+(i-1)*Duration;
        for j = 1:Duration
            n =  (i-1)*Duration +j;
            dates(n) = datetime(start_date) + n - 1;    
        end
    end
    air_drag_coef=0.0016;
    Ne = length(air_drag_coef);    
    Ne_include=Ne; 
    mnt_OSISAF_dir = '/cluster/projects/nn2993k/sim/data/OSISAF_ice_drift';
    mnt_dir='/cluster/home/chengsukun/src/simulations'; 
    simul_dir = '/test_free_drift_2019-10-09_9days_x_23cycles'; 
    simul_dir = [mnt_dir simul_dir];  
    filename = 'freedrift.mat';
    if ~exist(filename)
        save(filename)
    else
        save(filename,'Exp_ID','dates','N_periods','periods_list','Ne','Ne_include','Duration','air_drag_coef','simul_dir','mnt_OSISAF_dir','-append');
    end  
    disp('fun1 load sea ice drift from simulations and OSISAF dataset')
    fun1_OSISAF_load_data(filename)  
    disp('fun2')
    fun2_OSISAF_process(filename)
    
% %% 
%     disp('fun1 load sea ice drift from simulations and OSISAF dataset')
%     fun1_OSISAF_load_data(filename) 
%     disp('fun2')
%     fun2_OSISAF_process(filename)
%     disp('fun3')
%     fun3_OSISAF_analysis_figures(filename)  
%     disp('done')
    
    
    % ---------------------------------------
    % an example process
    % n = 0;
    % for it = 1:length(dates)
    %     n = n+1;
    %     data_dir = [ simul_dir '/date' num2str(it) ];
    %     t = datetime(periods_list(it))+6;
    %     dates(n) = t;
    %     nextsim_data = '/cluster/home/chengsukun/src/nextsim/data';
    % % compare concentration with OSISAF
    %     OSISAF_dir = [ nextsim_data '/OSISAF' ];
    %     temp = strrep(datestr(t,26),'/','');
    %     filename = [ OSISAF_dir '/ice_conc_nh_polstere-100_multi_' temp '1200.nc' ];
    %     obs_data = ncread(filename,'ice_conc');
    %     lon = ncread(filename,'lon');
    %     lat = ncread(filename,'lat');
    %     data_tmp = [];
    %     data = [];
    %     filename = ['OSISAF_Drifters_' temp '.nc'];
    %     for ie = 1:ensemble_size    
    %         file_dir = [data_dir '/mem' num2str(ie) '/' filename];
    %         data_tmp = ncread(file_dir,'sic'); 
    %         data(ie,:,:) = data_tmp(:,:,1);
    %     end
    %     num_mean = squeeze(mean(data,1));
    %     bias = num_mean - obs_data;
    %     subplot(131); fun_geo_plot(lon,lat,bias,'ensemble mean analysis');
    %     subplot(132); fun_geo_plot(lon,lat,bias,'obs');
    %     subplot(133); fun_geo_plot(lon,lat,bias,'bias');
    
    % end
end

function fun_geo_plot(lon,lat,var,Title)
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);
    m_pcolor(lon, lat, var); shading flat; 
    h = colorbar;
    title(h, '(m)');
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    colormap(bluewhitered);
    title(Title)
end
