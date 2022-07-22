#!/bin/bash 
# ======================================================
# * Use absolute file path for config file since in slurm
# we are not immediately in the submitting directory
# Similarly for paths inside config file
# * see SLURM Parameter and Settings https://documentation.sigma2.no/jobs/job_scripts/slurm_parameter.html
# ======================================================
#SBATCH --account=nn2993k  #nn9481k #nn9878k   # #nn2993k   #ACCOUNT_NUMBER
#SBATCH --job-name=nextsim
##SBATCH --time=0-5:35:0        #dd-hh:mm:ss
##SBATCH --qos=devel            # preproc, devel, short and normal if comment this line,  https://documentation.sigma2.no/jobs/job_types/fram_job_types.html
#SBATCH --nodes=40              # request number of nodes
#SBATCH --ntasks-per-node=128  # MPI parallel thread size
#SBATCH --cpus-per-task=1      #
#SBATCH --output=slurm.nextsim.%j.log         # Stdout
#SBATCH --error=slurm.nextsim.%j.log          # Stderr
# set -uex  # uncomment for debugging
ENSPATH=$1         
ENSSIZE=$2         
Nnode=$3
# --------------------------------------------------------
# SLURM_SUBMIT_DIR doesn't work occasionally
# source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src
# ln -sf $NEXTSIM_DATA_DIR/* $SCRATCH/  #note the slash '/' is necessary. It only links files not directory, so adding files in $SCRATCH later will not appear in $NEXTSIM_DATA_DIR/ in user login node
#  link restarts from previous forecasts and DA analysis statevector (=restart_source) to restart_path.

# export NEXTSIM_DATA_DIR=$SCRATCH/  
# restart_path=$NEXTSIM_DATA_DIR/

for (( i=1; i<=$ENSSIZE; i++ )); do
    MEMPATH=$ENSPATH/mem${i}
    cd $MEMPATH
    export NEXTSIM_DATA_DIR=${MEMPATH}/data   #<<<<<<< special part >>>>>>>>
    cp nextsim.cfg.backup nextsim.cfg
    grep -q -s "Simulation done" task.log && continue
    rm -rf *.nc *.log *.bin *.dat *.txt restart
    srun --nodes=1 --mpi=pmi2 -n128 $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg 2>&1 | tee task.log  &    
    (( $i%$Nnode==0 )) && wait    
    cp nextsim.cfg.backup nextsim.cfg
done
wait

# cmd="singularity exec --cleanenv /cluster/projects/nn2993k/sim/singularity_image_files/pynextsim-no-code.sif mpirun -np 32 $progdir/nextsim.exec   --config-files=$config"
# srun --nodes=1 --tasks-per-node=128 --time=00:10:00 --qos=devel --account=nn2993k --pty $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg
# 
# srun -N1 -r0 --mpi=pmi2 -n128 $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg
# srun --nodes=4 --time=00:30:00  --account=nn2993k --pty /bin/bash -i
# for (( i=0; i<2; i++ )); do
#     srun -N1 -n2 -r $i --mpi=pmi2 hostname >>test_$SLURM_JOB_ID.txt &    
# done
# srun -n128 $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg 2>&1 | tee task.log