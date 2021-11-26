function [] = main_moorings_animation()
    clc
    clear
    close all
    % dbstop if error
    
    main_settings
    load('test_inform.mat')   % 
    method = 'mean'; %{'mean', 'Spread'}  %mean: ensemble ensemble, spread: ensemble spread
    N_contour = 20;
    % simul_dir = '/cluster/work/users/chengsukun/simulations/test_FreeRun_2019-10-18_7days_x_26cycles_memsize40_offline_perturbations';
    data_dir = [ simul_dir '/date11' ];
    t = datetime(2019,12,31);
    filename = ['Moorings_' num2str(year(t)) 'd' num2str(day(t,'dayofyear'),'%03d') '.nc'];
    check_a_member = 1; % check_a_member=0 presents ensemble average
    if check_a_member==0
        id = 1:Ne;
    else
        id = check_a_member;
    end    
    for ie = id
        file_dir = [data_dir '/mem' num2str(ie) '/' filename]
        data_tmp = ncread(file_dir,'sic');
        sic(ie,:,:) = data_tmp(:,:,1);
        data_tmp = ncread(file_dir,'sit');
        sit_sic(ie,:,:) = data_tmp(:,:,1);
        
    end   
    sit_sic(sic==0) = nan;   % exclude open water from nextsim.Moorings
    sic(sic==0)=nan;
    sit = sit_sic./(sic+1.e-10);
    if check_a_member>0
        SIC = squeeze(sic); 
        SIT = squeeze(sit);
        SIT_SIC = squeeze(sit_sic);               
    else 
        SIC = squeeze(mean(sic,1)); 
        SIT = squeeze(mean(sit,1));
        SIT_SIC = squeeze(mean(sit_sic,1));               
    end

    lon = ncread(file_dir,'longitude');
    lat = ncread(file_dir,'latitude');
    
    % -------- plot ------------------------------     
    figure(1);set(gcf,'Position',[10,15,1800,800], 'color','w')
    colormap(viridis)
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25); 
    subplot(131)
    Var = SIC;
    m_contourf(lon,lat,Var,N_contour); shading flat
    % m_scatter(reshape(lon,1,[]),reshape(lat,1,[]),[],reshape(Var,1,[]),'.');
    h = colorbar;
    % title(h,'(m)')  
    m_coast('patch',0.7*[1 1 1]);  hold on;
    m_grid('color','k');  
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    caxis([0 1])
    title({[Exp_ID ' SIC'],''})
    
    subplot(132)
    Var = SIT;
    m_contourf(lon,lat,Var,N_contour); shading flat
    % m_scatter(reshape(lon,1,[]),reshape(lat,1,[]),[],reshape(Var,1,[]),'.');
    h = colorbar;
    title(h,'(m)')  
    m_coast('patch',0.7*[1 1 1]);  hold on;
    m_grid('color','k');  
    % caxis([0 5])
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({['SIT mean:' num2str(nanmean(nanmean(Var)))],''})
    
    
    subplot(133)
    Var = SIT_SIC;
    m_contourf(lon,lat,Var,N_contour); shading flat
    % m_contourf(lon(:,:,1),lat(:,:,1),fice(:,:,1),N_contour); shading flat;
    % m_scatter(reshape(lon,1,[]),reshape(lat,1,[]),[],reshape(Var,1,[]),'.');
    h = colorbar;1
    title(h,'(m)')  
    m_coast('patch',0.7*[1 1 1]);  hold on;
    m_grid('color','k');  
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    % caxis([0 5])
    title({['SIT*SIC  mean:' num2str(nanmean(nanmean(Var)))],''})
    
    set(findall(gcf,'-property','FontSize'),'FontSize',15);

    Exp_ID = 'FreeRun';
    if check_a_member>0
        saveas(figure(1),[ Exp_ID '_2D_mem' num2str(check_a_member) '.png'],'png')
    else
        saveas(figure(1),[ Exp_ID '_2D_ensmean.png'],'png')
    end
          
end



% convergen of filter. 
% spread. 
% srf.  spread reduction 1 is the devision by 2, 
% dfs.  <=30
% R reflexision,     a matrix of ensemble mean
% square root filter apply inflation on anormalies