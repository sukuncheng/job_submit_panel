function [] = main_prior()
    clc
    clear
    close all
    dbstop if error
    format short g
    % ---------------------- settings ---------------------------
    periods_list = ["2019-9-3" "2019-9-10" "2019-9-17" "2019-9-24" "2019-10-1" "2019-10-8" ];  % d = day(t,'dayofyear')
    N_periods = length(periods_list);                     
    Duration = 7; % duration days set in nextsim.cfg    
    Ne = 40;     % ensemble_size   
   mnt_dir  = '/nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun'; 
    % mnt_dir='/cluster/home/chengsukun/src/simulations'; 
    % mnt_dir = '/Users/sukeng/Desktop/nird'; % mac;     %    mnt_dir = 'Z:\';  % window  
    simul_dir = '/ensemble_forecasts_2019-09-03_7days_x_6cycles_memsize100'; 
    simul_dir = [mnt_dir simul_dir];   

%% ------------------------------------------------------------------------
    Var = 'sit';
    check_a_member = 1; % check_member=Ne presents ensemble average
    n = 0;
    figure(1)
    m_proj('Stereographic','lon',-45,'lat',90,'radius',18);
    for it = 1:length(periods_list)
        n = n+1;
        data_dir = [ simul_dir '/date' num2str(it) ];
        t = datetime(periods_list(it))+Duration;
    % priors
        clear data
        m = 0;
        for ie = 1:Ne
            filename = [simul_dir '/filter/prior/mem' num2str(ie,'%03d') '.nc'];
            data_tmp = ncread(filename,Var); 
            m = m +1;
            data(ie,:,:) = data_tmp(:,:,it); 
        end 
        forecast_data = squeeze(std(data,1));
        if check_a_member==1
            forecast_data = squeeze(data);   
        else 
            forecast_data = squeeze(std(data,1));
        end
        lon = ncread(file_dir,'longitude');
        lat = ncread(file_dir,'latitude');
        % save spread plot
        subplot(2,3,n)
        m_pcolor(lon,lat,forecast_data); shading flat; caxis([0 2.2])
        m_coast('patch',0.7*[1 1 1]);  
        colormap(bluewhitered);
        set(gca,'Visible','off')
            % add text on plot    
            TEXT=datestr(t);
            Ylim=get(subplot(2,3,n),'Ylim');
            Xlim=get(subplot(2,3,n),'Xlim');
            tx = Xlim(2) - 0.85*(Xlim(2)-Xlim(1));
            ty = Ylim(1) + 0.88*(Ylim(2)-Ylim(1));
            text(double(tx),double(ty),TEXT,'color','k');
        %
        X = reshape(X,1,[]);
        meanspread(n) = nanmean(X);
        dates(n) = t+1;
    end
    colorbar; 
    set(figure(1),'Position',[100,200,1600,900], 'color','w')
    row = 2;
    col = 3;
    for i = 1:row*col
        x(i,:) = get(subplot(row,col,i),'Position');
    end
    % it's easier to increase width,height than changing cooridinate
    % use ratio to controls wanted size
    ratio = 0.95;
    dx = x(2,1)-x(1,1); % distance between horizontal two panels
    dy = x(1,2)-x(4,2); % distance between vertial two panels        
    x(:,3) = dx; % panel width
    x(:,4) = dy*ratio; % panel height
    x(:,1) = x(:,1) - dx*2*(1-ratio);
    x(:,2) = x(:,2) - dy*2*(1-ratio);
    for i = 1:row*col
        set(subplot(row,col,i),'Position',x(i,:));
    end
    %
    set(findall(gcf,'-property','FontSize'),'FontSize',20); 
    if check_a_member==1
        saveas(figure(1),[ Var '_' datestr(t) '_main_priors.png'],'png')
    else
        saveas(figure(1),['spread_' Var '_' datestr(t) '_main_priors.png'],'png')
        figure(2)
        plot(dates, meanspread,'-o'); ylabel('Spatial averaged spread of sit (m)')
        ylim([0 0.12])
        set(findall(gcf,'-property','FontSize'),'FontSize',16); 
        saveas(figure(2),'ensemble mean of ice thickness_main_priors.png','png')
    end
end
