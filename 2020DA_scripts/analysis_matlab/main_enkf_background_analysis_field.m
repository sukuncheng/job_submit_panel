function [] = main_enkf_fieldstates()
    clc
    clear
    close all
    dbstop if error
    format short g
    %
    global  title_date ID
    load('test_inform.mat')
    ID = 1:Ne; %take ensemble mean.
    % where ID are indices of ensemble members included in calculation. 
    % ID = n indicates the plot only show results from n-th member 
    
    gifname = [ Exp_ID '_background_analysis_field_sit.gif'];
    for i = 1:N_periods
        n = (i-1)*Duration +1;
        title_date = dates(n);
        enkf_dir = [ simul_dir '/date' num2str(i) '/filter'];
        fun_plot_background_analysis_fields(enkf_dir)
    end
    % -------- animation -------------------------------------
    f = getframe(gcf);
    im=frame2im(f);
    [I,map] = rgb2ind(im,256);
    if i==1  
        imwrite(I,map,gifname,'gif','loopcount',inf,'Delaytime',.5)
    else
        imwrite(I,map,gifname,'gif','writemode','append','Delaytime',.5)
    end
    % -------------------------------------------------------- 
end
%%
function fun_plot_background_analysis_fields(enkf_dir)
    global  title_date ID
% % compare with CS2-SMOS, NOTE this dataset is from Oct.15 to April
    Var = 'sit';
    %% load analysis data, **.nc.analysis
    it = 1;
    clear data data_tmp
    for ie = ID
        filename = [enkf_dir '/prior/mem' num2str(ie,'%03d') '.nc.analysis'];
        data_tmp = ncread(filename,Var); 
        data(ie,:,:) = data_tmp(:,:,it); %% change date index it =1
    end
    analysis_data = squeeze(mean(data,1));

    %% load background data, **.nc 
    clear data data_tmp
    for ie = ID
        filename = [enkf_dir '/prior/mem' num2str(ie,'%03d') '.nc'];
        data_tmp = ncread(filename,Var); 
        data(ie,:,:) = data_tmp(:,:,it); 
    end
    forecast_data = squeeze(mean(data,1));
    lon = ncread(filename,'longitude');
    lat = ncread(filename,'latitude');

%% load observation
    mnt_CS2SMOS_dir = '~/src/nextsim_data_dir/CS2_SMOS_v2.2';
    t = dates(it)+Duration;
    temp1 = strrep(datestr(t,26),'/','');
    temp2 = strrep(datestr(t+Duration-1,26),'/','');
    filename = [ mnt_CS2SMOS_dir '/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_' temp1 '_' temp2 '_r_v202_01_l4sit.nc' ]
    data_obs = ncread(filename,'analysis_sea_ice_thickness');  
    % obs_data = ncread(filename,'sea_ice_concentration');
    lon_obs = ncread(filename,'lon');
    lat_obs = ncread(filename,'lat');

%%  make plot
    figure(1); set(gcf,'Position',[100,150,1100,850], 'color','w');clf
    unit = '(m)';
    subplot(221); fun_geo_plot(lon,lat,forecast_data,' background',unit); caxis([0 6]); 
    subplot(222); fun_geo_plot(lon,lat,analysis_data,' analysis',unit); caxis([0 6]); 
    subplot(223); fun_geo_plot(lon,lat,analysis_data-forecast_data,'analysis - background',unit);  %caxis([-2 2]); 
    subplot(224); fun_geo_plot(lon_obs,lat_obs, data_obs,['observation ' temp1],unit); caxis([0 6]);
    set(findall(gcf,'-property','FontSize'),'FontSize',16); 
end

function fun_geo_plot(lon,lat,Var,Title, unit)
    % Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
    m_pcolor(lon, lat, Var); shading flat; 
    h = colorbar;
    title(h, unit);
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title(Title)
    colormap(gca,bluewhitered);
    m_grid('linest',':');
end
