function [] = main_enkf_spreadnc()
    clc
    clear
    close all
    dbstop if error
    format short g
    % 
    load('test_inform.mat')
    row = 3;
    col = 4;
    for i = 1:N_periods
        subplot(row,col,i)
        enkf_dir = [ simul_dir '/date' num2str(i) '/filter'];
        fun_process_spreadnc(enkf_dir,datestr(periods_list(i)))
    end
    colorbar
    set(gcf,'Position',[100,200,1600,900], 'color','w')
    set(findall(gcf,'-property','FontSize'),'FontSize',16);
%======== adjust margins between panels ==============
    for i = 1:row*col
        x(i,:) = get(subplot(row,col,i),'Position');
    end
    % it's easier to increase width,height than changing cooridinate
    % use ratio to controls wanted size
    ratio = 0.88;  % =1, bigger
    dx = x(2,1)-x(1,1); % distance between horizontal two panels
    dy = x(1,2)-x(col+1,2); % distance between vertial two panels        
    x(:,3) = dx; % panel width
    x(:,4) = dy*ratio; % panel height
    x(:,1) = x(:,1) - dx*2*(1-ratio);
    x(:,2) = x(:,2) - dy*2*(1-ratio);
    for i = 1:row*col
        set(subplot(row,col,i),'Position',x(i,:));
    end
%======================================================
end

%%
% calcualte the mean and std (b & d) of reduced centered random variable (RCRV) at the assimilation time. https://os.copernicus.org/articles/13/123/2017/os-13-123-2017.pdf 
% they provides simple diagnostics of whether the forecast ensemble provides a reliable estimate of the uncertainty of the ensemble mean, which is a trusted in view of the observations with the assumed uncertainties.
function fun_process_spreadnc(path,date)
    filename = [path '/spread.nc']
    ncdisp(filename)
    sit    = ncread(filename,'sit');     % sea_ice_thickness
    sit_an = ncread(filename,'sit_an');  % sea_ice_thickness analysis

    %
    filename = '../reference_grid.nc';
    lon = ncread(filename,'plon'); 
    lat = ncread(filename,'plat'); 
    %
%     figure();
%     set(gcf,'Position',[100,150,1100,850], 'color','w')
    unit = '(m)';
    fun_geo_plot(lon,lat,squeeze(sit_an - sit),date,unit);
%     subplot(121); fun_geo_plot(lon,lat,squeeze(sit),' sit',unit); 
%     subplot(122); fun_geo_plot(lon,lat,squeeze(sit_an),' sit analysis',unit); 
%     set(findall(gcf,'-property','FontSize'),'FontSize',16); 
end

%%
function fun_geo_plot(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);
    m_pcolor(lon, lat, Var); shading flat; 
    h = colorbar;
%     title(h, unit);
%     m_grid('xtick',6,'tickdir',3,'out','ytick',[70 88],'linest','-'); % replace set(gca,'Visible','off')
    m_grid('linest',':');
    m_coast('patch',0.7*[1 1 1]);   
    title(Title,'fontweight','normal','HorizontalAlignment','right');
    colormap(gca,bluewhitered);
    caxis([-0.9 0])
%     set(gcf,'Position',[100,200,1600,900], 'color','w')
%     set(findall(gcf,'-property','FontSize'),'FontSize',16);
end
