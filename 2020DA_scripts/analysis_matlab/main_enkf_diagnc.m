function [] = main_enkf_diagnc()
% display data in enkf_diag.nc
    clc
    clear
    close all
    dbstop if error
    format short g
    %
    global title_date
    load('test_inform.mat')
    Var = 'sit';
    gifname = [ Exp_ID '_dfs_srf_' Var '.gif'];
    for i = 1:N_periods
        n = (i-1)*Duration +1;
        title_date = dates(n);
        enkf_dir = [ simul_dir '/date' num2str(i) '/filter'];
        fun_process_enkf_diag(enkf_dir)

        % -------- animation -------------------------------------
        f = getframe(gcf);
        im=frame2im(f);
        [I,map] = rgb2ind(im,256);
        if i==1  
            imwrite(I,map,gifname,'gif','loopcount',inf,'Delaytime',.5)
        else
            imwrite(I,map,gifname,'gif','writemode','append','Delaytime',.5)
        end
        % --------------------------------------------------------
    end
end

% calcualte the mean and std (b & d) of reduced centered random variable (RCRV) at the assimilation time. https://os.copernicus.org/articles/13/123/2017/os-13-123-2017.pdf 
% they provides simple diagnostics of whether the forecast ensemble provides a reliable estimate of the uncertainty of the ensemble mean, which is a trusted in view of the observations with the assumed uncertainties.
function statistics = fun_process_enkf_diag(enkf_dir)
    global  title_date
    % nlobs = alloc2d(nj, ni, sizeof(int));
    % dfs = alloc2d(nj, ni, sizeof(float));
    % srf = alloc2d(nj, ni, sizeof(float));
    % averaging the number of observations
    % pnlobs = alloc3d(obs->nobstypes, nj, ni, sizeof(int));
    % pdfs = alloc3d(obs->nobstypes, nj, ni, sizeof(float));
    % psrf = alloc3d(obs->nobstypes, nj, ni, sizeof(float));    
    
    namelist = {'dfs','srf','nlobs','pdfs','psrf','pnlobs'};
    filename = [enkf_dir '/enkf_diag.nc'];
    % ncdisp(filename)
    dfs    = ncread(filename,'dfs');     % degrees of freedom of signal 
    srf    = ncread(filename,'srf');     % spread reduction factor
    nlobs  = ncread(filename,'nlobs');
    % pdfs   = ncread(filename,'pdfs');  
    % psrf   = ncread(filename,'psrf');   
    % pnlobs = ncread(filename,'pnlobs');
    %
    statistics(1) = nanmean(reshape(dfs,1,[]));
    statistics(2) = nanmean(reshape(srf,1,[]));
    statistics(3) = nanmean(reshape(nlobs,1,[]));
    % statistics(4) = nanmean(reshape(pdfs,1,[]));
    % statistics(5) = nanmean(reshape(psrf,1,[]));
    % statistics(6) = nanmean(reshape(pnlobs,1,[]));
        %
    filename = [enkf_dir '/reference_grid.nc'];
    % ncdisp(filename)
    lon = ncread(filename,'plon');
    lat = ncread(filename,'plat');
    unit = '';
    figure(1);set(gcf,'Position',[100,150,1130,550], 'color','w'); clf
    subplot(131); fun_geo_plot(lon,lat, dfs,[datestr(title_date) ' dfs'],unit); caxis([0 18])
    subplot(132); fun_geo_plot(lon,lat, srf,' srf',unit); caxis([0 3])
    subplot(133); fun_geo_plot(lon,lat, nlobs,' nlobs',unit); 
        % pdfs seems to be the average of multi-observations. for single observation, pdfs = dfs
%         subplot(234); fun_geo_plot(lon,lat,  pdfs,'pdfs',unit); 
%         subplot(235); fun_geo_plot(lon,lat,  psrf,'psrf',unit); 
%         subplot(236); fun_geo_plot(lon,lat,pnlobs,'pnlobs',unit); 
    set(findall(gcf,'-property','FontSize'),'FontSize',18);
    
% gridnodes-0.txt in old version
%         figure(); set(gcf,'Position',[100,150,1100,850], 'color','w')
%         fileID = fopen([path '/gridnodes-0.txt'],'r'); % % %  one can either use lon, lat in enkf_diag.nc (modified by sukun cheng) or use lon, lat in /gridnodes-0.txt  
%         data = textscan(fileID,'%f %f','HeaderLines',1) ;
%         data = cell2mat(data);
%         fclose(fileID);
%         size(data)
%         xlon = data(:,1);
%         xlat = data(:,2);
%         
%         m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
%         m_coast(); hold on
%         subplot(121);m_scatter(xlon,xlat,[],1:length(xlat),'.')
%         hold on
%         x = reshape(lon',1,[]);
%         y = reshape(lat',1,[]);
%         subplot(122);m_scatter(x,y,[],1:length(x),'.')    
end

function fun_geo_plot(lon,lat,Var,Title, unit)
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);

    if 0
        m_pcolor(lon, lat, Var); shading flat; 
    else
        ID= find(Var~=0);
        x = reshape(lon(ID),1,[]);
        y = reshape(lat(ID),1,[]);
        z = reshape(Var(ID),1,[]);
        m_scatter(x,y,20,z,'.');
    end

    h = colorbar;
    title(h, unit);
    m_grid();
    m_coast(); 
%     m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({Title,''},'fontweight','normal');
%     colormap(gca,bluewhitered);
    colormap(jet)
end
