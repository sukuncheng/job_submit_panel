function [] = main_test2_ensemble_size()
    clc
    clear
    close all
    dbstop if error
    format short g
     disp('-------------------------')
    % ---------------------- settings ---------------------------
    periods_list = "2018-11-11"; %["2018-11-11" "2018-11-18" "2018-11-25" "2018-12-02"];
    N_periods = length(periods_list);                     
    Duration = 7; % duration days set in nextsim.cfg    
    Ne = 80;      
    Ne_include = 80;
    Radius = 6378.273; % radius of earth
    legend_info = {''}; 
%     mnt_dir  = '/nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun'; % fram  
%    mnt_dir = '/Users/sukeng/Desktop/nird'; % mac;     %    mnt_dir = 'Z:\';  % window          
%    simul_dir = [mnt_dir simul_dir];          
    simul_dir='/cluster/home/chengsukun/src/IO_nextsim/test2_ensemble_size_Ne80_T4_D7';   % raw data path
    filename = '/cluster/home/chengsukun/src/nird_IO_nextsim/data/data_ensemble_size.mat';% path of output data

    %---------------- remote processing ----------------------          
    fun0_buoy_post_processing(filename)

    %---------------- local processing -----------------------
%         fun_buoy_distance2coast(filename)
% 
%       fun4_buoy_analysis_figures(filename,pattern)
    %
    %     fun1_OSISAF_load_data(filename) 
    %     fun2_OSISAF_process(filename)
    %     fun3_OSISAF_analysis_figures(filename)  
end

%%
function fun0_buoy_post_processing(filename)
    load(filename)
    disp('load drifter data and exact drifters trajactories'); 
    for i = 1:N_periods
        data_dir = [ simul_dir '/date' num2str(i) ];         
        % set IABP drifter, Equal drifter directories
        start_time = datenum(periods_list(i))+1;  
        tmp = datestr(start_time,30);
        datetime = tmp(1:8);
        iabp_dir = ['IABP_Drifters_' datetime '.txt'];                    
        equal_space_buoy_dir = ['Equally_Spaced_Drifters_' datetime '.nc'];                      
        [iabp_model, iabp_obs, EqDrifter_raw] = fun1_buoy_load_data(data_dir,iabp_dir,Ne,equal_space_buoy_dir); % data are saved in matrices with two dimensions: days and ensemble. Matrix is easier for trajectories average.
        %
        N_t = length([iabp_model(1,:).Simul_Dates]); 
        Simul_Dates(i).Simul_Dates = [iabp_model(1,:).Simul_Dates];   
        % positions of simulated drifters and observations
        IABP(i).data      = fun2_buoy_trajactory(Radius,iabp_model,iabp_obs,Ne,N_t,[iabp_model(1,:).Simul_Dates]);
        EqDrifter(i).data = fun2_buoy_trajactory(Radius,EqDrifter_raw,  [],Ne,N_t);              
    end       
% -----------------------------------------------
    disp('processing ensemble drifter data')
    for i = 1:N_periods
        IABP(i).features      = fun3_buoy_ensemble_spread(N_t,Ne,Ne_include,IABP(i).data,1);        
        EqDrifter(i).features = fun3_buoy_ensemble_spread(N_t,Ne,Ne_include,EqDrifter(i).data,0);
    end
    save(filename,'N_t','Simul_Dates','IABP','EqDrifter','-append');
end

%%
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
function dist2coast = fun_distance(Ne,coast,Radius,data,features)
    %
    pos_init = [data.Pt_pos_x(1:Ne:end,1), data.Pt_pos_y(1:Ne:end,1)]/Radius;      
    for ibuoy = 1:size(pos_init,1)        
        distance = sqrt((pos_init(ibuoy,1) - coast(:,1)).^2 + ...
                        (pos_init(ibuoy,2) - coast(:,2)).^2);        
        dist2coast(ibuoy) = min(distance)*Radius;
    end
end



% calcualte the reduced centered random variable b & d at the assimilation time.
% they provides simple diagnostics of whether the forecast ensemble provides a reliable estimate of the uncertainty of the ensemble mean, which is a trusted in view of the observations with the assumed uncertainties.
% function fun_calculate_RCRV()
%     
%         for it = 2:N_t  
%             % ice concentration
%             for m = 1:N_buoy  % number of observations                
%                 innovation = e(j,it)  
%                 sigma_o    =   % the observation error
%                 sigma_en   =   % std of the forecase ensemble - the uncertianty of bias estimation
%                 q(m) = innovation/sqrt(sigma_o^2 + sigma_en^2);
%             end
%             % take mean and std of q over the total number of observations 
%             b = mean(q);
%             d =  std(q);
%             % % ice thickness
%             % innovation = 
%             % sigma_o    =   % the observation error
%             % sigma_en   =   % std of the forecase ensemble - the uncertianty of bias estimation
%             % q_ithk = innovation/sqrt(sigma_o^2 + sigma_en^2);
%         end
% end
