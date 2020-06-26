function [] = main_enkf_outputs_unix()
    clc
    clear    
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);

%% enkf-prep outputs    
    h_fig = figure('visible','off');
    file = 'observations.nc';
    fun_plot_observation(file);    
    saveas(h_fig,'observations.png','png');

%% enkf-update outputs
    fun_geomap_spread();
    
    % compare forecast, increment and analysis results
    fun_geomap_field();
end

%%
function fun_geomap_spread()
% part 1. get longitude and latitudes from reference grid
    gridfile = 'reference_grid.nc';
    lon = ncread(gridfile,'plon');
    lat = ncread(gridfile,'plat');

% part 2. get sit from spread.nc
    file = 'spread.nc';
    v1 = ncread(file, 'sit');
    v1(v1<=0) = nan;
    v2 = ncread(file, 'sit_an');    
% part 3. plot
    h_fig = figure('visible','off'); 
    set(h_fig,'Position',[100,200,900,300], 'color','w');
    colormap jet;
    upper = max(max(max(v1)), max(max(v2)));
    subplot(121); func_arctic_map(lon, lat, v1);  title('forecast ensemble spread'); caxis([0 upper]);
    subplot(122); func_arctic_map(lon, lat, v2);  title('analysis ensemble spread'); caxis([0 upper]);
%   
    saveas(h_fig,'spread.png','png');
end

%
function fun_geomap_field()
% load grid coordinates
    gridfile = 'reference_grid.nc';
    lon = ncread(gridfile,'plon');
    lat = ncread(gridfile,'plat');
% load variables
    file = 'prior/mem001.nc';
    lon1 = ncread(file, 'longitude');
    lat1 = ncread(file, 'latitude');
    v1  = ncread(file, 'sit');
    v1  = squeeze(v1(:,:,1));
    file = 'prior/mem001.nc.analysis';
    v2   = ncread(file, 'sit');
% plot   forecast_analysis
    h_fig = figure('visible','off'); 
    set(h_fig,'Position',[100,200,900,300], 'color','w');
    colormap jet;
    upper = max(max(max(v1)), max(max(v2)));
    subplot(121); func_arctic_map(lon, lat, v1); title('forecast field');   caxis([0 upper]);
    subplot(122); func_arctic_map(lon, lat, v2); title('analysis field');   caxis([0 upper]);
    saveas(gcf,'field_forecast_analysis.png','png');    
% plot increment
    h_fig = figure('visible','off'); 
    inc = v2 - v1;
    inc(inc==0) = nan;
    func_arctic_map(lon, lat, inc); title('increment');
    saveas(gcf,'field_increment.png','png');    
end
%  -----------------
function func_arctic_map(lon, lat, var)
    m_pcolor(lon, lat, var); shading flat; 
    h = colorbar;
    title(h, '(m)');
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
end
%  -----------------
function fun_plot_observation(file)    
    %ncdisp(file);
    lon = ncread(file,'lon');
    lat = ncread(file,'lat');
    Z = ncread(file,'value');
    Z(Z<0) = nan;
%     
    colormap jet;
    m_scatter(lon,lat,10,Z,'o','filled'); 
    hold on;
    m_coast('patch',0.7*[1 1 1]);
    m_grid('color','k');
    h = colorbar;
    title(h, '(m)');
end



% filename = 'obs/SMOS_Icethickness_v3.1_north_20181111_north_singleob.nc';
% ncid = netcdf.open(filename,'write');
% varid = netcdf.inqVarID(ncid,'ice_thickness_uncertainty');
% netcdf.putVar(ncid,varid,10.0);
% netcdf.close(ncid);

% 
% % get name and length of first dimensions
% for dimid = 1:ndim
%     [dimname, dimlen] = netcdf.inqDim(ncid,dimid-1)   
% end
% 
% % retrieve identifier of dimensions
% dimid = netcdf.inqDimID(ncid,dimname)

%     % retrieve variable ID
%     varid = netcdf.inqVarID(ncid,'xc');
%     xc = netcdf.getVar(ncid,varid);
%     varid = netcdf.inqVarID(ncid,'yc');
%     yc = netcdf.getVar(ncid,varid);
% 
%     varid = netcdf.inqVarID(ncid,'analysis_sea_ice_thickness')
%     sit = netcdf.getVar(ncid,varid);
