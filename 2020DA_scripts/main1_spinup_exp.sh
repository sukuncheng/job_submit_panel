#!/bin/bash 
# script for submitting an ensemble run without DA, restarting from a restart file.

# create workpath
# link restart file
# call part1_create_file_system.sh to file nextsim.cfg and mkdir folder infrastruce
# submit jobs to queue by slurm_nextsim from workpath

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

# Instruction:
# create workpath
# link restart file
# call part1_create_file_system.sh to modify nextsim.cfg and pseudo2D.nml and enkf settings to workpath
# submit jobs to queue by slurm_nextsim from workpath
# link restart file
##-------  Confirm working,data,ouput directories --------
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)
ENV_FILE=${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
slurm_nextsim=slurm.ensemble.template.sh

>nohup.out  # empty this file
restart_path=$NEXTSIM_DATA_DIR   # select a folder for exchange restart data
##-------  Confirm working,data,ouput directories --------
# experiment settings
time_init=2019-09-03   # starting date of simulation
basename=20190903T000000Z # set this variable, if the first run is from restart
duration=45    # forecast length; tduration*duration is the total simulation time
tduration=1    # number of DA cycles. 
ENSSIZE=40     # ensemble size  
UPDATE=0       # 1: active EnKF assimilation 
first_restart_path=$HOME/src/restart

OUTPUT_DIR=${simulations}/test_spinup_${time_init}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}_offline_perturbations
echo 'work path:' $OUTPUT_DIR
#[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 

# link perturbations
rm -f ${restart_path}/Perturbations/*.nc
Perturbations_Dir=/cluster/work/users/chengsukun/offline_perturbations/result
# Nseries=`ls ${Perturbations_Dir}/mem1/*.nc | wc -l`
Nfiles=$(( $duration*4+1+4))
for (( i=1; i<=${ENSSIZE}; i++ )); do
    memname=mem${i}    
    for (( j=0; j<${Nfiles}; j++ )); do
        ln -sf ${Perturbations_Dir}/${memname}/synforc_${j}.nc  ${restart_path}/Perturbations/Perturbations_${memname}_series${j}.nc
    done
done

## ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    restart_from_analysis=false
    start_from_restart=true
    if $start_from_restart; then
        restart_path=$NEXTSIM_DATA_DIR   # select a folder for exchange restart data
        rm -f  $restart_path/{field_mem* mesh_mem* WindPerturbation_mem* *.nc.analysis}
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            memname=mem${i}
            ln -sf ${first_restart_path}/field_${basename}.bin  $restart_path/field_${memname}.bin
            ln -sf ${first_restart_path}/field_${basename}.dat  $restart_path/field_${memname}.dat
            ln -sf ${first_restart_path}/mesh_${basename}.bin   $restart_path/mesh_${memname}.bin
            ln -sf ${first_restart_path}/mesh_${basename}.dat   $restart_path/mesh_${memname}.dat
        done  
    fi
    echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + ${duration} day")"
# a. create files strucure, copy and modify configuration files inside
    ENSPATH=${OUTPUT_DIR}/date${iperiod}
    mkdir -p ${ENSPATH}   
    source ${JOB_SETUP_DIR}/part1_create_file_system.sh

    XPID0=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 
# b. submit the script for ensemble forecasts
    cd $ENSPATH
    script=${ENSPATH}/$slurm_nextsim
    cp $NEXTSIM_ENV_ROOT_DIR/$slurm_nextsim $script 

    sbatch --time=0-0:45:0   $script $ENSPATH $ENV_FILE ${ENSSIZE} 
    WaitforTaskFinish $XPID0
    
    # [ ! -d ${ENSPATH}/filter/prior ] && mkdir -p ${ENSPATH}/filter/prior
    # for (( i=1; i<=$ENSSIZE; i++ )); do
    #     mv ${ENSPATH}/mem${i}/prior.nc  ${ENSPATH}/filter/prior/$(printf "mem%.3d" ${i}).nc
    # done
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}
echo "finished"
