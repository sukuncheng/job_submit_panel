function [] = main_OSISAF()
    clc
    clear
    close all
    dbstop if error
    format short g
    % ---------------------- settings ---------------------------
    periods_list = ["2019-10-1" ];  % d = day(t,'dayofyear')
    N_periods = length(periods_list);                     
    Duration = 7; % duration days set in nextsim.cfg    
    Ne = 100;     % ensemble_size
    Ne_include = 100;
    mnt_OSISAF_dir = '/cluster/projects/nn2993k/sim/data/OSISAF_ice_drift';
%     mnt_dir  = '/nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun'; 
    mnt_dir='/cluster/home/chengsukun/src/IO_nextsim'; 
    %mnt_dir = '/Users/sukeng/Desktop/fram'; % mac;     %    mnt_dir = 'Z:\';  % window  
    simul_dir = '/ensemble_forecasts_2019-09-03_7days_x_5cycles_memsize100'; 
    simul_dir = [mnt_dir simul_dir];   
  
%   path of output data
    filename='OSISAF_results.mat';
    if ~exist(filename)
        save(filename)
    else
        save(filename,'periods_list','N_periods','Ne','Ne_include','simul_dir','Duration','-append');
    end  
    
%% 
disp('fun1')
fun1_OSISAF_load_data(filename) 
disp('fun2')
fun2_OSISAF_process(filename)
disp('fun3')
fun3_OSISAF_analysis_figures(filename)  
disp('done')
    % n = 0;
    % for it = 1:length(periods_list)
    %     n = n+1;
    %     % data_dir = [ simul_dir '/date' num2str(it) ];
    %     data_dir = [ simul_dir '/date5'];
    %     t = datetime(periods_list(it))+6;
    %     dates(n) = t;
        %

    %     %nextsim_data = '/Users/sukeng/Desktop/fram_nextsim_data';
    %     nextsim_data = '/cluster/home/chengsukun/src/nextsim/data';

    % % compare concentration with OSISAF
    %     OSISAF_dir = [ nextsim_data '/OSISAF' ];
    %     temp = strrep(datestr(t,26),'/','');
    %     filename = [ OSISAF_dir '/ice_conc_nh_polstere-100_multi_' temp '1200.nc' ];
    %     obs_data = ncread(filename,'ice_conc');
    %     lon = ncread(filename,'lon');
    %     lat = ncread(filename,'lat');
    %     %
    %     data_tmp = [];
    %     data = [];
    %     filename = ['OSISAF_Drifters_' temp '.nc'];
    %     for ie = 1:ensemble_size    
    %         ie
    %         size(data)
    %         size(data_tmp)
    %         file_dir = [data_dir '/mem' num2str(ie) '/' filename];
    %         data_tmp = ncread(file_dir,'sic'); 
    %         data(ie,:,:) = data_tmp(:,:,1);
    %     end
    %     num_mean = squeeze(mean(data,1));
    %     bias = num_mean - obs_data;
    %     figure()
    %     subplot(131); fun_geo_plot(lon,lat,bias,'ensemble mean analysis');
    %     subplot(132); fun_geo_plot(lon,lat,bias,'obs');
    %     subplot(133); fun_geo_plot(lon,lat,bias,'bias');
    %     saveas(gcf,'OSISAF_comparison.png','png')
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
