function [] = main_observation_RCRV()
% display statistics in observation.nc, Hx, std
% for i = 1:length(id)
%     j = id(i);
%     q(i) = (y(j) - Hx(j))/sqrt(std_o(j)^2 + std_e(j)^2);
% end
% b = mean(q);
% d = std(q);
    clc
    clear
    close all
    % dbstop if error
    N_periods=25;
    Duration = 7;
    start_date = "2019-10-18";
    dates = datetime(start_date) + (0:(N_periods-1))*Duration;
    mnt_dir = '/cluster/work/users/chengsukun/simulations/DASIMII_EnKF-neXtSIM_exps/';
    simul_dir{1}=[mnt_dir 'test_sic7_2019-10-18_7days_x_26cycles_memsize40_d5'];
    simul_dir{2}=[mnt_dir 'test_sit7_2019-10-18_7days_x_26cycles_memsize40_d5'];
    simul_dir{3}=[mnt_dir 'test_sic7sit7_2019-10-18_7days_x_26cycles_memsize40_d5'];
    simul_dir{4}=[mnt_dir 'test_sic1sit7_2019-10-18_1days_x_182cycles_memsize40_d5'];

    figure(1); 
    set (gcf,'Position',[100,200,1400,600], 'color','w')
    for j = 1:length(simul_dir)
        clear b d
        for i = 1:N_periods
            enkf_dir = [ simul_dir{j} '/date' num2str(i) '/filter'];         
            [b(i), d(i)] = fun_get_RCRV_statistics(enkf_dir);
        end
        %
        subplot(211)
        plot(dates,b,'.-','linewidth',1); hold on; ylabel('mean RCRV, \mu_q')
        subplot(212)
        plot(dates,d,'.-','linewidth',1); hold on; ylabel('std RCRV, \sigma_q')
    end
    subplot(211)
    xlim([dates(1)-1 dates(end)+1]);
    legend('sic7','sit7','sic7sit7','sic1sit7')

    subplot(212)
    xlim([dates(1)-1 dates(end)+1]);
    legend('sic7','sit7','sic7sit7','sic1sit7')
    % ax = gca;
    % ax.XAxis.TickValues = dates';
    % ax.XAxis.TickLabelFormat = 'dd-MMM-yy';
    set(findall(gcf,'-property','FontSize'),'FontSize',16);  
    
    saveas(gcf,'enkf_observationnc_statstics','png');
end

% calcualte the mean and std (b & d) of reduced centered random variable (RCRV) at the assimilation time. https://os.copernicus.org/articles/13/123/2017/os-13-123-2017.pdf 
% they provides simple diagnostics of whether the forecast ensemble provides a reliable estimate of the uncertainty of the ensemble mean, which is a trusted in view of the observations with the assumed uncertainties.
function [b, d] = fun_get_RCRV_statistics(filepath)  
    filename = [filepath '/observations.nc'];
    y     = ncread(filename,'value');  % observation value
    Hx    = ncread(filename,'Hx_a');   % forecast(_f)/analysis(_a) observation (forecast observation ensemble mean)
    std_o = ncread(filename,'estd');   % standard deviation of observation error used in DA
    std_e = ncread(filename,'std_a');  % standard deviation of the forecast(_f) or analysis(_a) observation ensemble
    id = find(Hx>0.0);                 % exclude some difference or NaN
    %
    for i = 1:length(id)
	    j = id(i);
        q(i) = (y(j) - Hx(j))/sqrt(std_o(j)^2 + std_e(j)^2);
    end
    b = mean(q);
    d = std(q);
    % %
    % lon = ncread(filename,'lon'); 
    % lat = ncread(filename,'lat'); 
    
    % m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
% %    
%     figure(1); 
%     clf
%     subplot(221); 
%     m_scatter(lon(id),lat(id),20,y(id)-Hx(id),'.');
%     title('y-Hx_a (m)','fontweight','normal','HorizontalAlignment','right');
%     subplot(222); 
%     m_scatter(lon(id),lat(id),20,q,'.');
%     title('q')
% %     
%     subplot(223); 
%     m_scatter(lon(id),lat(id),20,std_e(id),'.');
%     title('\sigma_{ens} (m)','fontweight','normal','HorizontalAlignment','right');
%     subplot(224); 
%     m_scatter(lon(id),lat(id),20,std_o(id),'.');
%     title('\sigma_{obs} (m)','fontweight','normal','HorizontalAlignment','right');
    
% %   
%     for i = 1:4
%         subplot(2,2,i)
%         colormap(gca,bluewhitered);
%         colorbar
%         m_coast('patch',0.7*[1 1 1]);  
%         m_grid('color','k')
%     end
%     set(findall(gcf,'-property','FontSize'),'FontSize',16); 
%     set(gcf,'Position',[100,150,1100,950], 'color','w')
%     saveas(gcf,'enkf_observationnc_statstics.png','png')
    %

end
