#!/bin/bash 
# script for submitting an ensemble run with DA(sic,sit, sitsic), restarting from spinup run, defined by main1_spinup_exp.sh
# Instruction:
# a. preprocess: Single thread, create file structure, prepare observations by enkf_prep 
# b. execute ensemble-DA cycles on job queue 
    
# set -uex  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

#----------------------  Experiment starting point -------------------------------
>nohup.out
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)
source ~/src/nextsim.ensemble.intel.src
source main4_config.sh

#  #Experiment execution: part 1 .preprocess files structures ------------------------------- 
#  # a. create files strucure, copy and modify configuration files inside
#  # [ -d $OUTPUT_DIR ] && rm -rf ${OUTPUT_DIR} 
#  [ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR} 
#  cp ${JOB_SETUP_DIR}/{$(basename $BASH_SOURCE),main4_config.sh,link_restart_perturbation.sh,slurm_ensembleDA_script.sh,part1_create_file_system.sh}  ${OUTPUT_DIR} 
#  cp ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src ${OUTPUT_DIR}
#  cp -r ${NEXTSIMDIR}/model ${OUTPUT_DIR}/nextsim_source_code

#  for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
#     [[ $(( ($iperiod)%7 )) -eq 0 && $Exp_ID=='sic1sit7' ]] && DA_VAR=sitsic  || DA_VAR=sic
#     time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
#     ENSPATH=${OUTPUT_DIR}/date${iperiod}
#     input_path=$ENSPATH/inputs  # model inputs exclude forcing, be consistent with input_path in part1_create_file_system.sh 
#     [ ! -d ${input_path} ] && mkdir -p ${input_path}  
#     source ${JOB_SETUP_DIR}/part1_create_file_system.sh   
#  done
#  # b. preprocess: process observations to observations.nc by enkf-c: enkf_prep
#  for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do    
#     cd ${OUTPUT_DIR}/date${iperiod}/filter
#     if ! grep -q -s "finished" prep.out
#     then        
#         make clean
#          ./enkf_prep --no-superobing enkf.prm 2>&1 > prep.out &
#          # srun -N1 -n1 -c1 --exact ./enkf_prep --no-superobing enkf.prm 2>&1 > prep.out &
#     fi
#  done
#  wait
#  echo "finished part1 files preprocess"

# Experiment execution: b. sbatch run jobs--------------------------       
# link restart files & perturbation files.
# submit jobs to queue 

# # In sic1sit7, fix  osisaf drift only has one time output
# for (( iperiod=1; iperiod<=182; iperiod++ )); do
#     for (( i=1; i<=${ENSSIZE}; i++ )); do
#         cd ${OUTPUT_DIR}/date${iperiod}/mem${i}       
#         sed -i "s/^duration=.*$/duration=${duration}/g; \
#                s/^write_final_restart.*$/write_final_restart=false/g; \
#                 s/^log-level=debug$/#log-level=debug/g" \
#                 nextsim.cfg.backup 
#         cp nextsim.cfg.backup nextsim.cfg
#     done
# done

# # part 2
#  cd ${JOB_SETUP_DIR}
#  >${Exp_ID}.log
# # ./slurm_ensembleDA_script.sh main4_config.sh link_restart_perturbation.sh
#  sbatch --job-name=$Exp_ID --output=${Exp_ID}.log  --output=${Exp_ID}.log slurm_ensembleDA_script.sh main4_config.sh link_restart_perturbation.sh
#  wait
#  cp ${JOB_SETUP_DIR}/{nohup.out,$Exp_ID.log}  ${OUTPUT_DIR}
#  echo " part2 ensemble simulations have been submitted"

# ##part3, in member folder, move Osisaf_drift.nc files to a subfolder
# for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
#     time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*1)) day")
#     date=$(date +%Y%m%d -d "${time_init0} + $((($iperiod-1)*1)) day")
#     echo $date
#     for (( i=1; i<=${ENSSIZE}; i++ )); do
#         cd ${OUTPUT_DIR}/date${iperiod}/mem${i}    
#         [ ! -d Osisaf_drift ] && mkdir Osisaf_drift
#         mv OSISAF_Drifters_*.nc Osisaf_drift/
#         cp Osisaf_drift/OSISAF_Drifters_$date.nc .
#     done
# done
