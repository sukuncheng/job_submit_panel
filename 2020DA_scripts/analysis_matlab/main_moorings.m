function [] = main_moorings()
    clc
    clear
    close all
    dbstop if error
    format short g
    % ---------------------- settings ---------------------------
    periods_list = ["2019-09-03" "2019-9-10" "2019-9-17" "2019-9-24" "2019-10-1" "2019-10-8" ];  % d = day(t,'dayofyear')
    periods_list = ["2019-09-03"]; 
    Duration = 42; % duration days set in nextsim.cfg    %
    row = 2;
    col = 3;
    Var = 'sit';
    N_periods = length(periods_list);                     
    Ne = 40;     % ensemble_size   
%    mnt_dir  = '/nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun'; 
    mnt_dir='/cluster/work/users/chengsukun/simulations'; 
    % mnt_dir = '/Users/sukeng/Desktop/nird'; % mac;     %    mnt_dir = 'Z:\';  % window  
    simul_dir = ['/test_' periods_list{1} '_' num2str(Duration) 'days_x_' num2str(length(periods_list)) 'cycles_memsize' num2str(Ne)];
    
    simul_dir = [mnt_dir simul_dir];   

%% ------------------------------------------------------------------------

    check_a_member = 0; % check_member=0 presents ensemble average
    figure(1)
    m_proj('Stereographic','lon',-45,'lat',90,'radius',15);
    % for it = 1:length(periods_list)
        % data_dir = [ simul_dir '/date' num2str(it) ];
        % t = datetime(periods_list(it))+it;
    data_dir = [ simul_dir '/date1' ];
    for it = 1:6
        t = datetime(periods_list(1))+it*7;
    % moorings
        filename = ['Moorings_2019d' num2str(day(t-1,'dayofyear')) '.nc']
        clear data
        m = 0;
        if check_a_member==0
            id = 1:Ne;
        else
            id = check_a_member;
        end
        for ie = id
            file_dir = [data_dir '/mem' num2str(ie) '/' filename]
            % ncdisp(file_dir)
            data_tmp = ncread(file_dir,Var); 
            m = m +1;
            data(m,:,:) = data_tmp(:,:,1);
        end   
        if check_a_member>0
            X = squeeze(data);   
        else 
            X = squeeze(std(data,1));
        end
        lon = ncread(file_dir,'longitude');
        lat = ncread(file_dir,'latitude');
        % save spread plot
        subplot(row,col,it)
        m_pcolor(lon,lat,X); shading flat; % caxis([0 1])
        m_grid('color','k'); % 'linestyle','-'
        m_coast('patch',0.7*[1 1 1]);  
        colormap(bluewhitered);
        set(gca,'Visible','off')
            % % add text on plot    
            % TEXT=datestr(t);
            % Ylim=get(subplot(row,col,it),'Ylim');
            % Xlim=get(subplot(row,col,it),'Xlim');
            % tx = Xlim(2) - 0.85*(Xlim(2)-Xlim(1));
            % ty = Ylim(1) + 0.8*(Ylim(2)-Ylim(1));
            % text(double(tx),double(ty),TEXT,'color','k');
        title([datestr(t) '                      '])
        %
        X = reshape(X,1,[]);
        meanspread(it) = nanmean(X);
        dates(it) = t;
    end
    h=colorbar; 
    title(h,'(m)')
    set(figure(1),'Position',[100,200,1600,900], 'color','w')
    
    % for i = 1:row*col
    %     x(i,:) = get(subplot(row,col,i),'Position');
    % end
    % % it's easier to increase width,height than changing cooridinate
    % % use ratio to controls wanted size
    % ratio = 0.9;
    % dx = x(2,1)-x(1,1); % distance between horizontal two panels
    % dy = x(1,2)-x(4,2); % distance between vertial two panels        
    % x(:,3) = dx; % panel width
    % x(:,4) = dy*ratio; % panel height
    % x(:,1) = x(:,1) - dx*2*(1-ratio);
    % x(:,2) = x(:,2) - dy*2*(1-ratio);
    % for i = 1:row*col
    %     set(subplot(row,col,i),'Position',x(i,:));
    % end
    %
    set(findall(gcf,'-property','FontSize'),'FontSize',20); 
    if check_a_member>0
        saveas(figure(1),[ Var '_mem' num2str(check_a_member) '.png'],'png')
    else
        saveas(figure(1),['spread_' Var '_' datestr(t) '_main_moorings.png'],'png')
        figure(2)
        plot(dates, meanspread,'-o'); ylabel('Spatial averaged spread of sit (m)')
        ylim([0 0.12])
        set(findall(gcf,'-property','FontSize'),'FontSize',16); 
        saveas(figure(2),'ensemble mean of ice thickness_main_moorings.png','png')
    end
end



% convergen of filter. 
% spread. 
% srf.  spread reduction 1 is the devision by 2, 
% dfs.  <=30
% R reflexision,     a matrix of ensemble mean
% square root filter apply inflation on anormalies