% this code is to load data from simulation and observations, iabp &
% equally_space_buoy, etc
function [iabp_model,iabp_obs,Drifters] = fun1_buoy_load_data(data_dir,iabp_dir,Ne,equal_space_buoy_dir)
    % data_dir = './neXtSIM_test26_03_damage';
    % iabp_dir = 'IABP_drifters_simulated_20070308T000000Z.txt';
    % Ne is ensemble size
%    data_dir
%    iabp_dir
%    equal_space_buoy_dir
    %% load ensemble data of equally spaced virtual buoys
    Drifters = [];
    if ~exist('equal_space_buoy_dir','var')
        disp('equal_space_buoy_dir is inexistence, at fun1_load_data_sub()');
        exit
    else
        for ie = 1:Ne 
            % filename = [data_dir '/mem' num2str(ie,'%03d') '/' equal_space_buoy_dir]
            filename = [data_dir '/mem' num2str(ie) '/' equal_space_buoy_dir]
            try
                %ncdisp(filename);
                longitude = ncread(filename,'longitude');
                latitude  = ncread(filename,'latitude');
                index = ncread(filename,'index');
                sic = ncread(filename,'sic');
            catch
                disp('file is inexistence:')
                filename        
                break
            end
            time = ncread(filename,'time');
            for it = 1:length(time)           
                Drifters(ie,it).sic = sic(1,:,it);
                Drifters(ie,it).buoyID  = index(1,:,it);
                Drifters(ie,it).lon = longitude(1,:,it);
                Drifters(ie,it).lat =  latitude(1,:,it);  
                Drifters(ie,it).Simul_Dates = time;
            end
        end
    end
    %% load ensemble dataset of IABP buoys        
    for ie = 1:Ne
        % filename = [data_dir '/mem' num2str(ie,'%03d') '/' iabp_dir]; 
        filename = [data_dir '/mem' num2str(ie) '/' iabp_dir]; 
        if ~exist(filename) 
            disp('file is inexistence:')
            filename               
        end
        [Year,Month,Day,Hour,buoyID,lat,lon,Concentration]=...
            textread(filename, '%d %d %d %d %d %f %f %f','headerlines',1);       
        Dates = datenum(Year,Month,Day,Hour,0*Hour,0*Hour);
    
        % select and restore data by dates   
        Simul_Dates = unique(Dates); 
        datestr(Simul_Dates);
        for it = 1:length(Simul_Dates)   
            id = find(Simul_Dates(it)==Dates);
            iabp_model(ie,it).Simul_Dates = Simul_Dates(it);
            iabp_model(ie,it).buoyID = buoyID(id);
            iabp_model(ie,it).lon = lon(id);
            iabp_model(ie,it).lat = lat(id);     
        end
    end
%% load observation of IABP trajectories as iabp
    % [Year,Month,Day,Hour,BuoyID,Lat,Lon]=textread('../data/IABP_drifters.txt',...
    %     '%d %d %d %d %d %f %f','headerlines',1);
        [Year,Month,Day,Hour,BuoyID,Lat,Lon]=textread('/cluster/home/chengsukun/src/nextsim/data/IABP_drifters.txt','%d %d %d %d %d %f %f','headerlines',1);
    iabp_obs = sortrows([datenum([Year,Month,Day,Hour zeros(length(Year),2)]), ...
                                BuoyID,Lon,Lat]);
                            
    % select the iabp buoys alive during the whole simulation:
    id = find(iabp_obs(:,1)>=Simul_Dates(1) & iabp_obs(:,1)<=Simul_Dates(end));
    iabp_obs = iabp_obs(id,:);   

end

%tmp(i).R = nanmean(IABP(i).R,1);           
% temporal mean of forecast_error:  dates in (date,day)    
% R,area_option2,area_option3,mu_b,mu_b2,mu_r,    e, e_para, e_perp  
% IABP_in_days.R              = reshape([tmp.R], N_t,[]);
% IABP_in_days.e      = reshape([A.e], N_t,[]);              
