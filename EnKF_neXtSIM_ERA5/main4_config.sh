#!/bin/bash 
#----------------------  Experiment setup:parameters -------------------------------
# Exp_ID=sit7     
# DA_VAR=sit  
# duration=7    # forecast length; tduration*duration is the total simulation time
# tduration=26  # number of DA cycles.

# Exp_ID=sic7     
# DA_VAR=sic 
# duration=7    # forecast length; tduration*duration is the total simulation time
# tduration=26  # number of DA cycles. 

# Exp_ID=sic7sit7     
# DA_VAR=sitsic  
# duration=7    # forecast length; tduration*duration is the total simulation time
# tduration=26  # number of DA cycles. 

Exp_ID=sic3sit7     
DA_VAR=sitsic   
duration=1     # forecast length; tduration*duration is the total simulation time
tduration=182  # number of DA cycles. 

ENSSIZE=40    # ensemble size  
time_init0=2019-10-18   # starting date of simulation
start_from_restart=true
restart_from_analysis=true
UPDATE=1           # 1: active EnKF assimilation 
INFLATION=1
LOCRAD=300
RFACTOR=2
KFACTOR=2
nudging_day=15
#----------------------  Experiment setup: file directories -------------------------------
slurm_nextsim_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.ensemble.template.sh
slurm_enkf_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.enkf.template.sh

OUTPUT_DIR=/cluster/work/users/chengsukun/simulations/test_${Exp_ID}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}_d${nudging_day}_R$RFACTOR
restart_source=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40_OceanNudgingDd${nudging_day}/date1

Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result

analysis_source=${restart_source}/filter/size40_I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}_DA${DA_VAR}

restart_path=/cluster/work/users/chengsukun/tempory_link_files/$Exp_ID
