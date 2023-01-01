function [] = main_enkf_diagnc_diagnostic()
    clc
    clear
    close all
    dbstop if error
    format short g
    
    start_date=datetime(2019,10,18);
    Ne = 40; % members   
    simul_dir ='/cluster/work/users/chengsukun/simulations/test_sic7_2019-10-18_7days_x_26cycles_memsize40';
    DA_var='sit'
    periods=26
    lons = -60:30:150; %[-60:30:150 -45:30:165];
    lats = 84*ones(1,length(lons)); %[84*ones(1,length(lons)/2) 86*ones(1,length(lons)/2)];
    row = 2;
    col = length(lons);
    N = length(lons); 
    for k = 1:periods
        k
        simul_dir = [mnt_dir '/date' num2str(k) '/filter'];
        thedate = start_date + k -1;
        %
        figure(1); %         set(gcf,'Position',[100,150,1400,700], 'color','w')
        set(gcf,'units','normalized','outerposition',[0 0 1 1])
        clf
        filename = ['../reference_grid.nc'];
        lon = ncread(filename,'plon');
        lat = ncread(filename,'plat');
        analysis_sit = ncread([simul_dir '/prior/mem001.nc.analysis'],'sit');
        prior_sit    = ncread([simul_dir '/prior/mem001.nc'],'sit');
        subplot(row,col,1); fun_geo_pcolor(lon,lat,analysis_sit-prior_sit,[datestr(thedate)  '   increment sit'],'m'); caxis([0 7]); 
        colormap(gca,summer);   
        analysis_sic = ncread([simul_dir '/prior/mem001.nc.analysis'],'sic');
        prior_sic    = ncread([simul_dir '/prior/mem001.nc'],'sic');
        subplot(row,col,2); fun_geo_pcolor(lon,lat,analysis_sic-prior_sic,[datestr(thedate)  '   increment sic'],'m'); caxis([0 7]); 
        colormap(gca,summer);    
        %
        % pre_fix = '/cluster/work/users/chengsukun/nextsim_data_dir/CS2_SMOS_v2.3/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_';
        % sur_fix = '_r_v203_01_l4sit.nc';
        % t1 = strrep(datestr(thedate-3,26),'/','');
        % t2 = strrep(datestr(thedate+3,26),'/','');
        % filename = [pre_fix t1 '_' t2 sur_fix];
        % lon = ncread(filename,'lon');
        % lat = ncread(filename,'lat');
        % Var = ncread(filename,'analysis_sea_ice_thickness');
        % subplot(row,col,2); fun_geo_pcolor(lon,lat,Var,'observation sit','m');  caxis([0 7]); colormap(gca,summer);    

        filename = [ simul_dir '/observations.nc'];
        lon = ncread(filename,'lon'); 
        lat = ncread(filename,'lat'); 
        y     = ncread(filename,'value');  % observation value
        Hx_a  = ncread(filename,'Hx_a');   % forecast(_f)/analysis(_a) observation (forecast observation ensemble mean)
        Hx_f  = ncread(filename,'Hx_f');
        unit = '';
        subplot(row,col,3); fun_geo_pcolor_scatter(lon,lat,y,[' observation ' DA_var] ,unit);  caxis([0 1]);colormap(gca,summer)
        subplot(row,col,4); fun_geo_pcolor_scatter(lon,lat,y-Hx_a,[DA_var 'analysis innovation: y - Hx_a'],unit);
        colormap(gca,bluewhitered);        
        hold on;
        m_plot(lons,lats,'.k','markersize',12); % add investigated points
        % ----------------    
        filename = [simul_dir '/enkf_diag.nc'];
        dfs    = ncread(filename,'dfs');     % degrees of freedom of signal 
        srf    = ncread(filename,'srf');     % spread reduction factor
        nlobs  = ncread(filename,'nlobs');
    %     pdfs   = ncread(filename,'pdfs');  
    %     % pdfs seems to be the average of multi-observations. for single observation, pdfs = dfs
    %     psrf   = ncread(filename,'psrf');   
    %     pnlobs = ncread(filename,'pnlobs');
        %
        filename = ['../reference_grid.nc'];
        lon = ncread(filename,'plon');
        lat = ncread(filename,'plat');
        unit = '';
        subplot(row,col,5); fun_geo_pcolor(lon,lat, dfs,' dfs',unit); colormap(gca,bluewhitered);     %caxis([0 18])
        subplot(row,col,6); fun_geo_pcolor(lon,lat, srf,' srf',unit); colormap(gca,bluewhitered);    %caxis([0 3])
        % subplot(row,col,7); fun_geo_pcolor(lon,lat, nlobs,' nlobs',unit); colormap(gca,bluewhitered);    
        %
        
        filename = [simul_dir '/spread.nc'];
        sit_an_spread = ncread(filename,'sit_an');  % sea_ice_thickness analysis
        subplot(row,col,7); fun_geo_pcolor(lon,lat,sit_an_spread,'spread of analysis sit','');
        colormap(gca,summer); 
        
        sic_an_spread = ncread(filename,'sic_an');  % sea_ice_thickness analysis
        subplot(row,col,8); fun_geo_pcolor(lon,lat,sic_an_spread,'spread of analysis sic','');
        colormap(gca,bluewhitered);  


       %% row 2 plot sic and sit from prior.nc and prior.nc.analysis, respectively
       col=2;
        for ie = 1:Ne
            filename = [simul_dir '/prior/mem' num2str(ie,'%03d') '.nc'];
            LON = ncread(filename,'longitude');
            LAT = ncread(filename,'latitude');
            pri_sic = ncread(filename,'sic');
            pri_sit = ncread(filename,'sit');        
            filename = [simul_dir '/prior/mem' num2str(ie) '.nc.analysis']; 
            ana_sic = ncread(filename,'sic');
            ana_sit = ncread(filename,'sit');
            for i = 1:N
                lon = lons(i);
                lat = lats(i);
                minimum = min(min((LON-lon).^2 + (LAT - lat).^2));
                [idx,idy] = find(((LON-lon).^2 + (LAT - lat).^2)==minimum);          
                prior(i).sic(ie) = pri_sic(idx,idy);
                prior(i).sit(ie) = pri_sit(idx,idy);
                analysis(i).sic(ie) = ana_sic(idx,idy);
                analysis(i).sit(ie) = ana_sit(idx,idy);
            end
        end
        for i = 1:N   
            subplot(row,col,col+i)
            plot(prior(i).sit, prior(i).sic,'or')
            hold on
            plot(analysis(i).sit,analysis(i).sic,'sb')
            xlabel('sit (m)');
            ylabel('sic'); 
            title(['(lon,lat)=(' num2str(lons(i)) ',' num2str(lats(i)) ')'])
        end
        legend('prior','analysis')
        set(findall(gcf,'-property','FontSize'),'FontSize',15);
        exportgraphics(figure(1),['day' num2str(k) '_maps.png'],'Resolution',300)
    end  
end
