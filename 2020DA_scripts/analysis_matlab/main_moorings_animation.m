function [] = main_moorings_animation()
    clc
    clear
    close all
    % dbstop if error
    
    main_settings
    check_a_member = 1; % check_a_member=0 presents ensemble average
    for method = {'mean', 'Spread'}  %mean: ensemble ensemble, spread: ensemble spread
        for Var = {'sit','sic'}
            fun_moorings(char(Var),char(method),check_a_member);
        end
    end
end

function fun_moorings(Var,method,check_a_member)
    load('test_inform.mat')   % 
    figure(1); set(gcf,'color','w')
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);  
    if strcmp(method,'Spread')
        colormap(bluewhitered)
    else
        colormap(viridis)
    end
    gifname = [ Exp_ID '_' method '_' Var '.gif']
    n = 0;
    for i = 1:N_periods
        for j = 1:Duration
            n = (i-1)*Duration +j;
            t = dates(n);
            data_dir = [ simul_dir '/date' num2str(i) ]
            filename = ['Moorings_' num2str(year(t)) 'd' num2str(day(t,'dayofyear'),'%03d') '.nc'];
            clear data
            [gifname '  ' datestr(t) '  ' filename]
            if check_a_member==0
                id = 1:Ne;
            else
                id = check_a_member;
            end
            for ie = id
                file_dir = [data_dir '/mem' num2str(ie) '/' filename];
    %             ncdisp(file_dir)
            if strcmp(Var,'sic')
                data_tmp = ncread(file_dir,'sic');
            elseif strcmp(Var,'sit')
                data_tmp = ncread(file_dir,'sit');
            elseif strcmp(Var,'abs_sit')
                total_sic = ncread(file_dir,'sic');
                total_sit = ncread(file_dir,'sit');
                data_tmp = total_sit./total_sic;
            end
                data(ie,:,:) = data_tmp(:,:,1);
            end   
            data(data==0) = nan;   % exclude open water from nextsim.Moorings
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
            h=colorbar;
            if strcmp(method,'mean')
                if strcmp(Var,'sic')
                    caxis([0 1])
                elseif strcmp(Var,'sit')
                    % caxis([0 4.5]);
                    title(h,'(m)')
                end
            else
                if strcmp(Var,'sic')
                    caxis([0 0.5])
                elseif strcmp(Var,'sit')
                    caxis([0 1.8]);
                    title(h,'(m)')
                end
            end
            
            m_grid('color','k'); % 'linestyle','-'
            m_coast('patch',0.7*[1 1 1]);  
            title([datestr(t) ' ' method ' ' Var],'fontweight','normal','HorizontalAlignment','right');
            set(findall(gcf,'-property','FontSize'),'FontSize',18);
            
            % -------- animation -------------------------------------
            f = getframe(gcf);
            im=frame2im(f);
            [I,map] = rgb2ind(im,256);            
            if n==1  
                imwrite(I,map,gifname,'gif','loopcount',inf,'Delaytime',.5)
            else
                imwrite(I,map,gifname,'gif','writemode','append','Delaytime',.5)
            end
            % ---------------------------------------------------------
            X = reshape(X,1,[]);
            meanspread(n) = nanmean(X);
        end
    end
%     if check_a_member>0
%         saveas(figure(1),[ Var '_mem' num2str(check_a_member) '.png'],'png')
%     end
    
    figure(2)
    set(figure(2),'Position',[100,200,550,400], 'color','w')
    plot(dates, meanspread,'.-');
    if strcmp(Var,'SIT')
        ylabel([method ' of ' Var '(m)'])
    else
        ylabel([method ' of ' Var])
    end

%     axis([dates(1)-1 dates(end)+1 0 0.2]);
    set(findall(gcf,'-property','FontSize'),'FontSize',18); 
    saveas(figure(2),[ Exp_ID 'Spatial_' method '_' Var '_main_moorings.png'],'png')
end



% convergen of filter. 
% spread. 
% srf.  spread reduction 1 is the devision by 2, 
% dfs.  <=30
% R reflexision,     a matrix of ensemble mean
% square root filter apply inflation on anormalies