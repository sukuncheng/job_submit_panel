#!/bin/bash 
# script for submitting an ensemble run with DA(sic,sit, sitsic), restarting from spinup run, defined by main1_spinup_exp.sh

# create workpath
# link restart file
# call part1_create_file_system.sh to file nextsim.cfg and mkdir folder infrastruce
# submit jobs to queue by slurm_nextsim from workpath

# set -uex  # uncomment for debugging
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR
function WaitforTaskFinish(){
    # ------ wait the completeness in this cycle.
    XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 	
    while [[ $XPID -gt $1 ]]; do 
        sleep 30
        XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) # number of running jobs 
    done
}
# 
function link_restarts(){
    echo "project *.nc.analysis on reference_grid.nc, links restart files to $restart_path for next DA cycle"
    ENSSIZE=$1  
    ENSPATH=$2
    FILTER=$2/filter  
    restart_path=$3
    analysis_source=$4

    rm -f  $restart_path/{field_mem* mesh_mem* WindPerturbation_mem* *.nc.analysis}

    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}
    #    ln -sf ${ENSPATH}/${memname}/WindPerturbation_${memname}.nc         ${restart_path}/WindPerturbation_${memname}.nc  
        ln -sf ${ENSPATH}/${memname}/restart/field_final.bin  $restart_path/field_${memname}.bin
        ln -sf ${ENSPATH}/${memname}/restart/field_final.dat  $restart_path/field_${memname}.dat
        ln -sf ${ENSPATH}/${memname}/restart/mesh_final.bin   $restart_path/mesh_${memname}.bin
        ln -sf ${ENSPATH}/${memname}/restart/mesh_final.dat   $restart_path/mesh_${memname}.dat
    done  

# link reanalysis
    [ ! -d ${analysis_source} ] && return;    
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}    
        [ ! -f ${analysis_source}/${memname}.nc.analysis ] && cdo merge ${NEXTSIM_DATA_DIR}/reference_grid.nc  ${analysis_source}/$(printf "mem%.3d" $i).nc.analysis  ${analysis_source}/${memname}.nc.analysis         
        ln -sf ${analysis_source}/${memname}.nc.analysis          $restart_path/${memname}.nc.analysis
    done
}

function link_perturbation(){ # note the index 180=45*4 correspond to the last perturbation used in the end of spinup run
    echo "links perturbation files to $restart_path/Perturbation using input file id"
    # link perturbations. The number is calculated ahead as Nfiles
    restart_path=$1
    duration=$2
    iperiod=$3
    ENSSIZE=$4

    rm -f ${restart_path}/Perturbations/*.nc
    Perturbations_Dir=/cluster/work/users/chengsukun/offline_perturbations/result

    # Nseries=`ls ${Perturbations_Dir}/mem1/*.nc | wc -l`
    Nfiles=$(( $duration*4+1+4 ))  # number of perturbations to link
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}    
        for (( j=0; j<${Nfiles}; j++ )); do
            ln -sf ${Perturbations_Dir}/${memname}/synforc_$((${j}+180 + ($iperiod-1)*($Nfiles-1))).nc  ${restart_path}/Perturbations/Perturbations_${memname}_series${j}.nc
        done
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
slurm_enkf=slurm.enkf.template.sh

>nohup.out  # empty this file
restart_path=$NEXTSIM_DATA_DIR   # select a folder for exchange restart data
##-------  Confirm working,data,ouput directories --------
# experiment settings
time_init0=2019-10-18   # starting date of simulation
duration=7     # forecast length; tduration*duration is the total simulation time
tduration=26       # number of DA cycles. 
ENSSIZE=40         # ensemble size  
UPDATE=1            # 1: active EnKF assimilation 
first_restart_path=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40_offline_perturbations/date1

INFLATION=1
LOCRAD=300
RFACTOR=2
KFACTOR=2
DA_VAR=sic   #sitsic, sit, sic
OUTPUT_DIR=${simulations}/test_DA${DA_VAR}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}_offline_perturbations
echo 'work path:' $OUTPUT_DIR
[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 

## ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    restart_from_analysis=true
    start_from_restart=true
    if [ $iperiod -eq 1 ]; then  # prepare and link restart files
        analysis_source=${first_restart_path}/filter/size40_I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}_DA${DA_VAR}
        link_restarts $ENSSIZE   $first_restart_path  $restart_path $analysis_source
    fi
    # link offline perturbations to ensemble members
    link_perturbation $restart_path $duration $iperiod $ENSSIZE

    time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
    echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + ${duration} day")"
# a. create files strucure, copy and modify configuration files inside
    ENSPATH=${OUTPUT_DIR}/date${iperiod}
    mkdir -p ${ENSPATH}   
    source ${JOB_SETUP_DIR}/part1_create_file_system.sh

    
# b. submit the script for ensemble forecasts
    cd $ENSPATH
    script=${ENSPATH}/$slurm_nextsim
    cp $NEXTSIM_ENV_ROOT_DIR/$slurm_nextsim $script 

    count=0
    for (( j=1; j<=3; j++ )); do
        for (( i=0; i<$ENSSIZE; i++ )); do
            grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && count=$(( $count+1 ))            
        done
        echo 'count='$count
        if [ $count -lt $ENSSIZE ]; then
            XPID0=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 
            sbatch --time=0-0:10:0   $script $ENSPATH $ENV_FILE ${ENSSIZE}
            WaitforTaskFinish $XPID0
        else
            break
        fi
    done
    [ ! -d ${ENSPATH}/filter/prior ] && mkdir -p ${ENSPATH}/filter/prior
    for (( i=1; i<=$ENSSIZE; i++ )); do
        mv ${ENSPATH}/mem${i}/prior.nc  ${ENSPATH}/filter/prior/$(printf "mem%.3d" ${i}).nc
    done

    ## 2.submit enkf after finishing the ensemble simulations 
    if [ ${UPDATE} == 1 ] && [ ! -f $ENSPATH/filter/update.out ]; then
        script=${ENSPATH}/$slurm_enkf
        cp ${NEXTSIM_ENV_ROOT_DIR}/$slurm_enkf $script
        cmd="sbatch $script $ENSPATH"  # --dependency=afterok:${jobid}
        $cmd 2>&1
    fi
    WaitforTaskFinish $XPID0
    #
    analysis_source=$ENSPATH/filter/prior
    link_restarts $ENSSIZE   $ENSPATH  $restart_path $analysis_source
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}
echo "finished"
