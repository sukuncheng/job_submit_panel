#!/bin/bash 
#-----------------  Experiment setup:parameters for DA runs-------------------------------
restart_from_analysis=true
UPDATE=1           # 1: active EnKF assimilation 

# Exp_ID=sit7     
# DA_VAR=sit  
# duration=7    # forecast length; tduration*duration is the total simulation time
# tduration=26  # number of DA cycles.

Exp_ID=sic7     
DA_VAR=sic 
duration=7    # forecast length; tduration*duration is the total simulation time
tduration=26  # number of DA cycles. 

#  Exp_ID=sic7sit7     
#  DA_VAR=sitsic  
#  duration=7    # forecast length; tduration*duration is the total simulation time
#  tduration=26  # number of DA cycles. 

# Exp_ID=sic1sit7     
# DA_VAR=sitsic   
# duration=1     # forecast length; tduration*duration is the total simulation time
# tduration=182  # number of DA cycles. 


# #  --------  settings for free run-----------------------
# Exp_ID=freerun     
# DA_VAR=   
# duration=45     # forecast length; tduration*duration is the total simulation time
# tduration=26     # number of DA cycles. 
# UPDATE=0           # 0: deactive EnKF assimilation 
# restart_from_analysis=false

#---------------common parameters ---------------- 
ENSSIZE=40    # ensemble size  
nudging_day=5
time_init0=2019-10-18   # starting date of simulation
start_from_restart=true
INFLATION=1
LOCRAD=300
RFACTOR=2
KFACTOR=2
#----------------------  Experiment setup: file directories ------------------------------- 
slurm_nextsim_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.ensemble.template.sh
slurm_enkf_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.enkf.template.sh

OUTPUT_DIR=/cluster/work/users/chengsukun/simulations/test_${Exp_ID}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}

restart_source=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40/date1
analysis_source=${restart_source}/filter/size40_I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}_DA${DA_VAR}

Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result

NEXTSIM_DATA_DIR=/cluster/work/users/chengsukun/nextsim_data_dir  # nextsim reserved key: path of general model input datasets
