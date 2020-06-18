#!/bin/bash
function usage {
    echo "Usage:"
    echo "run.fram CONFIG_FILE GET_EXECUTABLE [options] [options for run.fram.sh]"
    echo "CONFIG_FILE is name of config file for nextsim"
    echo "    This should be a template with ensemble member and output directory"
    echo "    to be changed with sed"
    echo "GET_EXECUTABLE = 0 or 1"
    echo "    1: get nextsim.exec from NEXTSIMDIR/model/bin"
    echo "    0: already have nextsim.exec in bin/nextsim.exec"
    echo ""
    echo "Options:"
    echo "-n|--number-of-ensemble-members N"
    echo "    Number of ensemble members to use"
    echo "-o|--outdir OUTDIR"
    echo "    ensemble members will be run in, and results saved to,"
    echo "    subdirs of this directory called eg mem_001"
    echo "-t|--test"
    echo "    Test input args are parsed correctly"
    echo "    (echo main commands instead of executing them)"
    echo ""
    echo "Slurm script options:"
    echo "see usage of slurm.template.sh"
}

# default values for options
TEST=false

# changed manually in slurm script with sed
NUM_ENS_MEM=1
OUTDIR=`pwd`

# passed in as options to run script
RUN_SCRIPT_OPTS=()

# parse optional parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -n|--number-of-ensemble-members)
            NUM_ENS_MEM="$2"
            shift # past argument
            shift # past value
            ;;
        -o|--outdir)
            OUTDIR="$2"
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
                RUN_SCRIPT_OPTS+=("$1") # save it in an array for later
            fi
            shift # past argument
            ;;
    esac
done

# restore positional parameters
set -- "${POSITIONAL[@]}" 

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
else
    config=`readlink -f $CONFIG`
fi

mkdir -p $OUTDIR
cd $OUTDIR
outdir=`pwd`

# get executable
if [ "$GET_EXECUTABLE" == "1" ]
then
    rm -rf bin
    if [ -z "$NEXTSIMDIR" ]
    then
        echo please define NEXTSIMDIR environment variable
        echo if you want to use GET_EXECUTABLE=1
        exit 1
    fi
    cmd="cp -r $NEXTSIMDIR/model/bin ."
    echo $cmd
    $cmd
fi
if [ ! -f "bin/nextsim.exec" ]
then
    echo "Can't find bin/nextsim.exec"
    echo "Use GET_EXECUTABLE=1"
    usage
    exit 1
fi

bindir=`readlink -f bin`
run_script=$NEXTSIM_ENV_ROOT_DIR/machines/fram_sukun/run.fram.sh
if [ ! -f $run_script ]
then
    echo "can't  find run.fram.sh"
    echo "it should be in $NEXTSIM_ENV_ROOT_DIR/machines/fram_sukun"
    exit 1
fi
#-----------------------------------------------------
# rm -rf ENS*
# pseudo2D=$NEXTSIMDIR/modules/enkf/perturbation/nml/pseudo2D.nml # used in slurm.template.sh, copy it to jobs/job_ID/
#-----------------------------------------------------
for i_ens in `seq 1 $NUM_ENS_MEM`
do
    # make the run directory for each ensemble member
    subdir=$outdir/`printf "ENS%.2d" "$i_ens"`
    mkdir -p $subdir

    # link to executable
    ln -sf $bindir $subdir/bin

    # get config file and modify
    cfg=$subdir/`basename $config`
    cp $config $cfg
    # modify the required fields
 #   sed -i "s|ENS_MEM|$i_ens|g" $cfg
    sed -i "s|OUTDIR|$subdir|g" $cfg

    # launch the job
    cmd="$run_script $cfg 0 ${RUN_SCRIPT_OPTS[@]}"
    echo $cmd
    if [ "$TEST" == "false" ]
    then
        $cmd
    fi
done
