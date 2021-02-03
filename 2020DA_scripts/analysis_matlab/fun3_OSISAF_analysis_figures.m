function fun3_OSISAF_analysis_figures(filename)
global i
    if i==10
        figure(20);  fun_OSISAF_spatial_comparison(filename);
    end
%     figure(32); fun_OSISAF_errors_vs_days(filename,filename_freedrift);
%     fun_OSISAF_corrcoef_scatter_plot
%     fun_ice_drift_scatter_plot
end
%-----------------------------------------------------------------------------
function fun_OSISAF_errors_vs_days(filename,filename_freedrift)
    load(filename);
    n = 0;
    for i = 1:N_periods
        for iday = 1:OSISAF_FILE_NUMBER
            n = n + 1;
            bias(n)  = osisaf_model(i).ensemble_mean.short_term(iday).bias;        
            RMSE(n)  = osisaf_model(i).ensemble_mean.short_term(iday).RMSE;        
            VRMSE(n) = osisaf_model(i).ensemble_mean.short_term(iday).VRMSE;        
            dates(n) = osisaf_model(i).ensemble_mean.short_term(iday).date;        
        end
    end
    %% plot
    subplot(311); fun_plot_error_vs_days(dates,bias, 'bias (km/day)');
    subplot(312); fun_plot_error_vs_days(dates,RMSE, 'RMSE (km/day)');
    subplot(313); fun_plot_error_vs_days(dates,VRMSE,'VRMSE (km/day)');
    subplot(311); legend(legend_info,'location','best');   
    saveas(gcf,['sit_main_OSISAF.png'])           
end
%
function fun_plot_error_vs_days(dates,var,Ylabel)
plot(dates,var, 'linewidth',2); 
hold on; 
grid on;
datetick('x',3);
% set(gca,'XTickLabelRotation',45)
xlim([dates(1)-1 dates(end)+5])
ylabel(Ylabel); 
set(findall(gcf,'-property','FontSize'),'FontSize',18);
end

%----------------------------------------------------------------------------------
function fun_OSISAF_spatial_comparison(filename)
    threshold = 1000.1; % this threshold is to exclude too large drift difference near open water
    data = load(filename);
    freedrift = load(data.filename_freedrift);
    a = [freedrift.osisaf_model.ensemble_mean];     FreeDrift = [a.short_term];
    Speed_freedrift = sqrt([FreeDrift.u].^2 + [FreeDrift.v].^2);
    %    
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
%% time-period averaged data
    ie = 1; % for a given alea factor
    N = 1.e6;
    Num  = zeros(1,N); X = Num; Y = Num; Z = Num;
    for iperiod = 1:data.N_periods
    for iday  = 1:data.Duration-3
        model = data.osisaf_model(iperiod).ensemble_mean(ie).short_term(iday);         
        obs   =   data.osisaf_obs(iperiod).ensemble_mean(ie).short_term(iday); 
        Svelocity = [model.u] + 1i*[model.v];  Sspeed = abs(Svelocity);
        Mvelocity = [obs.u] + 1i*[obs.v];      Mspeed = abs(Mvelocity);
        id = 1:length(Svelocity);   % id = find(Sspeed>=7 & Sspeed<=19 & Mspeed>=7 & Mspeed<=19);
        % ----- filter data for free drift area --------------
        id = 1:length(Sspeed);
        id(isnan(Sspeed)) = [];
        %     Restrict 1, the analysis to the range of ice speeds go- ing from 7 to 19km/day        
        id = find(Sspeed>=7 & Sspeed<=19 & Mspeed>=7 & Mspeed<=19);
        %     Restrict 2, The simulated drift from the reference run is selected for the optimisation analysis only 
        %        if it differs by less than 10% from the drift simulated by the free drift run. 
        a = [freedrift.osisaf_obs.ensemble];
        obs_freedrift = [a.short_term];
        obs_freedrift_u = [obs_freedrift.u]; % indices of the positions are identified by matching observations saved in freedrift and ensemble simulations
        [~,ia1,ib1] = intersect(obs_freedrift_u,[obs.u]);
        id2 = find((Sspeed(ib1) - Speed_freedrift(ia1))./Speed_freedrift(ia1) < 0.1);
        id  = intersect(id, id2);  
        % 
%         id3 = find(abs(Svelocity-Mvelocity)<=0.1);
%         id  = intersect(id, id3);  
        % -------------------------------------------------------  
        index = model.index(id);
        [Xt,Yt] = m_ll2xy(model.day0_lon(id),model.day0_lat(id));
        Num(index) = Num(index) + 1;
        X(index) = Xt;
        Y(index) = Yt;
        Z(index) = abs(Svelocity(id)-Mvelocity(id));    % drift_error        
    end
    end
%     Z = Z./Num;
    id = find(Num==0 | Z>threshold);
    X(id) = [];
    Y(id) = [];
    Z(id) = [];
% imagesc(X,Y,Z); set(gca,'YDir','normal')  
    dx = 2*median(diff(X));
    xn = min(X)-0.5*dx:dx:max(X)+0.5*dx;  % x = sort(X); step = diff(x)
    yn = min(Y)-0.5*dx:dx:max(Y)+0.5*dx;
    
    Zgrid = nan(length(yn),length(xn));
    for ix = 1:length(xn)-1
    for iy = 1:length(yn)-1
        id = find(X>xn(ix) & X<=xn(ix+1) & Y>yn(iy) & Y<=yn(iy+1));  
        if isempty(id)
            Zgrid(iy,ix) = nan;
        else
            Zgrid(iy,ix) = median(Z(id)); 
        end
    end      
    end
    [Xgrid,Ygrid] = meshgrid(xn,yn); 
%     colormap jet        
    %% add buoy trajectories

    [long,lat] = m_xy2ll(Xgrid,Ygrid);
    
    m_pcolor(long,lat,Zgrid); 
%     scatter(X,Y,[],Z/max(Z),'s','filled');
    hold on;
    m_coast('patch',0.7*[1 1 1]);
%     m_grid('color','k');
    h = colorbar  
    title(h,'(km)')
    caxis([0 10])
%     caxis([0 threshold])
%     title(data.legend_info{end})
    title(['Number of occurrence of free drift events, ' data.legend_info{end}])
    set(gca,'XTickLabel',[],'YTickLabel',[])  
    set(findall(gcf,'-property','FontSize'),'FontSize',18);

for i = 1:data.N_periods
    X = reshape(data.IABP(i).Obs_pos_x,1,[])/Radius;
    Y = reshape(data.IABP(i).Obs_pos_y,1,[])/Radius;
    plot(X,Y,'.')    
    hold on
%     [x,y] = m_xy2ll(X,Y);
%     m_plot(x,y,'.r')    
end    

end

function fun_ice_drift_scatter_plot(filename)    
    set(gcf,'Position',[100,100,900,350], 'color','w')    
    for i = 1:2 % loop for U,V components                    
        subplot(1,2,i)
        plot(X(i,:),Y(i,:),'.b'); 
        hold on;  
        range = 23;
        xx = [-1,1]*range;    
        plot(xx,xx,'k'); 
        axis([-1 1 -1 1]*range);
        %         
        TEXT= {['r = ' num2str(cross_coef(ie,i))],['RMSE =' num2str(RMSE(ie,i))]};
        Ylim=get(gca,'Ylim');
        Xlim=get(gca,'Xlim');
        tx = Xlim(1) + 0.1*(Xlim(2)-Xlim(1));
        ty = Ylim(1) + 0.85*(Ylim(2)-Ylim(1));
        text(tx,ty, TEXT,'color','k');
        if i==1
            title([ variable_name ' = ' num2str(ensemble_array(ie))])
            xlabel('U_{model} (km/day)'); ylabel('U_{OSISAF} (km/day)');    
        else
            xlabel('V_{model} (km/day)'); ylabel('V_{OSISAF} (km/day)');
        end                
        set(findall(figure(2),'-property','FontSize'),'FontSize',16); 
        %                 saveas(gcf,'scatter plots of ice drift speed','fig');
    end
end


%%
function fun_OSISAF_corrcoef_scatter_plot(filename,filename_freedrift,variable_name)
% present the correlation coefficient between modelled and observed ice
% drift for each ensemble member. It is originally used to tune air drag
% coef.
    %ensemble_run = load(filename);    
    % freedrift = load(filename_freedrift);
    % % 
    % a = [freedrift.osisaf_model.ensemble]; 
    % model_freedrift = [a.short_term];
    % Speed_freedrift = sqrt([model_freedrift.u].^2 + [model_freedrift.v].^2);
    % ensemble_array = ensemble_run.ensemble_array;
%    for ie = 1:length(ensemble_array)     
%         tmp1 = [];
%         tmp2 = [];
%         for iperiod = 1:length(ensemble_run.periods_list)
%             tmp1 = [ tmp1 ensemble_run.osisaf_model(iperiod).ensemble(ie)]; 
%             tmp2 = [ tmp2 ensemble_run.osisaf_obs(iperiod).ensemble(ie)];
%         end
%         model = [tmp1.short_term];
%         obs   = [tmp2.short_term];          
        
%         Svelocity = [model.u] + 1i*[model.v];  Sspeed = abs(Svelocity);
%         Mvelocity = [obs.u] + 1i*[obs.v];      Mspeed = abs(Mvelocity);
%         %% filter data for free drift area
%         id = 1:length(Sspeed);
%         id(isnan(Sspeed)) = [];
% %     Restrict 1, the analysis to the range of ice speeds go- ing from 7 to 19km/day        
% %        id = find(Sspeed>=7 & Sspeed<=19 & Mspeed>=7 & Mspeed<=19);
% %     Restrict 2, The simulated drift from the reference run is selected for the optimisation analysis only 
% %        if it differs by less than 10% from the drift simulated by the free drift run. 
%         a = [freedrift.osisaf_obs.ensemble];
%         obs_freedrift = [a.short_term];
%         obs_freedrift_u = [obs_freedrift.u]; % indices of the positions are identified by matching observations saved in freedrift and ensemble simulations
%         [~,ia1,ib1] = intersect(obs_freedrift_u,[obs.u]);
%         id2 = find((Sspeed(ib1) - Speed_freedrift(ia1))./Speed_freedrift(ia1) < 0.1);
%         id  = intersect(id, id2);  
%         %
% %% compute rmse & correlation coef, then plot  
%         clear X Y
%         X(1:2,:) = [real(Svelocity(id)); imag(Svelocity(id))]; 
%         Y(1:2,:) = [real(Mvelocity(id)); imag(Mvelocity(id))]; 
%         for i = 1:2
%             RMSE(ie,i) =  rms(X(i,:) - Y(i,:));        
%             tmp = corrcoef(X(i,:), Y(i,:));
%             cross_coef(ie,i) = tmp(1,2); 
%         end
%    end

    ensemble_run = load(filename);    
    ensemble_array = ensemble_run.N_array;
    for i = 1:2
        n = 0;
        for ie = 1:length(ensemble_array)        
        for iperiod = 1:length(ensemble_run.periods_list)
        for iday = 1:OSISAF_FILE_NUMBER                
            n = n + 1;
            cross_coef(n,i) = osisaf_model(iperiod).ensemble_mean.short_term(iday).corrcoef_xy(i);
            RMSE(n,i) = osisaf_model(iperiod).ensemble_mean.short_term(iday).RMSE_xy(i);
        end
        end
        end        
    end
    %
    subplot(121)
    plot(ensemble_array,cross_coef(:,1),'o-'); hold on;
    plot(ensemble_array,cross_coef(:,2),'o-');
    legend('U component','V component','location','best');
    xlabel(variable_name); 
    ylabel('correlation coef. ');    
    grid on
    subplot(122)
    plot(ensemble_array,RMSE(:,1),'o-'); hold on;
    plot(ensemble_array,RMSE(:,2),'o-');
    legend('U component','V component','location','best');
    xlabel(variable_name); 
    ylabel('RMSE');    
    grid on
    set(findall(gcf,'-property','FontSize'),'FontSize',18); 
%     saveas(gcf,'../plots/r_vs_drag_coef','fig');    
end
