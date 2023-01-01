#!/bin/bash 
#  ======================================================
#SBATCH --account=nn2993k  #nn9481k #nn9878k   # #nn2993k   #ACCOUNT_NUMBER
#SBATCH --job-name=freerun
#SBATCH --time=0-10:0:0        #dd-hh:mm:ss, # Short request job time can be accepted easier.
#SBATCH --nodes=40             # request number of nodes
##SBATCH --time=0-1:0:0 
##SBATCH --qos=devel           # preproc, devel, short and normal if comment this line,  https://documentation.sigma2.no/jobs/job_types/fram_job_types.html
##SBATCH --nodes=1             # request number of nodes
#SBATCH --ntasks-per-node=128  # MPI parallel thread size
#SBATCH --cpus-per-task=1      #
#SBATCH --output=deterministic.log         # Stdout
#SBATCH --error=deterministic.log          # Stderr
# ======================================================

# 

# Instruction:
# script for submiting an ensemble run without DA, restarting from spinup run, defined by main1_spinup_exp.sh
# create file structure 
# call part1_create_file_system.sh to modify nextsim.cfg and enkf settings to workpath
# link restart files &perturbation files.
# submit jobs to queue by slurm_nextsim_script from workpath.

set -uex  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

##-------  Confirm working,data,ouput directories --------
>nohup.out  # empty this file
>deterministic.log
# JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)
JOB_SETUP_DIR=/cluster/home/chengsukun/src/job_submit_panel/2020nextsim-enkf
slurm_nextsim_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.ensemble.template.sh
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
source link_restart_perturbation.sh

##-------  Confirm working,data,ouput directories --------
# experiment settings
Exp_ID=FreeRun-daily-restart
ENSSIZE=40  
time_init0=2019-10-18   # starting date of simulation
duration=7      # forecast length; tduration*duration is the total simulation time
tduration=26    # number of DA cycles.

start_from_restart=true
UPDATE=0        # 1: active EnKF assimilation 
nudging_day=5
DA_VAR=
restart_source=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40/date1
Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result
nextsim_data_dir=/cluster/work/users/chengsukun/nextsim_data_dir
OUTPUT_DIR=${simulations}/test_${Exp_ID}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
echo 'output path:' $OUTPUT_DIR
[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
# cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 
cp ${JOB_SETUP_DIR}/main5_1mem_interp_error_estimation.sh  ${OUTPUT_DIR} 
cp $slurm_nextsim_script  ${OUTPUT_DIR}  
cp -rf ${NEXTSIMDIR}/model ${OUTPUT_DIR}/nextsim_source_code 
# ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    if (( $iperiod ==1 )); then
        restart_from_analysis=false
        analysis_source=0
    else
        restart_from_analysis=true
        analysis_source=${ENSPATH}/filter/prior
        restart_source=${ENSPATH}
    fi
    time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
    echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + ${duration} day")"
# a. create files strucure, copy and modify configuration files inside
    ENSPATH=${OUTPUT_DIR}/date${iperiod}
    mkdir -p ${ENSPATH}
    input_path=$ENSPATH/inputs  # inputs exclude forcing, be consistent with input_path in part1_create_file_system.sh  
    source ${JOB_SETUP_DIR}/part1_create_file_system.sh

# b. submit the script for ensemble forecasts
    cd $ENSPATH
    cp ${slurm_nextsim_script} $ENSPATH/.
    for (( jj=1; jj<=2; jj++ )); do          # check for crashed member and resubmit
        count=0
        list=()
        for (( i=1; i<=$ENSSIZE; i++ )); do
            ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && count=$(($count+1)) && list=(${list[@]-} $i);
        done
        if (( $count >0 )); then
            (( jj==1 )) && link_restarts     $ENSSIZE   $restart_source      ${input_path} $analysis_source
            (( jj==1 )) && link_perturbation $ENSSIZE   $Perturbation_source ${input_path} $duration  $iperiod 45
            echo 'Try' $jj ', date' $iperiod ', start calculating member(s):' ${list[@]-} 
            #
            for (( i=1; i<=$ENSSIZE; i++ )); do                                
                cd $ENSPATH/mem${i}
                cp nextsim.cfg.backup nextsim.cfg
                grep -q -s "Simulation done" task.log && continue
                rm -rf *.nc *.log *.bin *.dat *.txt restart
                srun --nodes=1 --mpi=pmi2 -n128 $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg 2>&1 | tee task.log  &
                cp nextsim.cfg.backup nextsim.cfg
            done
            wait
        else
            break
        fi
    done
    # check for crashed member, report error and exit
    for (( i=1; i<=$ENSSIZE; i++ )); do
        ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && echo $ENSPATH'/mem'$i 'has crashed ' $(( $jj-1 )) ' times. EXIT' && exit
        
        # Pretend to have been assimilated, copy DA input prior.nc as its output
        rm -f ${NEXTSIM_DATA_DIR}/${memname}.nc.analysis
        cdo merge ${NEXTSIM_DATA_DIR}/reference_grid.nc  ${ENSPATH}/mem${i}/prior.nc  ${NEXTSIM_DATA_DIR}/${memname}.nc.analysis
        # cp ${ENSPATH}/mem${i}/prior.nc  ${NEXTSIM_DATA_DIR}/${memname}.nc.analysis
    done
    # restart_source=${ENSPATH}
done
cp ${JOB_SETUP_DIR}/deterministic.log  ${OUTPUT_DIR}
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}
echo "finished"