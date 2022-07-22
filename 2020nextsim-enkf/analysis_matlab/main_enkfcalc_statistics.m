clc
clear
close all

% get x from calc_result.md by running ~/src/fram_job_submit_panel/2020DA_scripts/collect_statistics_dates.sh
% the values are outputs from calc.out
% NumberofObs.  [for.inn.]  [an.inn.]   for.inn.   an.inn.  for.spread    an.spread
x = [    
    8567    0.376      0.272    -0.0671    -0.0289     0.0839     0.0683  
    10005    0.315      0.238   -0.00781     0.0159     0.0712     0.0576  
    10543    0.348      0.256    0.00174     0.0392     0.0817     0.0632  
    11056    0.301      0.206    -0.0504    -0.0214     0.0904     0.0694  
    11488     0.29      0.191    -0.0535    -0.0232     0.0972     0.0738  
    11686     0.25      0.169    -0.0682    -0.0296      0.103     0.0788  
    11815    0.279      0.185     -0.113    -0.0528      0.103     0.0804  
    12027    0.318      0.201     -0.184    -0.0902      0.105     0.0819  
    12220    0.309      0.209     -0.188     -0.101        0.1     0.0784  
    12298    0.329      0.239      -0.18      -0.11      0.102     0.0798  
    12352    0.327      0.235     -0.181     -0.115      0.112      0.087  
    12213    0.332      0.252     -0.189     -0.134      0.101     0.0805  
 ];
             
load('test_inform.mat')
Xdata = dates(1:Duration:end);
subplot(211)
plot(Xdata,x(:,6),'-o','linewidth',1.5)
hold on
plot(Xdata,x(:,7),'-o','linewidth',1.5)
ylabel('spread of SIT (m)')
xlim([Xdata(1) Xdata(end)])
% ylim([ 0 0.2]);
legend('background','analysis','location','best')
ax = gca;
ax.XAxis.TickValues = Xdata';
ax.XAxis.TickLabelFormat = 'dd-MMM-yy';
%
subplot(212)
% innovation
plot(Xdata,x(:,4),'-o','linewidth',1.5)
hold on;
plot(Xdata,x(:,5),'-o','linewidth',1.5)
% rmsd
plot(Xdata,x(:,2),'-o','linewidth',1.5)
plot(Xdata,x(:,3),'-o','linewidth',1.5)
ylim([-0.3 0.7]);
plot(Xdata,x(:,5)*0,'--','color','k','linewidth',1.5)
xlim([Xdata(1) Xdata(end)])
ylabel('innovation of SIT (m)')
ax = gca;
ax.XAxis.TickValues = Xdata';
ax.XAxis.TickLabelFormat = 'dd-MMM-yy';
legend('background','analysis','RMSD of background','RMSD of analysis','location','best')

set(findall(gcf,'-property','FontSize'),'FontSize',18); 
set (gcf,'Position',[100,200,1400,550], 'color','w')
%    
saveas(gcf,'enkfcalc_statistics.png')    