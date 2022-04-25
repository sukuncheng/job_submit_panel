#!/bin/bash 
# ======================================================
#SBATCH --account=nn2993k      #nn9481k #nn9878k   # #nn2993k   #ACCOUNT_NUMBER
#SBATCH --time=0-10:30:0        #dd-hh:mm:ss, # Short request job time can be accepted easier.
##SBATCH --qos=devel          # preproc, devel, short and normal if comment this line,  https://documentation.sigma2.no/jobs/job_types/fram_job_types.html
#SBATCH --nodes=40           # request number of nodes
#SBATCH --ntasks-per-node=128  # MPI parallel thread size
#SBATCH --cpus-per-task=1      #

##SBATCH --job-name=
##SBATCH --output=$Exp_ID_%j.log         # Stdout
##SBATCH --error=$Exp_ID_%j.log          # Stderr
# ======================================================

# link restart files &perturbation files.
# submit ensemble-DA jobs to queue.

 #
#set -uex  # uncomment for debugging,# Bash empty array expansion with `set -u`, use ${arr[@]-} instead of use ${arr[@]} to avoid errors
source $1
source $2
export NEXTSIM_DATA_DIR=${restart_path}
# NEXTSIM_DATA_DIR=$3
# ln -sf ${NEXTSIM_DATA_DIR}/* ${$SCRATCH}/ #note the slash '/' is necessary. It only links files not directory
# export NEXTSIM_DATA_DIR=${$SCRATCH}
# ----------- execute ensemble runs ----------
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    time_init=$(date +%Y-%m-%d -d "${time_init0} + $((($iperiod-1)*${duration})) day")
    echo "period ${time_init} to $(date +%Y%m%d -d "${time_init} + ${duration} day")"
    ENSPATH=${OUTPUT_DIR}/date${iperiod}
    cd $ENSPATH
    for (( jj=1; jj<=3; jj++ )); do          # check for crashed member and resubmit
        count=0
        list=()
        for (( i=1; i<=$ENSSIZE; i++ )); do
            ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && count=$(($count+1)) && list=(${list[@]-} $i);
        done
        if (( $count >0 )); then
            (( jj==1 )) && link_restarts     $ENSSIZE   $restart_source      $restart_path $analysis_source
            (( jj==1 )) && link_perturbation $ENSSIZE   $Perturbation_source $restart_path $duration  $iperiod 
            echo 'Try' $jj ', date' $iperiod ', start calculating member(s):' ${list[@]-} 
            echo $ENSPATH
            #
            for (( i=1; i<=$ENSSIZE; i++ )); do                                
                cd $ENSPATH/mem${i}
                cp nextsim.cfg.backup nextsim.cfg
                grep -q -s "Simulation done" task.log && continue
                rm -rf *.nc *.log *.bin *.dat *.txt restart
                srun --nodes=1 --mpi=pmi2 -n128 --time=$((1*$duration+5)):00 $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg 2>&1 | tee task.log  & 
                # mpirun -np 64 $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg 2>&1 > task.log  &       
                cp nextsim.cfg.backup nextsim.cfg      
            done   
            wait
        else
            break
        fi  
    done
    # check for crashed member, report error and exit
    for (( i=1; i<=$ENSSIZE; i++ )); do
        ! grep -q -s "Simulation done" $ENSPATH/mem$i/task.log && echo $ENSPATH'/mem'$i 'has crashed ' $(( $jj-1 )) ' times. EXIT' && exit
    done
    #------------------
    ## 2.submit enkf after finishing the ensemble simulations 
    if [ -d ${OUTPUT_DIR}/date${iperiod}/filter ] && ! grep -q -s "finished" ${ENSPATH}/filter/update.out ; then  
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            cp ${ENSPATH}/mem${i}/prior.nc  ${ENSPATH}/filter/prior/$(printf "mem%.3d" $i).nc
        done       
        cd ${ENSPATH}/filter
        srun --nodes=1 --mpi=pmi2 -n128 ./enkf_calc --use-rmsd-for-obsstats --ignore-no-obs enkf.prm 2>&1 > calc.out
        srun --nodes=1 --mpi=pmi2 -n128 ./enkf_update --calculate-spread enkf.prm 2>&1 > update.out
    fi
    analysis_source=${ENSPATH}/filter/prior
    restart_source=${ENSPATH}
done
