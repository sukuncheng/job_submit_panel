function [] = main_enkf_diag()
    clc
    clear
    close all
    dbstop if error
    format short g
    mnt_dir = '/Users/sukeng/Desktop/fram';
%     mnt_dir = '/cluster/work/users/chengsukun/src/simulations';
    run_dir = '/run_2019-10-15_Ne30_T12_D7/I1_L600_R2_K2';
 
    % 
    Duration = 7;
    for i = 1:7
        fun_process_enkf_diag([ mnt_dir run_dir '/date' num2str(i) '/filter'])
        dates(i) = datetime(2019,10,15 + i*Duration);
    end
end

% calcualte the mean and std (b & d) of reduced centered random variable (RCRV) at the assimilation time. https://os.copernicus.org/articles/13/123/2017/os-13-123-2017.pdf 
% they provides simple diagnostics of whether the forecast ensemble provides a reliable estimate of the uncertainty of the ensemble mean, which is a trusted in view of the observations with the assumed uncertainties.
function fun_process_enkf_diag(path)
    filename = [path '/enkf_diag.nc'];
    ncdisp(filename)
    dfs    = ncread(filename,'dfs');     % degrees of freedom of signal 
    srf    = ncread(filename,'srf');     % spread reduction factor
    nlobs  = ncread(filename,'nlobs');
    %
    pdfs   = ncread(filename,'pdfs');  
    psrf   = ncread(filename,'psrf');   
    pnlobs = ncread(filename,'pnlobs');

    %
    filename = [path '/reference_grid.nc'];
    lon = ncread(filename,'plon'); 
    lat = ncread(filename,'plat'); 
    
    figure();
    set(gcf,'Position',[100,150,1100,850], 'color','w')
    unit = '(m)';
    subplot(231); fun_geo_plot(lon,lat,   dfs',' dfs',unit); 
    subplot(232); fun_geo_plot(lon,lat,   srf',' srf',unit); 
    subplot(233); fun_geo_plot(lon,lat, nlobs',' nlobs',unit); 
    subplot(234); fun_geo_plot(lon,lat,  pdfs','pdfs',unit); 
    subplot(235); fun_geo_plot(lon,lat,  psrf','psrf',unit); 
    subplot(236); fun_geo_plot(lon,lat,pnlobs','pnlobs',unit); 
    set(findall(gcf,'-property','FontSize'),'FontSize',16); 
end

function fun_geo_plot(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);
    m_pcolor(lon, lat, Var); shading flat; 
    h = colorbar;
    title(h, unit);
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title(Title)
    colormap(gca,bluewhitered);
end
