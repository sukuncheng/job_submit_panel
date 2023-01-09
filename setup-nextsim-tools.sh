#!/bin/bash

## download nextsim
# git clone https://github.com/nansencenter/nextsim.git
# download nextsim-env
cd ~/src
git clone https://github.com/nansencenter/nextsim-env.git
## Install neXtSIM-tool environment
## wgethttps://github.com/nansencenter/nextsim-env/raw/master/docker/environment.yml     # address invalid
rollback to commit af72e591085ff81a6fa68003128d832c0e134881  for neXtSIMDA-plotting


# geodataset has many files ~18000, thus, install it to work path
# # install geodataset, 
# ml load Anaconda3/2020.11
# conda update -n base -c defaults conda
# cd /cluster/work/users/chengsukun
# git clone https://github.com/nansencenter/geodataset.git
# cd  /cluster/work/users/chengsukun/geodataset
# conda env create -f environment.yml -n geodataset
# ln -sf /cluster/work/users/chengsukun/geodataset ~/src/geodataset
# export PYTHONPATH=$PYTHONPATH:/cluster/home/chengsukun/src/geodataset
# conda activate geodataset

# steup nextsim-tools for neXtSIM-plotting to plot ensemble runs
# https://github.com/nansencenter/nextsim-tools 
module --force purge
ml load StdEnv
ml load Anaconda3/2020.11
conda update conda #The current user does not have write permissions to the target environment.
# rm -rf .conda
cp ~/src/nextsim-env/docker/environment.yml ~/src/job_submit_panel/ice_environment.yml
conda env create  -f ~/src/job_submit_panel/ice_environment.yml -p /cluster/work/users/chengsukun/conda # install to specified path
conda activate /cluster/work/users/chengsukun/conda
Or
conda env create  -f ~/src/job_submit_panel/ice_environment.yml # install to default path
conda activate ice
pip install geodataset
export NEXTSIMDIR=$HOME/src/nextsim
export NEXTSIMTOOLS_ROOT_DIR=$HOME/src/nextsim-tools
export MAPXDIR=$HOME/src/nextsim/contrib/mapx
export BAMGDIR=$HOME/src/nextsim/contrib/bamg
export PATH=$PATH:$NEXTSIMTOOLS_ROOT_DIR/python/pynextsim/scripts
export PYTHONPATH=$PYTHONPATH:$NEXTSIMTOOLS_ROOT_DIR/python
export PYTHONPATH=$PYTHONPATH:$NEXTSIMTOOLS_ROOT_DIR/python/swarp_funs
# set environment variables
# install nextsimf
cd ~/src
git clone https://github.com/nansencenter/nextsimf.git

# get data from nird
# scp chengsukun@fram.sigma2.no://nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun/DASIMII_EnKF-neXtSIM_exps/freerun.tar.gz cluster/work/users/chengsukun/simulations




# Problem and Solution:
# 1. 'NetcdfList' object has no attribute 'file_objects'
Change file_objects to filenames, refer to nextsim-tool/pynextsim/netcdf_list.py
# 2. 'str' object has no attribute 'get_lonlat_arrays'
# In get_ensmean.py, Insert 
# from geodataset.tools import open_netcdf
# 3. use old cs2smos version 2.3: change neXtSIM-plotting/src/get_ensmean.py: class MooringToObsInterp: 
        # if self.args.src=='Cs2SmosThick':
        #     self.opener_obs.append( pnops.OPENER_DICT[self.args.src](version='2.3'))
        # else:
        #     self.opener_obs.append( pnops.OPENER_DICT[self.args.src]())

Change
	lon, lat = self.moorings.filenames[0].get_lonlat_arrays()
To         
    ds = open_netcdf(self.moorings.filenames[0]) 
    lon, lat = ds.get_lonlat_arrays()
#
Change 
    nci_obs = self.obs_file_list.filenames[0]
To 
    nci_obs = open_netcdf(self.obs_file_list.filenames[0])

# a bug in conda 3.10, error
PackagesNotFoundError: The following packages are not available from current channels:
  - python=3.1
  
conda install python=3.9


function filenumbers {	#
	for d in `pwd`/{*,.*}/ ; do
		[[ $d == *'/../'* ]] &&	continue
		echo $d
		find $d/* -type f | wc -l
	done
}


pyenv
/cluster/home/chengsukun/py/bin/python -m pip install --upgrade pip
pip install scipy
