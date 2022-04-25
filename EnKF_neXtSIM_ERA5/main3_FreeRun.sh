#!/bin/bash 
# ======================================================
#SBATCH --account=nn2993k      #nn9481k #nn9878k   # #nn2993k   #ACCOUNT_NUMBER
#SBATCH --job-name=freerun
#SBATCH --time=0-5:0:0        #dd-hh:mm:ss, # Short request job time can be accepted easier.
##SBATCH --qos=devel          # preproc, devel, short and normal if comment this line,  https://documentation.sigma2.no/jobs/job_types/fram_job_types.html
#SBATCH --nodes=40             # request number of nodes
#SBATCH --ntasks-per-node=128  # MPI parallel thread size
#SBATCH --cpus-per-task=1      #
#SBATCH --output=$SLURM_JOB_NAME.log         # Stdout
#SBATCH --error=$SLURM_JOB_NAME.log          # Stderr
# ======================================================

# script for submitting an ensemble run without DA, restarting from spinup run, defined by main1_spinup_exp.sh
# Instruction:
# create file structure 
# call part1_create_file_system.sh to modify nextsim.cfg and enkf settings to workpath
# link restart files &perturbation files.
# submit jobs to queue by slurm_nextsim_script from workpath.

# set -ux  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
   echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

##-------  Confirm working,data,ouput directories --------
JOB_SETUP_DIR=/cluster/home/chengsukun/src/job_submit_panel/2020DA_scripts  #$(cd `dirname $BASH_SOURCE`;pwd)
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
source ./link_restart_perturbation.sh
##-------  Confirm working,data,ouput directories --------
# experiment settings
ENSSIZE=40      # ensemble size  
time_init0=2019-10-18   # starting date of simulation
duration=7      # forecast length; tduration*duration is the total simulation time
tduration=26    # number of DA cycles. 
Exp_ID=$SLURM_JOB_NAME
DA_VAR=
start_from_restart=true
restart_from_analysis=false   
UPDATE=0        # 1: active EnKF assimilation 

# days=( 5 15 25 )
# for nudging_day in "${days[@]}"; do
nudging_day=5    
    restart_source=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40_OceanNudgingDd${nudging_day}/date1
    Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result
    analysis_source=0
    restart_path=/cluster/work/users/chengsukun/tempory_link_files/${Exp_ID}_${nudging_day}
    [ ! -d ${restart_path} ] && mkdir -p ${restart_path}
    ln -sf ${NEXTSIM_DATA_DIR}/* ${restart_path}/ #note the slash '/' is necessary. It only links files not directory
    export NEXTSIM_DATA_DIR=${restart_path}
    OUTPUT_DIR=${simulations}/test_${Exp_ID}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}_OceanNudgingDd${nudging_day}
    echo 'work path:' $OUTPUT_DIR
    #[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
    [ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
    cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 
    cp -rf ${NEXTSIMDIR}/model ${OUTPUT_DIR}/nextsim_source_code 
    # ----------- execute ensemble runs ----------
    for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
        time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
        echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + ${duration} day")"
    # a. create files strucure, copy and modify configuration files inside
        ENSPATH=${OUTPUT_DIR}/date${iperiod}
        mkdir -p ${ENSPATH}   
        source ${JOB_SETUP_DIR}/part1_create_file_system.sh

    # b. execute simulation
        cd $ENSPATH
        Nnode=40
        for (( jj=1; jj<=2; jj++ )); do          # check for crashed member and resubmit
            count=0
            list=()
            for (( i=1; i<=$ENSSIZE; i++ )); do
                ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && count=$(($count+1)) && list=(${list[@]-} $i);
            done
            if (( $count >0 )); then
                (( jj==1 )) && link_restarts     $ENSSIZE   $restart_source      $restart_path $analysis_source
                (( jj==1 )) && link_perturbation $ENSSIZE   $Perturbation_source $restart_path $duration  $iperiod 
                echo 'Try' $jj ', date' $iperiod ', start calculating member(s):' ${list[@]-} 
                #
                for (( i=1; i<=$ENSSIZE; i++ )); do                                
                    cd $ENSPATH/mem${i}
                    cp nextsim.cfg nextsim.cfg.backup
                    grep -q -s "Simulation done" task.log && continue
                    rm -rf *.nc *.log *.bin *.dat *.txt restart
                    srun --nodes=1 --mpi=pmi2 -n128 $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg 2>&1 | tee task.log  &    
                    (( $i%$Nnode==0 )) && wait    
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
        done
        restart_source=${ENSPATH}
    done
    cp ${JOB_SETUP_DIR}/${SLURM_JOB_NAME}.log  ${OUTPUT_DIR}
# done
echo "finished"