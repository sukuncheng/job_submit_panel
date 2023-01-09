#!/bin/bash
# operate to download era5 data and organize data
# NB! be sure the variable dimension is consistent with that defined in nextsim/model/dataset.cpp. 
# In ensemble case, dimension: number must be removed by cdo --reduce_dim --copy
# NB! getERA5_ensemble.py is customized by sea ice modeling group, which could be more convinent. 
#     Or one can use the api provided by https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=form
#     an example is getERA5_ensemble_api.py, just change the download.nc and split the file by variables
# pip install cdsapi cdo

# options 'ensemble_mean', 'ensemble_members', 'ensemble_spread', 'reanalysis',
# cd /cluster/work/users/chengsukun/ERA5_ensemble/data_ensemble
# python getERA5_ensemble.py 2019 2020 ensemble_members

#
cd /cluster/work/users/chengsukun/ERA5_ensemble/data_ensemble
strings='msdwswrf d2m msdwlwrf msl msr mtpr t2m u10 v10'
years='2019 2020'
for year in $years;do
    for var in $strings;do
        infile="ERA5_${var}_y${year}.nc"
        outfile="ERA5_${var}_y${year}_"
        cdo splitlevel $infile $outfile
        
        for i in {1..10};do
            [ ! -d ens${i} ] && mkdir ens${i}
            cdo --reduce_dim -copy "${outfile}00000$(($i-1)).nc" ens${i}/${infile}   # <<< NB
        done
    done
done
# 
# cd ~/src/nextsim
# git checkout IOPerturbation-fram-compile
# make fresh -j16
