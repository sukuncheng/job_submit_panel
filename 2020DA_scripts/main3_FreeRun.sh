#!/bin/bash 
# script for submitting an ensemble run without DA, restarting from spinup run, defined by main1_spinup_exp.sh

# create workpath
# link restart file
# call part1_create_file_system.sh to file nextsim.cfg and mkdir folder infrastruce
# submit jobs to queue by slurm_nextsim_script from workpath

# set -ux  # uncomment for debugging, it causes error: unbounded variable https://www.coder.work/article/2569773
err_report() {
   echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

# 
function link_restarts(){
    #echo "project *.nc.analysis on reference_grid.nc, links restart files to $restart_path for next DA cycle"
    ENSSIZE=$1  
    ENSPATH=$2
    FILTER=$2/filter  
    restart_path=$3
    analysis_source=$4

    rm -f  $restart_path/{field_mem* mesh_mem* WindPerturbation_mem* *.nc.analysis}    
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}
    #    ln -sf ${ENSPATH}/${memname}/WindPerturbation_${memname}.nc         ${restart_path}/WindPerturbation_${memname}.nc  
        ln -sf ${ENSPATH}/${memname}/restart/field_final.bin  $restart_path/field_${memname}.bin
        ln -sf ${ENSPATH}/${memname}/restart/field_final.dat  $restart_path/field_${memname}.dat
        ln -sf ${ENSPATH}/${memname}/restart/mesh_final.bin   $restart_path/mesh_${memname}.bin
        ln -sf ${ENSPATH}/${memname}/restart/mesh_final.dat   $restart_path/mesh_${memname}.dat
    done  

# link reanalysis
    [ ! -d ${analysis_source} ] && return;    
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}    
        [ ! -f ${analysis_source}/${memname}.nc.analysis ] && cdo merge ${NEXTSIM_DATA_DIR}/reference_grid.nc  ${analysis_source}/$(printf "mem%.3d" $i).nc.analysis  ${analysis_source}/${memname}.nc.analysis         
        ln -sf ${analysis_source}/${memname}.nc.analysis          $restart_path/${memname}.nc.analysis
    done
}

function link_perturbation(){ 
    # note the index 180=45*4 correspond to the last perturbation used in the end of spinup run
    echo "links perturbation files to $restart_path/Perturbation using input file id"
    # The number is calculated ahead as Nfiles +1
    restart_path=$1
    duration=$2
    iperiod=$3
    ENSSIZE=$4

    [ ! -d ${restart_path}/Perturbations ] && mkdir -p ${restart_path}/Perturbations || rm -f ${restart_path}/Perturbations/*.nc
    Perturbations_Dir=/cluster/work/users/chengsukun/offline_perturbations/result

    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}    
        # link data sources based on different loading frequencies
        # atmoshphere
        Nfiles=$(( $duration*4+1))  # number of perturbations to link
        for (( j=0; j<=${Nfiles}; j++ )); do  #+1 is because an instance could end at 23:45 or 24:00 for different members due to ? +1 corresponds to the longer one.
            ln -sf ${Perturbations_Dir}/${memname}/synforc_$((${j}+45*4 + ($iperiod-1)*($Nfiles-1) )).nc  ${restart_path}/Perturbations/AtmospherePerturbations_${memname}_series${j}.nc
        done
        # ocean 
        Nfiles=$duration+1  # topaz data is loaded at 12:00pm. 
        for (( j=0; j<=${Nfiles}; j++ )); do
            ln -sf ${Perturbations_Dir}/${memname}/synforc_$((${j}+45   + ($iperiod-1)*$Nfiles)).nc  ${restart_path}/Perturbations/OceanPerturbations_${memname}_series${j}.nc
        done
    done
}

##-------  Confirm working,data,ouput directories --------
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
slurm_nextsim_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.ensemble.template.sh
slurm_enkf_script=${NEXTSIM_ENV_ROOT_DIR}/slurm.enkf.template.sh

restart_path=$NEXTSIM_DATA_DIR   # select a folder for exchange restart data
##-------  Confirm working,data,ouput directories --------
# experiment settings
first_restart_path=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40_offline_perturbations/date1
time_init0=2019-10-18   # starting date of simulation
duration=7      # forecast length; tduration*duration is the total simulation time
tduration=26    # number of DA cycles. 
ENSSIZE=40         # ensemble size  

UPDATE=0           # 1: active EnKF assimilation 
DA_VAR=
restart_from_analysis=false   

>nohup.out  # empty this file
OUTPUT_DIR=${simulations}/test_FreeRun_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}_offline_perturbations
echo 'work path:' $OUTPUT_DIR
#[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 

## ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    start_from_restart=true
    if [ $iperiod -eq 1 ]; then  # prepare and link restart files
        analysis_source=0
        link_restarts $ENSSIZE   $first_restart_path  $restart_path $analysis_source
    fi

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
    for (( k=1; k<=3; k++ )); do            
            count=0
            list=()
            for (( i=1; i<=$ENSSIZE; i++ )); do
                ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && count=$(($count+1)) && list=(${list[@]-} $i);
            done
            echo $k $count
            if (( $count >0 )); then
		        echo 'Try' $k ', date' $iperiod ', start calculating member(s):' ${list[@]-} 
                # dynamically request nodes based on the number of idle node
                idle_node=`sinfo --states=idle | grep normal | grep idle | awk '{print $4}'`
            	dt=10  # unit time cost of a member, in minutes
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
                    Time=$(( $dt*($count+$Nnode-1)/$Nnode ))
                fi
		        (( $Nnode<4 )) && Nnode=4  
                (( k==1 )) && link_perturbation $restart_path $duration $iperiod $ENSSIZE  # link perturbation files  
                echo "request nodes and time/node: " $Nnode ", " $Time   
                sbatch -W --time=0-0:$Time:0 --nodes=$Nnode $slurm_nextsim_script ${ENSPATH} ${ENSSIZE}  $Nnode
                wait
            else
                break
            fi
        done
    # check for crashed member, report error and exit
    for (( i=1; i<=$ENSSIZE; i++ )); do
            ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && echo $ENSPATH'/mem'$i 'has crashed ' $(( $k-1 )) ' times. EXIT' && exit
    done
    #------------------
    analysis_source=0
    link_restarts $ENSSIZE   $ENSPATH  $restart_path $analysis_source
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
