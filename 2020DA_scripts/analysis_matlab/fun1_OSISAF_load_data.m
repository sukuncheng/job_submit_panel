%% load_OSISAF_data
function fun1_OSISAF_load_data(filename)    
    filename    
    load(filename)
    disp('loading OSISAF modelled and observed data');
    % the actual file number minus 2 for 2-dates drift, the .nc file
    % contains intial and 2-day(final) results, and outputs come out since 2nd day, thus minus 3
    OSISAF_FILE_NUMBER = Duration - 3; 
    for iperiod = 1:N_periods
        % set time period in a short forecast
        start_time = datenum(periods_list(iperiod))+1;
        end_time   = start_time + OSISAF_FILE_NUMBER -1;
        dates = start_time:end_time;            
        % load ensemble member
        for ie = 1:Ne
            data_dir = [simul_dir '/date' num2str(iperiod) '/mem' num2str(ie)];    % set file directory        
            [osisaf_model(iperiod).ensemble(ie).short_term,osisaf_obs(iperiod).ensemble(ie).short_term] = ...
                            fun_get_simulated_observed_OSISAF_ice_drift(data_dir,mnt_OSISAF_dir,dates);               
        end
    end
    save(filename,'osisaf_model','osisaf_obs','OSISAF_FILE_NUMBER','-append')
end
%
function  [model,obs] = fun_get_simulated_observed_OSISAF_ice_drift(data_dir,mnt_dir,dates)
% load nextsim dir, indicated by S as first letter
% load OSISAF_data, indicated by M as first letter

    Radius = 6378.273; 
    m_proj('Stereographic','lon',-45,'lat',90,'radius',25);    
%
    for i = 1:length(dates)  % loop dates to get a set of rmse in those dates
        DATE = dates(i);
        TEMP = strrep(datestr(DATE,26),'/',''); % Find and replace substring,newStr = strrep(str,old,new)       
    %
        readin_file = [data_dir '/OSISAF_Drifters_' TEMP '.nc']
        if exist(readin_file)==0
            disp(['inexistence ' readin_file])
            pause
        end
        try
            Time= ncread(readin_file,'time');         % 2010-09-25:1200-2010-09-27:1200
        catch
            valid_date(i) = nan;
            disp(['cannot read ' readin_file])
            break
        end
           
        MONTH = datestr(DATE,5);
        if length(Time)==1 || (str2num(MONTH)<10 && str2num(MONTH)>4)
            valid_date(i) = nan;
            disp('no osisaf simulation data')
            continue
        end
        [datestr(double(Time(1))+ datenum(1900,1,1),21) ' - ' datestr(double(Time(2))+ datenum(1900,1,1),21)]
        Slon = ncread(readin_file,'longitude');
        Slat = ncread(readin_file,'latitude');
        Ssic = ncread(readin_file,'sic');
        Sindex = ncread(readin_file,'index');
        % 
        Slon0 = squeeze(Slon(1,:,1));
        Slat0 = squeeze(Slat(1,:,1));
        Slon1 = squeeze(Slon(1,:,2));
        Slat1 = squeeze(Slat(1,:,2));
        index = squeeze(Sindex(1,:,2)); % index varies per file
        %
        sic = squeeze(Ssic(1,:,2));         % ice concentration
        %% osisaf dataset
        [Mlat0,Mlon0,Mlat1,Mlon1] = fun_OSISAF_ice_drift(mnt_dir,DATE); % time format 2010-09-23:1200-2010-09-25:1200
        Mlat0 = reshape(Mlat0,1,[]); 
        Mlon0 = reshape(Mlon0,1,[]);  
        Mlat1 = reshape(Mlat1,1,[]); % same index order as reshape(Mlat,[],1);
        Mlon1 = reshape(Mlon1,1,[]); 
    % matching indices with start positions, and exclude some data points
        [Sid,Mid] = fun_set_index(Slon0,Slat0,Slon1,Slat1,Mlon0,Mlat0,Mlon1,Mlat1);
    % convert geocooridinate to Polar Stereographic x,y (km) by NSIDC Polar Stereographic Projection
        [SX0,SY0] = m_ll2xy(Slon0(Sid),Slat0(Sid));          
        [SX1,SY1] = m_ll2xy(Slon1(Sid),Slat1(Sid));
        %
        [MX0,MY0] = m_ll2xy(Mlon0(Mid),Mlat0(Mid));
        [MX1,MY1] = m_ll2xy(Mlon1(Mid),Mlat1(Mid));        
        id = find(~isnan(SX1) & ~isnan(MX1));
        Sid = Sid(id);
        Mid = Mid(id);
        % checked meshes matching: plot(Slon0(Sid),Slat0(Sid),'o'); hold on; plot(Mlon0(Mid),Mlat0(Mid),'x');
    % 1) save X,Y components of speeds of simulated ice drift                
        model(i).valid_date = DATE;             
        model(i).u = (SX1(id)-SX0(id))*Radius/2; % divide 2 day
        model(i).v = (SY1(id)-SY0(id))*Radius/2;
        model(i).day0_lon = Slon0(Sid);
        model(i).day0_lat = Slat0(Sid);
%         model(i).day2_lon = Slon1(Sid);
%         model(i).day2_lat = Slat1(Sid);
        model(i).index = index(Sid);
        model(i).ice_con = sic(Sid); 
        obs(i).u = (MX1(id)-MX0(id))*Radius/2;
        obs(i).v = (MY1(id)-MY0(id))*Radius/2;
%         obs(i).day0_lon = Mlon0(Mid);
%         obs(i).day0_lat = Mlat0(Mid);
%         obs(i).day2_lon = Mlon1(Mid);
%         obs(i).day2_lat = Mlat1(Mid);
  
%     %% plot
%         figure(1); % ice drift vector
%         subplot(121)
%         id = find(abs(Slon1-Slon0)<4); % 4 is observed by plotting out abs(Slon1-Slon0), remove outliers
%         m_quiver(Slon0(id),Slat0(id),Slon1(id)-Slon0(id),Slat1(id)-Slat0(id));
%         hold on
%         id = find(abs(Mlon1-Mlon0)<4);
%         m_quiver(Mlon0(id),Mlat0(id),Mlon1(id)-Mlon0(id),Mlat1(id)-Mlat0(id));
%         hold off
%         m_coast('patch',[.9 .9 .9],'edgecolor','none');
%         set(gca, 'XTick', [], 'YTick', []);
%         m_grid('tickdir','out','yaxislocation','right',...
%             'xaxislocation','top','xlabeldir','end','ticklen',.02);
% 
%         subplot(122)
%         quiver(SX0,SY0,SX1-SX0,SY1-SY0);
%         hold on
%         quiver(MX0,MY0,MX1-MX0,MY1-MY0); 
%         hold off
%         set(gca, 'XTick', [], 'YTick', []);
% 
%         % check validation
%         figure(2)
%         subplot(121); plot(Slon1(Sid),Slat1(Sid),'.k',Mlon1(Mid),Mlat1(Mid),'or');title('selected OSISAF drifters, dot - nextsim, circle - OSISAF');
%         subplot(122); plot(SX1,SY1,'.k',MX1,MY1,'or'); title('polar stereographic projection');
%         %
%         figure(3) % compare of ice concentration between two dates
%         subplot(121)
%         scatter(SX0,SY0,[],sic(id_icon),'filled');colorbar     
%         m_grid('xtick',12,'tickdir','out','ytick',[70 80],'linest','-');   
%         m_coast('patch',[.7 .7 .7],'edgecolor','k');
%         title('first day, ice concentration')
%         subplot(122)
%         scatter(SX1,SY1,[],sic(id_icon),'filled');colorbar     
%         m_grid('xtick',12,'tickdir','out','ytick',[70 80],'linest','-');   
%         m_coast('patch',[.7 .7 .7],'edgecolor','k');
%         title('2 dates later, ice concentration')
%         pause
    end  
end

%% load OSISAF_data 
function [lat,lon,lat1,lon1] = fun_OSISAF_ice_drift(mnt_dir,DATE)
    YEAR  = datestr(DATE,10);
    MONTH = datestr(DATE,5);
    DATE1 = strrep(datestr(DATE  ,26),'/','');
    DATE2 = strrep(datestr(DATE+2,26),'/','');
%     2008 file has a prefix "ice-drift_"
    filename = [ mnt_dir '/' YEAR '/' MONTH '/' ...
                 'ice_drift_nh_polstere-625_multi-oi_' DATE1 '1200-' DATE2 '1200.nc'];
%   this if-statement is for the last day of a month           
    if ~exist(filename)
        MONTH = num2str(str2num(MONTH)+1);
        if str2num(MONTH)<10
            MONTH = ['0' MONTH];
        end
        filename = [ mnt_dir '/' YEAR '/' MONTH '/' ...
                 'ice-drift_ice_drift_nh_polstere-625_multi-oi_' DATE1 '1200-' DATE2 '1200.nc'];
    end      
    if ~exist(filename)
        filename
        disp('file is inexistent, command mnt_osisaf in terminal to mount the data folder')
        pause
    end
    lat = ncread(filename,'lat');         
    lon = ncread(filename,'lon');
    lat1 = ncread(filename,'lat1');         
    lon1 = ncread(filename,'lon1');
%     status_flag = ncread(filename,'status_flag');
% flag_values   = [0   1   2   3   4  10  11  12  13  20  21  22  30]
% flag_meanings = 'missing_input_data over_land no_ice close_to_coast_or_edge summer_period processing_failed too_low_correlation not_enough_neighbours filtered_by_neighbours smaller_pattern corrected_by_neighbours interpolated nominal_quality'    
end

%%
function [Sid,Mid] = fun_set_index(Slon0,Slat0,Slon1,Slat1,Mlon0,Mlat0,Mlon1,Mlat1)
% match simulated and observational meshes, record indices of ice covered grid points of both meshes.
% if tracked drifter is in open water at stop positions from OSISAF-observation grid
% delete points from simulated meshes
Sid = [];
Mid = [];
n = 0;
for iS = 1:length(Slon0)
    [error,iM] = min((Slon0(iS)-Mlon0).^2 + (Slat0(iS)-Mlat0).^2);    
    % delete an extreme point (180,90) and no-observation points from computational grid        
    if isnan(Mlon1(iM)) || isnan(Mlat1(iM)) || isnan(Slon1(iS)) || isnan(Slat1(iS)) || ...  % nan data
       (Slon0(iS)==180 && Slat0(iS)==90)                                                          % concentration       
    else
        n = n + 1;
        Sid(n) = iS; % index =0 ice cover, nan - open water based on observational grid
        Mid(n) = iM; % indices of observational grid to match computational grid
    end    
end
end

% %% example, sketch map of simulated drift at a given date
% function fun_demonstrate_nextsim_maker_position(ie,dates)
%     i = 1;filename='overlap_grids.gif';
%     DATE = dates(1);
%     while DATE<=dates(end)
%      %load OSISAF_data, indicated by M as first letter
%         [Mlat,Mlon,Mlat1,Mlon1] = fun_OSISAF_ice_drift(mnt_dir,DATE); % time format 2010-09-23:1200-2010-09-25:1200
%         Mlat = reshape(Mlat,1,[]); % same index order as reshape(Mlat,[],1);
%         Mlon = reshape(Mlon,1,[]);
%         plot(Mlon,Mlat,'.r'); hold on 
%         
%     % load nextsim dir  
%         TEMP = strrep(datestr(DATE,26),'/',''); % Find and replace substring,newStr = strrep(str,old,new)     
%         readin_file = ['./neXtSIM_test04_04/ENS' num2str(ie,'%02d') '/OSISAF_' TEMP '.nc'];  
% %          ncdisp(readin_file);  
%         Time= ncread(readin_file,'time');         % 2010-09-25:1200-2010-09-27:1200
%         [datestr(double(Time(1))+ datenum(1900,1,1),21) ' - ' datestr(double(Time(2))+ datenum(1900,1,1),21)]
%         Slon = ncread(readin_file,'longitude');
%         Slat = ncread(readin_file,'latitude');
%         Ssic = ncread(readin_file,'sic');
%         Sindex = ncread(readin_file,'index');
%      
%      % start positions of nextsim
%         Slon0 = squeeze(Slon(1,:,1));
%         Slat0 = squeeze(Slat(1,:,1));
%         index = squeeze(Sindex(1,:,1));
% %         plot(Slon0,Slat0,'.k');hold on
% 
%      % stop positions of nextsim
%         Slon1 = squeeze(Slon(1,:,2));
%         Slat1 = squeeze(Slat(1,:,2));
%         index = squeeze(Sindex(1,:,2));
%         plot(Slon1,Slat1,'.');hold on
%         
% %         plot(Mlon(index),Mlat(index),'or');  
%         xlabel('longitude');ylabel('latitude');
%         title(datestr(double(Time(1))+ datenum(1900,1,1),21))
%         set(findall(gcf,'-property','FontSize'),'FontSize',16); 
%         
%         % animation
%         f = getframe(gcf);
%         im=frame2im(f);
%         [I,map] = rgb2ind(im,256);
%         if i==1  
%             imwrite(I,map,filename,'gif','loopcount',inf,'Delaytime',.5)
%         else
%             imwrite(I,map,filename,'gif','writemode','append','Delaytime',.5)
%         end  
% 
%       % loop increment
%         i = i+1;
%         DATE = DATE + 1;  % update file ID 
%     end
%     title('1-Oct, to 26-Nov-2010. Circle - starting positions, Dot- ending positions after two dates,square - OSISAF map')
% end