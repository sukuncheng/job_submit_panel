#!/bin/bash 
# create workpath
# link restart file
# call part1_create_file_system.sh to modify nextsim.cfg and pseudo2D.nml and enkf settings to workpath
# submit jobs to queue by slurm_nextsim from workpath
# link restart file
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
JOB_SETUP_DIR=$(cd `dirname $0`;pwd)  
ENV_FILE=${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
slurm_nextsim=slurm.ensemble.template.sh
# ENV_FILE=${NEXTSIM_ENV_ROOT_DIR}/pynextsim.sing.src
# slurm_nextsim=slurm.singularity.template.sh

>nohup.out  # empty this file
##-------  Confirm working,data,ouput directories --------
    # experiment settings
    time_init=2019-09-03   # starting date of simulation
    basename=20190903T000000Z # set this variable, if the first run is from restart
    duration=42    # tduration*duration is the total simulation time
    tduration=1    # number of DA cycles. 
    ENSSIZE=40     # ensemble size  
    block=1        # number of forecasts in a job
    jobsize=$((${ENSSIZE}/${block})) #number of nodes requested 
    first_restart_path=$HOME/src/restart  
    # randf in pseudo2D.nml, whether do perturbation
    [[ ${ENSSIZE} > 1 ]] && randf=true || randf=false 

    OUTPUT_DIR=${simulations}/test_windcohesion_${time_init}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
    echo 'work path:' $OUTPUT_DIR
    [ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
    [ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}

## ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    ENSPATH=${OUTPUT_DIR}/date${iperiod}  
    mkdir -p ${ENSPATH}     
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

    ### option2 can resubmit failed task in jobarray
    for (( j=1; j<=3; j++ )); do
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            grep -q -s "Simulation done" ${ENSPATH}/mem${i}/task.log && continue
            cmd="sbatch $script $ENSPATH $ENV_FILE ${block} $i"  # change slurm.ensemble.template.sh: SLURM_ARRAY_TASK_ID=$4   #i is member_id, specifying member to run or rerun
            $cmd 2>&1 
        done
        WaitforTaskFinish $XPID0
    done
done
cp ${JOB_SETUP_DIR}/{main_spinup_exp.sh,part1_create_file_system.sh,nohup.out}  ${OUTPUT_DIR} 
