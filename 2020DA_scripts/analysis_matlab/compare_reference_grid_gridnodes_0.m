clc
clear
close all

load('test_inform.mat')
simul_dir = [simul_dir '/date1/FILTER'];
m_proj('Stereographic','lon',-45,'lat',90,'radius',50); 
% %%  compare reference_grid. nc and gridnode-0.txt, they are the same, but different index order
% figure();set(gcf,'color','w')
% subplot(121)
% fileID = fopen([simul_dir '/gridnodes-0.txt'],'r');% output equal to refrence_grid.nc
% data = textscan(fileID,'%f %f','HeaderLines',1) ;
% data = cell2mat(data);
% fclose(fileID);
% size(data)
% xlon = data(:,1);
% xlat = data(:,2);
% % m_scatter(xlon,xlat,[],1:length(xlat),'.'); 
% m_plot(xlon(1:600),xlat(1:600),'.r');
% colorbar
% title('gridnodes-0.txt')
% hold on
% m_coast('color','k');
% colormap(bluewhitered)
% %%
% subplot(122)
mnt_dir = '..';
filename = [mnt_dir '/reference_grid.nc'];
ncdisp(filename)
% load plon plat
lon = ncread(filename,'plon');
lat = ncread(filename,'plat');
% m_coast('color','k');
% hold on
x = reshape(lon,1,[]);
y = reshape(lat,1,[]);
% m_scatter(x,y,[],1:length(x),'.');
m_plot(x,y,'.r');
colorbar
title('reference\_grid.nc')
colormap(bluewhitered)

norm(x'-xlon)
norm(y'-ylon)