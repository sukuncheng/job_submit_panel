function [] = main_enkf_spreadnc()
    clc
    clear
    close all
    dbstop if error
    format short g
    global title_date

    main_settings
    load('test_inform.mat')
    % figure(1);set(gcf,'Position',[100,200,1300,550], 'color','w')
    % gifname = 'enkf_spreadnc.gif';
    for i = 1:N_periods
        enkf_dir = [simul_dir '/date' num2str(i) '/filter'];
        n = (i-1)*Duration +1;
        title_date = dates(n);
        fun_process_spreadnc(enkf_dir);

        % % -------- animation -------------------------------------
        % f = getframe(gcf);
        % im=frame2im(f);
        % [I,map] = rgb2ind(im,256);
        % if i==1  
        %     imwrite(I,map,gifname,'gif','loopcount',inf,'Delaytime',.5)
        % else
        %     imwrite(I,map,gifname,'gif','writemode','append','Delaytime',.5)
        % end
        % % --------------------------------------------------------
    end
    
    set(findall(gcf,'-property','FontSize'),'FontSize',16);
end

%%
function fun_process_spreadnc(enkf_dir)
    global title_date
    filename = [enkf_dir '/spread.nc']
    ncdisp(filename)
    sit    = ncread(filename,'sit');     % sea_ice_thickness
    sit_an = ncread(filename,'sit_an');  % sea_ice_thickness analysis
    %
    filename = [enkf_dir '/reference_grid.nc'];
    lon = ncread(filename,'plon'); 
    lat = ncread(filename,'plat'); 
    %
    unit = '(m)';
    fun_geo_plot(lon,lat,squeeze(sit_an - sit),datestr(title_date),unit);
%     subplot(121); fun_geo_plot(lon,lat,squeeze(sit),' sit',unit); 
%     subplot(122); fun_geo_plot(lon,lat,squeeze(sit_an),' sit analysis',unit); 
    set(findall(gcf,'-property','FontSize'),'FontSize',18); 
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
    m_coast();   
    title(Title,'fontweight','normal','HorizontalAlignment','right');
    % colormap(flipud(jet))
    % colormap(gca,bluewhitered);
    caxis([-0.9 0])
%     set(gcf,'Position',[100,200,1600,900], 'color','w')
%     set(findall(gcf,'-property','FontSize'),'FontSize',16);
end




% function [] = main_enkf_spreadnc()
%     clc
%     clear
%     close all
%     dbstop if error
%     format short g
%     % 
%     load('test_inform.mat')
%     row = 3;
%     col = 4;
%     for i = 1:N_periods
%         subplot(row,col,i)
%         enkf_dir = [ simul_dir '/date' num2str(i) '/filter'];
%         fun_process_spreadnc(enkf_dir,dates(i))
%     end
%     colorbar
%     set(gcf,'Position',[100,200,1600,900], 'color','w')
%     set(findall(gcf,'-property','FontSize'),'FontSize',16);
% %======== adjust margins between panels ==============
%     for i = 1:row*col
%         x(i,:) = get(subplot(row,col,i),'Position');
%     end
%     % it's easier to increase width,height than changing cooridinate
%     % use ratio to controls wanted size
%     ratio = 0.88;  % =1, bigger
%     dx = x(2,1)-x(1,1); % distance between horizontal two panels
%     dy = x(1,2)-x(col+1,2); % distance between vertial two panels        
%     x(:,3) = dx; % panel width
%     x(:,4) = dy*ratio; % panel height
%     x(:,1) = x(:,1) - dx*2*(1-ratio);
%     x(:,2) = x(:,2) - dy*2*(1-ratio);
%     for i = 1:row*col
%         set(subplot(row,col,i),'Position',x(i,:));
%     end
% %======================================================
% end