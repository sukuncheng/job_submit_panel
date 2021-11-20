#!/bin/bash 
# script for submitting an ensemble run without DA, restarting from a restart file.

# create workpath
# link restart file
# call part1_create_file_system.sh to file nextsim.cfg and mkdir folder infrastruce
# submit jobs to queue by slurm_nextsim_script from workpath

set -uex  # uncomment for debugging
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

# Instruction:
# create workpath
# link restart file
# call part1_create_file_system.sh to modify nextsim.cfg and pseudo2D.nml and enkf settings to workpath
# submit jobs to queue by slurm_nextsim_script from workpath
# link restart file


function link_perturbation(){ 
    # note the index 180=45*4 correspond to the last perturbation used in the end of spinup run
    echo "links perturbation files to $restart_path/Perturbation using input file id"
    # The number is calculated ahead as Nfiles +1
    restart_path=$1
    duration=$2
    iperiod=$3
    ENSSIZE=$4

    [ ! -d ${restart_path}/Perturbations ] && mkdir -p ${restart_path}/Perturbations || rm -f ${restart_path}/Perturbations/*.nc
    Perturbations_Dir=/cluster/work/users/chengsukun/offline_perturbations/result
    
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}    
        # link data sources based on different loading frequencies
        # atmoshphere
        Nfiles=$(( $duration*4+1))  # number of perturbations to link
        for (( j=0; j<=${Nfiles}; j++ )); do  #+1 is because an instance could end at 23:45 or 24:00 for different members due to ? +1 corresponds to the longer one.
            ln -sf ${Perturbations_Dir}/${memname}/synforc_$((${j}+45*4 + ($iperiod-1)*($Nfiles-1) )).nc  ${restart_path}/Perturbations/AtmospherePerturbations_${memname}_series${j}.nc
        done
        # ocean 
        Nfiles=$duration+1  # topaz data is loaded at 12:00pm. 
        for (( j=0; j<=${Nfiles}; j++ )); do
            ln -sf ${Perturbations_Dir}/${memname}/synforc_$((${j}+45   + ($iperiod-1)*$Nfiles)).nc  ${restart_path}/Perturbations/OceanPerturbations_${memname}_series${j}.nc
        done
    done
}

##-------  Confirm working,data,ouput directories --------
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
slurm_nextsim_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.ensemble.template.sh

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
DA_VAR=
first_restart_path=$HOME/src/restart

OUTPUT_DIR=${simulations}/test_spinup_${time_init}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}_offline_perturbations
echo 'work path:' $OUTPUT_DIR
#[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 

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
    # link perturbation files
    link_perturbation $restart_path $duration $iperiod $ENSSIZE  
# b. submit the script for ensemble forecasts
    cd $ENSPATH
    cp $slurm_nextsim_script $ENSPATH/.
    Nnode=40
    sbatch -W --time=0-0:50:0  --nodes=$Nnode $slurm_nextsim_script $ENSPATH ${ENSSIZE}  $Nnode
    wait
    # check for crashed member, report error and exit
    for (( i=1; i<=$ENSSIZE; i++ )); do
        ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && echo $ENSPATH'/mem'$i 'has crashed. EXIT' && exit
    done
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}
echo "finished"
