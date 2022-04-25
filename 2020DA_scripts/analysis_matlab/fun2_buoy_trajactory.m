%% return IABP buoy positions
function DATAset = fun2_buoy_trajactory(Radius,model,obs,Ne,N_t,IABP_Dates)   
    % Intruction of parameters: 
    % Pt_pos_init: model(x0,t0)
    % pos_init: initial positions (x,y) of buoys, where x,y are two coordinate vectors  
    % Pt: model(x0,t0,t)
    % Pt_pos_x: 1st coordinate of model(x0,t0,t), domain: (ensemble of 1st buoy+ ensemble of 2nd buoy + 3rd buoy ..., time)
    % Pt_pos_y: 2nd coordinate of model(x0,t0,t)
    % B_Basis: B
    % N_t: number of time steps
    % N_buoy: number of buoy trajectories
    % Ne: ensemble number
    % Pt_int: recoordinate x,y as Fig.2
    % b_para, b_perp: b//, b⊥
    % std_para,std_perp: Eq. 9 
    % R_anisotropy: Eq.10
    % R_para, R_perp: a//,a⊥, The main axes of the ellipsein Fig. 16. 
    % mbs_in  -- (POC)﻿The probability of finding a drifting object inside the search area
    
    % iabp corresponds to IABP_used2 in Mathias' code
    %  reduction to living IABP buoys during the whole time of simulation:                      
    if isempty(obs)
        buoy_id = model(1,1).buoyID % model(ie,it) equally spaced drifters
    else
        % IABP drifters observation
        buoy_ID = unique(obs(:,2));
        buoy_id = [];
        for i = 1:length(buoy_ID)
            % obs [dates,iabp_nr, iabp_lon, iabp_lat]
            id = find(obs(:,2) ==buoy_ID(i)); % number of records for a given buoy
            if length(id) < N_t  % record buoy survived the whole time
                obs(id,:) = [];
            else
                buoy_id = [buoy_id buoy_ID(i)];
            end
        end
    end
    % Select a subset of buoyID,  which are shared by all ensemble (loop ie ) over the simulation time (loot it).   
    for it = 1:N_t
    for ie = 1:Ne
        if isempty(model(ie,it).buoyID)            
            disp('error in fun2_buoy_trajactory_sub: no available buoy to study in one ensemble member, consider to delete the member')
            disp(['mem' num2str(ie,'%03d') ', time step ' num2str(it)])
            return
        end
        buoy_id = intersect(buoy_id,model(ie,it).buoyID);       
    end
    end    
    % --------------------------------------
    N_buoy = length(buoy_id);    
    disp(['find ' num2str(N_buoy) ' common buoys in this ensemble']); 

    % changing basis (in the Barycentric basis) for virtual buoys model      
    % ignoring the bias in stereographic projection in short distance
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);   % be sure this setting is not changed in the code series
    for it = 1:N_t       % loop of time
        Xtmp = [];  Ytmp = [];
        for id = 1:N_buoy  % loop of buoys
            for ie = 1:Ne % loop of ensemble
                i = find(model(ie,it).buoyID==buoy_id(id));
                i = i(1);
                Xtmp = [Xtmp; model(ie,it).lon(i)];   
                Ytmp = [Ytmp; model(ie,it).lat(i)];
            end
        end
        [X,Y] = m_ll2xy(Xtmp,Ytmp);
        Pt_pos_x(:,it) = X*Radius;
        Pt_pos_y(:,it) = Y*Radius;
    end
    clear X Y  
    DATAset.buoy_id = buoy_id;     
    DATAset.N_buoy = N_buoy;
    DATAset.Pt_pos_x = Pt_pos_x;
    DATAset.Pt_pos_y = Pt_pos_y;
    if ~isempty(obs)
        % Basis of Observation model   
        [X,Y] = m_ll2xy(obs(:,3),obs(:,4));
        Obs_pos_x = zeros(N_buoy,N_t);
        Obs_pos_y = zeros(N_buoy,N_t);
        for it=1:N_t    
            for j=1:N_buoy
                k = find(obs(:,1)==IABP_Dates(it) & obs(:,2)==buoy_id(j));  % truncated iabp dateset fitted in the simulated time period 
                Obs_pos_x(j,it) = X(k)*Radius;
                Obs_pos_y(j,it) = Y(k)*Radius;
            end
        end
        DATAset.Obs_pos_x = Obs_pos_x;
        DATAset.Obs_pos_y = Obs_pos_y;
    end
end
