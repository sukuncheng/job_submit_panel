#!/bin/bash
source ./fram_sukun/nextsim.src

# set io （basic and restart） in nextsim.cfg，output directoru is defined below
# set evironmetnal variables
Job_sub_dir=$(cd `dirname $0`;pwd)       # path of this .sh 
cp $Job_sub_dir/nextsim.cfg step1a_deterministic_no_restart $Job_sub_dir/nextsim.cfg
config=$Job_sub_dir/nextsim.cfg
run_script=${NEXTSIM_ENV_ROOT_DIR}/run.fram.sh  # link of $NEXTSIM_ENV_ROOT_DIR/machines/fram_sukun/run.fram.sh
pseudo2D=$Job_sub_dir/pseudo2D.nml  # link of $NEXTSIMDIR/modules/enkf/perturbation/nml/pseudo2D.nml
opened_script=$Job_sub_dir/`basename $0`  
sed -i --follow-symlinks 's/^iopath.*$/iopath   = "."/g' $pseudo2D
sed -i --follow-symlinks "s;^randf.*$;randf = .false.;g" $pseudo2D

# set output directories  in nextsim.cfg, as well as restart settings
# 01.01.2007-31.12.2007
outdir=$IO_nextsim/neXtSIM_step1_deterministic_run_1
# 01.01.2008-28.04.2008, restart=true
#outdir=$IO_nextsim/neXtSIM_step1_deterministic_run_2
sed -i "s|^exporter_path.*$|exporter_path=$outdir|g"  $config               

#-------------------------------------
rm -rf $outdir
mkdir -p $outdir
cd $outdir
cp $pseudo2D .
cp $run_script . # backup
cp $opened_script . # backup filepath=$(cd "$(dirname "$0")"; pwd)  

# should not be simplified cfg, it avoids overwrite and use nextsim.cfg in job_submisson folder in . $run_script $cfg 1 -e ~/nextsim.ensemble.src      
cfg=$outdir/`basename $config`  
cp $config $cfg       
# submit job        
 $run_script $cfg 1 -e ~/nextsim.ensemble.src    
#   1 - copy nextsim.exec from NEXTSIMDIR/model/bin in order to run
#   -t test run without submit to fram
#   -e ~/nextsim.ensemble.src      # envirmonental variables
# submit a debug job
#sbatch $Job_sub_dir/run.fram.debug.sh `readlink -f $config` 
