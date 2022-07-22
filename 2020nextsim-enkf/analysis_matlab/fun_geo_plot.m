function fun_geo_plot(lon,lat,var,Title,unit)
    m_proj('Stereographic','lon',-45,'lat',90,'radius',90);
    m_pcolor(lon, lat, var); shading flat; 
    h = colorbar;
    title(h, unit);
    m_coast('patch',0.7*[1 1 1]); 
    % m_coast('color','r'); 
    set(gca,'XTickLabel',[],'YTickLabel',[]);
    colormap(bluewhitered);
%     m_grid('color','k');
    title(Title,'fontweight','normal');
end
