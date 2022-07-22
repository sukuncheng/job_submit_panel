function [] = main_moorings_animation()
    clc
    clear
    close all
    % dbstop if error
    
    Ne = 40; % members   
    mnt_dir = '/cluster/work/users/chengsukun/simulations'
    % simul_dir = [ mnt_dir '/test_sic7sit7_2019-10-18_7days_x_26cycles_memsize40_d5'];
    % simul_dir = [ mnt_dir '/test_FreeRun_2019-10-18_7days_x_26cycles_memsize40_OceanNudgingDd5'];
    simul_dir = [ mnt_dir '/test_sic7_2019-10-18_7days_x_26cycles_memsize40_d5'];
    data_dir  = [ simul_dir '/date1' ];
    t = datetime(2019,10,24);
    filename = ['Moorings_' num2str(year(t)) 'd' num2str(day(t,'dayofyear'),'%03d') '.nc'];

    for ie = 1:Ne
        file_dir = [data_dir '/mem' num2str(ie) '/' filename];
        data_tmp = ncread(file_dir,'sic');
        sic(ie,:,:) = data_tmp(:,:,1);
        data_tmp = ncread(file_dir,'sit');
        sit_sic(ie,:,:) = data_tmp(:,:,1);    
    end   
    % sic(sic<0.15) = 0;
    sit_sic(sic<1.e-6) = nan;
    sic(sic<1.e-6) = nan;
    sit = sit_sic./(sic+1.e-10);
    lon = ncread(file_dir,'longitude');
    lat = ncread(file_dir,'latitude');
    for i = 1:size(lon,1)
        for j = 1:size(lat,2)
            sicsit_corr(i,j) = corr(squeeze(sic(:,i,j)),squeeze(sit(:,i,j)));
        end
    end    
    % -------- plot ------------------------------     
    figure(1);set(gcf,'Position',[10,15,800,600], 'color','w')   
    fun_geo_pcolor(lon,lat, sicsit_corr,'sic-sit\_corr',''); 
    colormap(gca,bluewhitered);
    set(findall(gcf,'-property','FontSize'),'FontSize',12);

    saveas(figure(1),[ 'sic_sit_corr.png'],'png')
          
end


function fun_geo_pcolor(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);
    m_pcolor(lon, lat, Var); shading flat; 
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({Title,''},'fontweight','normal')
    m_grid('linest',':');
    h = colorbar%('southoutside');
    title(h, unit);
end

% convergen of filter. 
% spread. 
% srf.  spread reduction 1 is the devision by 2, 
% dfs.  <=30
% R reflexision,     a matrix of ensemble mean
% square root filter apply inflation on anormalies