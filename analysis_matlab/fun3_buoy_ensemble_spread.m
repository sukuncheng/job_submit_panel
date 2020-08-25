function features = fun3_buoy_ensemble_spread(N_t,Ne,Ne_include,data,buoy_type)     
%(N_t,IABP(i).N_iabp,Ne,Ne_include,IABP(i).Pt_pos_x, IABP(i).Pt_pos_y, IABP(i).Obs_pos_x,IABP(i).Obs_pos_y);  
%N_buoy,Ne,Ne_include,Pt_pos_x,Pt_pos_y,Obs_pos_x,Obs_pos_y) 
%[e,e_para,e_perp,area_option2,POC_option2,area_option3,POC_option3,mu_r,mu_b,mu_b2,b_para,b_perp,R]
% note
% To plot ensemble buoys' positions: area(j,it) = fun_get_ellipse(Pt,0); % 2nd input - plot_ellipe>0
% Intruction of parameters: 
% Pt_pos_init: buoy_model(x0,t0)
% pos_init: initial positions (x,y) of buoys, where x,y are two coordinate vectors  
% Pt: buoy_model(x0,t0,t)
% Pt_pos_x: 1st coordinate of buoy_model(x0,t0,t), domain: (ensemble of 1st buoy+ ensemble of 2nd buoy + 3rd buoy ..., time)
% Pt_pos_y: 2nd coordinate of buoy_model(x0,t0,t)
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
    N_buoy   = data.N_buoy;
    Pt_pos_x = data.Pt_pos_x;
    Pt_pos_y = data.Pt_pos_y; 
    if(buoy_type==1)
        Obs_pos_x = data.Obs_pos_x;
        Obs_pos_y = data.Obs_pos_y;
    else
        Obs_pos_x = Pt_pos_x(21:Ne:end,:); % 21-th ensemble member is not perturbed, thus, as a reference
        Obs_pos_y = Pt_pos_y(21:Ne:end,:);
    end
    % note the initial position is started at the 1st (it = 1) output    
    pos_init = [Obs_pos_x(:,1) Obs_pos_y(:,1)];
    id = [];
    for j = 1:N_buoy     
        id = [id (j-1)*Ne+1:((j-1)*Ne+Ne_include)];
    end
    B_Basis = barycentric_basis(pos_init,Pt_pos_x(id,:),Pt_pos_y(id,:));
    %   
    for j = 1:N_buoy     
        for it = 2:N_t               
            Obs_xy = [Obs_pos_x(j,it) Obs_pos_y(j,it)]; % corrdinates of observations
            %
            B_pos_x(j,1) = pos_init(j,1);  
            B_pos_y(j,1) = pos_init(j,2);  
            index = (j-1)*Ne+1:((j-1)*Ne+Ne_include); 

            % mean trajectory of ensemble
            temp = cell2mat(B_Basis(j,it));  
            B_pos_x(j,it) = temp(1,1);  % It corresponds to traj_M,  Base{i,it}(1,:) = [Traj_M(i,it+1,1) Traj_M(i,it+1,2)]; in Mathia' code
            B_pos_y(j,it) = temp(1,2);        
            % distance r and b defined at the end of page 938, domain (buoy_id, time)
            for ie = index
                r_i(ie) = norm([Pt_pos_x(ie,it)-B_pos_x(j,1);  Pt_pos_y(ie,it)-B_pos_y(j,1)]);          
                b_i(ie) = norm([Pt_pos_x(ie,it)-B_pos_x(j,it); Pt_pos_y(ie,it)-B_pos_y(j,it)]);            
            end
            % mean r & b of ensemble, Eq.(8)
            mu_r(j,it) = mean(r_i(index)); % mean of Ne
            mu_b(j,it) = mean(b_i(index));       
            mu_b2(j,it)= mean(b_i(index).^2); 
            sigma_b(j,it)= std(b_i(index));     
            % calculate new coordinates of virtual buoys' positions
            Pt_xy = [Pt_pos_x(index,it) Pt_pos_y(index,it)];
            Pt_B  = base_chg(Pt_xy,[0 0;1 0;0 1],B_Basis{j,it});
            b_para = Pt_B(:,1); % para
            b_perp = Pt_B(:,2); % perp            
            sigma_b_para = std(b_para); % standard deviation, Eq.(9)
            sigma_b_perp = std(b_perp);

            %% search area,
            % ratio of the anistropy Eq.(10)
            O_B(1:2) = nan;
            dis = nan;  
            dis_std = nan;          
            R = sigma_b_para/sigma_b_perp;
            if R>5  % smoothing R: treshold = 5; depending outliers shown by plot(R)igma_b_para<0.003 && sigma_b_perp<0.003 || length(id)<11 || length(id)<0.5*Ne_include
                R = nan;
            else
                % option1:   % search circle of one drifter     
                %         Rpara = max(b_i(index));
                %         Rperp = R(j,it)*Rpara;      

                % option2:       % search ellipse of one drifter        
                % (X,Y) members coordinates in the bary basis.
                % R_anisotropy = std_para / std_perp     =>     std_para = R_anisotropy x std_perp
                % (X/Rpara)^2 + (Y/Rperp)^2 <= 1         =>     Rperp >= sqrt( X^2 + Y^2 x R_anisotropy^2 ) / R_anisotropy              
                s = max(sqrt((b_para/sigma_b_para).^2 + (b_perp/sigma_b_perp).^2));
                Rpara = s*sigma_b_para;
                Rperp = s*sigma_b_perp;
                option2(j,it).area = pi*Rpara*Rperp;
                
                % coordinate of O in x0-B system, buoy real buoys at time t, Eq. (12) in Rabatel et al. (2018)
                O_B = base_chg(Obs_xy,[0 0;1 0;0 1],B_Basis{j,it}); 
                dis = norm(O_B);
                s = sqrt((O_B(1)/sigma_b_para).^2 + (O_B(2)/sigma_b_perp).^2);
                option2(j,it).POC = pi*(s*sigma_b_para)*(s*sigma_b_perp);  
                
                tmp = Pt_xy - Obs_xy;
                tmp = sqrt(tmp(:,1).^2+tmp(:,2).^2);
                dis_std = std(tmp);            
            end      
            option2(j,it).R = R;   
            option2(j,it).b_para = b_para;
            option2(j,it).b_perp = b_perp;
            %
            e(j,it) = dis;
            e_std(j,it) = dis_std;
            e_para(j,it) = -O_B(1);
            e_perp(j,it) = -O_B(2);
            %------------------------------------------------------
            % option3: ellipse generated by bivariate Gaussian distribution
            try                 
                GMModel = fitgmdist(Pt_xy,1);  
                option3(j,it).ellipse = fun_get_ellipse(GMModel); % if number of inputs is >1, plot ellipse
                option3(j,it).POC = mvnpdf(Obs_xy,GMModel.mu,GMModel.Sigma);
                

                % plot ellipse
                if 0 
                    %% ellipse using Guassian distribution                        
                    fun_get_ellipse(GMModel,Pt_xy);
                    plot(B_pos_x(j,1),B_pos_y(j,1),'or','markersize',25); % observation at t=0
                    plot(Obs_xy(1),Obs_xy(2),'.r','markersize',25);         % observation at t = it

                    %% ellipse in the 2nd way above                 
                    vec = [B_pos_x(j,it) B_pos_y(j,it)] - [B_pos_x(j,1) B_pos_y(j,1)];
                    vec_n = vec/sqrt(vec(1)*vec(1)+vec(2)*vec(2));
                    th1 = acos(vec_n(1)); th2 = asin(vec_n(2));
                    if th2==0
                        sg=1; 
                    else
                        sg = th2/abs(th2); 
                    end
                    ang = sg*th1;                        
                    % draw orign and parallel axes:                        
                    line([B_pos_x(j,1) B_pos_x(j,it)],[B_pos_y(j,1) B_pos_y(j,it)],'Color','k','linewidth',2)

                    % draw ellipse
                    ellipse(B_pos_x(j,it),B_pos_y(j,it),...
                        Rpara(j,it),Rperp(j,it),ang,'linewidth',2); % mpa: horizontal axis, mpe: vertical axis
                    % draw axes
                    % parallel axis
                    line([B_pos_x(j,it) B_pos_x(j,it) + Rpara(j,it)*vec_n(1)],...
                        [B_pos_y(j,it) B_pos_y(j,it) + Rpara(j,it)*vec_n(2)],'Color','k','linewidth',2)
                    % perpendicular axis
                    line([B_pos_x(j,it) B_pos_x(j,it) - Rperp(j,it)*vec_n(2)],...
                        [B_pos_y(j,it) B_pos_y(j,it) + Rperp(j,it)*vec_n(1)],'Color','k','linewidth',2)
                    title(['pdf of Guassian=' num2str(POC_option3(j,it))])
                    pause
                    clf 
                end
            catch
                %
            end         
        end               
    end
    % ellipse: the length of the axes are defined by the standard deviations \sigma_x and \sigma_y of the data 
    % save characteristics for spread in (buoy, time) dimensions
    features.mu_r = mu_r;
    features.mu_b = mu_b;  
    features.mu_b2= mu_b2; 
    features.sigma_b= sigma_b;  
    features.B_pos_x = B_pos_x;
    features.B_pos_y = B_pos_y;
    features.option2 = option2;    
    features.option3 = option3;            
    
    % save observation related variables
    features.e = e;
    features.e_std = e_std;
    features.e_para = e_para;
    features.e_perp = e_perp;
    features.Obs_pos_x = Obs_pos_x;
    features.Obs_pos_y = Obs_pos_y;
end
%