#!/bin/bash 
# script for submitting an ensemble run with DA(sic,sit, sitsic), restarting from spinup run, defined by main1_spinup_exp.sh

# Instruction:
# create workpath
# call part1_create_file_system.sh to modify nextsim.cfg and enkf settings to workpath
# link restart files &perturbation files.
# submit jobs to queue by slurm_nextsim_script from workpath.

# set -ux  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

##-------  Confirm working,data,ouput directories --------
>nohup.out  # empty this file
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
slurm_nextsim_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.ensemble.template.sh
slurm_enkf_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.enkf.template.sh
source ./link_restart_perturbation.sh
##-------  Confirm working,data,ouput directories --------
# experiment settings
ENSSIZE=40      # ensemble size  
time_init0=2019-10-18   # starting date of simulation
duration=7      # forecast length; tduration*duration is the total simulation time
tduration=26    # number of DA cycles. 
Exp_ID=sic7     # sit7,sic7sit7
DA_VAR=sic      # sit, sicsit
start_from_restart=true
restart_from_analysis=true
UPDATE=1           # 1: active EnKF asrezsimilation 
INFLATION=1
LOCRAD=300
RFACTOR=2
KFACTOR=2

nudging_day=5
restart_source=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40_OceanNudgingDd${nudging_day}/date1
Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result
analysis_source=${restart_source}/filter/size40_I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}_DA${DA_VAR}
restart_path=/cluster/work/users/chengsukun/tempory_link_files/$Exp_ID
[ ! -d ${restart_path} ] && mkdir -p ${restart_path}  || rm -rf ${restart_path}/*
ln -sf ${NEXTSIM_DATA_DIR}/* ${restart_path}/ #note the slash '/' is necessary. It only links files not directory
export NEXTSIM_DATA_DIR=${restart_path}
OUTPUT_DIR=${simulations}/test_${Exp_ID}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
echo 'work path:' $OUTPUT_DIR
[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR 
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

# b. submit the script for ensemble forecasts
    cd $ENSPATH
    cp $slurm_nextsim_script $ENSPATH/.

#------------------
    # check for crashed member and resubmit
    for (( jj=1; jj<=2; jj++ )); do
        count=0
        list=()
        for (( i=1; i<=$ENSSIZE; i++ )); do
            ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && count=$(($count+1)) && list=(${list[@]-} $i);
        done
        if (( $count >0 )); then
            (( jj==1 )) && link_restarts     $ENSSIZE   $restart_source      $restart_path $analysis_source
            (( jj==1 )) && link_perturbation $ENSSIZE   $Perturbation_source $restart_path $duration  $iperiod 
            echo 'Try' $jj ', date' $iperiod ', start calculating member(s):' ${list[@]-} 
            # dynamically request nodes based on the number of idle node
            idle_node=`sinfo --states=idle | grep normal | grep idle | awk '{print $4}'`
            dt=$((1*$duration+5))  # unit time cost of a member, in minutes
            if (( $count<=$idle_node )); then
                Nnode=$count
                Time=$dt
            else
                Numbers=(4 5 8 10 20 40)
                for (( id=1; id<${#Numbers[@]}; id++ )); do
                    if (( ${Numbers[id]}> $idle_node )); then                        
                        Nnode=${Numbers[id-1]}
                        break
                    fi
                done
                Time=$(( $dt*$count/$Nnode ))
            fi
            (( $Nnode<4 )) && Nnode=4  
            echo "request nodes and time/node: " $Nnode ", " $Time
            sbatch -W --time=0-0:$Time:0 --nodes=$Nnode $slurm_nextsim_script ${ENSPATH} ${ENSSIZE}  $Nnode
            # sbatch -W --time=0-0:$Time:0 --nodes=1 --qos=devel $slurm_nextsim_script ${ENSPATH} ${ENSSIZE}  $Nnode
            wait
        else
            break
        fi
    done
    # check for crashed member, report error and exit
    for (( i=1; i<=$ENSSIZE; i++ )); do
        ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && echo $ENSPATH'/mem'$i 'has crashed ' $(( $jj-1 )) ' times. EXIT' && exit
    done
    #------------------
    ## 2.submit enkf after finishing the ensemble simulations 
    if [ ${UPDATE} == 1 ] && ! grep -q -s "finished" ${ENSPATH}/filter/update.out ; then  
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            cp ${ENSPATH}/mem${i}/prior.nc  ${ENSPATH}/filter/prior/$(printf "mem%.3d" $i).nc
        done          
        cp $slurm_enkf_script ${ENSPATH}/.
        # Do EnKF
        sbatch $slurm_enkf_script ${ENSPATH}
        wait
    fi
    analysis_source=${ENSPATH}/filter/prior
    restart_source=${ENSPATH}
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}
echo "finished"



# function WaitforTaskFinish(){
#     # ------ wait the completeness in this cycle.
#     ENSSIZE=$1
#     count=0
#     while [[ $count -lt $ENSSIZE ]]; do 
#         for (( i=0; i<$ENSSIZE; i++ )); do
#             grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && count=$(( $count+1 ))            
#         done
#         sleep 30        
#     done
# }
# # 
# jstat=$(squeue -u chengsukun |grep $jid |awk '{print $5}')
# #if $jstat == 'R'
# #if $jstat == 'CG'

# sbatch --time=0-0:10:0   $script $ENSPATH $ENV_FILE ${ENSSIZE} > job_submit.log
# jid=$(cat job_submit.log |awk '{print $4}')
# WaitforTaskFinish $jstat

# function WaitforTaskFinish(){
#     # ------ wait the completeness in this cycle.
#     XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 	
#     while [[ $XPID -gt $1 ]]; do 
#         sleep 60
#         XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) # number of running jobs 
#     done
# }

# function WaitforTaskFinish(){
#     # ------ wait the completeness in this cycle.
#     XPID=0
#     while [[ $XPID -gt $1 ]]; do 
#         sleep 30
#         XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) # number of running jobs 
#     done
# }
