clc
clear
close all

load('test_inform.mat')
simul_dir = [simul_dir '/date1/filter'];
m_proj('Stereographic','lon',-45,'lat',90,'radius',30); 
mnt_dir = '..';
filename = [mnt_dir '/reference_grid.nc'];
% load plon plat
lon = ncread(filename,'plon');
lat = ncread(filename,'plat');
mask = ncread(filename,'mask');
x = reshape(lon,1,[]);
y = reshape(lat,1,[]);
% plot
figure(1)
% % colormap(bluewhitered)
subplot(121)
m_pcolor(lon,lat,mask); hold on
m_coast('color','k'); hold on;
m_grid();
title('modified mask in reference_grid.nc')
% 
%%
fname = 'observations.nc' % 'observations.nc';
filename = [simul_dir '/' fname]
ncdisp(filename)
lon = ncread(filename,'lon');
lat = ncread(filename,'lat');
value = ncread(filename,'value');
subplot(122); m_scatter(lon,lat,[],value,'.');
m_coast('color','k'); hold on;
m_grid();
colorbar
title('observations.nc SIT(m)')
set(findall(gcf,'-property','FontSize'),'FontSize',18);
set(gcf,'color','w')


% % %%  ------------------------------
% % figure(2)   
% % subplot(121)
% % filename = '../W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_20191015_20191021_r_v202_01_l4sit.nc'; 
% % ncdisp(filename)
% % Lambert_Azimuthal_Grid = ncread(filename,'Lambert_Azimuthal_Grid');
% % lon = ncread(filename,'lon');
% % lat = ncread(filename,'lat');
% % Var = ncread(filename,'analysis_sea_ice_thickness');
% % % %
% % % m_proj('Stereographic','lon',-45,'lat',90,'radius',40); 
% % % pcolor(X,Y,Var); shading flat
% % m_scatter(reshape(lon,1,[]),reshape(lat,1,[]),[],reshape(Var,1,[]),'.');
% % h = colorbar;
% % % title(h,'(m)')  
% % m_coast('color','k');hold on;
% % m_grid('color','k');  
% % title('CS2SMOS SIT (m)','HorizontalAlignment','right')
% % 
% % %%
% % subplot(122)
% % % m_proj('Stereographic','lon',-45,'lat',90,'radius',40); 
% % mnt_dir = simul_dir;
% % mnt_dir = '..';
% % filename = [mnt_dir '/reference_grid_coast.nc'];
% % % load plon plat
% % plon = ncread(filename,'lon');
% % plat = ncread(filename,'lat');
% % m_coast('color','k');
% % hold on
% % m_plot(plon,plat,'.r')
% % m_grid()
% % title('reference\_grid\_coast.nc','HorizontalAlignment','right');
% % 
% % set(gcf,'color','w')
% % set(findall(gcf,'-property','FontSize'),'FontSize',18);

% %% output obserservations.nc of enkf_prep
% figure(3)
% fname = {'observations-orig.nc', 'observations.nc'};
% colors = {'r','g'};   
% for i = 2:2
%     subplot(1,2,i)
%     filename = [simul_dir '/' char(fname{i})]
%     ncdisp(filename)
%     lon = ncread(filename,'lon');
%     lat = ncread(filename,'lat');
%     value = ncread(filename,'value');
% %     status = ncread(filename,'status');
% %     unique(unique(status))  
%     m_scatter(lon,lat,[],value,'.'); 
% %     N = floor(max(max(value))/0.1);
% %     colormap(parula(N));
%     h = colorbar;
% % %     title(h,'(m)')
% %     m_plot(lon,lat,'.','color',colors{i},'markersize',2); 
%     hold on;
%     m_coast('color','k');
%     m_grid();  
% %
%     title(char(fname{i}),'HorizontalAlignment','right')
% end
% subplot(1,2,2)
% title('observations.nc SIT (m)')
% set(findall(gcf,'-property','FontSize'),'FontSize',18);
% 

% ----------------------------------------------------------
% gridnode-0.txt is in old version of enkf-c
% %%  compare reference_grid. nc and gridnode-0.txt, they are the same, but different index order
% figure();set(gcf,'color','w')
% % -----------
% fileID = fopen([simul_dir '/gridnodes-0.txt'],'r');% output equal to refrence_grid.nc
% data = textscan(fileID,'%f %f','HeaderLines',1) ;
% data = cell2mat(data);
% fclose(fileID);
% size(data)
% xlon = data(:,1);
% xlat = data(:,2);
% % % m_scatter(xlon,xlat,[],xlat*0,'.'); 
% % m_plot(xlon,xlat,'.k');
% % hold on
% % ------------