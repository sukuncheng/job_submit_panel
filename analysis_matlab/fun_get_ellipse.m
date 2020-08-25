
function ellipse = fun_get_ellipse(GMModel,data,colors)    
% https://www.visiondummy.com/2014/04/draw-error-ellipse-representing-covariance-matrix/    
    XY_mean = GMModel.mu;
    covariance = GMModel.Sigma;        
    [eigenvec, eigenval] = eig(covariance);
    % Get the confidence interval error, P(s<4.605,5.991,9.21)=0.9,0.95,0.99
    % where, s is in the equation (x/a)^2+(y/b)^2=s, a,b are std - eigenval
    % of covariance matrix        
    ellipse.error = 0.99; % set the confidence interval error for ellipse size
    chisquare_val = sqrt(9.21);      

    % Get the index of the largest eigenvector
    [largest_eigenvec_ind_c, r] = find(eigenval == max(max(eigenval)));
    largest_eigenvec = eigenvec(:, largest_eigenvec_ind_c);

    % Get the largest eigenvalue
    largest_eigenval = max(max(eigenval));

    % Get the smallest eigenvector and eigenvalue
    if(largest_eigenvec_ind_c == 1)
        smallest_eigenval = max(eigenval(:,2));
        smallest_eigenvec = eigenvec(:,2);
    else
        smallest_eigenval = max(eigenval(:,1));
        smallest_eigenvec = eigenvec(1,:);
    end

    % Calculate the angle between the x-axis and the largest eigenvector
    angle = atan2(largest_eigenvec(2), largest_eigenvec(1));

    % This angle is between -pi and pi.
    % Let's shift it such that the angle is between 0 and 2pi
    if(angle < 0)
        angle = angle + 2*pi;
    end

    % Get the coordinates of the data mean
    theta_grid = linspace(0,2*pi,50);
    phi = angle;

    a=chisquare_val*sqrt(largest_eigenval);
    b=chisquare_val*sqrt(smallest_eigenval);
    
    % save returns
    ellipse.area = pi*a*b;
    ellipse.axis = [a b];  
    ellipse.anisotropy = a/b;% the length of the axes are defined by the standard deviations \sigma_x and \sigma_y of the data 
    % the ellipse in x and y coordinates 
    ellipse_x_r  = a*cos( theta_grid );
    ellipse_y_r  = b*sin( theta_grid );

    %Define a rotation matrix
    R = [ cos(phi) sin(phi); -sin(phi) cos(phi) ];

    %let's rotate the ellipse to some angle phi
    r_ellipse = [ellipse_x_r;ellipse_y_r]' * R;
    ellipse.XY = r_ellipse + XY_mean;       
%% Draw the error ellipse    
    if nargin > 1
        % Plot the original data
        plot(data(:,1), data(:,2), '.','color',colors,'markersize',8);          
        hold on
        if ~isempty(ellipse)
            % set color
            if nargin==2
                colors = [rand rand rand];
            end
            plot(ellipse.XY(:,1),ellipse.XY(:,2),'-','color',colors, 'linewidth',2)
            hold on;
            
            % Plot the eigenvectors
            quiver(X0, Y0,  largest_eigenvec(1)*sqrt(largest_eigenval),   largest_eigenvec(2)*sqrt(largest_eigenval), '-','color',colors, 'linewidth',2);
            quiver(X0, Y0, smallest_eigenvec(1)*sqrt(smallest_eigenval), smallest_eigenvec(2)*sqrt(smallest_eigenval),'-','color',colors, 'linewidth',2);
        end
        % Set the axis labels
        axis equal
    end
end