clc
clear
close all

file_dir = '/cluster/work/users/chengsukun/nextsim_data_dir/TOPAZ4RC_daily/';
filename = [file_dir '20191104_dm-metno-MODEL-topaz4-ARC-b20191103-fv02.0.nc']; 
filename_save = 'TOPAZ_20191104.png'
ncdisp(filename)
lon = ncread(filename,'longitude');
lat = ncread(filename,'latitude');
hice = ncread(filename,'hice');
fice = ncread(filename,'fice');
hice(hice==0) = nan;
fice(fice==0) = nan;
Var = hice.*fice;

figure(1);set(gcf,'Position',[10,15,1800,700], 'color','w')
colormap(viridis)
subplot(131)
m_proj('Stereographic','lon',-45,'lat',90,'radius',25); 
% pcolor(X,Y,Var); shading flat
m_contourf(lon(:,:,1),lat(:,:,1),fice(:,:,1),50); shading flat;
%m_scatter(reshape(lon(:,:,1),1,[]),reshape(lat(:,:,1),1,[]),[],reshape(Var(:,:,1),1,[]),'.');
h = colorbar;
title(h,'(m)')  
m_coast('patch',[.7 .7 .7],'edgecolor','k');
m_grid('color','k');  
set(gca,'XTickLabel',[],'YTickLabel',[]);
title({'TOPAZ forecast, SIC','' })
% 
subplot(132)
% pcolor(X,Y,Var); shading flat
m_contourf(lon(:,:,1),lat(:,:,1),hice(:,:,1),50); shading flat;
%m_scatter(reshape(lon(:,:,1),1,[]),reshape(lat(:,:,1),1,[]),[],reshape(Var(:,:,1),1,[]),'.');
h = colorbar;
title(h,'(m)')  
m_coast('patch',[.7 .7 .7],'edgecolor','k');
m_grid('color','k');  
set(gca,'XTickLabel',[],'YTickLabel',[]);
caxis([0 3.5])
title({['mean SIT:' num2str(nanmean(nanmean(hice)))],'' })
% 
subplot(133)
% pcolor(X,Y,Var); shading flat
m_contourf(lon(:,:,1),lat(:,:,1),Var(:,:,1),50); shading flat;
%m_scatter(reshape(lon(:,:,1),1,[]),reshape(lat(:,:,1),1,[]),[],reshape(Var(:,:,1),1,[]),'.');
h = colorbar;
title(h,'(m)')  
m_coast('patch',[.7 .7 .7],'edgecolor','k');
m_grid('color','k');  
set(gca,'XTickLabel',[],'YTickLabel',[]);
caxis([0 3.5])

set(findall(gcf,'-property','FontSize'),'FontSize',15);
title({['mean SIT*SIC:' num2str(nanmean(nanmean(Var)))],'' })
saveas(figure(1),filename_save,'png');
