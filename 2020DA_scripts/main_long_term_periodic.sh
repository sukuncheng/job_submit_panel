#!/bin/bash 
#set -uex  # uncomment for debugging
ENV_FILE=${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src

>nohup.out  # empty this file
##-------  Confirm working,data,ouput directories --------
    JOB_SETUP_DIR=$(cd `dirname $0`;pwd)      
    # experiment settings
    # time_init=2019-08-14   # starting date of simulation
    # basename=20190814T000000Z # set this variable, if the first run is from restart
    # duration=7    # tduration*duration is the total simulation time
    # tduration=8   # number of DA cycles. 

    time_init=2019-09-03   # starting date of simulation
    basename=20190903T000000Z # set this variable, if the first run is from restart
    duration=7    # tduration*duration is the total simulation time
    tduration=5    # number of DA cycles. 
    ENSSIZE=1    # ensemble size  
    block=1
    jobsize=$((${ENSSIZE}/${block}))
    first_restart_path=$HOME/src/restart
    # randf in pseudo2D.nml, whether do perturbation
    [[ $ENSSIZE > 1 ]] && randf=true || randf=false 

    # OUTPUT_DIR
    OUTPUT_DIR=${IO_nextsim}/ensemble_forecasts_${time_init}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
    echo 'work path:' $OUTPUT_DIR
    # [ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR  
    # mkdir -p ${OUTPUT_DIR}
    #
    restart_path=$NEXTSIMDIR/data    #be consistent with restart path defined in slurm.jobarray.template.sh

## ---------- do data assimilation using EnKF
    UPDATE=0 # 1: active assimilation

    # observation CS2SMOS data discription
    OBSNAME_PREFIX=$NEXTSIMDIR/data/CS2_SMOS_v2.2/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_ 
    OBSNAME_SUFFIX=_r_v202_01_l4sit  # backup data is in NEXTSIM_DATA_DIR

## ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    ENSPATH=${OUTPUT_DIR}/date${iperiod}  
    mkdir -p ${ENSPATH}     
    # --- edit nextsim.cfg ---------------------
    if [ $iperiod -eq 1 ]; then 
        start_from_restart=true
        restart_from_analysis=false
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            memname=mem${i}
            ln -sf ${first_restart_path}/field_${basename}.bin  $restart_path/field_${memname}.bin
            ln -sf ${first_restart_path}/field_${basename}.dat  $restart_path/field_${memname}.dat
            ln -sf ${first_restart_path}/mesh_${basename}.bin   $restart_path/mesh_${memname}.bin
            ln -sf ${first_restart_path}/mesh_${basename}.dat   $restart_path/mesh_${memname}.dat
        done  
    else
        start_from_restart=true
        restart_from_analysis=false
        time_init=$(date +%Y-%m-%d -d "${time_init} + ${duration} day")
    fi
    echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + $((${duration})) day")"
    # 0. create files strucure, copy and modify configuration files inside
        cp ${JOB_SETUP_DIR}/{main_long_term_periodic.sh,part1_create_file_system.sh}  ${ENSPATH} 
        source ${ENSPATH}/part1_create_file_system.sh

    XPID0=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 
    # 1. submit the script for ensemble forecasts
        cd $ENSPATH
        script=${ENSPATH}/slurm.jobarray.nextsim.sh
        cp $NEXTSIM_ENV_ROOT_DIR/slurm.jobarray.template.sh $script 

        ### option1
        # cmd="sbatch --array=1-${jobsize} $script $ENSPATH $ENV_FILE ${block}"
        # $cmd 2>&1 | tee sjob.id
        # jobid=$( awk '{print $NF}' sjob.id)

        ### option2 skip completed runs
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            grep -q -s "Simulation done" ${ENSPATH}/mem${i}/task.log && continue
            ls ${ENSPATH}/mem${i}/task.log
            cmd="sbatch $script $ENSPATH $ENV_FILE ${block} $i"  # change slurm.jobarray.template.sh: SLURM_ARRAY_TASK_ID=$4   #if not use jobarray
            $cmd 2>&1 | tee sjob.id
        done
    # 2.submit enkf after finishing the ensemble simulations     
    if [ ${UPDATE} -eq 1 ]; then
        cd ${ENSPATH}
        script=${ENSPATH}/slurm.enkf.nextsim.sh
        cp ${NEXTSIM_ENV_ROOT_DIR}/slurm.enkf.template.sh $script
        cmd="sbatch --dependency=afterok:${jobid} $script $ENSPATH"
        $cmd    
    fi
    # ------ wait the completeness in this cycle.
    XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 	
    while [[ $XPID -gt $XPID0 ]]; do 
        sleep 60
        XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) # number of running jobs 
    done
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
            cdo merge reference_grid.nc  prior/$(printf "mem%.3d" $i).nc.analysis  ${memname}.nc.analysis         
            ln -sf ${FILTER}/${memname}.nc.analysis               $restart_path/${memname}.nc.analysis 
            cp ${ENSPATH}/${memname}/WindPerturbation_${memname}.nc $restart_path/WindPerturbation_${memname}.nc  # must use copy, it will be copied again to work path. The one in work path will be updated by the program.
        fi  
    done  
#COMMENT
done

cp ${JOB_SETUP_DIR}/nohup.out ${OUTPUT_DIR}