#!/bin/bash 
# -----------------------------------------------------------
# set -uex  # uncomment for debugging
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
# -------------------------------------------------------------


## To turn off ENSEMBLE code, set ENSEMBLE=0 in ENV_FILE, then recompile neXtSIM !
##-------  Confirm working,data,ouput directories --------
ENV_FILE=${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src  
sed -i "s|^export USE_ENSEMBLE.*$|export USE_ENSEMBLE|g;" ${ENV_FILE} 
cd ~/src/nextsim
make fresh -j8
JOB_SETUP_DIR=$(cd `dirname $0`;pwd)  

>nohup.out  
    # experiment settings
    start_date=2019-10-09     # starting date of simulation
    basename=20190903T000000Z # set this variable, if the first run is from restart
    duration=9     # tduration*duration is the total simulation time
    tduration=23   # number of DA cycles. 
    ENSSIZE=1      # ensemble size  
    block=1        # number of forecasts in a job
    jobsize=$((${ENSSIZE}/${block})) #number of nodes requested 

    sed -i "s|^dynamics-type=.*$|dynamics-type=free_drift|g"  ${JOB_SETUP_DIR}/nextsim.cfg
    air_drag_coef=(0.0016)
    #
    OUTPUT_DIR=${simulations}/test_free_drift_${start_date}_${duration}days_x_${tduration}cycles
    echo 'work path:' $OUTPUT_DIR
    [ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
    [ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
    #
    restart_from_analysis=false
    start_from_restart=true
    restart_path=/cluster/work/users/chengsukun/simulations/test_deterministic_2019-09-03_260days/mem1/restart
    #
    script=${NEXTSIM_ENV_ROOT_DIR}/slurm.single.sh

## ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    XPID0=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 
    
    basename=$(date +%Y%m%dT000000Z -d "${start_date} + $((${duration}*($iperiod-1))) day")
    time_init=$(date +%Y-%m-%d -d "${start_date} + $((${duration}*($iperiod-1))) day")
    echo $time_init $basename 
    for (( i=1; i<=${#air_drag_coef[@]}; i++ )); do
    # a. setting config files
        sed -i "s|^time_init=.*$|time_init=${time_init}|g; \
            s|^duration=.*$|duration=${duration}|g; \
            s|^output_timestep=.*$|output_timestep=1|g; \
            s|^start_from_restart=.*$|start_from_restart=${start_from_restart}|g; \
            s|^write_final_restart=.*$|write_final_restart=false|g; \
            s|^input_path=.*$|input_path=${restart_path}|g; \
            s|^basename.*$|basename=${basename}|g; \
            s|^ECMWF_quad_drag_coef_air.*$|ECMWF_quad_drag_coef_air=${air_drag_coef[$i-1]}|g; \
            s|^restart_from_analysis=.*$|restart_from_analysis=${restart_from_analysis}|g" \
            ${JOB_SETUP_DIR}/nextsim.cfg
        
    # b. create work path
        member_dir=${OUTPUT_DIR}/date${iperiod}/mem${i}  
        mkdir -p ${member_dir}
        cd $member_dir
        cp ${JOB_SETUP_DIR}/nextsim.cfg .
        # cp ${JOB_SETUP_DIR}/pseudo2D.nml .
    # c. submit a job from $member_dir
        cmd="sbatch $script $member_dir $ENV_FILE "
        $cmd 2>&1 
    done
    WaitforTaskFinish $XPID0
done
cp ${JOB_SETUP_DIR}/`basename $0` ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR} 
echo "finished"
