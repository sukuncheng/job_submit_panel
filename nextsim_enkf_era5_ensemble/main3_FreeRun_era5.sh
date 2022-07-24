#!/bin/bash 
#  ======================================================
#SBATCH --account=nn2993k  #nn9481k #nn9878k   # #nn2993k   #ACCOUNT_NUMBER
#SBATCH --job-name=era5_freerun
#SBATCH --time=0-10:0:0        #dd-hh:mm:ss, # Short request job time can be accepted easier.
##SBATCH --qos=devel           # preproc, devel, short and normal if comment this line,  https://documentation.sigma2.no/jobs/job_types/fram_job_types.html
#SBATCH --nodes=40             # request number of nodes
#SBATCH --ntasks-per-node=128  # MPI parallel thread size
#SBATCH --cpus-per-task=1      #
#SBATCH --output=$SLURM_JOB_NAME.log         # Stdout
#SBATCH --error=$SLURM_JOB_NAME.log          # Stderr
# ======================================================
# Instruction:
# script for submiting an ensemble run without DA, restarting from spinup run, defined by main1_spinup_exp.sh
# restart per 7 days to keep same run stucture for postprocessing
# for spin-up
# cd ~/src/restart$ 
# cp  field_20190903T000000Z.dat_youngold field_20190903T000000Z.dat
# cd ~/src/nextsim/modules/enkf/enkf-c/arch
# cp make.inc.betzy-intel ../make.inc
# cd ~/src/nextsim; make fresh -j16

set -uex  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

##-------  Confirm working,data,ouput directories --------
>nohup.out  # empty this file
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd) 
slurm_nextsim_script=${JOB_SETUP_DIR}/slurm.ensemble.template.sh
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src

##-------  Confirm working,data,ouput directories --------
# experiment settings
Exp_ID=era5_FreeRun
ENSSIZE=40 
time_init0=2019-10-18   # starting date of simulation
duration=7      # forecast length; tduration*duration is the total simulation time
tduration=26    # number of DA cycles.

start_from_restart=true
restart_from_analysis=false
UPDATE=0        # 1: active EnKF assimilation 
nudging_day=5  #15,15,25,35,45
DA_VAR=
analysis_source=0
restart_source=/cluster/work/users/chengsukun/simulations/test_era5_spinup_2019-09-02_46days_x_1cycles_memsize40/date1
nextsim_data_dir=/cluster/work/users/chengsukun/nextsim_data_dir
OUTPUT_DIR=${simulations}/test_${Exp_ID}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
echo 'output path:' $OUTPUT_DIR
[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 
cp $slurm_nextsim_script  ${OUTPUT_DIR}  
cp -rf ${NEXTSIMDIR}/model ${OUTPUT_DIR}/nextsim_source_code
# ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
    echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + ${duration} day")"
# a. create files strucure, copy and modify configuration files inside
    ENSPATH=${OUTPUT_DIR}/date${iperiod}
    mkdir -p ${ENSPATH}
    for (( i=1; i<=${ENSSIZE}; i++ )); do     
    ##### special section >>>>>
        i_cluster=$(( $i/10 ))
        i_j=$(( $i%10 ))
        (( $i_j==0 )) && i_j=10 && i_cluster=$((${i_cluster}-1))
        time_init=${time_inits[$i_cluster]}
        duration=${durations[$i_cluster]}
        basename=${basenames[$i_cluster]}
        echo 'time_init:' $time_init  ', duration:' $duration  ,'mem:' $i_j
        # link external forcing files into each member/data folder
        memname=mem${i}
        MEMPATH=${ENSPATH}/${memname}
        input_path=${ENSPATH}/${memname}/data
        mkdir -p ${input_path}
        sed -i "s/^time_init=.*$/time_init=${time_init}/g; \
            s/^duration=.*$/duration=${duration}/g; \
            s/^dynamics-type=.*$/dynamics-type=bbm/g; \
            s/^ocean_nudge_timeS=.*$/ocean_nudge_timeS=$((86400*$nudging_day))/g; \
            s/^ocean_nudge_timeT=.*$/ocean_nudge_timeT=$((86400*$nudging_day))/g; \
            s/^output_timestep=.*$/output_timestep=1/g; \
            s/^start_from_restart=.*$/start_from_restart=${start_from_restart}/g; \
            s/^write_final_restart=.*$/write_final_restart=true/g; \
            s/^DAtype.*$/DAtype=${DA_VAR}/g; \
            s/^restart_from_analysis=.*$/restart_from_analysis=${restart_from_analysis}/g" \
        ${JOB_SETUP_DIR}/nextsim.cfg 

        sed -e "s|^basename.*$|basename=${memname}|g; \
                s|^ensemble_member.*$|ensemble_member=${i}|g; \
                s|^exporter_path.*$|exporter_path=${MEMPATH}|g; \
                s|^input_path=.*$|input_path=${input_path}|g; \
                s|^restart_path=.*$|restart_path=|g" \
            ${JOB_SETUP_DIR}/nextsim.cfg > ${MEMPATH}/nextsim.cfg.backup
      
        ln -sf /cluster/work/users/chengsukun/ERA5_ensemble/data_ensemble/ens${i_j}  ${input_path}/ERA5
        ln -sf /cluster/work/users/chengsukun/nextsim_data_dir/*   ${input_path}/

        nextsim_data_dir=${input_path}
    ###### <<<<<<<<<
        if ${start_from_restart}; then
            ln -sf ${restart_source}/field_${basename}.bin  ${input_path}/field_${memname}.bin
            ln -sf ${restart_source}/field_${basename}.dat  ${input_path}/field_${memname}.dat
            ln -sf ${restart_source}/mesh_${basename}.bin   ${input_path}/mesh_${memname}.bin
            ln -sf ${restart_source}/mesh_${basename}.dat   ${input_path}/mesh_${memname}.dat
        fi
    done  
# submit
    Nnode=${ENSSIZE}
    # sbatch -W --time=0-0:30:0 --nodes=$Nnode $slurm_nextsim_script ${ENSPATH} ${ENSSIZE} ${Nnode} 
    # wait
    for (( i=1; i<=$ENSSIZE; i++ )); do
        MEMPATH=$ENSPATH/mem${i}
        cd $MEMPATH
        export NEXTSIM_DATA_DIR=${MEMPATH}/data   #<<<<<<< special part >>>>>>>>
        cp nextsim.cfg.backup nextsim.cfg
        grep -q -s "Simulation done" task.log && continue
        rm -rf *.nc *.log *.bin *.dat *.txt restart
        srun --nodes=1 --mpi=pmi2 -n128 $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg 2>&1 | tee task.log  &    
        # (( $i%$Nnode==0 )) && wait    
    done
    wait
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}    
echo "finished"