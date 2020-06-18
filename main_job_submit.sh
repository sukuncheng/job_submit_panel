#!/bin/bash
#set -e
# main job submitting script
# - core.sh includes 1) nextsim, 2) enkf. They call docker individually
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
    echo "Confirm working/data/ouput directories"
    NEXTSIMDIR=/home/cheng/Desktop/nextsim  
    NEXTSIM_DATA_DIR=/home/cheng/Desktop/data #/media/cheng/_cheng/data
    NEXTSIM_MESH_DIR=/home/cheng/Desktop/mesh #/media/cheng/_cheng/mesh    
    REFGRID=${NEXTSIM_DATA_DIR}/reference_grid.nc  # enkf reference grid
    RUNPATH=$(cd `dirname $0`;pwd)  # path of this .sh 
    RUNFILE=$(basename $0)          # name of this .sh
    
#--------  experiment settings ------------
    ENSPATH=$RUNPATH/one_step_nextsim_enkf    # output directory
    time_init=2018-11-11                  # starting date of simulation
    #   tduration*duration is the total simulation time in days
    duration=1   # nextsim duration in a forecast-analysisf cycle, which is usually CS2SMOS frequency
    tduration=1   # number of nextsim-enkf (forecast-analysis) cycle. 
    UPDATE=1      # UPDATE=0 indicates forecast is executed without EnKF
    ESIZE=2      # ensemble size
    NPROC=6       # cpu cores   
    # prefix & suffix of observation data, also modify SMOSOBS in part2_core.sh
    OBSNAME_PREFIX=$NEXTSIM_DATA_DIR"/CS2SMOS/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_" 
    OBSNAME_SUFFIX="_r_v202_01_l4sit"    
    OBS_DIR=/data/CS2SMOS #   $NEXTSIM_DATA_DIR/CS2SMOS
    #
    docker_image='nextsim_enkf' # select docker image
    if [ $UPDATE -gt 0 ]; then 
        echo "execute nextsim with EnKF filter!"
    else
        echo "execute nextsim only, no assimilation!"
    fi
#-------------------------------------------------------------
# rm -r $ENSPATH
# create ensemble directories and files
. $RUNPATH/part1_initialization.sh   
# execute ensemble runs
for (( i=1; i<=${tduration}; i++ )); do
    if [ $i -eq 1 ]; then 
        restart_from_analysis=false
    else 
        restart_from_analysis=true
        time_init=$(date +%Y-%m-%d -d "${time_init} + ${duration} day")        
    fi
    # a forecast-analysis cycle  
    . $RUNPATH/part2_core.sh   
done