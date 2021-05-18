#!/bin/bash 
# set -uex
# ======================================================
# * Use absolute file path for config file since in slurm
# we are not immediately in the submitting directory
# Similarly for paths inside config file
# * see SLURM Parameter and Settings https://documentation.sigma2.no/jobs/job_scripts/slurm_parameter.html
# ======================================================

#SBATCH --account=nn2993k   #ACCOUNT_NUMBER
#SBATCH --job-name=nextsim
#SBATCH --time=0-0:20:0     #WALL_TIME_DAYS-WALL_TIME_HOURS:WALL_TIME_MINUTES:0
#SBATCH --nodes=1            #NUM_NODES
#SBATCH --ntasks-per-node=32 # for MPI 
#SBATCH --cpus-per-task=1    # set=1 for MPI 
##SBATCH --qos=devel          # preproc, devel, short and normal if comment this line,  https://documentation.sigma2.no/jobs/job_types/fram_job_types.html
#SBATCH --mail-type=NONE                       # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=SLURM_EMAIL # email to the user
#SBATCH --output=slurm.nextsim.%j.log         # Stdout
#SBATCH --error=slurm.nextsim.%j.log          # Stderr

# settings
SUBMIT_DIR=$1       # SLURM_SUBMIT_DIR doesn't work occasionally
ENV_FILE=$2         # src of environmental variables
source $ENV_FILE

# --------------------------------------------------------
    # cp config_file and pseudo2D.nml to work path
    CONFIG=$SUBMIT_DIR/nextsim.cfg
    config=$SCRATCH/`basename $CONFIG`   
    cp $SUBMIT_DIR/nextsim.cfg $config 
    sed -i "s;^exporter_path.*$;exporter_path=${SCRATCH};g" $config 
    cp $config  $SCRATCH/nextsim.cfg.backup  # todo, for unknow reason, $config is emptied after accessed by nextsim.exec
    # copy pseudo2D.nml
    cd $SCRATCH 
    cp $SUBMIT_DIR/pseudo2D.nml .

    # Go to the SCRATCH directory to run
    cmd="srun $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=$config"
    # cmd="singularity exec --cleanenv /cluster/projects/nn2993k/sim/singularity_image_files/pynextsim-no-code.sif mpirun -np 32 $progdir/nextsim.exec   --config-files=$config"
    $cmd 2>&1 | tee task.log   

    # Save log (copy from SCRATCH back to submitting directory) except waltime is reached
    mv nextsim.cfg.backup nextsim.cfg
    cp -rf ${SCRATCH} ${SUBMIT_DIR}

# srun --nodes=1 --tasks-per-node=32 --time=00:30:00 --qos=devel --account=nn2993k --pty $NEXTSIMDIR/model/bin/nextsim.exec  --config-files=nextsim.cfg
