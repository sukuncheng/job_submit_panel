#!/bin/bash 
set -uex
# direct way
cd /cluster/work/users/chengsukun/simulations/ensemble_forecasts_2019-09-03_1days_x_1cycles_memsize1/date1/mem1
cp nextsim.cfg.backup nextsim.cfg
# sbatch --nodes=1 --tasks-per-node=128 --time=00:60:00 --qos=devel --account=nn2993k mpirun -np 128  $NEXTSIMDIR/model/bin/nextsim.exec  --config-file=nextsim.cfg
 sbatch --nodes=4 --tasks-per-node=128 --time=0:30:00 --account=nn2993k mpirun -np 128  $NEXTSIMDIR/model/bin/nextsim.exec  --config-file=nextsim.cfg

# error, step creation temporarily disabled, retrying (Requested nodes are busy)
# srun --partition=preproc --mem-per-cpu=2G --time=0-1:0:00 --account=nn2993k mpirun -np 2  $NEXTSIMDIR/model/bin/nextsim.exec  --config-file=nextsim.cfg  #np<=16 for preproc



# interactive way
## step 1, request cpu node 
srun --nodes=1 --tasks-per-node=32 --time=00:30:00 --qos=devel --account=nn2993k --pty bash -i  

## step 2, copy a case to authorized cpu node
echo "NEXTSIM_MESH_DIR: " $NEXTSIM_MESH_DIR
# export NEXTSIM_DATA_DIR=/cluster/work/users/chengsukun/simulations/test_era5_spinup_2019-09-02_46days_x_1cycles_memsize40/date1/mem1/data
echo "NEXTSIM_DATA_DIR: " $NEXTSIM_DATA_DIR
echo "SCRATCH: "  $SCRATCH

cp -r /cluster/work/users/chengsukun/simulations/ensemble_forecasts_2019-09-03_1days_x_1cycles_memsize1/date1/mem1 $SCRATCH
cd $SCRATCH/mem1
config=nextsim.cfg 
cp nextsim.cfg.backup  $config
sed -i "s;^exporter_path.*$;exporter_path=${SCRATCH};g"        $config
sed -i "s;^input_path=.*$;input_path=$NEXTSIM_DATA_DIR;g"      $config
cat $config

# ## step 3 
mpirun -np 128  $NEXTSIMDIR/model/bin/nextsim.exec  --config-file=nextsim.cfg >& task.log 
code task.log 
# other options
mpirun -np 2  $NEXTSIMDIR/model/bin/nextsim.exec  --configile=nextsim.cfg 
