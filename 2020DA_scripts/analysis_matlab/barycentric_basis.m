%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Barycentric basis (Matthias Rabatel Post-doc 2016-2017)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% From an N-ensemble of trajectories:
% 1/ computation of the mean trajectory
% 2/ construction of the barycentric basis (the barycenter is the origin
% and the axes are the two directions 'parallel' and 'perpendicular' 
% defined in the article.
%
% 25/7/2019
% modify: include initial position into Pt_pos_x
% add mean(,1) to constrain the first parameter,Traj_M(i,:,2) = mean(Pt_pos_y(ind_d,:),1);
% if A is a matrix, then mean(A,2) is a column vector containing the mean of each row.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Base = barycentric_basis(Pt_pos_init,Pt_pos_x,Pt_pos_y)

    Na_d = size(Pt_pos_init,1);N = size(Pt_pos_x,1)/Na_d;
    assert(N==floor(N),'dimension issue')
    N_t = size(Pt_pos_x,2);

    % Contruction of the ensemble mean trajectory
    Traj_M = zeros(Na_d,N_t,2);
    Traj_M(:,1,1) = Pt_pos_init(:,1);
    Traj_M(:,1,2) = Pt_pos_init(:,2);
    for i=1:Na_d
        ind_d = (i-1)*N+1:i*N;
        Traj_M(i,:,1) = mean(Pt_pos_x(ind_d,:),1);
        Traj_M(i,:,2) = mean(Pt_pos_y(ind_d,:),1);
    end

    % Construction of the direct orthonormal base centered in B (the barycenter)
    Base = cell(Na_d,N_t);
    for i=1:Na_d
        for t=1:N_t
            Base{i,t} = zeros(3,2);
            Base{i,t}(1,:) = [Traj_M(i,t,1) Traj_M(i,t,2)];
            
            % Construction of parallel axis: vector : Origin to Barycenter
            vec = [Traj_M(i,t,1)-Traj_M(i,1,1) Traj_M(i,t,2)-Traj_M(i,1,2)];
            norm_vec = sqrt(vec(1)^2+vec(2)^2);
            ax_para = vec/norm_vec;
            Base{i,t}(2,:) = ax_para;
            
            % Construction of perp axis: direct
            ax_perp = [-ax_para(2) ax_para(1)];
            Base{i,t}(3,:) = ax_perp;
        end
    end
end