function fun2_OSISAF_process(filename)
% if Ne_include, copy the only member to ensemble_mean
    load(filename)
% average ice drift of ensemble members    
    for iperiod = 1:N_periods        
    for iday = 1:OSISAF_FILE_NUMBER % assuming positions of pixels in ensemble members are different.       
        % --------------------- ensemble mean -----------------------------
        common_id = 1:1.e6;
        for ie = 1:Ne_include
            common_id = intersect(osisaf_model(iperiod).ensemble(ie).short_term(iday).index,common_id);
        end
        %
        clear U V ice_con
        for ie = 1:Ne_include
            osisaf_model(iperiod).ensemble_mean.short_term(iday).index = common_id;
            [~,id,~] = intersect(osisaf_model(iperiod).ensemble(ie).short_term(iday).index,common_id);
            U(ie,:) = osisaf_model(iperiod).ensemble(ie).short_term(iday).u(id);
            V(ie,:) = osisaf_model(iperiod).ensemble(ie).short_term(iday).v(id);
            ice_con(ie,:) = osisaf_model(iperiod).ensemble(ie).short_term(iday).ice_con(id);
        end
        
        % save coordinates and indices of buoys
        model_no1 = osisaf_model(iperiod).ensemble(1).short_term(iday);                    
        [~,id,~] = intersect(model_no1.index,common_id);
        osisaf_model(iperiod).ensemble_mean.short_term(iday).index = id;
        osisaf_model(iperiod).ensemble_mean.short_term(iday).day0_lon = model_no1.day0_lon(id);
        osisaf_model(iperiod).ensemble_mean.short_term(iday).day0_lat = model_no1.day0_lat(id);
        osisaf_model(iperiod).ensemble_mean.short_term(iday).date = model_no1.valid_date;
        osisaf_model(iperiod).ensemble_mean.short_term(iday).u = mean(U,1); % save averaged values
        osisaf_model(iperiod).ensemble_mean.short_term(iday).v = mean(V,1);
        osisaf_model(iperiod).ensemble_mean.short_term(iday).ice_con = mean(ice_con,1);
        % obseration data
        obs_no1 = osisaf_obs(iperiod).ensemble(1).short_term(iday);        
        osisaf_obs(iperiod).ensemble_mean.short_term(iday).u = obs_no1.u(id);
        osisaf_obs(iperiod).ensemble_mean.short_term(iday).v = obs_no1.v(id);                                 
        % --------------------- ensemble mean <<< -------------------------
        
        % % --------------------- ice drift errors --------------------------
        % freedrift = load(filename_freedrift);
        % [corrcoef_xy,RMSE_xy,RMSE,VRMSE,bias] = fun_OSISAF_errors_analysis(osisaf_model,osisaf_obs,freedrift,iperiod,iday);
        % osisaf_model(iperiod).ensemble_mean.short_term(iday).corrcoef_xy = corrcoef_xy;
        % osisaf_model(iperiod).ensemble_mean.short_term(iday).RMSE_xy = RMSE_xy;
        % osisaf_model(iperiod).ensemble_mean.short_term(iday).RMSE  = RMSE;
        % osisaf_model(iperiod).ensemble_mean.short_term(iday).VRMSE = VRMSE;
        % osisaf_model(iperiod).ensemble_mean.short_term(iday).bias  = bias;            
    end
    end
    save(filename,'osisaf_model','osisaf_obs','-append')
end

%%
function [corrcoef_xy,RMSE_xy,RMSE,VRMSE,bias] = fun_OSISAF_errors_analysis(osisaf_model,osisaf_obs,freedrift,iperiod,iday)
% present the correlation coefficient between modelled and observed ice
% drift for each ensemble member, originally used to tune air drag coef.
    obs_freedrift   = freedrift.osisaf_obs(iperiod  ).ensemble_mean.short_term(iday);
    model_freedrift = freedrift.osisaf_model(iperiod).ensemble_mean.short_term(iday);
    Speed_freedrift = sqrt([model_freedrift.u].^2 + [model_freedrift.v].^2);
    %
    model = osisaf_model(iperiod).ensemble_mean.short_term(iday);         
    obs   = osisaf_obs(iperiod  ).ensemble_mean.short_term(iday); 
    Svelocity = [model.u] + 1i*[model.v];  Sspeed = abs(Svelocity);
    Mvelocity = [obs.u] + 1i*[obs.v];      Mspeed = abs(Mvelocity);        
% filter data for free drift area
    id = 1:length(Sspeed);
    id(isnan(Sspeed)) = [];
    % Restrict 1, the analysis to the range of ice speeds go- ing from 7 to 19km/day        
%         id = find(Sspeed>=7 & Sspeed<=19 & Mspeed>=7 & Mspeed<=19);
    % Restrict 2, The simulated drift from the reference run is selected for the optimisation analysis only 
    % if it differs by less than 10% from the drift simulated by the free drift run.         
    obs_freedrift_u = [obs_freedrift.u]; % indices of the positions are identified by matching observations saved in freedrift and ensemble simulations
    [~,ia1,ib1] = intersect(obs_freedrift_u,[obs.u]);
    id2 = find((Sspeed(ib1) - Speed_freedrift(ia1))./Speed_freedrift(ia1) < 0.1);
    id  = intersect(id, id2);  
% compute bias, rmse & correlation coef as vector/specific components
    [bias,RMSE,VRMSE] = fun_vector_bias_RMSE_VRMSE(Svelocity(id),Mvelocity(id)); 
    X(1:2,:) = [real(Svelocity(id)); imag(Svelocity(id))]; 
    Y(1:2,:) = [real(Mvelocity(id)); imag(Mvelocity(id))]; 
    for i = 1:2
        RMSE_xy(i) =  rms(X(i,:) - Y(i,:));        
        tmp = corrcoef(X(i,:), Y(i,:));
        corrcoef_xy(i) = tmp(1,2); 
    end    
end

%%
function [bias,RMSE] = fun_scalar_bias_RMSE(model,obs)
    % the spatial mean over pixels where both model and observation are defined
    model = reshape(model,[],1);
    obs   = reshape(obs,[],1);
    bias = mean(model-obs);
    RMSE = rms(model -obs);
end

% for ice velocity
function [bias,RMSE,VRMSE] = fun_vector_bias_RMSE_VRMSE(model,obs)
    % Assuming velocity vector is saved as complex values, real part: U, image part: V  
    % the spatial mean over pixels where both model and observation are defined
    model = reshape(model,[],1);
    obs   = reshape(obs,[],1);
    % this threshold is to exclude too large drift difference near open water,
    % according to the spatial error plot
    threshold = 0.1;
    id = find(abs(abs(model)-abs(obs))>threshold);
    model(id) = [];
    obs(id) = [];
    % the mean and RMS values of the difference in speed respectively
    bias = mean(abs(model)-abs(obs));
    RMSE = rms(abs(model) -abs(obs));
    % VMSRE is defined as the RMS of the vector difference
    VRMSE = rms(abs(model-obs));
end