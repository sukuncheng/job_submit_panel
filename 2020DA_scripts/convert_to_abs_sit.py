import xarray as xr
import sys
import os

# filename = sys.argv[1]
dir1 = '/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40_offline_perturbations/date1/filter/prior_effective_sit/'
dir2 = '/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40_offline_perturbations/date1/filter/prior/'
os.system('rm -rf ' +dir2)
os.system('mkdir ' +dir2)
for j in range(1,41):
    filename = 'mem' +'{}'.format(str(j).zfill(3))+'.nc'
    print(filename)
    f = xr.open_dataset(dir1+filename)
    f['sit'] = f['sit']/(f['sic'] + 1.e-12)
    f.to_netcdf(dir2+filename)
    f.close()