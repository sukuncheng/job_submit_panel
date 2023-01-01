% exmaple  fun_geo_pcolor_scatter(lon,lat,y-Hx_a,[DA_var 'analysis innovation: y - Hx_a'],unit);
function fun_geo_pcolor(lon,lat,Var,Title, unit)
    Var(Var==0) = nan;
    m_proj('Stereographic','lon',-45,'lat',90,'radius',20);
    m_pcolor(lon, lat, Var); shading flat;  
    m_coast('patch',0.7*[1 1 1]);    
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    title({Title,''},'fontweight','normal')
    m_grid('linest',':');
    h = colorbar;%('southoutside');
    title(h, unit);

    colormap(gca,bluewhitered);
end
%

% function fun_geo_pcolor_scatter(lon,lat,Var,Title, unit)
%     Var(Var==0) = nan;
%     m_proj('Stereographic','lon',-45,'lat',90,'radius',20);
%     m_scatter(lon, lat, 12, Var,'.'); shading flat; 
%     h = colorbar('southoutside');
%     title(h, unit);
%     m_coast('patch',0.7*[1 1 1]);    
%     set(gca,'XTickLabel',[],'YTickLabel',[]);
%     title({Title,''})
%     m_grid('linest',':');
% end
