function fun4_buoy_analysis_figures(filename,pattern)
global line_type color_type colors
    colors = flipud(lines(3));
    line_types = {'-','--',':'};    
    line_type = string(line_types(pattern));
    color_type= colors(pattern,:);  
    %% equally spaced drifter
%     figure(1); fun_plot_buoy_initial_position(filename)  % figure 1c
%     figure(5);fun_spread_rmse_vs_days(filename)
%     figure(6); fun_ensemble_spread_vs_day(filename,'area')
%     figure(7); fun_plot_spatial_distribution(filename,'area'); 
% % Figure 8
%     figure(9);fun_ensemble_spread_vs_day(filename,'anisotropy')
%     figure(10); fun_plot_spatial_distribution(filename,'anisotropy'); 

    
    %% iabp. not present
    %     figure(171);fun_ellipse_evolution_biGaussian_fit(filename); % the area seems not be affected by the choices of vwnd
    %     figure(16); fun_taylor_diagram(filename)
    %     figure(18); fun_plot_error_vs_spread_12h(filename);       
    %     figure(101);fun_POC_GaussianFit(filename )  
    %     figure(19); fun_POC(filename)
%     figure(106); fun_plot_forecast_error_e_IABP(filename)  % 
%       fun_plot_forecast_error_e_EqDrifter(filename)  % figure 151,152\   
%     figure(101); fun_pdf_of_b(filename); % large value at x=0 since non-moved drifters are accounted for. 
%     figure(102); fun_bi2_vs_days(filename); 
%     figure(105); fun_buoy_positions(filename)
    end
    %%-----------------------------------------------------------
    function fun_plot_buoy_initial_position(filename)
        load(filename)    
        m_proj('Stereographic','lon',-45,'lat',90,'radius',25);   
        m_coast('patch',0.7*[1 1 1]);
        axis equal
        hold on
        it = 2;
        %
        iperiod = 1; % shor term No. 
        X = EqDrifter(iperiod).features.B_pos_x(:,it); 
        Y = EqDrifter(iperiod).features.B_pos_y(:,it); 
        plot(X/Radius,Y/Radius,'.b');
        
        id = find(EqDrifter(iperiod).features.dist2coast>100);	
        X = EqDrifter(iperiod).features.B_pos_x(id,it); 
        Y = EqDrifter(iperiod).features.B_pos_y(id,it); 
        plot(X/Radius,Y/Radius,'.g');   
        set(gca,'XTickLabel',[],'YTickLabel',[])
        % add iabp buoy position
        x = [];
        y = [];
        for iperiod = 1:N_periods
            for it= 1:11
            for ibuoy = 1:size(IABP(iperiod).data.Obs_pos_x,1)
                x = [x IABP(iperiod).data.Obs_pos_x(ibuoy,it)];
                y = [y IABP(iperiod).data.Obs_pos_y(ibuoy,it)];
            end
            end
        end
        x = x/Radius;
        y = y/Radius;
        plot(x,y,'.r')        
    end
    %%------------------------------------------------------------
    function fun_plot_spatial_distribution(filename,variable)
    disp('adjust the position of color bar')
    set (gcf,'Position',[100,200,1100,300], 'color','w')
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);   
    load(filename)    
    d0 = 100; % minimum distance of buoys from the shore
    days = [3 5 7];
    for iday = 1:length(days)        
        day = days(iday);
        it = 1+2*day;
        %
        X = [];Y = [];Z = [];    
        for iperiod = 1:N_periods
            id = find(EqDrifter(iperiod).features.dist2coast>d0);
            X = [X; EqDrifter(iperiod).features.B_pos_x(id,it)]; % feature of all buoys at given time
            Y = [Y; EqDrifter(iperiod).features.B_pos_y(id,it)];        
            for j = id
                try
                    Z = [Z; EqDrifter(iperiod).features.option3(j,it).ellipse.(variable)];
                catch
                    Z = [Z; nan];
                end
            end
        end
%         
        if strcmp(variable,'area')
            subplot(3,3,3*(iday-1) + pattern)
            caxis([0 900])    
        elseif strcmp(variable,'anisotropy')
            subplot(1,3,pattern)
            caxis([1 3])
        end   
        
        fun_spatial_distribution(X/Radius,Y/Radius,Z);   
        set(findall(gcf,'-property','FontSize'),'FontSize',18);
        title(legend_info{pattern})     
        % without averaging over short-term simulations
    %     for iperiod = 1:N_periods
    %         for it =2:N_t
    %             X = squeeze(EqDrifter(iperiod).features.B_xy(:,it,1));    % feature of all buoys at given time
    %             Y = squeeze(EqDrifter(iperiod).features.B_xy(:,it,2));    % feature of all buoys at given time
    %             Z =         EqDrifter(iperiod).features.(variable)(:,it); % feature of all buoys at given time
    %             fun_spatial_distribution(X,Y,Z);
    %             title(datestr(Simul_Dates(iperiod).Simul_Dates(it)))
    %             pause
    %             clf
    %         end
    %     end
    end
    
    if pattern==3
        h = colorbar;
        if strcmp(variable,'area')
            title(h,'(km^2)')
        end
    end
    end
    
    %------------------------------------------------------------
    function fun_spatial_distribution(X,Y,Z)
        id = find(isnan(Z));
        X(id) = [];
        Y(id) = [];
        Z(id) = [];
        %
        gap = 50;
        xn = linspace(min(X),max(X),gap);
        yn = linspace(min(Y),max(Y),gap);
        Zgrid_mean = nan(length(yn),length(xn));
        for ix = 1:length(xn)-1
        for iy = 1:length(yn)-1
            id = find(X>xn(ix) & X<=xn(ix+1) & Y>yn(iy) & Y<=yn(iy+1));          
            if isempty(id)
                Zgrid_mean(iy,ix) = 0.;
            else            
                Zgrid_mean(iy,ix) = mean(Z(id));
            end
        end      
        end
        % plot
        [Xgrid,Ygrid] = meshgrid(xn,yn); 
        [long,lat] = m_xy2ll(Xgrid,Ygrid);
        m_pcolor(long,lat,(Zgrid_mean));    
        hold on;
        m_coast('patch',0.7*[1 1 1]);
        set(gca,'XTickLabel',[],'YTickLabel',[])  %     m_grid('color','k');
        %h = colorbar;     
%         set(h,'YTick',[1 6])
%         caxis([quantile(reshape(Z,1,[]),0.1) quantile(reshape(Z,1,[]),0.9)])    % test colorbar scale to further set range
%         caxis([0 30])    
%         caxis([1 3])
    %     hold on;
    %     m_coast('patch',0.7*[1 1 1]);
    %     %     m_grid('color','k');
    %     h = colorbar;    title(h,'(km)')        
    %     set(gca,'XTickLabel',[],'YTickLabel',[])  
    %     set(findall(gcf,'-property','FontSize'),'FontSize',18);
        % imagesc(X,Y,Z); set(gca,'YDir','normal')  
    %     dx = 400*median(diff(sort(X)));
    %     xn = min(X)-0.5*dx:dx:max(X)+0.5*dx;  % x = sort(X); step = diff(x)
    %     yn = min(Y)-0.5*dx:dx:max(Y)+0.5*dx;
    end
    
    %% 
    function fun_ellipse_evolution_biGaussian_fit(filename)
    global line_type color_type colors
        load(filename)  
    %     %
    %     j = 3;      % buoy ID
    %     iperiod = 1; % 1 ~ 9     
    %     time_id = 2*(1:7)-1; % day/2
    %     gap = 50*(pattern-1); % shift cluster to void overlap of clusters from different perturbations
    %     Nt = length(time_id);
    %     colors  = jet(Nt); 
    %     colormap(colors);
    %     
    %     %
    %     subplot(212)
    %     index = (j-1)*Ne+1:j*Ne;
    %     for i = 1:Nt
    %         it = time_id(i);
    %         Pt = [IABP(iperiod).data.Pt_pos_x(index,it) IABP(iperiod).data.Pt_pos_y(index,it)];
    %         Pt(:,1) = Pt(:,1) + gap;
    %         area = fun_get_ellipse(Pt,j,colors(i,:)); %  j-th EqDrifter drifter  
    %     end
    %     xlabel('distance (km)')
    %     h = colorbar; caxis([1 Nt]); title(h,'day');
    % 
    %     % initial position of buoy, Pt0
    %     Pt0 = [IABP(iperiod).data.Pt_pos_x(index(1),1);
    %            IABP(iperiod).data.Pt_pos_y(index(1),1)];    
    %     text(Pt0(1)+gap-10,Pt0(2)+5,legend_info{pattern},'color','k');    
    %     %
    %     if pattern==3
    %     subplot(211)
    %         m_proj('Stereographic','lon',-45,'lat',90,'radius',25);   
    %         m_coast('patch',0.7*[1 1 1]);  
    %         hold on              
    %         plot(Pt0(1)/Radius,Pt0(2)/Radius,'.b','markersize',18)
    %         set(gca,'XTickLabel',[],'YTickLabel',[]) 
    %     end 
    %     %
        %
        
        j = 3; % 3, 20, 40     % buoy ID
        iperiod = 1; % 1 ~ 9     
        time_id = 2*[1 7]-1; % day/2
        Nt = length(time_id);
        colormap(colors);  
        index = (j-1)*Ne+1:j*Ne;
        % initial position of buoy, Pt0
        Pt0 = [IABP(iperiod).data.Pt_pos_x(index(1),1);
               IABP(iperiod).data.Pt_pos_y(index(1),1)];       
        %
        subplot(122)    
        for i = 1:Nt
            it = time_id(i);
            Pt = [IABP(iperiod).data.Pt_pos_x(index,it) ...
                  IABP(iperiod).data.Pt_pos_y(index,it)];
            try
                GMModel = fitgmdist(Pt,1);  
                fun_get_ellipse(GMModel,Pt,color_type); %  j-th EqDrifter drifter  
            catch
                plot(Pt(:,1), Pt(:,2), '.','color',color_type,'markersize',8);          
                hold on
            end
        end
        xlabel(['distance (km), day' num2str((it+1)/2)])
        Ptmean = mean(Pt);
        text(Ptmean(1)-10,Ptmean(2)+5,legend_info{pattern},'color',color_type);    
        plot(Pt0(1),Pt0(2),'.r','markersize',25)
        %
        if pattern==3      
            subplot(121)
            m_proj('Stereographic','lon',-45,'lat',90,'radius',25);   
            m_coast('patch',0.7*[1 1 1]);  
            hold on              
            plot(Pt0(1)/Radius,Pt0(2)/Radius,'.r','markersize',25)
            set(gca,'XTickLabel',[],'YTickLabel',[]) 
        end 
        %
        set(findall(gcf,'-property','FontSize'),'FontSize',18);
    end
    
%%  plot temporal evolution of area / anisotropy
    function fun_ensemble_spread_vs_day(filename,variable)
    load(filename)
    global line_type color_type colors ax1 ax2
    lw= [2,1.5,1];
    line_width = lw(pattern);
    
    % minimum distance of buoys to the shore
    d0 = 100; 
 
    if pattern==1
        figure(14);ax1 = gca; box on;
        ax2 = axes('Position',[.3 .5 .3 .4]); box on
        % setting for the legend
        hold(ax1, 'on');
        for i = 1:3  % three types of perturbations     
            plot(ax1,Simul_Dates(1).Simul_Dates(1),0,'linewidth',2,'color',colors(i,:));        
            hold on
        end 
    end    
    hold(ax1, 'on');
    %
    if strcmp(variable,'area')
        Ylabel = 'A (km^2)';
        ylim(ax1,[0 3000]);
    elseif strcmp(variable,'anisotropy')
        Ylabel = 'R';
        ylim(ax1,[1 6]);
    end
    for iperiod = 1:length(periods_list) 
        id = find(EqDrifter(iperiod).features.dist2coast>d0);
        X = Simul_Dates(iperiod).Simul_Dates(1:21);
        for ib = id
        for it = 1:N_t
            try
                tmp(ib,it) = EqDrifter(iperiod).features.option3(ib,it).ellipse.(variable);
            end
        end
        end
        tmp = rmoutliers(tmp);
        tmp(tmp==0) = nan;
        Y_mean = nanmean(tmp);
        Y_std  = nanstd(tmp);
        fun_plotXY(ax1,X,Y_mean,Y_std,[],Ylabel,color_type,line_width); 
    end    
    datetick(ax1,'x',3);
    ylabel(ax1,Ylabel);
    if pattern==3
        legend(ax1,legend_info,'location','ne');       
    end
        
    %% embeded plot - time averaged quantity
    X = 1:length(Simul_Dates(1).Simul_Dates);
    X = (X-1)/2; % convert to unit in day        
    for iperiod = 1:length(periods_list)   
        id = find(EqDrifter(iperiod).features.dist2coast>d0);
        for ib = id
        for it = 1:N_t
            try
                tmp(ib,it) = EqDrifter(iperiod).features.option3(ib,it).ellipse.(variable);
            end
        end
        end            
    end
    tmp = rmoutliers(tmp);
    tmp(tmp==0) = nan;
    Y_mean = nanmean(tmp);
    Y_std  = nanstd(tmp);
    hold(ax2, 'on');
    fun_plotXY(ax2,X,Y_mean,[],'day',Ylabel,color_type,line_width);     
    if strcmp(variable,'area')
        axis(ax2,[0 10.5 0 1500])
    elseif strcmp(variable,'anisotropy')
        axis(ax2,[0 10.5 1.5 2.5])
    end
    %
    set(findall(gcf,'-property','FontSize'),'FontSize',16);
    end
    
    
% ---------------------------------------------------
    function fun_plotXY(ax,X,Y_mean,Y_bar,Xlabel,Ylabel,colors,lw)
    % if ~isempty(Y_bar)
    %     yu = Y_mean + Y_bar;
    %     yl = Y_mean - Y_bar;
    %     fill([X fliplr(X)], [yu' (yl)'], [.9 .9 .9], 'linestyle', 'none')
    %     hold all
    % end
        if nargin<8
            lw = 2;
        end
        plot(ax,X,Y_mean, 'linewidth',lw,'color',colors);  hold on
        if ~isempty(Y_bar)
            error = Y_bar;
            errorbar(ax,X, Y_mean,error,'.-','linewidth',lw,'color',colors)
        end
        xlabel(ax,Xlabel); 
        ylabel(ax,Ylabel); xlim(ax,[X(1)-1 X(end)+1])        
    end
    
    % 
    function fun_pdf_of_b(filename)
    global line_type color_type
    d0 = 100;
        load(filename)  
        N_t = 2*10+1; % day 10
        set(gcf,'Position',[100,150,950,350], 'color','w')
        % plot of b_para  
        subplot(121)
        tmp = []; 
        for i = 1:N_periods
            id = find(EqDrifter(i).features.dist2coast>d0);	        
            tmp = [tmp; reshape([EqDrifter(i).features.option2(id,N_t).b_para],[],1)];
        end        
        pd = fitdist(tmp,'kernel'); %  fit a kernel probability distribution
        x = -25:0.5:25;
        y = pdf(pd,x);
        plot(x,y,line_type,'linewidth',2);        
        hold on
        xlabel(' Distance from bary center (km)');
        ylabel('PDF of b_{//}')
        
        % plot of b_perp
        subplot(122)
        tmp = [];
        for i = 1:N_periods
            id = find(EqDrifter(i).features.dist2coast>d0);	
            tmp = [tmp; reshape([EqDrifter(i).features.option2(id,N_t).b_perp],[],1)];
            id = find(tmp==0);
            histogram(tmp)
        end        
        pd = fitdist(tmp,'kernel'); %  fit a kernel probability distribution
        x = -25:1:25;
        y = pdf(pd,x);
        plot(x,y,line_type,'linewidth',2); hold on
        xlabel(' Distance from bary center (km)');
        ylabel('PDF of b_{\perp}')
        legend(legend_info,'location','best');%     
        set(findall(gcf,'-property','FontSize'),'FontSize',18);
    %     saveas(gcf,['../plots/fall_PDF_of_b_' suffix '.fig'],'fig')    
    end
    
    %%
    function fun_bi2_vs_days(filename)
    global line_type color_type colors
        load(filename)    
        % setting for the legend
        for i = 1:3       
            loglog(0,0,'color',colors(i,:),'linewidth',2);        
            hold on
        end 
        %
        d0 = 100;
        for i = 1:N_periods
            id = find(EqDrifter(i).features.dist2coast>d0);	
            y(i,:) = nanmean(EqDrifter(i).features.mu_b2(id,:),1);
        end
        y = mean(y)';
        id = 2:length(y);
        xx = (id-1)/2;  % convert to day
        yy = y(id)';
        
        loglog(xx,yy,'o'); 
        hold on  
        %
        clear x y
        id = 1:3;
        x=log10(xx(id));
        y=log10(yy(id));
        p = polyfit(x,y,1); disp(['slope of left part is ' num2str(p(1))])
        f = polyval(p,x);
        plot(10.^x,10.^f,'color',color_type,'linewidth',2)    
        
        id = 6:20;
        x=log10(xx(id));
        y=log10(yy(id));
        p = polyfit(x,y,1); disp(['slope of right part is ' num2str(p(1))])
        f = polyval(p,x);
        plot(10.^x,10.^f,'color',color_type,'linewidth',2)
        legend(legend_info,'location','best')    
    
        xlabel('Time (days)'); ylabel('<<b_i^2>>_D (km^2)');   
        grid minor
        xticks([0.5 1 2 3 4 5 6 10]);
        xticklabels({"12h", '1', '2', '3', '4', '5', '6', '10'});
        axis([0. 11.5 0. 100])
        set(findall(gcf,'-property','FontSize'),'FontSize',18);    
    end
    
    
    %%
    function fun_spread_rmse_vs_days(filename)
    % the ratio spread/RMSE
        load(filename)     
        for i = 1:N_periods
            mu_b(:,i) = nanmean(IABP(i).features.mu_b,1);
            e(:,i)    = nanmean(IABP(i).features.e,1);
        end    
    %     x = (0:N_t-1)/2;    
    %     y = mean(mu_b)./mean(e);
    %     plot(x,y,'s-','linewidth',1.5); hold on
    %     xlabel('day');     
    
        x = [Simul_Dates.Simul_Dates];
        y = reshape(mu_b,[],1)./reshape(e,[],1);
        plot(x,y,'linewidth',2); hold on
        ylabel('||\mu_b||/||e||');
        datetick('x',3);  
        legend(legend_info);
    %         
        set(findall(gcf,'-property','FontSize'),'FontSize',16);
        set(gcf,'Position',[100,150,500,300])    
        
    % function fun_plot_error_vs_spread_12h(filename)
    % % B-O vs mu_b(spread of ensemble)
    %     load(filename)
    %     plot(avg_periods.mu_b,avg_periods.e,'linewidth',2);    
    %     hold on
    %     xlabel('Value range of \mu_b (km)'); ylabel('Spatial and 12-h averageds of ||e|| (km)');
    %     grid on;
    %     %         
    %     legend(legend_info,'location','best');
    %     set(findall(gcf,'-property','FontSize'),'FontSize',16);
    %     set(gcf,'Position',[100,150,450,300])    
    % %     saveas(gcf,'../plots/error_vs_spread_12h' ,'fig')    
    % end
        
    end
    
    
    %%
    function fun_POC_GaussianFit(filename)
        load(filename)  
        % 
        day=3;
        it = 1+2*day;
        it = 2:23;
        % pdf of observation point in an ensemble cluster based on Guassian fit
        m_proj('Stereographic','lon',-45,'lat',90,'radius',25);   
        m_coast('patch',0.7*[1 1 1]);  
        hold on
        set(gca,'XTickLabel',[],'YTickLabel',[])
        x = [];
        y = [];
        z = [];
        for iperiod = 1:N_periods          
            for ibuoy = 1:size(IABP(iperiod).data.Obs_pos_x,1)
                x = [x IABP(iperiod).data.Obs_pos_x(ibuoy,it)];
                y = [y IABP(iperiod).data.Obs_pos_y(ibuoy,it)];
                z = [z IABP(iperiod).features.POC_option3(ibuoy,it)];   
            end        
    
            x = x/Radius;
            y = y/Radius;
            scatter(x,y,16,z,'o','filled'); 
            colorbar; 
    %         caxis([0 quantile(z,0.75)])
            caxis([0 0.01])
        end
        set(gca,'XTickLabel',[],'YTickLabel',[])
        
        
        %%
        set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
        xlim([0 N_periods+1])
        ylim([-0.010 0.1])
        
        xlabel('Short term No.');     ylabel('Gaussian pdf score');
    %         
        set(findall(gcf,'-property','FontSize'),'FontSize',16);
        set(gcf,'Position',[100,150,500,300])    
    end
    
    %%
    function fun_POC(filename)
    global color_type
        load(filename)    
        variable = 'POC_option3';
        time_id = 1+2*[1 2 3 7];
        line_types = {'-','--','-.',':'};
        N_periods = N_periods;
    %     
        % setting for the legend
        for i = 1:3       
            plot(0,0,'color',colors(i,:),'linewidth',2);        
            hold on
        end 
        for i = 1:length(time_id)
            search_area = 0;
            for iperiod = 1:N_periods           
                search_area = [search_area; IABP(iperiod).features.(variable)(:,time_id(i))];
            end
            search_area(1) = [];    
            search_area(isnan(search_area)) = [];  % ignore these buoys that virtual buoys are nearly still in the simulations
            search_area = sort(search_area);
            %         
            yy = (1:length(search_area))/length(search_area);
            semilogx(search_area,yy,line_types{i},'linewidth',2,'color',color_type);
            hold on
        end
        
        if variable=='POC_option2'
            xlim([0.1 1.2e3])
        else
            xlim([1.e-5 1.])
        end
        set(gca,'xscale','log')
        ylabel('POC');
        grid on;
        legend(legend_info,'location','best');
    %     legend('t_0 + 1 day','t_0 + 2 day','t_0 + 3 day','t_0 + 7 day','location','best');
        set(findall(gcf,'-property','FontSize'),'FontSize',16);
        set(gcf,'Position',[100,150,500,300])    
    
    end
    
    %%
    function fun_plot_error_vs_spread_12h(filename)
    % B-O vs mu_b(spread of ensemble)
        load(filename)
        plot(avg_periods.mu_b,avg_periods.e,'linewidth',2);    
        hold on
        xlabel('Value range of \mu_b (km)'); ylabel('Spatial and 12-h averageds of ||e|| (km)');
        grid on;
        %         
        legend(legend_info,'location','best');
        set(findall(gcf,'-property','FontSize'),'FontSize',16);
        set(gcf,'Position',[100,150,450,300])    
    %     saveas(gcf,'../plots/error_vs_spread_12h' ,'fig')    
    end
    
    %% plot ,e e_para, e_perp (Fig. 15)
    function fun_plot_forecast_error_e_IABP(filename)   
    global color_type colors
        d0 = 100;
        load(filename);  
        lw = [2,1.5,1];
        line_width = lw(pattern);
    % --------------------------------------------------------
    % a) compare e among different time periods
        figure(151)
        %     setting for legend       
        X = Simul_Dates(1).Simul_Dates(1);    
        for i = 1:3        
            subplot(3,1,i)
            for j = 1:3
                plot(X(1),0,'color',colors(j,:),'linewidth',lw(j));        
                hold on
            end
        end 
        %     
        for i = 1:N_periods
            id = find(IABP(i).features.dist2coast>d0);	
            X = Simul_Dates(i).Simul_Dates(1:21);
            e_norm_mean = nanmean(IABP(i).features.e(id,:),1);  % dim(IABP(i).features.e)= (buoy number N_buoy, time step N_t)
            e_para_mean = nanmean(IABP(i).features.e_para(id,:),1);
            e_perp_mean = nanmean(IABP(i).features.e_perp(id,:),1);
            e_norm_std  = nanmean(IABP(i).features.e_std(id,:),1);  
    %         e_norm_std  =  nanstd(IABP(i).features.e,1);        
    %         e_para_std  =  nanstd(IABP(i).features.e_para,1);
    %         e_perp_std  =  nanstd(IABP(i).features.e_perp,1);
            % plot        
            subplot(311); fun_plotXY(gca,X,e_norm_mean,e_norm_std, [],'<||e||> (km)',color_type,line_width); datetick('x',3);  
            subplot(312); fun_plotXY(gca,X,e_para_mean,[], [],'<e_{||}> (km)',color_type,line_width);datetick('x',3);      % set(gca,'XTickLabelRotation',45)
            subplot(313); fun_plotXY(gca,X,e_perp_mean,[], [],'<e_{\perp}> (km)',color_type,line_width);datetick('x',3); %ylim([-30 30])      % set(gca,'XTickLabelRotation',45)
        end
        subplot(311); lgnd = legend(legend_info,'location','best','Orientation','horizontal');    %,'Orientation','horizontal');        
        set(lgnd,'color','none'); legend boxoff     
        
    % --------------------------------------------------------
        figure(152)
        X = (0:N_t-1)/2;
        for i = 1:3        
            subplot(1,3,i)
            for j = 1:3
                plot(X(1),0,'color',colors(j,:),'linewidth',lw(j));        
                hold on
            end
        end 
        for i = 1:length(periods_list)   
            id = find(IABP(i).features.dist2coast>d0);	        
            e(i,:) = nanmean(IABP(i).features.e(id,:));  % dim(IABP(i).features.e)= (buoy number N_buoy, time step N_t)
            e_para(i,:) = nanmean(IABP(i).features.e_para(id,:));
            e_perp(i,:) = nanmean(IABP(i).features.e_perp(id,:));
        end
        
        e_norm_mean = nanmean(e);
        e_para_mean = nanmean(e_para);
        e_perp_mean = nanmean(e_perp);
        subplot(131); fun_plotXY(gca,X,e_norm_mean,[],'day','<||e||>_D (km)',color_type,line_width); 
        subplot(132); fun_plotXY(gca,X,e_para_mean,[],'day','<e_{||}>_D (km)',color_type,line_width);
        subplot(133); fun_plotXY(gca,X,e_perp_mean,[],'day','<e_{\perp}>_D (km)',color_type,line_width);
        subplot(133); lgnd = legend(legend_info,'location','best');    %,'Orientation','horizontal');        
        set(lgnd,'color','none'); legend boxoff     
    end
    %
    function fun_plot_forecast_error_e_EqDrifter(filename)   
    global color_type colors
        d0 = 100;
        load(filename);  
        lw = [2,1.5,1];
        line_width = lw(pattern);
    % --------------------------------------------------------
    % a) compare e among different time periods
        figure(151)
        %     setting for legend       
        X = Simul_Dates(1).Simul_Dates(1);    
        for i = 1:3        
            subplot(3,1,i)
            for j = 1:3
                plot(X(1),0,'color',colors(j,:),'linewidth',lw(j));        
                hold on
            end
        end 
        %     
        for i = 1:N_periods
            id = find(EqDrifter(i).features.dist2coast>d0);	
            X = Simul_Dates(i).Simul_Dates(1:21);
            e_norm_mean = nanmean(EqDrifter(i).features.e(id,:),1);  % dim(EqDrifter(i).features.e)= (buoy number N_buoy, time step N_t)
            e_para_mean = nanmean(EqDrifter(i).features.e_para(id,:),1);
            e_perp_mean = nanmean(EqDrifter(i).features.e_perp(id,:),1);
            e_norm_std  = nanmean(EqDrifter(i).features.e_std(id,:),1);  
    %         e_norm_std  =  nanstd(EqDrifter(i).features.e,1);        
    %         e_para_std  =  nanstd(EqDrifter(i).features.e_para,1);
    %         e_perp_std  =  nanstd(EqDrifter(i).features.e_perp,1);
            % plot        
            subplot(311); fun_plotXY(gca,X,e_norm_mean,e_norm_std, [],'<||e||> (km)',color_type,line_width); datetick('x',3);  
            subplot(312); fun_plotXY(gca,X,e_para_mean,[], [],'<e_{||}> (km)',color_type,line_width);datetick('x',3);      % set(gca,'XTickLabelRotation',45)
            subplot(313); fun_plotXY(gca,X,e_perp_mean,[], [],'<e_{\perp}> (km)',color_type,line_width);datetick('x',3); %ylim([-30 30])      % set(gca,'XTickLabelRotation',45)
        end
        subplot(311); lgnd = legend(legend_info,'location','best','Orientation','horizontal');    %,'Orientation','horizontal');        
        set(lgnd,'color','none'); legend boxoff     
        
    % --------------------------------------------------------
        figure(152)
        X = (0:N_t-1)/2;
        for i = 1:3        
            subplot(1,3,i)
            for j = 1:3
                plot(X(1),0,'color',colors(j,:),'linewidth',lw(j));        
                hold on
            end
        end 
        for i = 1:length(periods_list)   
            id = find(EqDrifter(i).features.dist2coast>d0);	        
            e(i,:) = nanmean(EqDrifter(i).features.e(id,:));  % dim(EqDrifter(i).features.e)= (buoy number N_buoy, time step N_t)
            e_para(i,:) = nanmean(EqDrifter(i).features.e_para(id,:));
            e_perp(i,:) = nanmean(EqDrifter(i).features.e_perp(id,:));
        end
        
        e_norm_mean = nanmean(e);
        e_para_mean = nanmean(e_para);
        e_perp_mean = nanmean(e_perp);
        subplot(131); fun_plotXY(gca,X,e_norm_mean,[],'day','<||e||>_D (km)',color_type,line_width); 
        subplot(132); fun_plotXY(gca,X,e_para_mean,[],'day','<e_{||}>_D (km)',color_type,line_width);
        subplot(133); fun_plotXY(gca,X,e_perp_mean,[],'day','<e_{\perp}>_D (km)',color_type,line_width);
        subplot(133); lgnd = legend(legend_info,'location','best');    %,'Orientation','horizontal');        
        set(lgnd,'color','none'); legend boxoff     
    end
    %
%-------------------------------------------
    function fun_buoy_positions(filename)
        load(filename)
        d0=100;
        m_proj('Stereographic','lon',-45,'lat',90,'radius',25);   
        m_coast('patch',0.7*[1 1 1]);
        axis equal
        hold on
        for i = 1 %1:N_periods
            id = find(EqDrifter(i).features.dist2coast>d0);	
            for it = N_t
                time = Simul_Dates(i).Simul_Dates(it);
                title(datestr(time));                
                
                for j = id
                    
                    id0 = (j-1)*Ne+1:((j-1)*Ne+Ne);
                    xn = EqDrifter(i).data.Pt_pos_x(id0,it)/Radius;
                    yn = EqDrifter(i).data.Pt_pos_y(id0,it)/Radius;
                    plot(xn,yn,'.b',xn(end),yn(end),'.r');
                    hold on
                    [j xn(end),yn(end)]
                end
            end
            
        end
    end