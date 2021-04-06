#!/bin/bash 
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
# start from here
# create workpath
# link restart file
# call part1_create_file_system.sh to modify nextsim.cfg and pseudo2D.nml and enkf settings to workpath
# submit jobs to queue by slurm_nextsim from workpath
# link restart file
##-------  Confirm working,data,ouput directories --------
JOB_SETUP_DIR=$(cd `dirname $0`;pwd)  
ENV_FILE=${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
slurm_nextsim=slurm.ensemble.template.sh
slurm_enkf=slurm.enkf.template.sh

>nohup.out  # empty this file
##-------  Confirm working,data,ouput directories --------
    # experiment settings
    time_init=2020-01-07   # starting date of simulation
    basename=final     # set this variable, if the first run is from restart
    duration=7     # tduration*duration is the total simulation time
    tduration=16   # number of DA cycles. 
    ENSSIZE=40     # ensemble size  
    block=1        # number of forecasts in a job
    jobsize=$((${ENSSIZE}/${block})) #number of nodes requested 
    UPDATE=1 # 1: active assimilation -- do data assimilation using EnKF
    # first_restart_path=/cluster/work/users/chengsukun/simulations/test_windcohesion_2019-09-03_42days_x_1cycles_memsize40/date1
    first_restart_path=/cluster/work/users/chengsukun/simulations/test_windcohesion_2019-10-15_7days_x_12cycles_memsize40/date12
    # randf in pseudo2D.nml, whether do perturbation
    [[ ${ENSSIZE} > 1 ]] && randf=true || randf=false 
    INFLATION=1
    LOCRAD=300
    RFACTOR=2
    KFACTOR=2
    # OUTPUT_DIR=${simulations}/run_${time_init}_Ne${ENSSIZE}_T${tduration}_D${duration}/I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}  
    OUTPUT_DIR=${simulations}/test_windcohesion_${time_init}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
    echo 'work path:' $OUTPUT_DIR
    [ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
    [ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
    cp ${JOB_SETUP_DIR}/{main_DA_exp2.sh,part1_create_file_system.sh}  ${OUTPUT_DIR}

## ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    ENSPATH=${OUTPUT_DIR}/date${iperiod}  
    mkdir -p ${ENSPATH}     
    restart_from_analysis=true   
    start_from_restart=true
    if [ $iperiod -eq 1 ] && [ restart_from_analysis ]; then  # prepare and link restart files
        restart_path=$NEXTSIM_DATA_DIR   # select a folder for exchange restart data
        rm -f   $restart_path/{field_mem* mesh_mem* WindPerturbation_mem* *.nc.analysis}
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            memname=mem${i}
            echo "UPDATE=1, project *.nc.analysis on nextsim_data_dir/reference_grid.nc, move it and restart file to $restart_path for ensemble forecasts"
            cd ${first_restart_path}/filter
            # analysis_path=${first_restart_path}/filter
            # cdo merge $NEXTSIM_DATA_DIR/reference_grid.nc   ${analysis_path}/$(printf "mem%.3d" $i).nc.analysis  ${memname}.nc.analysis       
            ln -sf ${first_restart_path}/filter/${memname}.nc.analysis   ${restart_path}/${memname}.nc.analysis   

            ln -sf ${first_restart_path}/${memname}/WindPerturbation_${memname}.nc        ${restart_path}/WindPerturbation_${memname}.nc   
            ln -sf ${first_restart_path}/${memname}/restart/field_final.bin  $restart_path/field_${memname}.bin
            ln -sf ${first_restart_path}/${memname}/restart/field_final.dat  $restart_path/field_${memname}.dat
            ln -sf ${first_restart_path}/${memname}/restart/mesh_final.bin   $restart_path/mesh_${memname}.bin
            ln -sf ${first_restart_path}/${memname}/restart/mesh_final.dat   $restart_path/mesh_${memname}.dat
        done
    else
        time_init=$(date +%Y-%m-%d -d "${time_init} + ${duration} day")
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

    ## 2.submit enkf after finishing the ensemble simulations 
    if [ ${UPDATE} -eq 1 ]; then
        cd ${ENSPATH}
        script=${ENSPATH}/$slurm_enkf
        cp ${NEXTSIM_ENV_ROOT_DIR}/$slurm_enkf $script
        cmd="sbatch $script $ENSPATH"  # --dependency=afterok:${jobid}
        $cmd 2>&1
    fi
    WaitforTaskFinish $XPID0
    
    # ----------------------------------------------
    echo "  project *.nc.analysis on reference_grid.nc, move it and restart file to $restart_path for ensemble forecasts in the next cycle"
#<<'COMMENT'
    for (( i=1; i<=${ENSSIZE}; i++ )); do
	    memname=mem${i}
        ln -sf ${ENSPATH}/${memname}/restart/field_final.bin  $restart_path/field_${memname}.bin
        ln -sf ${ENSPATH}/${memname}/restart/field_final.dat  $restart_path/field_${memname}.dat
        ln -sf ${ENSPATH}/${memname}/restart/mesh_final.bin   $restart_path/mesh_${memname}.bin
        ln -sf ${ENSPATH}/${memname}/restart/mesh_final.dat   $restart_path/mesh_${memname}.dat
        if [ ${UPDATE} -eq 1 ]; then
            cd  ${FILTER}
            cdo merge ${NEXTSIM_DATA_DIR}/reference_grid.nc  ${FILTER}/prior/$(printf "mem%.3d" $i).nc.analysis  ${memname}.nc.analysis         
            ln -sf ${FILTER}/${memname}.nc.analysis               $restart_path/${memname}.nc.analysis 
            ln -sf ${ENSPATH}/${memname}/WindPerturbation_${memname}.nc $restart_path/WindPerturbation_${memname}.nc  # must use copy, it will be copied again to work path. The one in work path will be updated by the program.
        fi  
    done  
#COMMENT
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR} 

# H=()
#   H+=("neXtSIM will provide mem%3d.nc in which all state variables will be on a curvilinear regular grid")
#   H+=("mem%3d.nc will be linked into the FILTER directory")
#   H+=("all \*.prm files will be modified by a shell script and linked into the FILTER directory")
#   H+=("enkf_prep enkf_calc, enkf_update will be linked into the FILTER directory")
#   H+=("observations in the assimilation cycle will be linked into the FILTER/obs directory")
#   H+=("mem%3d.nc.analysis will be written by enkf-c")