function [] = main_enkf_diagnc_diagnostic()
    clc
    clear
    close all
    dbstop if error
    format short g
    
    start_date=datetime(2019,10,18);
    Ne = 40; % members   
    mnt_dir = '/Users/sukeng/Desktop/betzy/simulations/test_DAsitsic_highfreq_2019-10-18_1days_x_84cycles_memsize40_offline_perturbations';
    lons = 0:30:150;
    lats = 84*ones(1,length(lons));
    N = length(lons); 
    for k = 1:84
        if(mod(k,7)==1)
            continue
        end
        simul_dir = [mnt_dir '/date' num2str(k) '/filter'];
        thedate = start_date + k -1;
        %
        figure(1); %         set(gcf,'Position',[100,150,1400,700], 'color','w')
        set(gcf,'units','normalized','outerposition',[0 0 1 1])
        clf
        filename = [ simul_dir '/observations.nc'];
        lon = ncread(filename,'lon'); 
        lat = ncread(filename,'lat'); 
        y     = ncread(filename,'value');  % observation value
        Hx_a  = ncread(filename,'Hx_a');   % forecast(_f)/analysis(_a) observation (forecast observation ensemble mean)
        Hx_f  = ncread(filename,'Hx_f');
        unit = '';
        subplot(262);  fun_geo_pcolor_scatter(lon,lat,y,' observation sic',unit);
        subplot(263); fun_geo_pcolor_scatter(lon,lat,y-Hx_a,'sic analysis innovation: y - Hx_a',unit);
%         subplot(263); fun_geo_pcolor_scatter(lon,lat,Hx_a-Hx_f,'increment: Hx_a-Hx_f',unit);  
        colormap(gca,bluewhitered);        
        
        hold on;
        m_plot(lons,lats,'.k','markersize',12); % add investigated points
        % ----------------    
        filename = [simul_dir '/enkf_diag.nc'];
        dfs    = ncread(filename,'dfs');     % degrees of freedom of signal 
        srf    = ncread(filename,'srf');     % spread reduction factor
        nlobs  = ncread(filename,'nlobs');
    %     pdfs   = ncread(filename,'pdfs');  
    %     psrf   = ncread(filename,'psrf');   
    %     pnlobs = ncread(filename,'pnlobs');
        %
        filename = ['../reference_grid.nc'];
        lon = ncread(filename,'plon');
        lat = ncread(filename,'plat');
        unit = '';
        subplot(264); fun_geo_pcolor(lon,lat, dfs,' dfs',unit); %caxis([0 18])
        subplot(265); fun_geo_pcolor(lon,lat, srf,' srf',unit); %caxis([0 3])
        subplot(266); fun_geo_pcolor(lon,lat, nlobs,' nlobs',unit); 
    %     % pdfs seems to be the average of multi-observations. for single observation, pdfs = dfs
    %     subplot(234); fun_geo_pcolor(lon,lat,  pdfs,'pdfs',unit); 
    %     subplot(235); fun_geo_pcolor(lon,lat,  psrf,'psrf',unit); 
    %     subplot(236); fun_geo_pcolor(lon,lat,pnlobs,'pnlobs',unit); 
    
        %
        analysis_sit = ncread([simul_dir '/prior/mem001.nc.analysis'],'sit');
        prior_sit    = ncread([simul_dir '/prior/mem001.nc'],'sit');
        subplot(261); fun_geo_pcolor(lon,lat,analysis_sit,[datestr(thedate)  '   analysis sit'],'m'); 
%         set(findall(gcf,'-property','FontSize'),'FontSize',14);

       %% row 2
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

%         figure(2)
%         set(gcf,'Position',[10,150,1100,900], 'color','w')
%         clf
%         row = 3;
%         col = ceil(N/row);
        row=2;
        col=6;
        for i = 1:N   
            subplot(row,col,col+i)
            plot(prior(i).sit, prior(i).sic,'or')
            hold on
            plot(analysis(i).sit,analysis(i).sic,'.g')
            xlabel('sit (m)');
            ylabel('sic'); 
            title(['(lon,lat)=(' num2str(lons(i)) ',' num2str(lats(i)) ')'])
        end
        set(findall(gcf,'-property','FontSize'),'FontSize',15);
        saveas(figure(1),['day' num2str(k) '_maps.png'],'png')
    end  
end


function fun_geo_pcolor(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
    m_pcolor(lon, lat, Var); shading flat; 
    h = colorbar('southoutside');
    title(h, unit);
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({Title,''})
    m_grid('linest',':');
end
%
function fun_geo_pcolor_scatter(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
    m_scatter(lon, lat, 12, Var,'.'); shading flat; 
    h = colorbar('southoutside');
    title(h, unit);
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({Title,''})
    m_grid('linest',':');
end