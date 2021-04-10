function [] = main_observation_RCRV()
% display data in observation.nc
    clc
    clear
    close all
    dbstop if error
    
    load('test_inform.mat')
    for i = 1:N_periods
        enkf_dir = [ simul_dir '/date' num2str(i) '/filter'];         
        [b(i), d(i)] = fun_get_RCRV_statistics(enkf_dir);
    end

    %%
    figure()
    set (gcf,'Position',[100,200,1150,300], 'color','w')
%     plot(dates,b,'b-o', dates,d,'g-x');
    plot(periods_list,b,'b-o', periods_list,d,'g-x');
    hold on;
    legend('\mu_q', '\sigma_q');
    ax = gca;
    ax.XAxis.TickValues = periods_list';
    ax.XAxis.TickLabelFormat = 'dd-MMM-yy';
    set(findall(gcf,'-property','FontSize'),'FontSize',16);  
    xlim([periods_list(1)-1 periods_list(end)+1]);
%     saveas(gcf,'sit_main_observation_RCRV','png');
end

% calcualte the mean and std (b & d) of reduced centered random variable (RCRV) at the assimilation time. https://os.copernicus.org/articles/13/123/2017/os-13-123-2017.pdf 
% they provides simple diagnostics of whether the forecast ensemble provides a reliable estimate of the uncertainty of the ensemble mean, which is a trusted in view of the observations with the assumed uncertainties.
function [b, d] = fun_get_RCRV_statistics(filepath)  
    filename = [filepath '/observations.nc'];
    y     = ncread(filename,'value');  % observation value
    Hx    = ncread(filename,'Hx_a');   % forecast(_f)/analysis(_a) observation (forecast observation ensemble mean)
    std_o = ncread(filename,'std');    % standard deviation of observation error used in DA
    std_e = ncread(filename,'std_a');  % standard deviation of the forecast(_f)/analysis(_a) observation ensemble
    id = find(Hx>=0.01);
    %
    for i = 1:length(id)
	j = id(i);
        q(i) = (y(j) - Hx(j))/sqrt(std_o(j)^2 + std_e(j)^2);
    end
    b = mean(q);
    d = std(q);
    %
    lon = ncread(filename,'lon'); 
    lat = ncread(filename,'lat'); 
    
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
%    
    figure(1); 
    clf
    subplot(131); m_scatter(lon(id),lat(id),8,y(id)-Hx(id),'.');title('y-Hx_a','fontweight','normal','HorizontalAlignment','right');
    subplot(132); m_scatter(lon(id),lat(id),8,sqrt(std_e(id).^2 + std_o(id).^2),'.');title('sqrt(\sigma_{ens}^2+\sigma_{obs}^2)','fontweight','normal','HorizontalAlignment','right');
    subplot(133); m_scatter(lon(id),lat(id),8,q,'.');title('q')
    for i=1:3
        colormap(subplot(1,3,i),bluewhitered);
        h = colorbar %('southoutside');
        if i<3
            title(h,'(m)')
        end
        m_coast('patch',0.7*[1 1 1]);  
        m_grid('color','k')
        
    end
    set(findall(gcf,'-property','FontSize'),'FontSize',16); 
    set(gcf,'Position',[100,150,1100,250], 'color','w')
%     saveas(gcf,'innovation_uncertainties_main_RCRV.png','png')
    %
    
    
    % figure(10)
    % subplot(311);plot(y(id) - Hx(id));title('y-Hx');hold on;
    % subplot(312);
    % plot(sqrt(std_o(id).^2+std_e(id).^2));hold on;
    % title('sqrt(std_{obs}^2+std_{ens}^2)');
    % subplot(313);plot(q);title('RCRV q');hold on;
    
    % figure(11);
    % plot(sqrt(std_o(id).^2+std_e(id).^2), y(id)-Hx(id),'.'); hold on
    % xlabel('sqrt(std_{obs}^2+std_{ens}^2)');
    % ylabel('y-Hx');
    % set(findall(gcf,'-property','FontSize'),'FontSize',16); 

end
