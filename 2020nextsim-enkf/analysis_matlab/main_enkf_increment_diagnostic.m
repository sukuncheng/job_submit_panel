function [] = main_enkf_increment_diagnostic()
    clc
    clear
    close all
    % dbstop if error
    %  load data sources data_src: 0-mooring, 1-prior, 2-analysis
    % data_src 1, moorings, with noise from postprocess and forecast, thus, it is more diffcult to explain.
    % data_src 2,3 DA inputs and outputs
    start_date = datetime(2019,10,18);  % display date
    test = 'sit7';
    simul_dir =['/cluster/work/users/chengsukun/simulations/test_' test '_2019-10-18_7days_x_26cycles_memsize40'];
    periods = 26;
    for i = 1:periods
        t = start_date + (i-1)*7;
        [sit_f, sic_f, lon, lat] = load_data(t,1,simul_dir);  % forecast
        [sit_a, sic_a, lon, lat] = load_data(t,2,simul_dir);  % analysis
        for i = 1:size(lon,1)
            for j = 1:size(lat,2)
                %% DA increment
                SIC_increment = squeeze(sic_a(:,i,j) - sic_f(:,i,j));
                SIT_increment = squeeze(sit_a(:,i,j) - sit_f(:,i,j));
            end
        end
        averages = nanmean(?,'all')
        averages = nanmean(?,'all')
    end
    
    % -------- plot increment ------------------------------     
    figure(1);set(gcf,'Position',[10,15,1600,600], 'color','w')   
    subplot(121)
    DATA = SIC_increment;
    averages = nanmean(DATA,'all')
    title = ['increments of SIC', ' mean=' num2str(averages)];
    fun_geo_pcolor(lon,lat, DATA ,title, '')
    %
    subplot(122)
    DATA = SIT_increment;
    averages = nanmean(DATA,'all')
    title = ['increments of SIT', ' mean=' num2str(averages)];
    fun_geo_pcolor(lon,lat, DATA ,title, '')
    set(findall(gcf,'-property','FontSize'),'FontSize',16);
    saveas(figure(1),[ 'sicsit_increments_' test '.png'],'png')


    % figure(2);set(gcf,'Position',[10,15,800,600], 'color','w')   
    % % title = ['correlation coef. between increments of SIC and SIT', ' mean=' num2str(averages)];
    % scatter(sit_f,sic_f,3,'.');  % todo: reshape sit_f
    % hold on
    % plot([-1 -1], [1,1],'--b')
    % xlabel('SIT increment');
    % ylabel('SIC increment')
    % set(findall(gcf,'-property','FontSize'),'FontSize',16);
    % saveas(figure(2),[ 'sicsit_corr_increments_scatter_' test '.png'],'png')

end

%
function [sit, sic, lon, lat] = load_data(t, data_src,simul_dir)
    % sit_sic(ie,x,y) saves sic*sit, 
    start_date=datetime(2019,10,18);
    Ne = 40; % members   
    
    idate = floor(datenum(t - start_date+1)/7)+1;
    data_dir  = [ simul_dir '/date' num2str(idate) ]
    
    if data_src==0
        % data_src 1, moorings
        filename = ['Moorings_' num2str(year(t)) 'd' num2str(day(t,'dayofyear'),'%03d') '.nc'];
        for ie = 1:Ne
            file_dir = [data_dir '/mem' num2str(ie) '/' filename];
            data_tmp = ncread(file_dir,'sic');
            sic(ie,:,:) = data_tmp(:,:,1);
            data_tmp = ncread(file_dir,'sit');
            sit_sic(ie,:,:) = data_tmp(:,:,1);    
        end   

        lon = ncread(file_dir,'longitude');
        lat = ncread(file_dir,'latitude');
    else
        % data_src 2, da inputs and outputs
        for ie = 1:Ne
            if data_src==1
                filename = ['mem' num2str(ie,'%03d') '.nc'];
            elseif data_src==2
                filename = ['mem' num2str(ie,'%03d') '.nc.analysis'];
            end
            file_dir = [data_dir '/filter/prior/' filename];
            data_tmp = ncread(file_dir,'sic');
            sic(ie,:,:) = data_tmp(:,:,1);
            data_tmp = ncread(file_dir,'sit');
            sit_sic(ie,:,:) = data_tmp(:,:,1);    
        end   
        lon = ncread([data_dir '/filter/prior/mem001.nc'],'longitude');
        lat = ncread([data_dir '/filter/prior/mem001.nc'],'latitude');
    end
    sic(sic<0.15) = 0;
    sit_sic(sic<1.e-6) = nan;
    sic(sic<1.e-6) = nan;
    sit = sit_sic./(sic+1.e-10);            
end
