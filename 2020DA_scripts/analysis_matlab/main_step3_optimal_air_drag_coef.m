% purpose: compare OSISAF (measured) and simulated ice drift to tune air drag
% coefficient.
% measurement dataset /Data/sim/data/OSISAF_ice_drift/2019,2020
%   data of second time stamp are NaN when first time stamp is in Sep. 
% modified from main_step3_optimal_air_drag_coef_test09_01

function [] = main_OSISAFdrift_air_drag()
% modified from main_OSISAF.m used in Cheng et al (2020) wind/cohesion perturbations on neXtSIM
% purpose: tune air_drag_coef based on the method first presented by Rampel et al . (2016)
    clc
    clear
    close all
    dbstop if error
    format short g
    disp('1) load freedrift OSISAF.nc')
    disp('2) load and optimize the air drag coef., according to correlation coef. and RMSs of ice drift w.r.t OSI-SAF')
    disp('3) load determinitic run with optmial air drag coef.')   

    % ---------------------- settings ---------------------------
    Exp_ID='ice drift OSISAF';
    start_date = "2019-10-09";  
    N_periods = 1; % number of DA cycles.          
    Duration = 9; % duration days set in nextsim.cfg    
    for i = 1:N_periods
        periods_list(i)=datetime(start_date)+(i-1)*Duration;
        for j = 1:Duration
            n =  (i-1)*Duration +j;
            dates(n) = datetime(start_date) + n - 1;    
        end
    end
    air_drag_coef=[0.0004 0.0006 0.0008 0.001 0.0012 0.0014 0.0016 0.0018 0.002 0.0022 0.0024 0.0026 0.0028 0.003 0.0035 0.004 0.0045 0.005];
    Ne = length(air_drag_coef);    
    Ne_include=Ne; 
    mnt_OSISAF_dir = '/cluster/projects/nn2993k/sim/data/OSISAF_ice_drift';
    mnt_dir='/cluster/home/chengsukun/src/simulations'; 
    simul_dir = '/test_tune_air_drag_2019-10-09_9days_x_23cycles'; 
    simul_dir = [mnt_dir simul_dir];    

    % ------------ path of output data
    filename='ice_drift_OSISAF_comparison.mat';
    filename_freedrift = 'step3_freedrift.mat';
    ensemble_array = air_drag_coef;
    if ~exist(filename)
        save(filename)
    else
        save(filename,'Exp_ID','dates','N_periods','periods_list','Ne','Ne_include','Duration','ensemble_array','simul_dir','mnt_OSISAF_dir','filename_freedrift','-append');
    end  
    
%% 
    % disp('fun1 load sea ice drift from simulations and OSISAF dataset')
    % fun1_OSISAF_load_data(filename) 
    disp('fun2')
    fun2_OSISAF_process(filename)
    % disp('fun3')
    % fun3_OSISAF_analysis_figures(filename)  
    % disp('done')
    fun_OSISAF_corrcoef_taylor_scatter(filename,filename_freedrift,'air_drag')
    
    % ---------------------------------------
    % an example process
    % n = 0;
    % for it = 1:length(dates)
    %     n = n+1;
    %     data_dir = [ simul_dir '/date' num2str(it) ];
    %     t = datetime(periods_list(it))+6;
    %     dates(n) = t;
    %     nextsim_data = '/cluster/home/chengsukun/src/nextsim/data';
    % % compare concentration with OSISAF
    %     OSISAF_dir = [ nextsim_data '/OSISAF' ];
    %     temp = strrep(datestr(t,26),'/','');
    %     filename = [ OSISAF_dir '/ice_conc_nh_polstere-100_multi_' temp '1200.nc' ];
    %     obs_data = ncread(filename,'ice_conc');
    %     lon = ncread(filename,'lon');
    %     lat = ncread(filename,'lat');
    %     data_tmp = [];
    %     data = [];
    %     filename = ['OSISAF_Drifters_' temp '.nc'];
    %     for ie = 1:ensemble_size    
    %         file_dir = [data_dir '/mem' num2str(ie) '/' filename];
    %         data_tmp = ncread(file_dir,'sic'); 
    %         data(ie,:,:) = data_tmp(:,:,1);
    %     end
    %     num_mean = squeeze(mean(data,1));
    %     bias = num_mean - obs_data;
    %     subplot(131); fun_geo_plot(lon,lat,bias,'ensemble mean analysis');
    %     subplot(132); fun_geo_plot(lon,lat,bias,'obs');
    %     subplot(133); fun_geo_plot(lon,lat,bias,'bias');
    
    % end

    disp('finished');
end

function fun_geo_plot(lon,lat,var,Title)
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);
    m_pcolor(lon, lat, var); shading flat; 
    h = colorbar;
    title(h, '(m)');
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    colormap(bluewhitered);
    title(Title)
end


%%
%% also check the same function in fun3_OSISAF...()
function fun_OSISAF_corrcoef_taylor_scatter(filename,filename_freedrift,variable_name)
    % present the correlation coefficient between modelled and observed ice
    % drift for each ensemble member. It is originally used to tune air drag
    % coef.
        data = load(filename);    
        freedrift = load(filename_freedrift);
        % 
        a = [freedrift.osisaf_model.ensemble]; 
        model_freedrift = [a.short_term];
        Speed_freedrift = sqrt([model_freedrift.u].^2 + [model_freedrift.v].^2);
        %
        ensemble_array = data.ensemble_array;
        for ie = 1:length(ensemble_array)       
            tmp1 = [];
            tmp2 = [];
            for iperiod = 1:length(data.periods_list)
                tmp1 = [ tmp1 data.osisaf_model(iperiod).ensemble(ie)]; 
                tmp2 = [ tmp2 data.osisaf_obs(iperiod).ensemble(ie)];
            end
            model = [tmp1.short_term];
            obs   = [tmp2.short_term];          
            
            Svelocity = [model.u] + 1i*[model.v];  Sspeed = abs(Svelocity);
            Mvelocity = [obs.u] + 1i*[obs.v];      Mspeed = abs(Mvelocity);
            % ----- filter data for free drift area --------------
            id = 1:length(Sspeed);
            id(isnan(Sspeed)) = [];
    %     Restrict 1, the analysis to the range of ice speeds go- ing from 7 to 19km/day        
            id = find(Sspeed>=7 & Sspeed<=19 & Mspeed>=7 & Mspeed<=19);
    %     Restrict 2, Simulated drift from the reference run is selected for the optimisation analysis 
    %        if it differs by less than 10% from the drift simulated by the free drift run. 
            a = [freedrift.osisaf_obs.ensemble];
            obs_freedrift = [a.short_term];
            obs_freedrift_u = [obs_freedrift.u]; 
            % indices of the positions are identified by matching observations saved in freedrift and ensemble simulations
            [~,ia1,ib1] = intersect(obs_freedrift_u,[obs.u]);
            id2 = find((Sspeed(ib1) - Speed_freedrift(ia1))./Speed_freedrift(ia1) < 0.1);
            id  = intersect(id, id2);  
            % -------------------------------------------------------
            % compute rmse & correlation coef, then plot  
            clear X ref
            X(1:2,:)   = [real(Svelocity(id)); imag(Svelocity(id))]; 
            ref(1:2,:) = [real(Mvelocity(id)); imag(Mvelocity(id))];        
            %
            for i = 1:2
                a = taylor_statistics(X(i,:),ref(i,:));
                RMSs(ie,i) = a.crmsd(2); 
                CORs(ie,i) = a.ccoef(2); 
                STDs(ie,i) = a.sdev(2); 
                std_ref(ie,i) = a.sdev(1);                      
            end       
            %
            if  ensemble_array(ie)==0.0055   % ie is selected according to optimal coefficient in figure() below
                figure(34);  set(gcf,'Position',[100,100,900,350], 'color','w')    
                for i = 1:2 % loop for U,V components                    
                    subplot(1,2,i)
                    plot(X(i,:),ref(i,:),'.b'); 
                    hold on;  
                    range = 23;
                    xx = [-1,1]*range;    
                    plot(xx,xx,'k'); 
                    axis([-1 1 -1 1]*range);
                    %         
                    TEXT= {['r = ' num2str(CORs(ie,i))],['RMSE =' num2str(RMSs(ie,i))]};
                    Ylim=get(gca,'Ylim');
                    Xlim=get(gca,'Xlim');
                    tx = Xlim(1) + 0.1*(Xlim(2)-Xlim(1));
                    ty = Ylim(1) + 0.85*(Ylim(2)-Ylim(1));
                    text(tx,ty, TEXT,'color','k');
                    if i==1
                        title([ variable_name ' = ' num2str(ensemble_array(ie))], 'Interpreter', 'none')
                        xlabel('U_{model} (km/day)'); ylabel('U_{OSISAF} (km/day)');    
                    else
                        xlabel('V_{model} (km/day)'); ylabel('V_{OSISAF} (km/day)');
                    end                                
                end
                set(findall(gcf,'-property','FontSize'),'FontSize',18); 
    %                 saveas(gcf,'scatter plots of ice drift speed','fig');
            end
        end
        %% plot    
    %     figure(35); % taylor diagram
    %     % this is not a good case for taylor diagram, because the rms and std
    %     % of reference vary with the predicational series, here I use averaged
    %     % std_ref, which doesn't satisfy the relaiton RMSs(i) = sqrt(STDs(i).^2 + STDs(1)^2 - 2*STDs(i)*STDs(1).*CORs(i))
    %     colors = 'rr';
    %     for i =1:2
    %         STD = [mean(std_ref(:,i)); STDs(:,i)];
    %         RMS = [0; RMSs(:,i)];
    %         COR = [1; CORs(:,i)];
    %         subplot(1,2,i)
    % %         [hp,ht,axl]=taylor_diagram(STD,RMS,COR);
    %         [hp,ht,axl]=taylor_diagram(STD,RMS,COR, ...
    %              'styleOBS','-','colOBS','r','markerobs','o','titleOBS','observations',...
    %              'markersize',6,'markercolor',colors(i)); %,'checkStats','on');
    %         if i==1
    %             title('x direction')
    %         else
    %             title('y direction')
    %         end
    %     end    
    %     set(findall(gcf,'-property','FontSize'),'FontSize',18); 
        %
        figure(36) % correlation coefficient vs tuned variables:air drag coef. or cohesion.
        % left y-axis
        yyaxis left
        plot(ensemble_array,CORs(:,1),'o-'); hold on;
        plot(ensemble_array,CORs(:,2),'*:');
        
        ylabel('correlation coefficient ');    
        grid on
        % ylim([0.9 1.1])
        % right y-axis
        yyaxis right
        plot(ensemble_array,RMSs(:,1),'o-'); hold on;
        plot(ensemble_array,RMSs(:,2),'*:');       
        ylabel('RMSE (km)');    
        % grid on
        xlabel('ECMWF forecast air drag coefficient');  

        legend('U component','V component','location','se');       
        set(findall(gcf,'-property','FontSize'),'FontSize',18); 
        saveas(gcf,'corrcoef_vs_air_drag_coef.png','png');    
    end
