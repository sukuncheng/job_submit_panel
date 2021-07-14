function [] = main_enkf_fieldstates()
    %  plot prior, analysis, and their difference
    clc
    clear
    close all
    dbstop if error
    format short g
    main_settings
    load('test_inform.mat')
    simul_dir0 = simul_dir;
    simul_dir = [simul_dir '/date1'];
    
    take_mean = 0;
    if take_mean==1
        ID = 1:Ne;
    else  
        ID = 1; 
    end


    %% 1. load prior/**.nc 
    clear data data_tmp
    it = 1;
    for ie = ID
        filename = [simul_dir '/filter/prior/mem' num2str(ie,'%03d') '.nc']
        data_tmp = ncread(filename,Var); 
        data(ie,:,:) = data_tmp(:,:,it); 
    end
    forecast_data = squeeze(mean(data,1));
    lon = ncread(filename,'longitude');
    lat = ncread(filename,'latitude');

    %% 2. load **.nc.analysis
    it = 1;
    clear data data_tmp
    for ie = ID
        filename = [simul_dir '/filter/prior/mem' num2str(ie) '.nc.analysis']
        data_tmp = ncread(filename,Var); 
        data(ie,:,:) = data_tmp(:,:,it); %% change date index it =1
    end
    analysis_data = squeeze(mean(data,1));
    analysis_data(analysis_data>1) = 1;
    analysis_data(analysis_data<0) = 0;
    
%%
    figure();
    set(gcf,'Position',[100,150,1100,850], 'color','w')
    unit = '(m)';
    subplot(231); fun_geo_plot(lon,lat,forecast_data,' background',unit); colormap(gca,jet); %caxis([0 6]); 
    subplot(232); fun_geo_plot(lon,lat,analysis_data,' analysis',unit); colormap(gca,jet);  %caxis([0 6]); 
    subplot(233); fun_geo_plot(lon,lat,analysis_data-forecast_data,'analysis - background',unit);  %caxis([-2 2]); 
    colormap(gca,bluewhitered);

% %% 4. load one day forecast
    % load forecast after 1day from restart
    filename = [simul_dir '/mem1/Moorings_2019d291.nc'];
    lon = ncread(filename,'longitude');
    lat = ncread(filename,'latitude');
    MooringVar=ncread(filename,Var);
    % MooringVar1=ncread(filename,Var);
    % simul_dir = [simul_dir0 '/date1_noOcean'];
    % filename = [simul_dir '/mem1/Moorings_2019d298.nc'];
    % MooringVar2=ncread(filename,Var);
    % MooringVar = MooringVar2-MooringVar1;
    unit = '';
    % subplot(234);  fun_geo_plot(lon,lat,MooringVar,{'25-10-2018, 1-day forecast from DA';' SIC(update SST,SSS) - SIC'},unit); colormap(gca,jet);  
    subplot(234);  fun_geo_plot(lon,lat,MooringVar,'25-10-2018, 1-day forecast from DA SIC',unit); colormap(gca,jet); 
    set(findall(gcf,'-property','FontSize'),'FontSize',20); 
%% load raw observation
%% % compare with CS2-SMOS, NOTE this dataset is from Oct.15 to April
    % Var = 'sic';
    % cs2smosID='2.2';
    % mnt_CS2SMOS_dir = ['~/src/nextsim_data_dir/CS2_SMOS_v' cs2smosID];
    % t = dates(it)+Duration;
    % temp1 = strrep(datestr(t-3,26),'/','');
    % temp2 = strrep(datestr(t+3,26),'/','');
    % if strcmp(cs2smosID,'2.3')
    %     filename = [ mnt_CS2SMOS_dir '/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_' temp1 '_' temp2 '_r_v203_01_l4sit.nc' ]
    % elseif strcmp(cs2smosID,'2.2')
    %     filename = [ mnt_CS2SMOS_dir '/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_' temp1 '_' temp2 '_r_v202_01_l4sit.nc' ]
    % end
    % data_obs = ncread(filename,'analysis_sea_ice_thickness');  
    % % obs_data = ncread(filename,'sea_ice_concentration');
    % lon_obs = ncread(filename,'lon');
    % lat_obs = ncread(filename,'lat');
    % load enkf interpolated observations.nc
    filename = [ simul_dir '/filter/observations.nc'];
    lon = ncread(filename,'lon'); 
    lat = ncread(filename,'lat'); 
    y     = ncread(filename,'value');  % observation value
    Hx_a  = ncread(filename,'Hx_a');   % forecast(_f)/analysis(_a) observation (forecast observation ensemble mean)
    Hx_f  = ncread(filename,'Hx_f');
    unit = '';
    subplot(235); fun_geo_plot_scatter(lon,lat,y-Hx_a,'y - Hx_a',unit); colormap(gca,jet);
    subplot(236); fun_geo_plot_scatter(lon,lat,y-Hx_f,'y - Hx_f',unit); colormap(gca,jet);
    % std_o = ncread(filename,'std');    % standard deviation of observation error used in DA
    % std_e = ncread(filename,'std_a');  % standard deviation of the forecast(_f)/analysis(_a) observation ensemble
    if(take_mean==1)
        saveas(gcf,[ 'size' num2str(Ne) '_mean_' Var '_main_enkf_fieldstates.png'],'png');
    else
        saveas(gcf,[ 'size' num2str(Ne) '_mem' num2str(ie) '_' Var '_main_enkf_fieldstates.png'],'png');
    end
end

%
function fun_geo_plot(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
    m_pcolor(lon, lat, Var); shading flat; 
    h = colorbar;
    title(h, unit);
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({Title,''})
    m_grid('linest',':');
end

%
function fun_geo_plot_scatter(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
    m_scatter(lon, lat, 12, Var,'.'); shading flat; 
    h = colorbar;
    title(h, unit);
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({Title,''})
    m_grid('linest',':');
end