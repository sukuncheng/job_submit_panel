#!/bin/bash 
#        # ======================================================
#        # problematic setting 
#        # SBATCH --account=nn2993k      #nn9481k #nn9878k   # #nn2993k   #ACCOUNT_NUMBER
#        # SBATCH --job-name=freerun
#        # SBATCH --time=0-0:30:0        # dd-hh:mm:ss, # Short request job time can be accepted easier.
#        # SBATCH --qos=normal           # preproc, devel, short and normal, https://documentation.sigma2.no/jobs/job_types/fram_job_types.html
#        # SBATCH --nodes=4             # request number of nodes
#        # #SBATCH --ntasks-per-node=128  # MPI parallel thread size
#        # SBATCH --cpus-per-task=1      #
#        # SBATCH --output=$SLURM_JOB_NAME.log         # Stdout
#        # SBATCH --error=$SLURM_JOB_NAME.log          # Stderr
#        # ======================================================

# script for submitting an ensemble run without DA, restarting from spinup run, defined by main1_spinup_exp.sh
# Instruction:
# create file structure 
# call create_file_system.sh to modify nextsim.cfg and enkf settings to workpath
# link restart files &perturbation files.
# submit jobs to queue by slurm_next sim_script from workpath.

# set -uex  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
   echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

##-------  Confirm working,data,ouput directories --------
>nohup.out        # empty this file
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)                          
slurm_nextsim_script=${JOB_SETUP_DIR}/slurm.ensemble.template.sh
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
source ./link_restart_perturbation.sh
##-------  Confirm working,data,ouput directories --------
# experiment settings
ENSSIZE=40      # ensemble size  
time_init0=2019-10-18   # starting date of simulation
duration=7      # forecast length; tduration*duration is the total simulation time
tduration=26    # number of DA cycles. 
Exp_ID=freerun
DA_VAR=
start_from_restart=true
restart_from_analysis=false   
UPDATE=0        # 1: active EnKF assimilation 

nudging_day=5    
restart_source=/cluster/work/users/chengsukun/simulations/test_spinup__44days_x_1cycles_memsize40/date1
# Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result
analysis_source=0
OUTPUT_DIR=${simulations}/test_${Exp_ID}_${time_init0}_${duration}days_x_${tduration}cycles_memsize${ENSSIZE}
echo 'work path:' $OUTPUT_DIR
[ -d $OUTPUT_DIR ] && rm -rf $OUTPUT_DIR
[ ! -d $OUTPUT_DIR ] && mkdir -p ${OUTPUT_DIR}
cp ${JOB_SETUP_DIR}/$(basename $BASH_SOURCE)  ${OUTPUT_DIR} 
cp -rf ${NEXTSIMDIR}/model ${OUTPUT_DIR}/nextsim_source_code 
# ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
    echo "period ${time_init} to $(date +%Y-%m-%d -d "${time_init} + ${duration} day")"
# a. create files strucure, copy and modify configuration files inside
    ENSPATH=${OUTPUT_DIR}/date${iperiod}
# source ${JOB_SETUP_DIR}/create_file_system.sh
# link forcing to each member directory
    for (( i=1; i<=${ENSSIZE}; i++ )); do     
        memname=mem${i}
        basename=mem${i}
# link external forcing files into each member/data folder
        MEM_DATA_DIR=${ENSPATH}/mem${i}/data
        nextsim_data_dir=${MEM_DATA_DIR}
        mkdir -p ${MEM_DATA_DIR}
        cd ${MEM_DATA_DIR}
        i_cluster=$(( $i/10 ))
        i_j=$(( $i%10 ))
        (( $i_j==0 )) && i_j=10 && i_cluster=$((${i_cluster}-1))
        
        ln -sf /cluster/work/users/chengsukun/ERA5_ensemble/data/ens${i_j}  ./ERA5
        # # ln -sf /cluster/work/users/chengsukun/ERA5_reanalysis  ./ERA5
        # # ln -sf /cluster/work/users/chengsukun/TIGGE/ens${i}  ./TIGGE
        ln -sf /cluster/work/users/chengsukun/nextsim_data_dir/*   .
        
        if ${start_from_restart}; then
            ln -sf ${restart_source}/${memname}/restart/field_final.bin  ${nextsim_data_dir}/field_${memname}.bin
            ln -sf ${restart_source}/${memname}/restart/field_final.dat  ${nextsim_data_dir}/field_${memname}.dat
            ln -sf ${restart_source}/${memname}/restart/mesh_final.bin   ${nextsim_data_dir}/mesh_${memname}.bin
            ln -sf ${restart_source}/${memname}/restart/mesh_final.dat   ${nextsim_data_dir}/mesh_${memname}.dat
        fi
        # link_perturbation $nextsim_data_dir $duration $iperiod $i   

        # set configuration file .cfg for each ensemble member
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

        memname=mem${i}
        MEMPATH=${ENSPATH}/${memname}
        sed -e "s|^basename.*$|basename=${memname}|g; \
                s|^ensemble_member.*$|ensemble_member=${i}|g; \
                s|^exporter_path.*$|exporter_path=${MEMPATH}|g; \
                s|^input_path=.*$|input_path=${MEMPATH}/data|g; \
                s|^restart_path=.*$|restart_path=|g" \
            ${JOB_SETUP_DIR}/nextsim.cfg > ${MEMPATH}/nextsim.cfg.backup
    done  

# # b. execute simulation
#     cd $ENSPATH
#     Nnode=40
#     for (( jj=1; jj<=2; jj++ )); do  # check for crashed member and resubmit        
#         echo 'Try' $jj ', date' $iperiod
#         for (( i=1; i<=$ENSSIZE; i++ )); do                                
#             cd $ENSPATH/mem${i}
#             cp nextsim.cfg.backup nextsim.cfg
#             grep -q -s "Simulation done" task.log && continue
#             rm -rf *.nc *.log *.bin *.dat *.txt restart
#             srun --nodes=1 --mpi=pmi2 -n128 $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg 2>&1 | tee task.log  &      
#         done   
#         wait  
#     done

#     # check for crashed member, report error and exit
#     for (( i=1; i<=$ENSSIZE; i++ )); do
#         ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && echo $ENSPATH'/mem'$i 'has crashed ' $(( $jj-1 )) ' times. EXIT' && exit
#     done

# submit
    # check for crashed member, report error and exit
    echo ${nextsim_data_dir}
    for (( jj=1; jj<=2; jj++ )); do          # check for crashed member and resubmit
        count=0
        list=()
        for (( i=1; i<=$ENSSIZE; i++ )); do
            ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && count=$(($count+1)) && list=(${list[@]-} $i);
        done
        if (( $count >0 )); then
            Nnode=$ENSSIZE        
            sbatch -W --time=0-0:10:0 --nodes=$Nnode $slurm_nextsim_script ${ENSPATH} ${ENSSIZE}  ${Nnode}  ${nextsim_data_dir}
        fi
    done
    restart_source=${ENSPATH}
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}  
# done
echo "finished"