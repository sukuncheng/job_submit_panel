#!/bin/bash 
# To turn off ENSEMBLE code, set ENSEMBLE=0 in ENV_FILE, then recompile neXtSIM !
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
JOB_SETUP_DIR=$(cd `dirname $0`;pwd)  
ENV_FILE=${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src   # set ENSEMBLE=0 in this file
sed -i "s|^export USE_ENSEMBLE.*$|export USE_ENSEMBLE=0|g;" ${ENV_FILE}  # NEED TO RECOMPILE neXtSIM
slurm_nextsim=slurm.single.sh
>nohup.out  # empty this file
##-------  Confirm working,data,ouput directories --------
    # experiment settings
    time_init=2019-09-03   # starting date of simulation
    basename=20190903T000000Z # set this variable, if the first run is from restart
    duration=240    # tduration*duration is the total simulation time
    tduration=1    # number of DA cycles. 
    ENSSIZE=1     # ensemble size  
    block=1        # number of forecasts in a job
    jobsize=$((${ENSSIZE}/${block})) #number of nodes requested 

    sed -i "s|^dynamics-type=.*$|dynamics-type=free_drift|g"  ${JOB_SETUP_DIR}/nextsim.cfg
    ASR_air_drag=(0.0016)
    OUTPUT_DIR=${simulations}/test_free_drift_${time_init}_${duration}days
    echo 'work path:' $OUTPUT_DIR
    [ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
    [ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
restart_from_analysis=false
start_from_restart=true
restart_path=/cluster/home/chengsukun/src/restart
## ----------- execute ensemble runs ----------
# b. prepare the slurm script 
    ENSPATH=${OUTPUT_DIR} 
    script=${ENSPATH}/$slurm_nextsim
    cp $NEXTSIM_ENV_ROOT_DIR/$slurm_nextsim $script

echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + $((${duration})) day")"
for (( i=1; i<=${#ASR_air_drag[@]}; i++ )); do
# a. create files strucure, copy and modify configuration files inside
    sed -i "s|^time_init=.*$|time_init=${time_init}|g; \
         s|^duration=.*$|duration=${duration}|g; \
         s|^output_timestep=.*$|output_timestep=1|g; \
         s|^start_from_restart=.*$|start_from_restart=${start_from_restart}|g; \
         s|^write_final_restart=.*$|write_final_restart=true|g; \
         s|^input_path=.*$|input_path=${restart_path}|g; \
         s|^basename.*$|basename=${basename}|g; \
         s|^ECMWF_quad_drag_coef_air.*$|ECMWF_quad_drag_coef_air=${ASR_air_drag[$i-1]}|g; \
         s|^restart_from_analysis=.*$|restart_from_analysis=${restart_from_analysis}|g" \
        ${JOB_SETUP_DIR}/nextsim.cfg
    
# c. submit a job to squeue 
    member_dir=${ENSPATH}/mem${i}  
    mkdir -p ${member_dir}
    cd $member_dir
    cp ${JOB_SETUP_DIR}/nextsim.cfg .
    cp ${JOB_SETUP_DIR}/pseudo2D.nml .
    cmd="sbatch $script $member_dir $ENV_FILE "
    $cmd 2>&1 
done
# cp ${JOB_SETUP_DIR}/{main_tune_air_drag_coefficient.sh,part1_create_file_system.sh,nohup.out}  ${OUTPUT_DIR} 
echo "finished"
