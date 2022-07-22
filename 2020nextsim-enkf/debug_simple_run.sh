#!/bin/bash 
set -uex
## step 1
#srun --nodes=1 --tasks-per-node=32 --time=00:30:00 --qos=devel --account=nn2993k --pty bash -i  

## step 2
echo "NEXTSIM_MESH_DIR: " $NEXTSIM_MESH_DIR
echo "NEXTSIM_DATA_DIR: " $NEXTSIM_DATA_DIR
echo "SCRATCH: "  $SCRATCH

CC=$SCRATCH
export CC=/cluster/work/jobs/2147904/mem1
cd $CC

cp -r /cluster/work/users/chengsukun/simulations/ensemble_forecasts_2019-09-03_1days_x_1cycles_memsize1/date1/mem1/* $CC

config=$CC/nextsim.cfg 
cp nextsim.cfg.backup  $config
sed -i "s;^exporter_path.*$;exporter_path=${CC};g" $config
sed -i "s;^input_path=.*$;input_path=$NEXTSIM_DATA_DIR;g"      $config
code $config


# ## step 3
export NEXTSIM_DATA_DIR=/cluster/work/users/chengsukun/simulations/test_era5_spinup_2019-09-02_46days_x_1cycles_memsize40/date1/mem1/data
cp nextsim.cfg.backup  nextsim.cfg
mpirun -np 2  $NEXTSIMDIR/model/bin/nextsim.exec  --config-file=nextsim.cfg >& task.log 
code task.log 