function [] = main_fieldstates_comparison()
    clc
    clear
    close all
    dbstop if error
    format short g
    % %
    % simul_dir = '/cluster/work/users/chengsukun/simulations'; %~/Desktop/fram
    % % filename =[ simul_dir '/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_20191015_20191021_r_v202_01_l4sit.nc'];
    % % lon = ncread(filename,'lon');
    % % lat = ncread(filename,'lat');
    % % data22 = ncread(filename,'analysis_sea_ice_thickness');
    % % %
    % % filename =[simul_dir '/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_20191015_20191021_r_v203_01_l4sit.nc'];
    % % data23 = ncread(filename,'analysis_sea_ice_thickness'); 
    % % fun_geo_plot(lon,lat,data23-data22,'CS2SMOSv2.3 - v2.2, analysis sit, 20191015\_20191021\_r','m');  
    % % colormap(jet); 
    % % set(findall(gcf,'-property','FontSize'),'FontSize',18);   

%%
    simul_dir = '/cluster/work/users/chengsukun/simulations'; %~/Desktop/fram
    Vars={'sic'}; %,'sit'
    for i = 1:length(Vars)
        Var = Vars{i}
%         %% load **.nc
%         filename = [simul_dir '/test_spinup_2019-09-03_45days_x_1cycles_memsize40/date1/filter/prior/mem001.nc'];
%         data1 = ncread(filename,Var); 
%         lon = ncread(filename,'longitude');
%         lat = ncread(filename,'latitude');
%         unit = '(m)';
%         subplot(2,3,1+3*(i-1)); fun_geo_plot(lon,lat,data1,['2019-10-17 nextsim ' Var],unit); colormap(jet); %caxis([0 6]);
%         % hold on
%         % colormap(jet)
%         %% load **.nc.analysis
%         filename = [simul_dir '/test_spinup_2019-09-03_45days_x_1cycles_memsize40/date1/filter/size40_I1_L300_R2_K2_DAsic/mem001.nc.analysis'];
%         data2 = ncread(filename,Var);
%     %     lon = ncread(filename,'plon');
%     %     lat = ncread(filename,'plat');
%         unit = '(m)';
%         subplot(2,3,2+3*(i-1)); fun_geo_plot(lon,lat,data2,['2019-10-17 analysis ' Var],unit); % colormap(jet); %caxis([0 6]);
% %         colormap(bluewhitered)
        % %% load **.nc
        % filename = [ simul_dir '/test_DAsic_2019-10-18_1days_x_1cycles_memsize1/date1/mem1/Moorings_2019d291.nc']
        % ncdisp(filename);
        % data = ncread(filename,Var);
        % lon = ncread(filename,'longitude');
        % lat = ncread(filename,'latitude');
        % unit = '(m)';
        % data(data<1)=nan;
        % % subplot(2,3,3+3*(i-1)); 
        % fun_geo_plot(lon,lat,data,['2019-10-18 nextsim ' Var],unit);  %colormap(jet);   
        plot(1:10)
    end
    saveas(gcf,['fieldstates_enkf_check.png'],'png')
end

function fun_geo_plot(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);
    m_pcolor(lon, lat, Var); shading flat; 
    h = colorbar;
    title(h, unit);
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({Title,''})
    m_grid('linest',':');
end
