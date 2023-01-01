function [] = estimate_interpolation_errors()
clc
clear 
%close all
% estimate the interpolation errors of state vector in DA between structured and unstructed grids compare two tests. 
% The two tests are deterministic free run, no DA
% test period is from 18.10.2019-16.4.2020
% test1=betzy@login-1:/cluster/work/users/chengsukun/simulations/test_FreeRun-daily-restart_2019-10-18_1days_x_182cycles_memsize1
        % restart every day, save and reload state vector on a reference grid
% test2=test_FreeRun-daily-restart_2019-10-18_182days_x_1cycles_memsize1
        % reference test, contineous without restart


data_dir = '/cluster/work/users/chengsukun/simulations';
% 
test_dir{1} = [data_dir '/test_FreeRun-daily-restart_2019-10-18_182days_x_1cycles_memsize1'];
test_dir{2} = [data_dir '/test_FreeRun-daily-restart_2019-10-18_7days_x_26cycles_memsize1'];
test_dir{3} = [data_dir '/test_FreeRun-daily-restart_2019-10-18_1days_x_182cycles_memsize1'];
% test1_dir = [data_dir '/test_FreeRun-daily-restart_2019-10-18_1days_x_182cycles_memsize1-unmodified-readstatevector'];


time0 = datetime(2019,10,18);
time1 = datetime(2020,04,16);
times = time0:time1;

for i = 1:182
    dt = times(i);
    filename = [ 'Moorings_' num2str(year(dt))  'd' num2str(day(dt,'dayofyear'),'%03d') '.nc' ];
    test_files{1} = [test_dir{1} '/date1/mem1/' filename];
    idate = floor((i-1)/7)+1;
    test_files{2} = [test_dir{2} '/date' num2str(idate) '/mem1/' filename];
    idate = i;
    test_files{3} = [test_dir{3} '/date' num2str(idate) '/mem1/' filename];
    vars = {'sic','sit'}
    std_errors12(i,:) = calc_error(test_files{1}, test_files{2}, vars);
    std_errors13(i,:) = calc_error(test_files{1}, test_files{3}, vars);
    averages(i,1,:) = calc_average(test_files{1}, vars);
    averages(i,2,:) = calc_average(test_files{2}, vars);
    averages(i,3,:) = calc_average(test_files{3}, vars);
end

% 
figure(1);clf
for i = 1: length(vars)
    subplot(2,1,i); 
    plot(times, std_errors12(:,i)); 
    hold on;
    plot(times, std_errors13(:,i)); 
    ylabel(['spatial averaged RMSE ' vars(i) ])
end
legend('test1-test2','test1-test3','location','best');
grid on;
saveas(gcf,'mean_ts_rmse.png')

figure(2);clf
for i = 1:2
    subplot(2,1,i);
    for j = 1:length(test_files)
        plot(times, averages(:,j,i)); 
        hold on;
    end
    % legend('free run', 'restart per 1day','restart per 7days')
    legend('test1', 'test2', 'test3','location','best');
    grid on;
    title(['mean ' vars{i}])
end
saveas(gcf,'mean_ts_thickness.png')

figure(3);clf
display_spatial_diff(test_files{1}, test_files{2}, vars);
% display_spatial_diff(test_files{1}, test_files{3}, vars);
saveas(gcf,'spatial_difference.png')
end

%
%
function averages = calc_average(test1_file, vars)
    max_thick = 6;
    for i = 1:length(vars)
        var = vars{i};
        data1 = ncread(test1_file,var);
        % exclude open water
        data1 = reshape(data1,1,[]);
        id = (data1 >0) & (data1<=max_thick) ;
        averages(i,:) = nanmean(data1(id));
    end
end

%
function errors = calc_error(test1_file, test2_file, vars)
    max_thick = 5;
    for i = 1:length(vars)
        var = vars{i};
        data1 = ncread(test1_file,var);
        data2 = ncread(test2_file,var);
        % Standard deviation of the difference
        % errors(i) = std(data1 - data2,1,'all');
        % exclude open water
        data1 = reshape(data1,1,[]);
        data2 = reshape(data2,1,[]);
        id = (data1 >0 | data2>0 ) & (data1<=max_thick & data2<=max_thick);
        % errors(i) = norm(data1(id) - data2(id))/sqrt(sum(id));
        errors(i) = sqrt(mean((data1(id) - data2(id)).^2));
    end
end

%
function display_spatial_diff(test1_file, test2_file, vars)
    max_thick = 5;
    var = vars{2};
    lon = ncread(test1_file,'longitude');
    lat = ncread(test1_file,'latitude');
    data1 = ncread(test1_file,var);
    data2 = ncread(test2_file,var);
    data1(data1>max_thick) =nan;
    data2(data2>max_thick) =nan;
    difference = data1 - data2;

    subplot(1,2,1)
    fun_geo_pcolor(lon,lat,data1,[var  ' no-interp'], '')
    subplot(1,2,2)
    fun_geo_pcolor(lon,lat,data2,[var  ' interp'], '')
    % colormap(gca,bluewhitered);

    % for i = 1:length(vars)
    %     var = vars{i};
    %     lon = ncread(test1_file,'longitude');
    %     lat = ncread(test1_file,'latitude');
    %     data1 = ncread(test1_file,var);
    %     data2 = ncread(test2_file,var);
    %     difference = data1 - data2;

    %     subplot(1,2,i)
    %     fun_geo_pcolor(lon,lat,difference,[var  'difference'], '')
    %     colormap(gca,bluewhitered);
    % end   
end

%
function fun_geo_pcolor(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);
    m_pcolor(lon, lat, Var); shading flat; 
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({Title,''},'fontweight','normal')
    m_grid('linest',':');
    h = colorbar; %('southoutside');
    title(h, unit);
end