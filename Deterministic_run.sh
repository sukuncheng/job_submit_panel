#!/bin/bash
# no purturbation 
# set io （basic and restart） in nextsim.cfg，output directoru is defined below
# set evironmetnal variables
IO_nextsim=/cluster/work/users/chengsukun/src/IO_nextsim
Job_sub_dir=$IO_nextsim/job_submission
config=$Job_sub_dir/nextsim.cfg
run_script=$Job_sub_dir/run.fram.sh  # link of $NEXTSIM_ENV_ROOT_DIR/machines/fram_sukun/run.fram.sh
pseudo2D=$Job_sub_dir/pseudo2D.nml  # link of $NEXTSIMDIR/modules/enkf/perturbation/nml/pseudo2D.nml

# output directories and set it in nextsim.cfg
outdir=$IO_nextsim/neXtSIM_test07_02

sed -i "s|^exporter_path.*$|exporter_path=$outdir|g"  $config               
#-------------------------------------
rm -rf $outdir
mkdir -p $outdir
cd $outdir
cp $config .
cp $pseudo2D .
cp $Job_sub_dir/Deterministic_run.sh .

# submit job        
#   1 - copy nextsim.exec from NEXTSIMDIR/model/bin in order to run
#   -t test run without submit to fram
#   -e ~/nextsim.ensemble.src      # envirmonental variables
 $run_script $config 1 -e ~/nextsim.ensemble.src    

# submit a debug job
#sbatch $Job_sub_dir/run.fram.debug.sh `readlink -f $config` 
