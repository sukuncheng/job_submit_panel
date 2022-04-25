#!/bin/bash 
# script for submitting an ensemble run with DA(sic,sit, sitsic), restarting from spinup run, defined by main1_spinup_exp.sh
# Instruction:
# a. preprocess: Single thread, create file structure, prepare observations by enkf_prep 
# b. execute ensemble-DA cycles on job queue 
    
# set -ux  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

#----------------------  Experiment starting point -------------------------------
>nohup.out
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
source main4_config.sh
source link_restart_perturbation.sh
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)


#---------------- Experiment execution: A.preprocess, use devel to process in parallel ------------------------------- 
# a. create files strucure, copy and modify configuration files inside
[ ! -d ${restart_path} ] && mkdir -p ${restart_path}  || rm -rf ${restart_path}/* 
ln -sf ${NEXTSIM_DATA_DIR}/* ${restart_path}/ #note the slash '/' is necessary. It only links files not directory
#export NEXTSIM_DATA_DIR=${restart_path}
# [ -d $OUTPUT_DIR ] && rm -rf ${OUTPUT_DIR} 
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR} 
cp ${JOB_SETUP_DIR}/{$(basename $BASH_SOURCE),main4_config.sh,link_restart_perturbation.sh,slurm*.sh,create_file_system.sh}  ${OUTPUT_DIR} 
cp ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src ${OUTPUT_DIR}
cp -r ${NEXTSIMDIR}/model ${OUTPUT_DIR}/nextsim_source_code

# for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
#     [[ $(( ($iperiod)%7 )) -eq 0 && $Exp_ID=='sic1sit7' ]] && DA_VAR=sitsic  || DA_VAR=sic
#     time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
#     ENSPATH=${OUTPUT_DIR}/date${iperiod}
#     [ ! -d ${ENSPATH} ] && mkdir -p ${ENSPATH}   
#     source ${JOB_SETUP_DIR}/create_file_system.sh
# done

# # preprocess: process observations to observations.nc by enkf-c: enkf_prep
# for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
#     cd ${OUTPUT_DIR}/date${iperiod}/filter
#     if ! grep -q -s "finished" prep.out
#     then        
#         make clean
#         srun -N1 -n1 ./enkf_prep --no-superobing enkf.prm 2>&1 > prep.out &
#         echo $iperiod
#     fi
# done
# wait

# ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
    echo "period ${time_init} to $(date +%Y-%m-%d -d "${time_init} + ${duration} day")"
    ENSPATH=${OUTPUT_DIR}/date${iperiod}
    cd $ENSPATH
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
            echo $ENSPATH
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
            sbatch -W --time=0-0:$Time:0 --nodes=$Nnode $slurm_nextsim_script ${ENSPATH} ${ENSSIZE}  $Nnode $restart_path
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
        sbatch -W $slurm_enkf_script ${ENSPATH}
        wait
    fi
    analysis_source=${ENSPATH}/filter/prior
    restart_source=${ENSPATH}
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}
echo "finished"
