#!/bin/bash -x
## Project:
#SBATCH --account=nn2993k
## Job name:
#SBATCH --job-name=nextsim_SA5km
## Wall time limit:
#SBATCH --time=0-0:0:5
## Number of nodes:
#SBATCH --nodes=1
## Number of tasks to start on each node:
#SBATCH --ntasks-per-node=32
## Set OMP_NUM_THREADS
#SBATCH --cpus-per-task=1
## debug queue
#SBATCH --qos=preproc

#SBATCH --mail-type=ALL                       # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=sukun.cheng@nersc.no # email to the user
#SBATCH --output=slurm.nextsim.%j.log         # Stdout
#SBATCH --error=slurm.nextsim.%j.log          # Stderr

# ======================================================
# * Use absolute file path for config file since in slurm
# we are not immediately in the submitting directory
# Similarly for paths inside config fie
# * For debug runs, use the --qos=preproc option, 1 node, and <1day
# ======================================================

# Reserved memory for the solver
MUMPS_MEM=512

# End user-modifiable content

# A run script for fram
function usage {
   echo "Usage: $0 config_file.cfg"
   echo "NB use absolute file path for safety"
}

if [ $# -eq 0 ]
then
   usage
   exit 1
else
   config=$1
fi

if [ ! -f "$config" ]
then
   echo "Can't find config file $config"
   echo "- use absolute file path for safety"
   exit 1
fi

if [ -z $SCRATCH ]
then
   echo "launch script with sbatch!"
   usage
   exit 1
fi
source $HOME/nextsim.src

log=$SCRATCH/$(basename $config .cfg).log

# Copy relevant parts of $NEXTSIMDIR to the working directory
for ddir in bin data mesh
do
   rm -rf $SCRATCH/$ddir
   mkdir $SCRATCH/$ddir
done
progdir=$SCRATCH/bin
cp -a $config $SCRATCH
pseudo2D=$NEXTSIMDIR/modules/enkf/perturbation/nml/pseudo2D.nml
cp -a $pseudo2D $SCRATCH
cp -a $NEXTSIMDIR/model/bin/nextsim.exec $progdir
cp -a $NEXTSIM_DATA_DIR/* $NEXTSIMDIR/data/* $SCRATCH/data
cp -a $NEXTSIM_MESH_DIR/* $NEXTSIMDIR/mesh/* $SCRATCH/mesh

# Set $NEXTSIMDIR, NEXTSIM_MESH_DIR, and NEXTSIM_DATA_DIR
export NEXTSIM_MESH_DIR=$SCRATCH/mesh
export NEXTSIM_DATA_DIR=$SCRATCH/data

# Go to the SCRATCH directory to run
cd $SCRATCH

# RUN!
srun $progdir/nextsim.exec \
   -mat_mumps_icntl_23 $MUMPS_MEM \
   --config-files=$config \
   2>&1 | tee $log
   #&> $log

# Save the log and the executable (copy from SCRATCH back to submitting directory)
# - this is done at end of job, even if script stopped due to errors, but not if wall
#   time is reached
savefile $log
cleanup "cp -r -a $progdir $SLURM_SUBMIT_DIR"
