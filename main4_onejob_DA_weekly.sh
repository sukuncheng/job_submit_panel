#!/bin/bash 
# script for submitting an ensemble run with DA(sic,sit, sitsic), restarting from spinup run, defined by main1_spinup_exp.sh
# Instruction:
# a. preprocess: Single thread, create file structure, prepare observations by enkf_prep 
# b. execute ensemble-DA cycles on job queue 
    
#set -ux  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

#----------------------  Experiment starting point -------------------------------
>nohup.out
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
source set_config.sh

##Experiment execution: a.preprocess ------------------------------- 
## a. create files strucure, copy and modify configuration files inside
#[ ! -d ${restart_path} ] && mkdir -p ${restart_path}  || rm -rf ${restart_path}/* 
#ln -sf ${NEXTSIM_DATA_DIR}/* ${restart_path}/ #note the slash '/' is necessary. It only links files not directory
##export NEXTSIM_DATA_DIR=${restart_path}
## [ -d $OUTPUT_DIR ] && rm -rf ${OUTPUT_DIR} 
#[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR} 
#cp ${JOB_SETUP_DIR}/{$(basename $BASH_SOURCE),main4_config.sh,link_restart_perturbation.sh,slurm_ensembleDA_script.sh,create_file_system.sh}  ${OUTPUT_DIR} 
#cp ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src ${OUTPUT_DIR}
#cp -r ${NEXTSIMDIR}/model ${OUTPUT_DIR}/nextsim_source_code
#
#for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
#    [[ $(( ($iperiod)%7 )) -eq 0 && $Exp_ID=='sic1sit7' ]] && DA_VAR=sitsic  || DA_VAR=sic
#    time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
#    ENSPATH=${OUTPUT_DIR}/date${iperiod}
#    [ ! -d ${ENSPATH} ] && mkdir -p ${ENSPATH}   
#    source ${JOB_SETUP_DIR}/create_file_system.sh   
#done
#
## preprocess: process observations to observations.nc by enkf-c: enkf_prep
#for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do    
#    cd ${OUTPUT_DIR}/date${iperiod}/filter
#    if ! grep -q -s "finished" prep.out
#    then        
#        make clean
#        srun -N1 -n1 -c1 --exact ./enkf_prep --no-superobing enkf.prm 2>&1 > prep.out &
#    fi
#done
#wait
#echo "finished files preprocess"

# Experiment execution: b. sbatch run jobs--------------------------       
# link restart files & perturbation files.
# submit jobs to queue 
 cd ${JOB_SETUP_DIR}
 >${Exp_ID}.log
 sbatch --job-name=$Exp_ID --output=${Exp_ID}.log  --output=${Exp_ID}.log slurm_ensembleDA_script.sh main4_config.sh link_restart_perturbation.sh
 cp ${JOB_SETUP_DIR}/{nohup.out,$Exp_ID.log}  ${OUTPUT_DIR}
 echo "finished"
