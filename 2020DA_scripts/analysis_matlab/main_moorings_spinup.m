function [] = main_moorings_spinup()
    clc
    clear
    close all
    dbstop if error
    
    load('test_inform.mat')
    % Var = 'SIT (m)';
    Var = 'SIC'
    method = 'mean'; 
    % method = 'Spread'; %'mean': ensemble ensemble, spread: ensemble spread
    check_a_member = 0; % check_a_member=0 presents ensemble average
%% ------------------------------------------------------------------------ 
    figure(1); set(gcf,'color','w')
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);  
    if strcmp(method,'Spread')
        colormap(bluewhitered)
    else
        colormap(jet)
    end
    
    gifname = [ 'Spinup_' method '_' Var '.gif'];
    for i = 1:42
        t = dates(i);  
%         continue
        data_dir = [ simul_dir '/date1' ];
        filename = ['Moorings_' num2str(year(t-1)) 'd' num2str(day(t-1,'dayofyear'),'%03d') '.nc']
        clear data
        if check_a_member==0
            id = 1:Ne;
        else
            id = check_a_member;
        end
        for ie = id
            file_dir = [data_dir '/mem' num2str(ie) '/' filename]
%             ncdisp(file_dir)
            if strcmp(Var,'SIC')
                data_tmp = ncread(file_dir,'sic');
            else
                data_tmp = ncread(file_dir,'sit');
            end
            data(ie,:,:) = data_tmp(:,:,1);
        end   
%         data(data==0) = nan;   % exclude open water from nextsim.Moorings
        if check_a_member>0
            X = squeeze(data);              
        else 
            if strcmp(method,'Spread')
                X = squeeze(std(data,1));
            elseif strcmp(method,'mean')==1
                X = squeeze(mean(data,1)); 
            end
        end
        
        % -------- plot ------------------------------     
        lon = ncread(file_dir,'longitude');
        lat = ncread(file_dir,'latitude');
        
        m_pcolor(lon,lat,X); shading flat; 
        if strcmp(method,'mean')
            if strcmp(Var,'SIC')
                caxis([0 1])
            else
                caxis([0 6]);
            end
        else
            if strcmp(Var,'SIC')
                caxis([0 0.5])
            else
                caxis([0 1.8]);
            end
        end
        
        m_grid('color','k'); % 'linestyle','-'
        m_coast('patch',0.7*[1 1 1]);  

        h=colorbar;
        
        title([datestr(t) ' ' method ' ' Var],'fontweight','normal','HorizontalAlignment','right');
        set(findall(gcf,'-property','FontSize'),'FontSize',18);
        
        % -------- animation -------------------------------------
        f = getframe(gcf);
        im=frame2im(f);
        [I,map] = rgb2ind(im,256);
        if i==1  
            imwrite(I,map,gifname,'gif','loopcount',inf,'Delaytime',.5)
%             imwrite(I,map,gifname,'gif');
        else
            imwrite(I,map,gifname,'gif','writemode','append','Delaytime',.5)
        end
        % ---------------------------------------------------------
        X = reshape(X,1,[]);
        meanspread(i) = nanmean(X);
    end
%     if check_a_member>0
%         saveas(figure(1),[ Var '_mem' num2str(check_a_member) '.png'],'png')
%     end
    
    figure(2)
    set(figure(2),'Position',[100,200,550,400], 'color','w')
    plot(dates, meanspread,'.-');
    ylabel([method ' of ' Var])
%     axis([dates(1)-1 dates(end)+1 0 0.2]);
    set(findall(gcf,'-property','FontSize'),'FontSize',18); 
    saveas(figure(2),['Spatial_spread_' Var 'main_moorings.png'],'png')
end



% convergen of filter. 
% spread. 
% srf.  spread reduction 1 is the devision by 2, 
% dfs.  <=30
% R reflexision,     a matrix of ensemble mean
% square root filter apply inflation on anormalies