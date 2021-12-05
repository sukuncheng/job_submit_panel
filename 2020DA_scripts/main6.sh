#!/bin/bash 
# ======================================================
#SBATCH --account=nn2993k      #nn9481k #nn9878k   # #nn2993k   #ACCOUNT_NUMBER
#SBATCH --job-name=sic1sit7
#SBATCH --time=0-5:0:0        #dd-hh:mm:ss, # Short request job time can be accepted easier.
##SBATCH --qos=devel          # preproc, devel, short and normal if comment this line,  https://documentation.sigma2.no/jobs/job_types/fram_job_types.html
#SBATCH --nodes=40             # request number of nodes
#SBATCH --ntasks-per-node=128  # MPI parallel thread size
#SBATCH --cpus-per-task=1      #
#SBATCH --output=sic1sit7_slurm%j.log         # Stdout
#SBATCH --error=sic1sit7_slurm%j.log          # Stderr
# ======================================================

# script for submitting an ensemble run with DA(sic,sit, sitsic), restarting from spinup run, defined by main1_spinup_exp.sh
# Instruction:
# a. preprocess: Single thread, create file structure, prepare observations by enkf_prep 
# b. execute ensemble-DA cycles on job queue 

# set -ux  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

#----------------------  Experiment setup:parameters -------------------------------
JOB_SETUP_DIR=/cluster/home/chengsukun/src/job_submit_panel/2020DA_scripts  #$
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
source ./link_restart_perturbation.sh
# experiment settings
Exp_ID=sic1sit7 
DA_VAR=sitsic      # start from sic da results
ENSSIZE=40         # ensemble size 
time_init0=2019-10-18   # starting date of simulation
duration=1      # forecast length; tduration*duration is the total simulation time
tduration=182   # number of DA cycles. 
start_from_restart=true
restart_from_analysis=true
UPDATE=1           # 1: active EnKF assimilation 
INFLATION=1
LOCRAD=300
RFACTOR=2
KFACTOR=2
nudging_day=5
#----------------------  Experiment setup: file directories -------------------------------
restart_source=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40_OceanNudgingDd${nudging_day}/date1
Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result
analysis_source=${restart_source}/filter/size40_I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}_DA${DA_VAR}
restart_path=/cluster/work/users/chengsukun/tempory_link_files/$Exp_ID
[ ! -d ${restart_path} ] && mkdir -p ${restart_path}  || rm -rf ${restart_path}/*
ln -sf ${NEXTSIM_DATA_DIR}/* ${restart_path}/ #note the slash '/' is necessary. It only links files not directory
export NEXTSIM_DATA_DIR=${restart_path}
OUTPUT_DIR=${simulations}/test_${Exp_ID}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
echo 'work path:' $OUTPUT_DIR
#[ -d $OUTPUT_DIR ] && rm -rf ${OUTPUT_DIR} 
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR} 
cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 
cp -rf ${NEXTSIMDIR}/model ${OUTPUT_DIR}/nextsim_source_code 

# #----------------------  Experiment execution: a.preprocess ------------------------------- 
# # a. create files strucure, copy and modify configuration files inside
# for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
# [ $(($iperiod%7)) -eq 0 ] && DA_VAR=sitsic  || DA_VAR=sic  
#     time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
#     ENSPATH=${OUTPUT_DIR}/date${iperiod}
#     mkdir -p ${ENSPATH}   
#     source ${JOB_SETUP_DIR}/part1_create_file_system.sh
# done

# #----------------------  Experiment execution: b. sbatch run jobs--------------------------       
# link restart files &perturbation files.
# submit jobs to queue by slurm_nextsim_script from workpath.
sbatch slurm_ensembleDA_script.sh 
mv ${JOB_SETUP_DIR}/$Exp_ID.log  ${OUTPUT_DIR}
echo "finished"
