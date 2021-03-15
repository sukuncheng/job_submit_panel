
function fun_ensemble_taylor_diagram(data_dir)
    A = dir(fullfile([ data_dir '/*.mat']));   
    for i_array = 1:size(A,1)
        i_array
        [A(i_array).folder '/' A(i_array).name]
        load([A(i_array).folder '/' A(i_array).name]);
        freedrift = load(filename_freedrift);
        % 
        a = [freedrift.osisaf_model.ensemble_mean];     FreeDrift = [a.short_term];
        Speed_freedrift = sqrt([FreeDrift.u].^2 + [FreeDrift.v].^2);
        model = [ osisaf_model(iperiod).ensemble_mean.short_term]; 
        obs   = [   osisaf_obs(iperiod).ensemble_mean.short_term];

        Svelocity = [model.u] + 1i*[model.v];  Sspeed = abs(Svelocity);
        Mvelocity = [obs.u] + 1i*[obs.v];      Mspeed = abs(Mvelocity);
        
        % ----- identify free drift area --------------
        %     Restrict 1, the analysis to the range of ice speeds go- ing from 7 to 19km/day        
        id1 = find(Sspeed>=7 & Sspeed<=19 & Mspeed>=7 & Mspeed<=19);
        %     Restrict 2, The simulated drift from the reference run is selected for the optimisation analysis only 
        %        if it differs by less than 10% from the drift simulated by the free drift run. 
        a = [freedrift.osisaf_obs.ensemble];
        obs_freedrift = [a.short_term];
        obs_freedrift_u = [obs_freedrift.u]; % indices of the positions are identified by matching observations saved in freedrift and ensemble simulations
        [~,ia1,ib1] = intersect(obs_freedrift_u,[obs.u]);
        id2 = find((Sspeed(ib1) - Speed_freedrift(ia1))./Speed_freedrift(ia1) < 0.1);
        id = 1:length(Sspeed);
        id(isnan(Sspeed)) = [];
        id  = intersect(id,union(id1, id2));  
        % find non free drift cases
        ID = 1:length(Sspeed);
        ID(isnan(Sspeed)) = [];
        id = setdiff(ID,id);
        % -------------------------------------------------------
%         [bias(i_array),RMSE(i_array),VRMSE(i_array)] = fun_vector_bias_RMSE_VRMSE(Svelocity(id),Mvelocity(id)); 
    
        X(1:2,:) = [real(Svelocity(id)); imag(Svelocity(id))]; 
        Y(1:2,:) = [real(Mvelocity(id)); imag(Mvelocity(id))];     
        for i = 1:2    
            a = taylor_statistics(X(i,:),Y(i,:));
            RMSs(i_array,i) = a.crmsd(2); 
            CORs(i_array,i) = a.ccoef(2); 
            STDs(i_array,i) = a.sdev(2); 
            std_ref(i_array,i) = a.sdev(1);     
        end
        
        a = taylor_statistics(Svelocity(id),Mvelocity(id));
        RMSv(i_array) = a.crmsd(2); 
        CORv(i_array) = a.ccoef(2); 
        STDv(i_array) = a.sdev(2); 
        std_refv(i_array) = a.sdev(1);          
        clear X Y
    end
    for i = 1:2        
        STD = [mean(std_ref(:,i)); STDs(:,i)];
        RMS = [0; RMSs(:,i)];
        COR = [1; CORs(:,i)]; 
        subplot(1,2,i)
        [hp,ht,axl]=taylor_diagram(STD,RMS,COR, ...
                'styleOBS','-','colOBS','r','markerobs','o','titleOBS','observation',...
                'markersize',3,'markercolor','r'); %,'checkStats','on');
        hold on
    end
    subplot(121); title('X component')
    subplot(122); title('Y component')
%         STD = [mean(std_refv); STDv'];
%         RMS = [0; RMSv'];
%         COR = [1; CORv']; 
%         [hp,ht,axl]=taylor_diagram(STD,RMS,COR, ...
%                 'styleOBS','-','colOBS','r','markerobs','o','titleOBS','observation',...
%                 'markersize',3,'markercolor','r'); %,'checkStats','on');
    
    set(findall(gcf,'-property','FontSize'),'FontSize',18);
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
%﻿the mean and RMS values of the difference in speed respectively
bias = mean(abs(model)-abs(obs));
RMSE = rms(abs(model) -abs(obs));
% VMSRE is defined as﻿the RMS of the vector difference
VRMSE = rms(abs(model-obs));
end