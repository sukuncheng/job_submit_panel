#!/bin/bash
mnt_dir=/cluster/work/users/chengsukun/simulations
# mnt_dir=/nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun/
# DIR=$mnt_dir/test_windcohesion_2019-10-15_7days_x_12cycles_memsize40/date1/filter
DIR=$mnt_dir/test_windcohesion_2019-09-03_42days_x_1cycles_memsize40/date1/filter

cd ~/src/nextsim; 
make  -j8; 
cd $DIR;
rm -f enkf_*
cp ~/src/nextsim/modules/enkf/enkf-c/bin/* .;make clean; 
./enkf_prep --log-all-obs --no-superobing enkf.prm 2>&1 | tee prep.out

# mpirun --allow-run-as-root -np 8 ./enkf_calc --use-rmsd-for-obsstats --ignore-no-obs enkf.prm 2>&1 | tee calc.out
# ./enkf_update --calculate-spreadls enkf.prm 2>&1 | tee update.out

# cd $DIR/prior
# for (( i=1; i<=40; i++ )); do
#     memid=$(printf "mem%.3d" ${i})
#     mv ${memid}_sit.nc ${memid}.nc 
# done