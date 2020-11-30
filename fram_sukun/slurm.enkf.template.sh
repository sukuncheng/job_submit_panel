#!/bin/bash -x
# set -uex
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
MUMPS_MEM=400 # Reserved memory for the solver
ENV_FILE=$HOME/src/nextsim-env/machines/fram_sukun/nextsim.ensemble.intel.src
DEBUG=false
TEST=false
echo $@

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

outdir=`pwd`
if [ $# -eq 0 ]
then
    usage
    exit 1
else
    CONFIG=$1
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

echo "SLURM_JOB_ID: " ${SLURM_JOB_ID}

if [ ! -f "$SLURM_SUBMIT_DIR/filter" ]
then
    echo "Can't find $SLURM_SUBMIT_DIR/filter"
fi
cp -rP $SLURM_SUBMIT_DIR/filter/* $SCRATCH/.

log=$SCRATCH/$(basename $CONFIG .cfg).log

cd $SCRATCH
echo `pwd`
# Go to the SCRATCH directory to run
cmd="srun enkf_prep --no-superobing enkf.prm"
if [ "$DEBUG" == "true" ]
then
    # model printouts go into the slurm output file
    $cmd 2>&1 | tee prep.out
else
    $cmd &> prep.out
fi
cmd="srun enkf_calc --use-rmsd-for-obsstats --ignore-no-obs enkf.prm"
if [ "$DEBUG" == "true" ]
then
    # model printouts go into the slurm output file
    $cmd 2>&1 | tee calc.out
else
    $cmd &> calc.out
fi
cmd="srun enkf_update --calculate-spread enkf.prm"
if [ "$DEBUG" == "true" ]
then
    # model printouts go into the slurm output file
    $cmd 2>&1 | tee update.out
else
    $cmd &> update.out
fi

#
cp -rf $SCRATCH/. $SLURM_SUBMIT_DIR/filter
# Save the log (copy from SCRATCH back to submitting directory)
# - this is done at end of job, even if script stopped due to errors, but not if wall
#   time is reached
# - use -d or --debug to also put the model printouts into the slurm output file
savefile prep.out
savefile calc.out
savefile update.out
