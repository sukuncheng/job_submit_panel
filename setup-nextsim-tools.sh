#!/bin/bash
# steup nextsim-tools for neXtSIM-plotting to plot ensemble runs
## download nextsim
# git clone https://github.com/nansencenter/nextsim.git
# download nextsim-env
cd ~/src
git clone https://github.com/nansencenter/nextsim-env.git
## Install neXtSIM-tool environment
## wget https://github.com/nansencenter/nextsim-env/master/docker/environment.yml    # address invalid
# rm -rf .conda
conda env create -f ~/src/nextsim-env/docker/environment.yml -p /cluster/work/users/chengsukun/conda
conda activate /cluster/work/users/chengsukun/conda

# install nextsimf
cd ~/src
git clone https://github.com/nansencenter/nextsimf.git

# # install geodataset, https://github.com/nansencenter/geodataset
# conda env create -f environment.yml
# conda activate geodataset
# pip install geodataset

# get data from nird
# scp chengsukun@fram.sigma2.no://nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun/DASIMII_EnKF-neXtSIM_exps/freerun.tar.gz cluster/work/users/chengsukun/simulations




# Problem and Solution:
# 1. 'NetcdfList' object has no attribute 'file_objects'
# Change file_objects to filenames, refer to nextsim-tool/pynextsim/netcdf_list.py
# 2. 'str' object has no attribute 'get_lonlat_arrays'
# In get_ensmean.py, 
# Insert 
# from geodataset.tools import open_netcdf
# 3. use old cs2smos version 2.3: change neXtSIM-plotting/src/get_ensmean.py: class MooringToObsInterp: 
        # if self.args.src=='Cs2SmosThick':
        #     self.opener_obs.append( pnops.OPENER_DICT[self.args.src](version='2.3'))
        # else:
        #     self.opener_obs.append( pnops.OPENER_DICT[self.args.src]())

# Change
# 	lon, lat = self.moorings.filenames[0].get_lonlat_arrays()
# To         
#     ds = open_netcdf(self.moorings.filenames[0]) 
#     lon, lat = ds.get_lonlat_arrays()

# Change 
#     nci_obs = self.obs_file_list.filenames[0]
# To 
#     nci_obs = open_netcdf(self.obs_file_list.filenames[0])
