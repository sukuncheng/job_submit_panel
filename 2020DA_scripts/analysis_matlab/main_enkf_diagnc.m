function [] = main_enkf_diagnc()
    % display data in enkf_diag.nc
        clc
        clear
        close all
        dbstop if error
        format short g
        %
        load('test_inform.mat')
        for i = 1:N_periods
            enkf_dir = [ simul_dir '/date' num2str(i) '/FILTER'];
            fun_process_enkf_diag(enkf_dir)
        end
    end
    
    % calcualte the mean and std (b & d) of reduced centered random variable (RCRV) at the assimilation time. https://os.copernicus.org/articles/13/123/2017/os-13-123-2017.pdf 
    % they provides simple diagnostics of whether the forecast ensemble provides a reliable estimate of the uncertainty of the ensemble mean, which is a trusted in view of the observations with the assumed uncertainties.
    function statistics = fun_process_enkf_diag(path)
    % nlobs = alloc2d(nj, ni, sizeof(int));
    % dfs = alloc2d(nj, ni, sizeof(float));
    % srf = alloc2d(nj, ni, sizeof(float));
    % averaging the number of observations
    % pnlobs = alloc3d(obs->nobstypes, nj, ni, sizeof(int));
    % pdfs = alloc3d(obs->nobstypes, nj, ni, sizeof(float));
    % psrf = alloc3d(obs->nobstypes, nj, ni, sizeof(float));
        namelist = {'dfs','srf','nlobs','pdfs','psrf','pnlobs'};
        filename = [path '/enkf_diag.nc'];
        ncdisp(filename)
        lon    = ncread(filename,'lon');
        lat    = ncread(filename,'lat');
        dfs    = ncread(filename,'dfs');     % degrees of freedom of signal 
        srf    = ncread(filename,'srf');     % spread reduction factor
        nlobs  = ncread(filename,'nlobs');
        pdfs   = ncread(filename,'pdfs');  
        psrf   = ncread(filename,'psrf');   
        pnlobs = ncread(filename,'pnlobs');
        %
        dfs(dfs==0) = nan;
        statistics(1) = nanmean(reshape(dfs,1,[]));
        statistics(2) = nanmean(reshape(srf,1,[]));
        statistics(3) = nanmean(reshape(nlobs,1,[]));
        statistics(4) = nanmean(reshape(pdfs,1,[]));
        statistics(5) = nanmean(reshape(psrf,1,[]));
        statistics(6) = nanmean(reshape(pnlobs,1,[]));
        
        figure(); set(gcf,'Position',[100,150,1100,850], 'color','w')
    
        fileID = fopen([path '/gridnodes-0.txt'],'r');
        data = textscan(fileID,'%f %f','HeaderLines',1) ;
        data = cell2mat(data);
        fclose(fileID);
        size(data)
        xlon = data(:,1);
        xlat = data(:,2);
        
        x = reshape(lon,1,[]);
        x(x==0) =nan;
        subplot(121);plot(xlon);hold on; plot(x,'r');
        x = reshape(lat,1,[]);
        x(x==0) =nan;
        subplot(122);plot(xlat);hold on; plot(x,'r');
        %
    %     unit = '(m)';
        subplot(231); fun_geo_plot(lon,lat, dfs,' dfs',unit); 
        subplot(232); fun_geo_plot(lon,lat, srf,' srf',unit); 
        subplot(233); fun_geo_plot(lon,lat, nlobs,' nlobs',unit); 
        subplot(234); fun_geo_plot(lon,lat,  pdfs,'pdfs',unit); 
        subplot(235); fun_geo_plot(lon,lat,  psrf,'psrf',unit); 
        subplot(236); fun_geo_plot(lon,lat,pnlobs,'pnlobs',unit); 
        set(findall(gcf,'-property','FontSize'),'FontSize',16);
    end
    
    function fun_geo_plot(lon,lat,Var,Title, unit)
        Var(Var==0) = nan;
        m_proj('Stereographic','lon',-45,'lat',90,'radius',50);
        
        if 0
            m_pcolor(lon, lat, Var); shading flat; 
        else
            x = reshape(lon,1,[]);
            y = reshape(lat,1,[]);
            z = reshape(Var,1,[]);
            m_scatter(x,y,20,z,'.');
        end
        
        h = colorbar;
        title(h, unit);
        m_grid();
        m_coast('color','k'); 
    %     m_coast('patch',0.7*[1 1 1]);    
        set(gca,'XTickLabel',[],'YTickLabel',[]);
        title({Title,''},'fontweight','normal');
    %     colormap(gca,bluewhitered);
    end
    