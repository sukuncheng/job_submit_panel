clc
clear
close all

file_dir = '/cluster/work/users/chengsukun/nextsim_data_dir/CS2_SMOS_v2.3/';
filename = [file_dir 'W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_20191101_20191107_r_v203_01_l4sit.nc']; 
filename_save = 'CS2SMOS_20191101_20191107.png';
% ncdisp(filename)
Lambert_Azimuthal_Grid = ncread(filename,'Lambert_Azimuthal_Grid');
lon = ncread(filename,'lon');
lat = ncread(filename,'lat');
SIT = ncread(filename,'analysis_sea_ice_thickness');
SIC = ncread(filename,'sea_ice_concentration');
SIC = SIC/100;
SIC(SIC<.15)=nan;
SIT(SIT<0.01)=nan;
figure(1);set(gcf,'Position',[10,15,1800,800], 'color','w')
colormap(viridis)
m_proj('Stereographic','lon',-45,'lat',90,'radius',25); 
subplot(131)
Var = SIC;
m_contourf(lon,lat,Var); shading flat
% m_scatter(reshape(lon,1,[]),reshape(lat,1,[]),[],reshape(Var,1,[]),'.');
h = colorbar;
% title(h,'(m)')  
m_coast('patch',0.7*[1 1 1]);  hold on;
m_grid('color','k');  
set(gca,'XTickLabel',[],'YTickLabel',[]);
caxis([0 1])
title({'CS2SMOS SIC',''})

subplot(132)
Var = SIT;
m_contourf(lon,lat,Var,50); shading flat
% m_scatter(reshape(lon,1,[]),reshape(lat,1,[]),[],reshape(Var,1,[]),'.');
h = colorbar;
title(h,'(m)')  
m_coast('patch',0.7*[1 1 1]);  hold on;
m_grid('color','k');  
% caxis([0 5])
set(gca,'XTickLabel',[],'YTickLabel',[]);
title({['SIT mean:' num2str(nanmean(nanmean(Var)))],''})


subplot(133)
Var = SIT.*SIC;
m_contourf(lon,lat,Var,50); shading flat
% m_scatter(reshape(lon,1,[]),reshape(lat,1,[]),[],reshape(Var,1,[]),'.');
h = colorbar;1
title(h,'(m)')  
m_coast('patch',0.7*[1 1 1]);  hold on;
m_grid('color','k');  
set(gca,'XTickLabel',[],'YTickLabel',[]);
% caxis([0 5])
title({['SIT*SIC  mean:' num2str(nanmean(nanmean(Var)))],''})

set(findall(gcf,'-property','FontSize'),'FontSize',15);
saveas(figure(1),filename_save,'png');
