#!/bin/bash
source ./fram_sukun/nextsim.src
# 
dir_list=("20080928T000000Z" "20081005T000000Z" "20081012T000000Z" "20081019T000000Z" "20081026T000000Z" \
          "20081102T000000Z" "20081109T000000Z" "20081116T000000Z" "20081123T000000Z")
time_init_list=("2008-09-28" "2008-10-05" "2008-10-12" "2008-10-19" "2008-10-26" \
                "2008-11-02" "2008-11-09" "2008-11-16" "2008-11-23" )

# set evironmetnal variables
# IO_nextsim=/cluster/work/users/chengsukun/src/IO_nextsim
# Job_sub_dir=~/src/fram_job_submit_panel
config=$Job_sub_dir/nextsim.cfg
run_script=$Job_sub_dir/run.fram.sh  # link of $NEXTSIM_ENV_ROOT_DIR/machines/fram_sukun/run.fram.sh
pseudo2D=$Job_sub_dir/pseudo2D.nml  # link of $NEXTSIMDIR/modules/enkf/perturbation/nml/pseudo2D.nml

# `pwd` - return of command pwd
# restart files io
# 1. send files link to nextsim/data/
# 2. copy files to work directory via nextsim/data/ in slurm.template.sh
restart_dir=$IO_nextsim/neXtSIM_test07_02/restart

# set pseudo2D.nml
# unsolved  sed -i --follow-symlinks "s;^iopath.*$;iopath   = `".`";g" $pseudo2D
sed -i --follow-symlinks "s;^randf.*$;randf = .false.;g" $pseudo2D
ASR_air_drag=(0.006 0.008 0.01 0.012 \
              0.014 0.016 0.018 0.02)
#
for (( i_date=1; i_date<=${#dir_list[@]}; i_date++ )); do # ${#dir_list[@]}
for (( i_air=1; i_air<=${#ASR_air_drag[@]}; i_air++ )); do  # ${#ASR_air_drag[@]}
  #   for (( i_ens=1; i_ens<=1; i_ens++ )); do
        # make the output directories L2
        outdir=$IO_nextsim/neXtSIM_test07_09_free_drift/date$i_date/airdrag${ASR_air_drag[$i_air-1]}
        # outdir=$IO_nextsim/neXtSIM_test07_09_free_drift/date$i_date/reference
        # make the run directory for each ensemble member L3
        ENSdir=$outdir  #/`printf "ENS%.2d" "$i_ens"`
          
        # modify config files and send to member directories
        sed -i "s|^exporter_path.*$|exporter_path=$ENSdir|g"  $config
        sed -i "s|^time_init.*$|time_init=${time_init_list[$i_date-1]}|g" $config            
        sed -i "s|^input_path.*$|input_path=$restart_dir|g" $config
        sed -i "s|^basename.*$|basename=${dir_list[$i_date-1]}|g" $config              
        sed -i "s|^ASR_quad_drag_coef_air.*$|ASR_quad_drag_coef_air=${ASR_air_drag[$i_air-1]}|g" $config    

        #-----------------------------------
        rm -rf $ENSdir
        mkdir -p $ENSdir
        cd $ENSdir
        cp $pseudo2D .
        cp $run_script . # backup
        cp $Job_sub_dir/Adjust_air_drag.sh . # backup

        # should not be simplified cfg, it avoids overwrite and use nextsim.cfg in job_submisson folder in . $run_script $cfg 1 -e ~/nextsim.ensemble.src      
        cfg=$ENSdir/`basename $config`  
        cp $config $cfg          
        # submit job        
        . $run_script $cfg 1 -e ~/nextsim.ensemble.src                 
  #  done   
done
done
# a block code to enable sequence job-submitting
      # XPID=$(squeue |grep chengsuk)
      # while [[ ${XPID}x != ""x ]]; do
      #   sleep 20
      #   XPID=$(squeue |grep chengsuk)
      #   echo $XPID
      # done    

#  . $run_script $cfg 1 -e ~/nextsim.ensemble.src                  
  #   1 - copy nextsim.exec from NEXTSIMDIR/model/bin in order to run
  #   -t test run without submit to fram
  #   -e ~/nextsim.ensemble.src      # envirmonental variables
