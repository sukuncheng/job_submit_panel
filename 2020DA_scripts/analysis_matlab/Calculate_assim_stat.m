%Script for calculatin statistic at assimilation time
%Launch the script from your RESULTS folder 
%/work/user/noresm/RESULTS/
clear all
idm=320;
jdm=384;
RMSE_all=zeros(idm,jdm);
BIAS_all=zeros(idm,jdm);
BIAS_obs_all=zeros(idm,jdm);
SPREAD_all=zeros(idm,jdm);
SPREAD_OBS_all=zeros(idm,jdm);
yr_start=1950;
yr_end=2018;
parea=ncgetvar('grid.nc','parea');
rec=0;
for yr=yr_start:yr_end
   yr
   for mm=1:12
      if exist([num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'], 'file') == 2
       ipiv=ncgetvar([num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'ipiv');
       jpiv=ncgetvar([num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'jpiv');
       inov=ncgetvar([num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'innovation');
       d=ncgetvar([num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'d');
%       depth = ncgetvar([num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'depth');
       obs_var=ncgetvar([num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'var');
       mod_var=ncgetvar([num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'forecast_variance');
       rec=rec+1;
       area = zeros(size(d));
       for k=1:length(inov)
	       area(k) = parea(ipiv(k),jpiv(k)); 
       end
       time_RMSE(rec)=sqrt(nansum(inov(:).^2.*area)/sum(area));
       time_bias(rec)=-nansum(inov(:).*area)/sum(area);
       time_spread(rec)=nansum(sqrt(mod_var(:)).*area(:))/sum(area);
       time_obs(rec)=nansum(sqrt(obs_var(:)).*area(:))/sum(area);
%       time_obs(rec) = nanmean(d(:));
%       time_mod(rec) = nanmean(mod_var(:));
       time_accu(rec)=nansum(sqrt(obs_var(:).*mod_var(:)./(obs_var(:)+mod_var(:))).*area(:))/sum(area);
       date_timeserie(rec)=datenum(yr,mm,15);

%       % free run
%       ipiv=ncgetvar(['../RESULT_freerun/' num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'ipiv');
%       jpiv=ncgetvar(['../RESULT_freerun/' num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'jpiv');
%       inov=ncgetvar(['../RESULT_freerun/' num2str(yr) '_' num2str(mm,'%2.2d') '/observations-SST.nc'],'innovation');
%       area = zeros(size(inov));
%       for k=1:length(inov)
%          area(k) = parea(ipiv(k),jpiv(k));
%       end
%       time_RMSE_free(rec)=sqrt(nansum(inov(:).^2.*area)/sum(area));
    end
   end
end
%%%%%%%%%%%%%
close all
figure(1)
axes('position',[.1  .1  .8  .4])
hold on
%set(gca,'fontsize',12,'fontweight','bold');
h(1)=plot(date_timeserie,time_bias,'r--','linewidth',1);
h(2)=plot(date_timeserie,time_spread,'b-','linewidth',1);
h(3)=plot(date_timeserie,time_obs,'g-','linewidth',1);
h(4)=plot(date_timeserie,time_RMSE,'r','linewidth',1);
h(5)=plot(date_timeserie,sqrt(time_obs.^2+time_spread.^2),'m--','linewidth',1);
%h(6)=plot(date_timeserie,time_accu,'k','linewidth',2);
plot(date_timeserie,zeros(length(date_timeserie),1),'k-');
%legend(h(1:6),{'innov','spread','obs-std','RMSE','spread+obs-std','RMSE-hist'}, 'NumColumns',3,'Location','best');
legend(h(1:5),{'$\bar{d}$','$\bar{\sigma^f}$','$\bar{\sigma^o}$','$\hat{d}$','$\bar{\sigma^t}$'}, 'Interpreter','latex', 'NumColumns',5,'Location','best','fontsize',16);
axis([date_timeserie(1) date_timeserie(end) min(time_bias) max([time_RMSE sqrt(time_obs.^2+time_spread.^2)]) ])
%axis([date_timeserie(1) datenum(2010,12,15) min(time_bias) max([time_RMSE sqrt(time_obs.^2+time_spread.^2)]) ])
%xlim([date_timeserie(1), datenum(2010,12,15)]);
datetick
ylabel('SST (K)')
%ylim([-0.2 2]);
%ylabel('Salinity (psu)')
ylim([-0.2 0.91])
%title('SST','fontsize',16)
print('-depsc2',['Assim_stat_summary-SST.eps']);
%%%%%%%%%%%%%%%
%figure(2)
%a=sqrt(RMSE_all/rec);
%micom_flat(a,[0.45 0.45 0.45])
%m_grid
%title(['Mean RMSE minval: ' num2str(min(a(:))) '  maxval ' num2str(max(a(:)))])
%colorbar;
%colormap(fc100);
%caxis([0 1.5])
%print('-djpeg95',['Spatial_RMSE.jpg']);
%%%%%%%%%%%%%%
%%figure(3)
%%a=(BIAS_all./rec);
%%micom_flat(a,[0.45 0.45 0.45])
%%m_grid
%colorbar;
%colormap(anomwide);
%title(['Mean bias minval: ' num2str(min(a(:))) '  maxval ' num2str(max(a(:)))])
%caxis([-.5 .5])
%print('-djpeg95',['Spatial_Bias.jpg']);
%%%%%%%%%%%%%%
%%figure(4)
%%a=(BIAS_obs_all./rec);
%%micom_flat(a,[0.45 0.45 0.45])
%%m_grid
%%colorbar;
%%colormap(anomwide);
%%title(['Mean bias minval: ' num2str(min(a(:))) '  maxval ' num2str(max(a(:)))])
%%caxis([-.5 .5])
%%print('-djpeg95',['Mean_Bias_obs-80-85.jpg']);
%
%%%%%%%%%%%%%%%
%figure(5)
%a=sqrt(SPREAD_all./rec);
%micom_flat(a,[0.45 0.45 0.45])
%m_grid
%colorbar;
%colormap(fc100);
%title(['Mean mod spread minval: ' num2str(min(a(:))) '  maxval ' num2str(max(a(:)))])
%caxis([0 1])
%print('-djpeg95',['Mean_spread.jpg']);
%%%%%%%%%%%%%%%
%figure(6)
%a=sqrt(SPREAD_OBS_all./rec);
%micom_flat(a,[0.45 0.45 0.45])
%m_grid
%colorbar;
%colormap(fc100);
%title(['Mean obs spread minval: ' num2str(min(a(:))) '  maxval ' num2str(max(a(:)))])
%caxis([0 1])
%print('-djpeg95',['Mean_obs-spread.jpg']);
%%%%%%%%%%%%%%%%%%
