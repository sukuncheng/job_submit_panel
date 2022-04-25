function [] = main_ensemblesize()
    clc
    clear
    close all
    dbstop if error

% ------------
filename = 'test_inform.mat';
    fun_load_moorings(filename)
    fun_sensitivity_ensemble_size_moorings(filename)  
    % fun_load_prior(filename)
    % fun_sensitivity_ensemble_size_prior(filename)  
    
% -------------
    % fun0_buoy_post_processing(filename)
    % fun_sensitivity_ensemble_size_drifters(filename,0); % equally spaced drifter=0, also can try iabp=1
    % fun_plots_drifters(filename) 
end

%%
function fun0_buoy_post_processing()
    load(filename)
    disp('load data of IABP drifter and equal spaced drifters, and exact drifters trajactories'); 
    for i = 1:N_periods
        data_dir = [ simul_dir '/date' num2str(i) ];         
        % set IABP drifter, equal spaced drifters
        start_time = datenum(periods_list(i));  % if it is frash run, start_time = start_time+1;
        tmp = datestr(start_time,30);
        if i==N_periods
            datetime = tmp(1:8);
        else
            datetime = '20190903'; % note: keep tracking after restart
        end
        iabp_dir = ['IABP_Drifters_' datetime '.txt'];                    
        equal_space_buoy_dir = ['Equally_Spaced_Drifters_' datetime '.nc'];                      
        % data are saved in matrices with two dimensions: days and ensemble. Matrix is easier for trajectories average.
        [iabp_model, iabp_obs, EqDrifter_raw] = fun1_buoy_load_data(data_dir,iabp_dir,Ne,equal_space_buoy_dir); 

        % simulation period
        N_t = length([iabp_model(1,:).Simul_Dates]); 
        Simul_Dates(i).Simul_Dates = [iabp_model(1,:).Simul_Dates];   
        %
        % positions of simulated drifters and observations
        IABP(i).data      = fun2_buoy_trajactory(Radius,iabp_model,iabp_obs,Ne,N_t,[iabp_model(1,:).Simul_Dates]);
        EqDrifter(i).data = fun2_buoy_trajactory(Radius,EqDrifter_raw,[],Ne,N_t);              
    end       
% -----------------------------------------------
% To test ensemble size, this part is blocked, which includes all ensembles
    disp('processing ensemble drifter data')
    for i = 1:N_periods
        IABP(i).features      = fun3_buoy_ensemble_spread(N_t,Ne,Ne_include,IABP(i).data,1);        
        EqDrifter(i).features = fun3_buoy_ensemble_spread(N_t,Ne,Ne_include,EqDrifter(i).data,0);
    end
    save(filename,'N_t','Simul_Dates','IABP','EqDrifter','-append');
end


%% note the data structure keeps consisitent with fun3_IABP_ensemble_processing()
function fun_sensitivity_ensemble_size_drifters(filename,buoy_type)    
    load(filename);  
%   
    for ie = 1:Ne
        Ne_include = ie
        % important, here ensemble runs are restarted from previous period,
        % we only investigate the spread of the last date. i =1
        i=N_periods;
        if buoy_type ==0      
            dataset = fun3_buoy_ensemble_spread(N_t,Ne,Ne_include,EqDrifter(i).data,buoy_type);
        else
            dataset = fun3_buoy_ensemble_spread(N_t,Ne,Ne_include,IABP.data(i),buoy_type);
        end        
        avg_periods(ie).R            = mean(reshape([dataset.option2.R], N_t,[]),2);
        avg_periods(ie).area_option2 = mean(reshape([dataset.option2.area], N_t,[]),2);
%         avg_periods(ie).area_option3 = mean(reshape([dataset.features.option3.area], N_t,[]),2);
        %     
        avg_periods(ie).mu_r   = mean(reshape([dataset.mu_r], N_t,[]),2);
        avg_periods(ie).mu_b   = mean(reshape([dataset.mu_b], N_t,[]),2);
        avg_periods(ie).mu_b2  = mean(reshape([dataset.mu_b2], N_t,[]),2); 
        avg_periods(ie).sigma_b  = mean(reshape([dataset.sigma_b], N_t,[]),2); 
        avg_periods(ie).B_pos_x  = mean(reshape([dataset.B_pos_x], N_t,[]),2); 
        avg_periods(ie).B_pos_y  = mean(reshape([dataset.B_pos_y], N_t,[]),2); 
        %  
    end
    save(filename,'avg_periods','-append')
end

% 

% plots variables against ensemble size to estimate ensemble size
function fun_plots_drifters(filename)    
    load(filename);  
    %% plot
    %avg_periods is removed in the new version, check backup code for definition
    % figure(1)
    % subplot(121);fun_plot_vs_Ne('R',avg_periods,Ne);   ylabel('<R>_D'); ylim([0.8 3])%set(gca,'yscale','log');
    % subplot(122);fun_plot_vs_Ne('area_option2',avg_periods,Ne); ylabel('search area (km^2)')
    
    figure(2)
    fun_plot_vs_Ne('mu_b',avg_periods,Ne); %ylabel('mean (km)')
    fun_plot_vs_Ne('sigma_b',avg_periods,Ne); %ylabel('std (km)')
    legend('\mu_b','\sigma_b')
    ylabel('\mu_b and \sigma_b')
    % fun_plot_vs_Ne('mu_r',avg_periods,Ne); ylabel('\mu_r (km)')
    set (gcf,'Position',[100,200,600,400], 'color','w')
    saveas(gcf,'mean_std_of_b_main_ensemblesize.png','png')
    
%     figure(3)
%     subplot(131);fun_plot_vs_Ne('e',avg_periods,Ne);      ylabel('||e|| (km)')
%     subplot(132);fun_plot_vs_Ne('e_para',avg_periods,Ne); ylabel('e_{parallel} (km)')
%     subplot(133);fun_plot_vs_Ne('e_perp',avg_periods,Ne); ylabel('e_{perp} (km)') 
end

%
function fun_plot_vs_Ne(variable,avg_periods,Ne)
%     days = [1 2 3 5];   % given time stamp at where one wants to see the result
    date_id = [ length(avg_periods(1).(variable))]; % convert given day into date index
    for i = 1:length(date_id) 
        % for each day, give a plot of y vs Ne
        for ie = 1:Ne
            Y(ie) = avg_periods(ie).(variable)(date_id(i));   
        end
        plot(1:Ne,Y,'linewidth',2); hold on
%         legend_info{i} = ['date_id ' num2str(date_id)];
    end
    xlabel('ensemble size'); 
    ylabel(variable)
%     lgnd = legend(legend_info,'location','ne'); 
%     set(lgnd,'color','none');
    set(findall(gcf,'-property','FontSize'),'FontSize',18);
    set(gcf,'Position',[100,150,600,300])        
end


%%
function fun_load_moorings(filename)
    load(filename)
    disp('load variables in moorings'); 

    iperiod = N_periods;
    start_time = datenum(periods_list(iperiod));  % if it is frash run, start_time = start_time+1; 
    % load ensemble member
    moorings = zeros(Ne,501,391);
    for ie = 1:Ne 
        data_dir = [ simul_dir '/date' num2str(iperiod) '/mem' num2str(ie)];                                         
        Year = datestr(start_time,10);
        DayofYear = start_time + Duration - datenum(str2double(Year),1,1);
        moorings_file = [data_dir '/Moorings_' Year 'd' num2str(DayofYear) '.nc' ];
        data = ncread(moorings_file,'sit');
        moorings(ie,:,:) = squeeze(data(:,:,end));               
    end
    save(filename,'moorings','-append')
end

%%
function fun_load_prior(filename)
    load(filename)
    disp('load variables in prior.nc'); 

    iperiod = N_periods;
    start_time = datenum(periods_list(iperiod));  % if it is frash run, start_time = start_time+1; 
    % load ensemble member
    prior = zeros(Ne,528,522);
    for ie = 1:Ne 
        filepath = [ simul_dir '/date' num2str(iperiod) '/filter/prior/mem' num2str(ie,'%03d') '.nc'];
        data = ncread(filepath,'sit');
        prior(ie,:,:) = squeeze(data(:,:,end));               
    end
    save(filename,'prior','-append')
end

function fun_sensitivity_ensemble_size_moorings(filename)
    load(filename)
    disp('load variables in moorings');
    for ie = 1:Ne
        Ne_include = ie
        data = moorings(1:Ne_include,:,:);
        tmp = std(data,0,1);  % spread among ensembles
        Var(ie) = nanmean(reshape(tmp,1,[]));
    end
    
    plot(1:Ne,Var,'linewidth',2); hold on
    xlabel('ensemble size'); 
    ylabel('spread of sit (m)')
    set(findall(gcf,'-property','FontSize'),'FontSize',16);
    set(gcf,'Position',[100,150,550,400],'color','w')  
%     legend('From Moorings.nc')
    saveas(gcf,'Sit-ensemblesize_main_ensemblesize.png','png')
end

%%
function fun_sensitivity_ensemble_size_prior(filename)
    load(filename)
    disp('load variables');
    for ie = 1:Ne
        Ne_include = ie
        data = prior(1:Ne_include,:,:);
        tmp = std(data,0,1);  % spread among ensembles
        Var(ie) = nanmean(reshape(tmp,1,[]));
    end
    
    plot(1:Ne,Var,'linewidth',2); hold on
    xlabel('ensemble size'); 
    ylabel('spread of sit (m)')
    set(findall(gcf,'-property','FontSize'),'FontSize',16);
%     set(gcf,'Position',[100,150,600,300])  
    legend('From prior.nc')
    saveas(gcf,'ensemble_analysis_sit_main_ensemblesize.png','png')
end


%% calculate shortest distances of drifters to the coast
function fun_buoy_distance2coast(filename)
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);   
    h = m_coast('patch',0.7*[1 1 1]);  hold on;
    coast = [];
    for i = 1:length(h)
        try
            coast = [coast; h(i).Vertices];
        end
    end    
    %-----------------------------------------
    load(filename)     
    for i = 1:N_periods
        IABP(i).features.dist2coast      = fun_distance(Ne,coast,Radius,IABP(i).data);        
        EqDrifter(i).features.dist2coast = fun_distance(Ne,coast,Radius,EqDrifter(i).data);
    end 
    save(filename,'IABP','EqDrifter','-append');  
end
% 
function dist2coast = fun_distance(Ne,coast,Radius,data)
    %
    pos_init = [data.Pt_pos_x(1:Ne:end,1), data.Pt_pos_y(1:Ne:end,1)]/Radius;      
    for ibuoy = 1:size(pos_init,1)        
        distance = sqrt((pos_init(ibuoy,1) - coast(:,1)).^2 + ...
                        (pos_init(ibuoy,2) - coast(:,2)).^2);        
        dist2coast(ibuoy) = min(distance)*Radius;
    end
end
