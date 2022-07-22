#!/bin/bash 
# script for submitting an ensemble run without DA, restarting from a restart file.

# Instruction:
# create workpath
# link perturbation file
# call part1_create_file_system.sh to modify nextsim.cfg and enkf settings to workpath
# submit jobs to queue by slurm_nextsim_script from workpath, in which link restart files.

# set -uex  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

##-------  Confirm working,data,ouput directories --------
>nohup.out  # empty this file
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)
slurm_nextsim_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.ensemble.template.sh
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
source link_restart_perturbation.sh

##-------  Confirm working,data,ouput directories --------
# experiment settings
ENSSIZE=40      # ensemble size  
time_init=2019-09-03   # starting date of simulatio
duration=45     # forecast length; tduration*duration is the total simulation time
tduration=1     # number of DA cycles. 

start_from_restart=true
restart_from_analysis=false
UPDATE=0        # 1: active EnKF assimilation 

Exp_ID=spinup
nudging_day=5  #15,15,25,35,45
DA_VAR=
analysis_source=0
restart_source=$HOME/src/restart
basename=20190903T000000Z # set this variable, if the first run is from restart
Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result
nextsim_data_dir=/cluster/work/users/chengsukun/nextsim_data_dir
# restart_path=${OUTPUT_DIR}/tempory_link_files   # select a folder for exchange restart data
# [ ! -d ${restart_path} ] && mkdir ${restart_path} 
# rm -f  $restart_path/{field_mem* mesh_mem* WindPerturbation_mem* *.nc.analysis}
OUTPUT_DIR=${simulations}/test_${Exp_ID}_${time_init}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
echo 'output path:' $OUTPUT_DIR
[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 
cp -rf ${NEXTSIMDIR}/model ${OUTPUT_DIR}/nextsim_source_code 
# ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + ${duration} day")"
# a. create files strucure, copy and modify configuration files inside
    ENSPATH=${OUTPUT_DIR}/date${iperiod}
    mkdir -p ${ENSPATH}   
    input_path=$ENSPATH/inputs  # inputs exclude forcing, be consistent with input_path in part1_create_file_system.sh  
    source ${JOB_SETUP_DIR}/part1_create_file_system.sh
    # link perturbation & link_restart     
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        if $start_from_restart; then
            memname=mem${i}
            mkdir -p ${input_path}
            ln -sf ${restart_source}/field_${basename}.bin  ${input_path}/field_${memname}.bin
            ln -sf ${restart_source}/field_${basename}.dat  ${input_path}/field_${memname}.dat
            ln -sf ${restart_source}/mesh_${basename}.bin   ${input_path}/mesh_${memname}.bin
            ln -sf ${restart_source}/mesh_${basename}.dat   ${input_path}/mesh_${memname}.dat
        fi
    done  
    link_perturbation $ENSSIZE   $Perturbation_source ${input_path} $duration  $iperiod 0

# b. submit the script for ensemble forecasts
    cd $ENSPATH
    cp $slurm_nextsim_script $ENSPATH/.
    for (( jj=1; jj<=2; jj++ )); do          # check for crashed member and resubmit
        count=0
        list=()
        for (( i=1; i<=$ENSSIZE; i++ )); do
            ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && count=$(($count+1)) && list=(${list[@]-} $i);
        done
        if (( $count >0 )); then
            echo 'Try' $jj ', date' $iperiod ', start calculating member(s):' ${list[@]-} 
            # dynamically request nodes based on the number of idle node
            idle_node=`sinfo --states=idle | grep normal | grep idle | awk '{print $4}'`
            if (( $count<=$idle_node )); then
                Nnode=$count
            else
                Numbers=(8 10 20 40)
                for (( id=1; id<${#Numbers[@]}; id++ )); do
                    if (( ${Numbers[id]}> $idle_node )); then                        
                        Nnode=${Numbers[id-1]}
                        break
                    fi
                done
            fi
            (( $Nnode<4 )) && Nnode=4  
            sbatch -W --time=0-0:50:0 --nodes=$Nnode $slurm_nextsim_script ${ENSPATH} ${ENSSIZE}  $Nnode ${nextsim_data_dir}            
            wait
        else
            break
        fi
    done
    # check for crashed member, report error and exit
    for (( i=1; i<=$ENSSIZE; i++ )); do
        ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && echo $ENSPATH'/mem'$i 'has crashed ' $(( $jj-1 )) ' times. EXIT' && exit
    done
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}
echo "finished"