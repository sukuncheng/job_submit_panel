#!/bin/bash 
#set -uex
set -e
#
    XPID0=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 	
#-------  Confirm working,data,ouput directories --------
    JOB_SETUP_DIR=$(cd `dirname $0`;pwd)       
    # observation CS2SMOS data discription
    OBSNAME_PREFIX=$NEXTSIMDIR/data/CS2_SMOS_v2.2/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_ 
    OBSNAME_SUFFIX=_r_v202_01_l4sit

    # experiment settings
    time_init=2018-11-11   # starting date of simulation
    duration=1    # tduration*duration is the total simulation time
    tduration=3   # number of forecast-analysis cycle. 
    ENSSIZE=2     # ensemble size
    
    # $OUTPUT_DIR
    OUTPUT_DIR=${IO_nextsim}/test_Ne${ENSSIZE}_T${tduration}_D${duration}/I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}   
    OUTPUT_DIR=${OUTPUT_DIR//./p}  ## what does it mean？
    echo 'work path:' $OUTPUT_DIR 
    [ -d $OUTPUT_DIR ] && rm -r $OUTPUT_DIR  
    mkdir -p $OUTPUT_DIR/reanalysis    
# ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    if [ $iperiod -eq 1 ]; then 
        start_from_restart=true
        restart_from_analysis=false
    else
        start_from_restart=false
        restart_from_analysis=true
        time_init=$(date +%Y-%m-%d -d "${time_init} + ${duration} day")        
    fi
    echo "start period ${time_init}"
    ENSPATH=${OUTPUT_DIR}/date${iperiod}  
    mkdir -p $ENSPATH  
    cp -r ${JOB_SETUP_DIR}/{jobs_array_submit.sh,part1_create_file_system.sh,run.job_array.sh} $ENSPATH 
    # create files strucure, copy and modify configuration files inside
    source ${ENSPATH}/part1_create_file_system.sh
    # note slurm.template.sh (later script) only use name of $config - nextsim.cfg
cd  ${ENSPATH}
    source ${ENSPATH}/run.job_array.sh ${ENSPATH}/nextsim.cfg 1 -ne $ENSSIZE -e $HOME/src/nextsim-env/machines/fram_sukun/nextsim.src
    # wait the completeness in this cycle.
    XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 	
    while [[ $XPID -gt $XPID0 ]]; do 
        sleep 200
        XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) # number of running jobs 
    done
    # 
    echo "  project *.nc.analysis on reference_grid.nc, save to /NEXTSIMDIR/data/ for ensemble forecasting in the next cycle"
#<<'COMMENT'
    rm -f ${NEXTSIMDIR}/data/*.nc.analysis    
    for (( mem=1; mem<=${ENSSIZE}; mem++ )); do
	memname=$(printf "mem%.3d" ${mem})
        [ ! -f ${FILTER}/prior/${memname} ] && sleep 5
        cdo merge ${FILTER}/reference_grid.nc  ${FILTER}/prior/${memname}.nc ${NEXTSIMDIR}/data/${memname}.nc.analysis 
        # note  enkf and cdo depend on the path of reference_grid.nc
    done
#COMMENT
done

#    . run.fram.sh $cfg 1 -e ~/nextsim.ensemble.src                  
#    1 - copy nextsim.exec from NEXTSIMDIR/model/bin to current path
#   -t test run without submit to fram
#   -e ~/nextsim.ensemble.src      # envirmonental variables

#   #Wait for all jobs to finish, or check "squeue -u chengsukun | grep -q ${JOBID[$mem]}"          
#         XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 	
#         while [[ $XPID -gt $XPID0 ]]; do 
#             sleep 200
#             XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) # number of current running jobs 
#             echo '    '$[$XPID-$XPID0] 'jobs are running'             
#         done 


# #   create a namelist of ensemble member directories
#     ENSEMBLE=()             
#     for (( mem=1; mem<=${ENSSIZE}; mem++ )); do
#         MEMBER=$(printf "%03d" $mem)
#         MEMNAME=mem${MEMBER}
#         ENSEMBLE+=([${mem}]=${MEMNAME})  
#     done 

# # create ensemble directories and files
#     source $JOB_SETUP_DIR/part1_initialization.sh   
# # a forecast-analysis cycle
# #    source $JOB_SETUP_DIR/part2_core.sh  
