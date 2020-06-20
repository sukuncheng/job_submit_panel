#!/bin/bash -x
## Project:
#SBATCH --account=ACCOUNT_NUMBER
## Job name:
#SBATCH --job-name=JOB_NAME
## Wall time limit:
#SBATCH --time=WALL_TIME_DAYS-WALL_TIME_HOURS:WALL_TIME_MINUTES:0
## Number of nodes:
#SBATCH --nodes=NUM_NODES
## Number of tasks to start on each node:
#SBATCH --ntasks-per-node=NUM_TASKS
## Set OMP_NUM_THREADS
#SBATCH --cpus-per-task=1
## uncomment for debug queue
##SBATCH --qos=preproc

#SBATCH --mail-type=ALL                       # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=SLURM_EMAIL # email to the user
#SBATCH --output=slurm.JOB_NAME.%j.log         # Stdout
#SBATCH --error=slurm.JOB_NAME.%j.log          # Stderr

# ======================================================
# * Use absolute file path for config file since in slurm
# we are not immediately in the submitting directory
# Similarly for paths inside config fie
# * For debug runs, use the --qos=preproc option, 1 node, and <1day
# ======================================================

function usage {
    echo "Usage:"
    echo "sbatch $0 CONFIG [options]"
    echo "-e|--env-file ENV_FILE"
    echo "   file to be sourced to get environment variables (~/nextsim.src)"
    echo "-m|--mumps-memory MUMPS_MEM"
    echo "   memory reserved for the solver (1000)"
    echo "-d|--debug"
    echo "   divert model printouts into the slurm output file"
    echo "   needed since sometimes the log file is not copied back to the"
    echo "   directory where the job was submitted from"
    echo "-t|--test"
    echo "   don't launch the model"
}

#defaults for options
MUMPS_MEM=1000 # Reserved memory for the solver
ENV_FILE=$HOME/nextsim.src
DEBUG=true
TEST=false

# parse optional parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -e|--env-file)
            ENV_FILE=$2
            shift # past argument
            shift # past value
            ;;
        -m|--mumps-memory)
            MUMPS_MEM=$2
            shift # past argument
            shift # past value
            ;;
        -d|--debug)
            DEBUG=true
            shift # past argument
            ;;
        -t|--test)
            TEST=true
            shift # past argument
            ;;
        *)
            # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done

# restore positional parameters
set -- "${POSITIONAL[@]}" 

if [ $# -eq 0 ]
then
    usage
    exit 1
else
    CONFIG=$1
fi

if [ -f "$CONFIG" ]
then
    config=$CONFIG
 else
    # if config file is not present, try path relative to
    # directory where job was submitted from
    config=$SLURM_SUBMIT_DIR/$CONFIG
fi
if [ ! -f "$config" ]
then
    echo "Can't find config file $CONFIG"
    echo "- use absolute file path for safety"
    exit 1
fi

# get environment variables
if [ ! -f "$ENV_FILE" ]
then
    echo "Can't find environment file $ENV_FILE"
    echo "- use absolute file path for safety"
    exit 1
else
    source $ENV_FILE
fi

# log file
bconfig=`basename $config`
log=$SCRATCH/$(basename $config .cfg).log

# Copy relevant parts of $NEXTSIMDIR to the working directory
for ddir in bin data mesh
do
    rm -rf $SCRATCH/$ddir
    mkdir $SCRATCH/$ddir
done
progdir=$SCRATCH/bin
cp -a $config $SCRATCH
#pseudo2D=$NEXTSIMDIR/modules/enkf/perturbation/nml/pseudo2D.nml
pseudo2D=./pseudo2D.nml # same path as nextsim.cfg set by user
cp -a $pseudo2D $SCRATCH
cp -a $SLURM_SUBMIT_DIR/bin/nextsim.exec $progdir
cp -a $NEXTSIMDIR/data/*  $NEXTSIM_DATA_DIR/*  $SCRATCH/data  # the order allow overwritten of files in different directories, but I don;t know the order
cp -a $NEXTSIM_MESH_DIR/* $NEXTSIMDIR/mesh/* $SCRATCH/mesh

# Set $NEXTSIMDIR, NEXTSIM_MESH_DIR, and NEXTSIM_DATA_DIR
export NEXTSIM_MESH_DIR=$SCRATCH/mesh
export NEXTSIM_DATA_DIR=$SCRATCH/data

# Go to the SCRATCH directory to run
cd $SCRATCH
cmd="srun $progdir/nextsim.exec \
    -mat_mumps_icntl_23 $MUMPS_MEM \
    --config-files=$bconfig"
if [ "$DEBUG" == "true" ]
then
    # model printouts go into the slurm output file
    $cmd 2>&1 | tee $log
else
    $cmd &> $log
fi

# Save the log (copy from SCRATCH back to submitting directory)
# - this is done at end of job, even if script stopped due to errors, but not if wall
#   time is reached
# - use -d or --debug to also put the model printouts into the slurm output file
savefile $log
