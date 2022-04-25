#!/bin/bash 
# script for submitting an ensemble run without DA, restarting from a restart file.

# Instruction:
# create workpath
# link perturbation file
# call create_file_system.sh to modify nextsim.cfg and enkf settings to workpath
# submit jobs to queue by slurm_nextsim_script from workpath, in which link restart files.

set -eux  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

function link_perturbation(){ 
    # note the index 180=45*4 correspond to the last perturbation used in the end of spinup run
    day0=0 # for spinup day0=0
    echo "links perturbation files to nextsim_data_dir/Perturbation using input file id"
    # The number is calculated ahead as Nfiles +1
    nextsim_data_dir=$1
    duration=$2
    iperiod=$3
    ENS_ID=$4
    # ENSSIZE=$4

    [ ! -d ${nextsim_data_dir}/Perturbations ] && mkdir -p ${nextsim_data_dir}/Perturbations || rm -f ${nextsim_data_dir}/Perturbations/*.nc
    Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result
    
    # for (( i=1; i<=${ENSSIZE}; i++ )); do
    i=$ENS_ID
        memname=mem${i}    
        # link data sources based on different loading frequencies
        # atmoshphere
        Nfiles=$(( $duration*4+1))  # number of perturbations to linkf
        for (( j=0; j<=${Nfiles}; j++ )); do  #+1 is because an instance could end at 23:45 or 24:00 for different members due to ? +1 corresponds to the longer one.
            ln -sf ${Perturbation_source}/${memname}/synforc_$((${j}+$day0*4 + ($iperiod-1)*($Nfiles-1) )).nc  ${nextsim_data_dir}/Perturbations/AtmospherePerturbations_${memname}_series${j}.nc
        done
        # ocean 
        Nfiles=$duration+1  # topaz data is loaded at 12:00pm. 
        for (( j=0; j<=${Nfiles}; j++ )); do
            ln -sf ${Perturbation_source}/${memname}/synforc_$((${j}+$day0 + ($iperiod-1)*$Nfiles)).nc  ${nextsim_data_dir}/Perturbations/OceanPerturbations_${memname}_series${j}.nc
        done
    # done
}

#-------  Confirm working,data,ouput directories --------
>nohup.out        # empty this file
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)                          # 
slurm_nextsim_script=${JOB_SETUP_DIR}/slurm.ensemble.template.sh

# experiment configuration
Exp_ID=spinup
ENSSIZE=4      # ensemble size  
time_init=2019-09-03   # starting date of simulatio
duration=2      # forecast length; tduration*duration is the total simulation time
tduration=1     # number of DA cycles. 
start_from_restart=false
restart_from_analysis=false
UPDATE=0        # 1: active EnKF assimilation 
nudging_day=30   # 15,15,25,35,45
DA_VAR=

basename=20190903T000000Z # set this variable associated with time_init for a restart run
restart_source=$HOME/src/restart
#
OUTPUT_DIR=${simulations}/test_${Exp_ID}_${time_init}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
echo 'creating work path:' $OUTPUT_DIR
[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 
cp $slurm_nextsim_script  ${OUTPUT_DIR}  
cp -rf $NEXTSIMDIR/model ${OUTPUT_DIR}/nextsim_source_code 

# ----------- execute ensemble runs ----------
# nextsim_data_dir=/cluster/work/users/chengsukun/tempory_link_files/$Exp_ID   # select a folder for exchange restart data
# [ ! -d ${nextsim_data_dir} ] && mkdir ${nextsim_data_dir} 
# rm -f  $nextsim_data_dir/{field_mem* mesh_mem* WindPerturbation_mem* *.nc.analysis}
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + ${duration} day")"

    ENSPATH=${OUTPUT_DIR}/date${iperiod}

# link forcing to each member directory
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}
        MEM_DATA_DIR=${ENSPATH}/mem${i}/data
        mkdir -p ${MEM_DATA_DIR}
        cd ${MEM_DATA_DIR}
        ln -sf /cluster/work/users/chengsukun/ERA5_reanalysis  ./ERA5
        ln -sf /cluster/work/users/chengsukun/TIGGE/ens${i}  ./TIGGE
        ln -sf /cluster/work/users/chengsukun/nextsim_data_dir/*   .

        nextsim_data_dir=${MEM_DATA_DIR}
        if ${start_from_restart}; then
            ln -sf ${restart_source}/field_${basename}.bin  $nextsim_data_dir/field_${memname}.bin
            ln -sf ${restart_source}/field_${basename}.dat  $nextsim_data_dir/field_${memname}.dat
            ln -sf ${restart_source}/mesh_${basename}.bin   $nextsim_data_dir/mesh_${memname}.bin
            ln -sf ${restart_source}/mesh_${basename}.dat   $nextsim_data_dir/mesh_${memname}.dat
        fi
        link_perturbation $nextsim_data_dir $duration $iperiod $i   
    done  
    
# create configuration files
    source ${JOB_SETUP_DIR}/create_file_system.sh
# submit
    Nnode=$ENSSIZE        
    sbatch -W --time=0-0:30:0 --nodes=$Nnode $slurm_nextsim_script ${ENSPATH} ${ENSSIZE}  ${Nnode}    
    wait
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}    
  
echo "finished"
