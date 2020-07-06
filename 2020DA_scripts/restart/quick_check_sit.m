
file = 'prior/mem001.nc.analysis';
v2   = ncread(file, 'sit');
v2(isnan(v2)) = 0;
unique(v2)