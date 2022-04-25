#!/bin/bash
    NPROC=4       # cpu cores 
    ESIZE=3  
for (( mem=1; mem<=${ESIZE}; mem++ )); do
    MEMPATH=/docker_io/mem$(printf "%03d" $mem)
    cd $MEMPATH
    mpirun --allow-run-as-root -np $NPROC nextsim.exec \
        -mat_mumps_icntl_23 1000 \
        --config-files=./nextsim.cfg > ./log.txt 2>&1
    echo '----member -----'  $mem
    # cmd="pgrep -x nextsim.exec | xargs ps -o cmd -p|grep -v ^CMD$|grep -c nextsim.exec"
    # echo "It is running member " $cmd
    # # allow running docker containers number
    # while [[ $cmd -ge 2*$NPROC ]]; do 
    #     echo "It is running member " $cmd
    #     sleep 10  # time in seconds to wait 
    # done             
done # ensemble loop
# kill all same name processes
#ps -ef | grep nextsim.exec | awk '{print $2}' | xargs kill
# number of same name processes
pgrep -x nextsim.exec | xargs ps -o cmd -p|grep -v ^CMD$|grep -c nextsim.exec