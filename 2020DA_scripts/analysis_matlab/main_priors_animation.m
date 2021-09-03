function [] = main_priors_animation()
    clc
    clear
    close all
    dbstop if error
    
    main_settings
    check_a_member = 1; % check_a_member=0 presents ensemble average
    for method = {'mean'}  %mean: ensemble ensemble, spread: ensemble spread
        for Var = {'sss','sst'}
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
        colormap(jet)
    end
    gifname = [ Exp_ID '_' Var '.gif']
    nfig = 1;
    for i = 1:N_periods
        for j = Duration
            n = (i-1)*Duration +j;
            t = dates(n)
            data_dir = [ simul_dir '/date' num2str(i) ];
            clear data         
            if check_a_member==0
                id = 1:Ne;
            else
                id = check_a_member;
            end
            for ie = id
                file_dir = [data_dir '/mem' num2str(ie) '/prior.nc'];
    %             ncdisp(file_dir)
                data_tmp = ncread(file_dir,Var);
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
            h=colorbar;
            if strcmp(method,'mean')
                if strcmp(Var,'sic')
                    caxis([0 1])
                elseif strcmp(Var,'sit')
                    caxis([0 6]);
                    title(h,'(m)')
                elseif strcmp(Var,'sss')
                    caxis([0 40])
                elseif strcmp(Var,'sst')
                    caxis([-10 5])
                end
            else
                if strcmp(Var,'sic')
                    caxis([0 0.5])
                elseif strcmp(Var,'sit')
                    caxis([0 1.8]);
                    title(h,'(m)')
                elseif strcmp(Var,'sss')
                    caxis([0 0.5])
                elseif strcmp(Var,'sst')
                    caxis([0 1])
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
            if nfig==1  
                imwrite(I,map,gifname,'gif'); %,'loopcount',inf,'Delaytime',.5)
            else
                imwrite(I,map,gifname,'gif','writemode','append','Delaytime',.5)
            end
            nfig = nfig + 1;
        end
    end
end
