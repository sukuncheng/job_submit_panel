#!/bin/bash 
#
set -uex  # uncomment for debugging
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR
function WaitforTaskFinish(){
    # ------ wait the completeness in this cycle.
    XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 	
    while [[ $XPID -gt $1 ]]; do 
        sleep 60
        XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) # number of running jobs 
    done
}

##-------  Confirm working,data,ouput directories --------
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)
BaseName=$(basename $BASH_SOURCE)
ENV_FILE=${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
slurm_nextsim=slurm.ensemble.template.sh

>nohup.out  # empty this file

##-------  Confirm working,data,ouput directories --------
    # experiment settings
    time_init=2019-09-03   # starting date of simulation
    duration=240    # tduration*duration is the total simulation time
    tduration=1    # number of DA cycles. 
    ENSSIZE=40     # ensemble size  
    block=1        # number of forecasts in a job
    jobsize=$((${ENSSIZE}/${block})) #number of nodes requested 
    UPDATE=0 # 1: active EnKF assimilation 
    first_restart_path=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40/date1
    # basename=20190903T000000Z # set this variable, if the first run is from restart
    # first_restart_path=$HOME/src/restart
    # randf in pseudo2D.nml, whether do perturbation
    [[ ${ENSSIZE} > 1 ]] && randf=true || randf=false 
    OUTPUT_DIR=${simulations}/test_FreeRun_${time_init}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
    echo 'work path:' $OUTPUT_DIR
    [ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
    [ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}

## ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    restart_from_analysis=false
    start_from_restart=true
    if $start_from_restart; then
        restart_path=$NEXTSIM_DATA_DIR   # select a folder for exchange restart data
        rm -f   $restart_path/{field_mem* mesh_mem* WindPerturbation_mem* *.nc.analysis}
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            memname=mem${i}
            ln -sf ${first_restart_path}/field_${basename}.bin  $restart_path/field_${memname}.bin
            ln -sf ${first_restart_path}/field_${basename}.dat  $restart_path/field_${memname}.dat
            ln -sf ${first_restart_path}/mesh_${basename}.bin   $restart_path/mesh_${memname}.bin
            ln -sf ${first_restart_path}/mesh_${basename}.dat   $restart_path/mesh_${memname}.dat
        done  
    fi
    echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + $((${duration})) day")"
# a. create files strucure, copy and modify configuration files inside
    ENSPATH=${OUTPUT_DIR}/date${iperiod}
    mkdir -p ${ENSPATH}   
    source ${JOB_SETUP_DIR}/part1_create_file_system.sh

    XPID0=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 
# b. submit the script for ensemble forecasts
    cd $ENSPATH
    script=${ENSPATH}/$slurm_nextsim
    cp $NEXTSIM_ENV_ROOT_DIR/$slurm_nextsim $script 

    ### option1 use job array
    # cmd="sbatch --array=1-${jobsize} $script $ENSPATH $ENV_FILE ${block}"
    # $cmd 2>&1 | tee sjob.id
    # jobid=$( awk '{print $NF}' sjob.id)
    # WaitforTaskFinish $XPID0

    ### option2 can resubmit failed task in jobarray, $block>1 doesn't work fully in this way.
    for (( j=1; j<=3; j++ )); do
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            grep -q -s "Simulation done" ${ENSPATH}/mem${i}/task.log && continue
            cmd="sbatch $script $ENSPATH $ENV_FILE ${block} $i"  # change slurm.ensemble.template.sh: SLURM_ARRAY_TASK_ID=$4
            $cmd 2>&1 
        done
        WaitforTaskFinish $XPID0
    done
done

cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR} 
cp ${JOB_SETUP_DIR}/${BaseName}  ${OUTPUT_DIR} 
echo "finished"
