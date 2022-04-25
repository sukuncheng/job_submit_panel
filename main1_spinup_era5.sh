#!/bin/bash 
# Instruction:
# script for submitting an ensemble run without DA, restarting from a restart file.
# create workpath
# link perturbation file
# call create_file_system.sh to modify nextsim.cfg and enkf settings to workpath
# submit jobs to queue by slurm_nextsim_script from workpath, in which link restart files.

# set -uex  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

function link_perturbation(){ 
    # links perturbation files to nextsim_data_dir/Perturbation using input file id
    # note the index 180=45*4 correspond to the last perturbation used in the end of spinup run
    day0=0 # for spinup day0=0    
    nextsim_data_dir=$1
    duration=$2
    iperiod=$3
    ENS_ID=$4
    # ENSSIZE=$4

    [ ! -d ${nextsim_data_dir}/Perturbations ] && mkdir -p ${nextsim_data_dir}/Perturbations || rm -f ${nextsim_data_dir}/Perturbations/*.nc
    Perturbation_source=/cluster/work/users/chengsukun/offline_perturbations/result
    #
    i=$ENS_ID
    memname=mem${i}    
    # link data sources based on different loading frequencies
    # atmoshphere
    Nfiles=$(( $duration*4+1))  # number of perturbations to link
    for (( j=0; j<=${Nfiles}; j++ )); do  #+1 is because an instance could end at 23:45 or 24:00 for different members due to ? +1 corresponds to the longer one.
        ln -sf ${Perturbation_source}/${memname}/synforc_$((${j}+$day0*4 + ($iperiod-1)*($Nfiles-1) )).nc  ${nextsim_data_dir}/Perturbations/AtmospherePerturbations_${memname}_series${j}.nc
    done
    # ocean 
    Nfiles=$duration+1  # topaz data is loaded at 12:00pm. 
    for (( j=0; j<=${Nfiles}; j++ )); do
        ln -sf ${Perturbation_source}/${memname}/synforc_$((${j}+$day0 + ($iperiod-1)*$Nfiles)).nc  ${nextsim_data_dir}/Perturbations/OceanPerturbations_${memname}_series${j}.nc
    done
}

#-------  Confirm working,data,ouput directories --------
>nohup.out        # empty this file
JOB_SETUP_DIR=$(cd `dirname $BASH_SOURCE`;pwd)                          # 
source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
slurm_nextsim_script=${JOB_SETUP_DIR}/slurm.ensemble.template.sh

# experiment configuration
Exp_ID=spinup
ENSSIZE=40      # ensemble size  
time_inits=("2019-09-02" "2019-09-03" "2019-09-04"  "2019-09-05" )    # starting date of simulation
durations=( "46" "45" "44" "43" )     # forecast length; tduration*duration is the total simulation time
# durations=("7" "6" "5" "4")     # forecast length; tduration*duration is the total simulation time
# set this variable associated with time_init for a restart run
basenames=( "20190902T000000Z" "20190903T000000Z" "20190904T000000Z" "20190905T000000Z" )

tduration=1     # number of DA cycles. 
start_from_restart=true
restart_from_analysis=false
UPDATE=0        # 1: active EnKF assimilation 
nudging_day=5   # 15,15,25,35,45
DA_VAR=

restart_source=$HOME/src/restart

Exp_ID=quicktest
ENSSIZE=4      # ensemble size  
time_inits=("2019-12-31")
durations=( "4" )
start_from_restart=false
#
OUTPUT_DIR=${simulations}/test_ #${Exp_ID}_${duration}_43days_x_${tduration}cycles_memsize${ENSSIZE}
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
    echo "period ${iperiod}"
    ENSPATH=${OUTPUT_DIR}/date${iperiod}

# link forcing to each member directory
    for (( i=1; i<=${ENSSIZE}; i++ )); do     
        memname=mem${i}
        i_cluster=$(( $i/10 ))
        i_j=$(( $i%10 ))
        (( $i_j==0 )) && i_j=10 && i_cluster=$((${i_cluster}-1))
        time_init=${time_inits[$i_cluster]}
        duration=${durations[$i_cluster]}
        basename=${basenames[$i_cluster]}
        echo $time_init  $duration  $i_j

        # link external forcing files into each member/data folder
        MEM_DATA_DIR=${ENSPATH}/mem${i}/data
        mkdir -p ${MEM_DATA_DIR}
        cd ${MEM_DATA_DIR}
        ln -sf /cluster/work/users/chengsukun/ERA5_ensemble/data/ens${i_j}  ./ERA5
        # # ln -sf /cluster/work/users/chengsukun/ERA5_reanalysis  ./ERA5
        # # ln -sf /cluster/work/users/chengsukun/TIGGE/ens${i}  ./TIGGE
        ln -sf /cluster/work/users/chengsukun/nextsim_data_dir/*   .

        nextsim_data_dir=${MEM_DATA_DIR}
        if ${start_from_restart}; then
            ln -sf ${restart_source}/field_${basename}.bin  ${MEM_DATA_DIR}/field_${memname}.bin
            ln -sf ${restart_source}/field_${basename}.dat  ${MEM_DATA_DIR}/field_${memname}.dat
            ln -sf ${restart_source}/mesh_${basename}.bin   ${MEM_DATA_DIR}/mesh_${memname}.bin
            ln -sf ${restart_source}/mesh_${basename}.dat   ${MEM_DATA_DIR}/mesh_${memname}.dat
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
                s|^restart_path=.*$|restart_path=${MEM_DATA_DIR}|g" \
            ${JOB_SETUP_DIR}/nextsim.cfg > ${MEMPATH}/nextsim.cfg.backup
    done  
    echo ${OUTPUT_DIR} 
# create configuration files
    source ${JOB_SETUP_DIR}/set_enkf_files.sh
# submit
    Nnode=${ENSSIZE}
    sbatch -W --time=0-0:30:0 --nodes=$Nnode $slurm_nextsim_script ${ENSPATH} ${ENSSIZE}  ${Nnode} ${MEM_DATA_DIR}
    wait
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR}    
  
echo "finished"
