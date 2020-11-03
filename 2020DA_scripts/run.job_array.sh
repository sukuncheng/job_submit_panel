#!/bin/bash
function usage {
    echo "Usage:"
    echo "run.fram CONFIG_FILE GET_EXECUTABLE [options] [slurm script options]"
    echo "CONFIG_FILE is name of config file for nextsim"
    echo "   NB use absolute file path for safety"
    echo "GET_EXECUTABLE = 0 or 1"
    echo "   1: get nextsim.exec from NEXTSIMDIR/model/bin"
    echo "   0: already have nextsim.exec in bin/nextsim.exec"
    echo ""
    echo "Options:"
    echo "-j|--job-name JOB_NAME"
    echo "      Name for the slurm job (nextsim)"
    echo "-a|--account-number ACCOUNT_NUMBER"
    echo "      Account number to charge the slurm job to (nn2993k)"
    echo "-nc|--number-of-cores NUM_CORES"
    echo "      Number of cores/nodes to ask for (1)"
    echo "      Use 1 for debugging; otherwise use at least 4"
    echo "-nt|--number-of-tasks-per-core NUM_TASKS"
    echo "      Number of processes on each core (32) - max is 32"
    echo "-wd|--wall-time-days WALL_TIME_DAYS"
    echo "      Wall time is given in DAYS-HOURS:MINUTES:SECONDS"
    echo "      eg 1-0:00:00 for 1 day (max time for debugging queue)"
    echo "      This options specifies DAYS (1)"
    echo "-wh|--wall-time-hours WALL_TIME_HOURS"
    echo "      Wall time is given in DAYS-HOURS:MINUTES:SECONDS"
    echo "      eg 1-0:00:00 for 1 day (max time for debugging queue)"
    echo "      This options specifies HOURS (0)"
    echo "-wm|--wall-time-minutes WALL_TIME_MINUTES"
    echo "      Wall time is given in DAYS-HOURS:MINUTES:SECONDS"
    echo "      eg 1-0:00:00 for 1 day (max time for debugging queue)"
    echo "      This options specifies MINUTES (0)"
    echo "-t|--test"
    echo "      Test input args are parsed correctly"
    echo "      (echo sbatch command instead of executing it)"
    echo ""
    echo "Slurm script options:"
    echo "see usage of slurm.template.sh"
}

# default values for options
TEST=false

# changed manually in slurm script with sed
JOB_NAME=nextsim
ACCOUNT_NUMBER=nn2993k
NUM_CORES=4
NUM_TASKS=32
WALL_TIME_DAYS=0
WALL_TIME_HOURS=2
WALL_TIME_MINUTES=0

# passed in as options to slurm script
SLURM_SCRIPT_OPTS=()
# parse optional parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -j|--job-name)
            JOB_NAME="$2"
            shift # past argument
            shift # past value
            ;;
        -a|--account-number)
            ACCOUNT_NUMBER=$2
            shift # past argument
            shift # past value
            ;;
        -nc|--number-of-cores)
            NUM_CORES=$2
            shift # past argument
            shift # past value
            ;;
        -nt|--number-of-tasks-per-core)
            NUM_TASKS=$2
            shift # past argument
            shift # past value
            ;;
        -wd|--wall-time-days)
            WALL_TIME_DAYS=$2
            shift # past argument
            shift # past value
            ;;
        -wh|--wall-time-hours)
            WALL_TIME_HOURS=$2
            shift # past argument
            shift # past value
            ;;
        -wm|--wall-time-minutes)
            WALL_TIME_MINUTES=$2
            shift # past argument
            shift # past value
            ;;
        -ne|--number-ensemble-member)
            NUM_ENS_MEM=$2
            shift # past argument
            shift # past value
            ;;
        -t|--test)
            TEST=true
            shift # past argument
            ;;
        *)
            # unknown option
            if [ ${#POSITIONAL[@]} -lt 2 ]
            then
                POSITIONAL+=("$1") # save it in an array for later
            else
                SLURM_SCRIPT_OPTS+=("$1") # save it in an array for later
            fi
            shift # past argument
            ;;
    esac
done
echo ${POSITIONAL[@]}

# restore positional parameters
set -- "${POSITIONAL[@]}"    # do not treat "${POSITIONAL[@]}" as options, https://unix.stackexchange.com/questions/308260/what-does-set-do-in-this-dockerfile-entrypoint/308263

# checks
if [ "$#" -lt 2 ]
then
    usage
    exit 1
else
    CONFIG=$1
    GET_EXECUTABLE=$2
fi

if [ ! -f "$CONFIG" ]
then
    echo "Can't find config file $CONFIG"
    exit 1
fi
sum_wall=$((WALL_TIME_DAYS + WALL_TIME_HOURS + WALL_TIME_MINUTES))
if [ $sum_wall -eq 0 ]
then
    echo "Please specify a non-zero wall time"
    exit 1
fi

# get executable
if [ "$GET_EXECUTABLE" == "1" ]
then
    rm -rf bin
    if [ -z "$NEXTSIMDIR" ]
    then
        echo "please define NEXTSIMDIR environment variable if you want to use GET_EXECUTABLE=1"
        exit 1
    fi
    cmd="cp -r $NEXTSIMDIR/model/bin ."
    echo $cmd
    $cmd
fi

if [ ! -f "bin/nextsim.exec" ]
then
    echo "Cannot find bin/nextsim.exec"
    echo "Use GET_EXECUTABLE=1"
    usage
    exit 1
fi

# get slurm template
script=slurm.${JOB_NAME}.sh
if [ -z "$NEXTSIM_ENV_ROOT_DIR" ]
then
    echo "please define NEXTSIM_ENV_ROOT_DIR environment variable in order to find slurm.template.sh"
    exit 1
fi

cmd="cp $NEXTSIM_ENV_ROOT_DIR/slurm.template.sh $script"
echo $cmd
$cmd

# modify the required fields
sed -i "s/JOB_NAME/$JOB_NAME/g" $script
sed -i "s/ACCOUNT_NUMBER/$ACCOUNT_NUMBER/g" $script
sed -i "s/NUM_NODES/$NUM_CORES/g" $script
sed -i "s/NUM_TASKS/$NUM_TASKS/g" $script
sed -i "s/WALL_TIME_DAYS/$WALL_TIME_DAYS/g" $script
sed -i "s/WALL_TIME_HOURS/$WALL_TIME_HOURS/g" $script
sed -i "s/WALL_TIME_MINUTES/$WALL_TIME_MINUTES/g" $script

# email
if [ ! -z "$MY_EMAIL" ]
then
    # can use "MY_EMAIL" environment variable
    sed -i "s/SLURM_EMAIL/$MY_EMAIL/g" $script
else
    #comment the email line
    sed -i 's/#SBATCH --mail-user/##SBATCH--mail-user/g' $script
fi

# number of cores: if 1 set qos=preproc for debug queue; exit if 2 or 3
    # uncomment the line asking to go into the debug queue
    # sed -i 's/##SBATCH --qos=preproc/#SBATCH --qos=preproc/g' $script
echo "Finished modifying $script"
# submit the script
cmd="sbatch --array=1-${NUM_ENS_MEM} $script `readlink -f $CONFIG` ${SLURM_SCRIPT_OPTS[@]}"
echo $cmd
if [ "$TEST" == "false" ]
then
    $cmd > sjob.id
#else
#    gvim $script
fi
jobid=$( awk '{print $NF}' sjob.id)

######################################################################
# submit enkf after finishing the ensemble simulations 
######################################################################
script=slurm.enkf.${JOB_NAME}.sh

cmd="cp $NEXTSIM_ENV_ROOT_DIR/slurm.enkf.template.sh $script"
echo $cmd
$cmd

# modify the required fields
sed -i "s/JOB_NAME/$JOB_NAME/g" $script
sed -i "s/ACCOUNT_NUMBER/$ACCOUNT_NUMBER/g" $script
sed -i "s/NUM_NODES/$NUM_CORES/g" $script
sed -i "s/NUM_TASKS/$NUM_TASKS/g" $script
sed -i "s/WALL_TIME_DAYS/$WALL_TIME_DAYS/g" $script
sed -i "s/WALL_TIME_HOURS/$WALL_TIME_HOURS/g" $script
sed -i "s/WALL_TIME_MINUTES/$WALL_TIME_MINUTES/g" $script


    # uncomment the line asking to go into the debug queue
    #sed -i 's/##SBATCH --qos=preproc/#SBATCH --qos=preproc/g' $script

# submit enkf after ensemble is done.
cmd="sbatch --dependency=afterok:${jobid} $script enkf "
$cmd
