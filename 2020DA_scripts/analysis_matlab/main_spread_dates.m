clc
clear
close all



% NumberofObs.  [for.inn.]  [an.inn.]   for.inn.   an.inn.  for.spread    an.spread
x = [ 2779       0.401      0.327     -0.052     -0.056      0.163      0.080
      3327       0.293      0.249     -0.011     -0.014      0.128      0.061  
      3866       0.272      0.230      0.033      0.027      0.133      0.058  
      4274       0.302      0.253      0.061      0.058      0.135      0.058  
      4555       0.297      0.243      0.000      0.007      0.132      0.058  
      4777       0.341      0.272     -0.003      0.010      0.155      0.065  
      4997       0.324      0.258      0.012      0.019      0.159      0.070  
      5370       0.336      0.265     -0.009      0.012      0.165      0.070   ];
Duration = 7;
for i = 1:size(x,1)
    dates(i) = datetime(2019,10,8+i*Duration);
end
% spread
subplot(121)
plot(dates,x(:,6),'-o','linewidth',1.5)
hold on
plot(dates,x(:,7),'-o','linewidth',1.5)
ylabel('spread of SIT (m)')
legend('forecast spread','analysis spread','location','best')
subplot(122)
% innovation
plot(dates,x(:,4),'-o','linewidth',1.5)
hold on;
plot(dates,x(:,5),'-o','linewidth',1.5)
% rmsd
plot(dates,x(:,2),'-o','linewidth',1.5)
plot(dates,x(:,3),'-o','linewidth',1.5)
% ylim([0.0 0.2]);
ylabel('innovation of SIT (m)')
legend('forecast innovation','analysis innovation','RMSD of forecast innovation','RMSD of analysis innovation','location','best')
set(findall(gcf,'-property','FontSize'),'FontSize',18); 
set (gcf,'Position',[100,200,1100,450], 'color','w')
%    
saveas(gcf,'spread_dates.png')    