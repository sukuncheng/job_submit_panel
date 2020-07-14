function [] = create_plots()
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);
    dates = ['2018-11-11'; '2018-11-17'; '2018-11-23'; '2018-11-29'];
    dir = pwd;
    for it = 1:size(dates,1)
        cd([dir '/' dates(it,:) '/filter']);
    % enkf-prep outputs    
        fun_plot_observation(); 

    % enkf-update outputs
        fun_geomap_spread('sit');
        fun_geomap_spread('sic');
        
        % compare forecast, increment and analysis results
        fun_geomap_field('sit'); 
        fun_geomap_field('sic'); 
    end
end

%%
function fun_geomap_spread(Var)
% part 1. get longitude and latitudes from reference grid
    gridfile = 'reference_grid.nc';
    lon = ncread(gridfile,'plon');
    lat = ncread(gridfile,'plat');

% part 2. get sit from spread.nc
    file = 'spread.nc';
    v1 = ncread(file, Var);
    v1(v1<0) = nan;
    v2 = ncread(file, [Var '_an']);    
% part 3. plot
    h_fig = figure(); 
    set(h_fig,'Position',[100,200,900,300], 'color','w');    
    upper = max(max(max(v1)), max(max(v2)));
    subplot(121); func_arctic_map(lon, lat, v1);  title(['forecast ensemble spread - ' Var]); caxis([0 upper]);
    subplot(122); func_arctic_map(lon, lat, v2);  title(['analysis ensemble spread - ' Var]); caxis([0 upper]);
    colormap(jet);
%   
    saveas(h_fig,['spread_' Var '.png'],'png');
end

%
function fun_geomap_field(Var)
% load grid coordinates
    gridfile = 'reference_grid.nc';
    lon = ncread(gridfile,'plon');
    lat = ncread(gridfile,'plat');

    Ne = 20; % dir(fullfile('./prior/*.nc'));
    disp([num2str(Ne) ' are processed in enkf'])
    for ie = 1:Ne
    % load variables
        memid = ['mem' num2str(ie,'%03d') ];
        file = ['prior/' memid '.nc'];
        lon1 = ncread(file, 'longitude');
        lat1 = ncread(file, 'latitude');
        v1  = ncread(file, Var);
        v1  = squeeze(v1(:,:,1));
        file = ['prior/' memid '.nc.analysis'];
        v2   = ncread(file, Var);
    % plot   forecast_analysis
        h_fig = figure(); 
        set(h_fig,'Position',[100,200,900,300], 'color','w');
        
        if (strcmp(Var,'sic'))
            upper = 1;
            lower =0.85;
        else 
            upper = max(max(max(v1)), max(max(v2)));
            lower = 0;
        end
        subplot(121); func_arctic_map(lon, lat, v1); title(['forecast - ' Var]);   caxis([lower upper]);
        subplot(122); func_arctic_map(lon, lat, v2); title(['analysis - ' Var]);   caxis([lower upper]);
        saveas(gcf,['field_' Var '_' memid '.png'],'png');    
    % plot increments
        h_fig = figure(); 
        inc = v2 - v1;
        inc(inc==0) = nan;
        upper = max(max(max(v1)), max(max(v2)));
        func_arctic_map(lon, lat, inc); title(['increment - ' Var]); caxis([-upper upper]);
        colormap(bluewhitered);
        saveas(gcf,['Increment_' Var '_' memid '.png'],'png');    
    end
end
%  -----------------
function func_arctic_map(lon, lat, var)
    m_pcolor(lon, lat, var); shading flat; 
    h = colorbar;
    title(h, '(m)');
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
end
%  -----------------
function fun_plot_observation(Var)
    h_fig = figure();
    file = 'observations.nc';    
    %ncdisp(file);
    lon = ncread(file,'lon');
    lat = ncread(file,'lat');
    Z = ncread(file,'value');
    Z(Z<0) = nan;
%     
    m_scatter(lon,lat,10,Z,'o','filled'); 
    hold on;
    m_coast('patch',0.7*[1 1 1]);
    m_grid('color','k');
    colormap(jet);
    h = colorbar;
    title(h, '(m)');
    saveas(h_fig,'observations.png','png');
end

%
function newmap = bluewhitered(m)
    %BLUEWHITERED   Blue, white, and red color map.
    %   BLUEWHITERED(M) returns an M-by-3 matrix containing a blue to white
    %   to red colormap, with white corresponding to the CAXIS value closest
    %   to zero.  This colormap is most useful for images and surface plots
    %   with positive and negative values.  BLUEWHITERED, by itself, is the
    %   same length as the current colormap.
    %
    %   Examples:
    %   ------------------------------
    %   figure
    %   imagesc(peaks(250));
    %   colormap(bluewhitered(256)), colorbar
    %
    %   figure
    %   imagesc(peaks(250), [0 8])
    %   colormap(bluewhitered), colorbar
    %
    %   figure
    %   imagesc(peaks(250), [-6 0])
    %   colormap(bluewhitered), colorbar
    %
    %   figure
    %   surf(peaks)
    %   colormap(bluewhitered)
    %   axis tight
    %
    %   See also HSV, HOT, COOL, BONE, COPPER, PINK, FLAG, 
    %   COLORMAP, RGBPLOT.
    
    
    if nargin < 1
       m = size(get(gcf,'colormap'),1);
    end
    
    
    bottom = [0 0 0.5];
    botmiddle = [0 0.5 1];
    middle = [1 1 1];
    topmiddle = [1 0 0];
    top = [0.5 0 0];
    
    % Find middle
    lims = get(gca, 'CLim');
    
    % Find ratio of negative to positive
    if (lims(1) < 0) & (lims(2) > 0)
        % It has both negative and positive
        % Find ratio of negative to positive
        ratio = abs(lims(1)) / (abs(lims(1)) + lims(2));
        neglen = round(m*ratio);
        poslen = m - neglen;
        
        % Just negative
        new = [bottom; botmiddle; middle];
        len = length(new);
        oldsteps = linspace(0, 1, len);
        newsteps = linspace(0, 1, neglen);
        newmap1 = zeros(neglen, 3);
        
        for i=1:3
            % Interpolate over RGB spaces of colormap
            newmap1(:,i) = min(max(interp1(oldsteps, new(:,i), newsteps)', 0), 1);
        end
        
        % Just positive
        new = [middle; topmiddle; top];
        len = length(new);
        oldsteps = linspace(0, 1, len);
        newsteps = linspace(0, 1, poslen);
        newmap = zeros(poslen, 3);
        
        for i=1:3
            % Interpolate over RGB spaces of colormap
            newmap(:,i) = min(max(interp1(oldsteps, new(:,i), newsteps)', 0), 1);
        end
        
        % And put 'em together
        newmap = [newmap1; newmap];
        
    elseif lims(1) >= 0
        % Just positive
        new = [middle; topmiddle; top];
        len = length(new);
        oldsteps = linspace(0, 1, len);
        newsteps = linspace(0, 1, m);
        newmap = zeros(m, 3);
        
        for i=1:3
            % Interpolate over RGB spaces of colormap
            newmap(:,i) = min(max(interp1(oldsteps, new(:,i), newsteps)', 0), 1);
        end
        
    else
        % Just negative
        new = [bottom; botmiddle; middle];
        len = length(new);
        oldsteps = linspace(0, 1, len);
        newsteps = linspace(0, 1, m);
        newmap = zeros(m, 3);
        
        for i=1:3
            % Interpolate over RGB spaces of colormap
            newmap(:,i) = min(max(interp1(oldsteps, new(:,i), newsteps)', 0), 1);
        end
        
    end
    % 
    % m = 64;
    % new = [bottom; botmiddle; middle; topmiddle; top];
    % % x = 1:m;
    % 
    % oldsteps = linspace(0, 1, 5);
    % newsteps = linspace(0, 1, m);
    % newmap = zeros(m, 3);
    % 
    % for i=1:3
    %     % Interpolate over RGB spaces of colormap
    %     newmap(:,i) = min(max(interp1(oldsteps, new(:,i), newsteps)', 0), 1);
    % end
    % 
    % % set(gcf, 'colormap', newmap), colorbar
end

