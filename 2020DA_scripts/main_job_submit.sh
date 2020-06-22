#!/bin/bash
#set -e
# main job submitting script
# - core.sh includes 1) nextsim, 2) enkf. 
# final results are saved in 
#   ENSPATH/filter/prior/***.nc.analysis  linked in NEXTSIM_DATA_DIR/...
# Directory structure:
# ENSPATH -- mem001
#         -- mem002
#         -- ...
#         -- mem***
#         -- filter (include EnKF package)
#                     -- obs  (link observations from NEXTIM_DATA_DIR)
#                     -- prior 
# changes in nextsim.cfg, pseudo2D.nml are summarized in part1_initialization.sh, seek them by searching sed command
#-------------------------------------------------------------
## common settings in part1 and part2
#---  model paths and alias --------------
# Modifications for Fram  
# 1. comment NEXTSIMDIR path
# 2. cp reference_grid.nc to data/ 
# 3. set RUNPATH to IO_nextsim on fram
# 4. path of CS2SMOS, check ~/src/data
# 5. put nextsim/bin/nextsim.exec in path
# 6. ln -s enkf-c/bin/enkf* to 
# 7. ln -sf /cluster/projects/nn2993k/sim/data/ECMWF_forecast_arctic/* /nextsim/data/ECMWF_forecast_arctic ,  not use INPUT_DATA_DIR includes too many data
#   same for /cluster/projects/nn2993k/sim/data/CS2_SMOS_v2.2, TOPAZ4RC_daily/20181*, 20190* .
# CS2_SMOS_v2.2 is weekly data, and variables are different.
#---------  Confirm working/data/ouput directories ----
    RUNFILE=$(basename $0)               # name of this .sh
    RUNPATH=$(cd `dirname $0`;pwd)       # path of this .sh 
    #save backup to nextsim-env/machines/fram_sukun
    ENVFRAM=/cluster/home/chengsukun/src/fram_job_submit_panel/fram_sukun 
    source $ENVFRAM/nextsim.src
    source $ENVFRAM/nextsim.ensemble.src
    #rm nohup.out
    ENSPATH=$IO_nextsim/test_18_06_ensemble_size    # output path
    #rm -r $ENSPATH    
    #
    OBSNAME_PREFIX=$NEXTSIMDIR/data/CS2_SMOS_v2.1/"CS2SMOS/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_" 
    OBSNAME_SUFFIX="_r_v202_01_l4sit"  

#--------  experiment settings ------------
    time_init=2018-11-11                  # starting date of simulation
    #   tduration*duration is the total simulation time in days
    duration=1    # nextsim duration in a forecast-analysisf cycle, usually CS2SMOS frequency
    tduration=2   # number of forecast-analysis cycle. 
    UPDATE=1      # UPDATE=0 indicates forecast is executed without EnKF
    ESIZE=3       # ensemble size
    #NPROC=4       # cpu cores  
    maximum_instants=10   # max instants (submitted jobs)
    #
    if [ $UPDATE -gt 0 ]; then 
        echo "execute nextsim with EnKF filter!"
    else
        echo "execute nextsim only"
    fi
#-------------------------------------------

# create ensemble directories and files
source $RUNPATH/part1_initialization.sh   
# execute ensemble runs
for (( i=1; i<=${tduration}; i++ )); do
    if [ $i -eq 1 ]; then 
        restart_from_analysis=false
    else 
        restart_from_analysis=true
        time_init=$(date +%Y-%m-%d -d "${time_init} + ${duration} day")        
    fi
    # a forecast-analysis cycle  
    source $RUNPATH/part2_core.sh   
done
