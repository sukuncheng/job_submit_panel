#!/bin/bash 
# H=()
#   H+=("neXtSIM will provide mem%3d.nc in which all state variables will be on a curvilinear regular grid")
#   H+=("mem%3d.nc will be linked into the FILTER directory")
#   H+=("all \*.prm files will be modified by a shell script and linked into the FILTER directory")
#   H+=("enkf_prep enkf_calc, enkf_update will be linked into the FILTER directory")
#   H+=("observations in the assimilation cycle will be linked into the FILTER/obs directory")
#   H+=("mem%3d.nc.analysis will be written by enkf-c")
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
# 
function link_restarts(){
    echo "project *.nc.analysis on reference_grid.nc, links restart files to $restart_path for next DA cycle"
    ENSSIZE=$1  
    ENSPATH=$2
    FILTER=$2/filter  
    restart_path=$3
    analysis_source=$4
    rm -f $restart_path/field_mem* 
    rm -f $restart_path/mesh_mem* 
    rm -f $restart_path/WindPerturbation_mem* 
    rm -f $restart_path/*.nc.analysis
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}
        ln -sf ${ENSPATH}/${memname}/WindPerturbation_${memname}.nc         ${restart_path}/WindPerturbation_${memname}.nc  
        ln -sf ${ENSPATH}/${memname}/restart/field_final.bin  $restart_path/field_${memname}.bin
        ln -sf ${ENSPATH}/${memname}/restart/field_final.dat  $restart_path/field_${memname}.dat
        ln -sf ${ENSPATH}/${memname}/restart/mesh_final.bin   $restart_path/mesh_${memname}.bin
        ln -sf ${ENSPATH}/${memname}/restart/mesh_final.dat   $restart_path/mesh_${memname}.dat
    done  

    [ ! -d ${analysis_source} ] && return;
    
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}    
        [ ! -f ${analysis_source}/${memname}.nc.analysis ] && cdo merge ${NEXTSIM_DATA_DIR}/reference_grid.nc  ${analysis_source}/$(printf "mem%.3d" $i).nc.analysis  ${analysis_source}/${memname}.nc.analysis         
        ln -sf ${analysis_source}/${memname}.nc.analysis          $restart_path/${memname}.nc.analysis
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
BaseName=$(basename $BASH_SOURCE)
ENV_FILE=${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
slurm_nextsim=slurm.ensemble.template.sh
slurm_enkf=slurm.enkf.template.sh

>nohup.out  # empty this file
restart_path=$NEXTSIM_DATA_DIR   # select a folder for exchange restart data
##-------  Confirm working,data,ouput directories --------
    # experiment settings
    time_init0=2019-10-18   # starting date of simulation
    duration=7     # tduration*duration is the total simulation time
    tduration=26   #25   # number of DA cycles. 
    ENSSIZE=40         # ensemble size  
    block=1            # number of forecasts in a job
    jobsize=$((${ENSSIZE}/${block})) #number of nodes requested 
    UPDATE=1 # 1: active EnKF assimilation 
    first_restart_path=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40/date1

    # randf in pseudo2D.nml, whether do perturbation
    [[ ${ENSSIZE} > 1 ]] && randf=true || randf=false 
    INFLATION=1
    LOCRAD=300
    RFACTOR=2
    KFACTOR=2
    DA_VAR=sit   #sitsic, sit, sic
    OUTPUT_DIR=${simulations}/test_DA${DA_VAR}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
    echo 'work path:' $OUTPUT_DIR
    #[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
    [ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}

## ----------- execute ensemble runs ----------
for (( iperiod=25; iperiod<=${tduration}; iperiod++ )); do
    restart_from_analysis=true   
    start_from_restart=true

    if [ $iperiod -eq 1 ]; then  
    # prepare and link restart files
        analysis_source=${first_restart_path}/filter/size40_I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}_DA${DA_VAR}
        link_restarts $ENSSIZE   $first_restart_path  $restart_path $analysis_source
    fi
    time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
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
cp ${JOB_SETUP_DIR}/${BaseName}  ${OUTPUT_DIR} 
echo "finished"
