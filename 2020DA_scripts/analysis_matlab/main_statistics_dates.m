clc
clear
close all


% the values are outputs from calc.out
% NumberofObs.  [for.inn.]  [an.inn.]   for.inn.   an.inn.  for.spread    an.spread
x = [    3327       0.405      0.312     -0.042     -0.021      0.071      0.039  
         3865       0.372      0.286     -0.006      0.018      0.065      0.036  
         4274       0.397      0.311      0.025      0.057      0.071      0.037  
         4555       0.355      0.270     -0.023      0.015      0.081      0.038  
         4777       0.367      0.276     -0.045      0.001      0.085      0.042  
         4997       0.365      0.285     -0.028      0.012      0.087      0.041  
         5370       0.396      0.314     -0.040      0.014      0.088      0.045  
         5651       0.442      0.352     -0.065      0.005      0.092      0.049  
         5749       0.452      0.367     -0.066      0.013      0.091      0.050  
         5869       0.471      0.385     -0.061      0.011      0.093      0.051  
         5909       0.488      0.410     -0.039      0.026      0.098      0.050  
         5937       0.519      0.444     -0.031      0.032      0.092      0.049   ];
             
load('test_inform.mat')
%% spread
subplot(211)
plot(dates,x(:,6),'-o','linewidth',1.5)
hold on
plot(dates,x(:,7),'-o','linewidth',1.5)
ylabel('spread of SIT (m)')
xlim([dates(1) dates(end)])
ylim([ 0 0.1]);
legend('background','analysis','location','best')
ax = gca;
ax.XAxis.TickValues = dates';
ax.XAxis.TickLabelFormat = 'dd-MMM-yy';
%
subplot(212)
% innovation
plot(dates,x(:,4),'-o','linewidth',1.5)
hold on;
plot(dates,x(:,5),'-o','linewidth',1.5)
% rmsd
plot(dates,x(:,2),'-o','linewidth',1.5)
plot(dates,x(:,3),'-o','linewidth',1.5)
% ylim([0.0 0.2]);
plot(dates,x(:,5)*0,'--','color','k','linewidth',1.5)
xlim([dates(1) dates(end)])
ylabel('innovation of SIT (m)')
ax = gca;
ax.XAxis.TickValues = dates';
ax.XAxis.TickLabelFormat = 'dd-MMM-yy';
legend('background','analysis','RMSD of background','RMSD of analysis','location','best')

set(findall(gcf,'-property','FontSize'),'FontSize',18); 
set (gcf,'Position',[100,200,1400,550], 'color','w')
%    
saveas(gcf,'spread_dates.png')    