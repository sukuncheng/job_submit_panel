function [] = main_moorings_subplots()
    clc
    clear
    close all
    dbstop if error
    
    load('test_inform.mat')
    Var = 'sit';
    method = 'mean'; %'mean': ensemble ensemble, std: ensemble spread
    check_a_member = 0; % check_a_member=0 presents ensemble average
%% ------------------------------------------------------------------------ 
    figure(1)
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
    
    row = 3;  col = 4;
%     row = 1;  col = 1;
    for i = 1:N_periods
    for j = 1:Duration
        t = dates((i-1)*Duration +j);   
        data_dir = [ simul_dir '/date' num2str(i) ];
        filename = ['Moorings_' num2str(year(t-1)) 'd' num2str(day(t-1,'dayofyear'),'%03d') '.nc']
        filename = 'prior.nc';
        clear data
        if check_a_member==0
            id = 1:Ne;
        else
            id = check_a_member;
        end
        for ie = id
            file_dir = [data_dir '/mem' num2str(ie) '/' filename]
            % ncdisp(file_dir)
            data_tmp = ncread(file_dir,Var);
            data(ie,:,:) = data_tmp(:,:,1);
        end   
%         data(data==0) = nan;   % exclude open water from nextsim.Moorings
        if check_a_member>0
            X = squeeze(data);              
        else 
            if strcmp(method,'std')==1
                X = squeeze(std(data,1));
            elseif strcmp(method,'mean')==1
                X = squeeze(mean(data,1)); 
            end
        end
        
        if row>1 && col>1        
            lon = ncread(file_dir,'longitude');
            lat = ncread(file_dir,'latitude');
            subplot(row,col,it)
            
            m_pcolor(lon,lat,X); shading flat; 
            if strcmp(Var,'sic')
                caxis([0 1])
            elseif strcmp(Var,'sit')
                caxis([0 6]);
            end
            if strcmp(method,'std')
%                 caxis([0 .2]);
                colorbar
            end
            m_grid('color','k'); % 'linestyle','-'
            m_coast('patch',0.7*[1 1 1]);  

            set(gca,'Visible','off')
            title(datestr(t),'fontweight','normal','HorizontalAlignment','right');
        end
        X = reshape(X,1,[]);
        meanspread(it) = nanmean(X);
    end
    end
    meanspread'
    
    h=colorbar; 
    if strcmp(Var,'sit')
        title(h,'(m)')
    end
    % colormap(bluewhitered);
    colormap(jet)
    set(figure(1),'Position',[100,200,1600,900], 'color','w')
    set(findall(gcf,'-property','FontSize'),'FontSize',16); 
    
    %======== adjust margins between panels ==============
        for i = 1:row*col
            x(i,:) = get(subplot(row,col,i),'Position');
        end
        % it's easier to increase width,height than changing cooridinate
        % use ratio to controls wanted size
        ratio = 0.9;
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
    if check_a_member>0
        saveas(figure(1),[ Var '_mem' num2str(check_a_member) '.png'],'png')
    else
        if strcmp(method,'std')==1
            saveas(figure(1),['spread_' Var '_' datestr(t) '_main_moorings.png'],'png')
        elseif strcmp(method,'mean')==1
            saveas(figure(1),['EnsembleMean_' Var '_' datestr(t) '_main_moorings.png'],'png')
        end
    end
    
    % summary of spreads of sic & sit
    sic_spread = [ 0.019152     0.020228     0.01428     0.014675     0.017808      0.01512      0.014945     0.014417     0.015786      0.01391     0.014123     0.012929];
    sit_spread = [ 0.13308      0.11833      0.11837      0.13785      0.15046      0.15324      0.15746      0.16853       0.1683        0.16836      0.17544      0.17585];
    figure(2)
    set (figure(2),'Position',[100,200,550,400], 'color','w')
    plot(dates, sic_spread,'.-',dates, sit_spread,'.-'); 
    legend('sic spread','sit spread (m)','location','best');
    axis([dates(1)-5 dates(end)+5 0 0.2]);
    datetick('x',2)
    set(findall(gcf,'-property','FontSize'),'FontSize',18); 
    saveas(figure(2),'Spatial_average_spread_main_moorings.png','png')
end



% convergen of filter. 
% spread. 
% srf.  spread reduction 1 is the devision by 2, 
% dfs.  <=30
% R reflexision,     a matrix of ensemble mean
% square root filter apply inflation on anormalies