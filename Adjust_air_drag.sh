#!/bin/bash

# 
dir_list=("20080928T000000Z" "20081005T000000Z" "20081012T000000Z" "20081019T000000Z" "20081026T000000Z" \
          "20081102T000000Z" "20081109T000000Z" "20081116T000000Z" "20081123T000000Z")
time_init_list=("2008-09-28" "2008-10-05" "2008-10-12" "2008-10-19" "2008-10-26" \
                "2008-11-02" "2008-11-09" "2008-11-16" "2008-11-23" )

# set evironmetnal variables
IO_nextsim=/cluster/work/users/chengsukun/src/IO_nextsim
Job_sub_dir=$IO_nextsim/job_submission
config=$Job_sub_dir/nextsim.cfg
pseudo2D=$Job_sub_dir/pseudo2D.nml  # link of $NEXTSIMDIR/modules/enkf/perturbation/nml/pseudo2D.nml
run_script=$Job_sub_dir/run.fram.sh  # link of $NEXTSIM_ENV_ROOT_DIR/machines/fram_sukun/run.fram.sh
# `pwd` - return of command pwd
# restart files io
# 1. send files link to nextsim/data/
# 2. copy files to work directory via nextsim/data/ in slurm.template.sh
restart_dir=/cluster/work/users/chengsukun/src/IO_nextsim/neXtSIM_test07_02/restart
#ln -sf $IO_nextsim/neXtSIM_test22_06/ENS01/restart/* $restart_dir
# set pseudo2D.nml
sed -i --follow-symlinks "s;^randf.*$;randf = .false.;g" $pseudo2D
ASR_air_drag=(0.001 0.0015 0.002 0.0025 0.003 0.0035 0.004 0.0045)
#
for (( i_date=1; i_date<=1; i_date++ )); do # ${#dir_list[@]}
for (( i_air=1; i_air<=7; i_air++ )); do  # ${#ASR_air_drag[@]}
  #   for (( i_ens=1; i_ens<=1; i_ens++ )); do
        # make the output directories L2
        outdir=$IO_nextsim/neXtSIM_test07_05_multitasks_test/date$i_date/airdrag${ASR_air_drag[$i_air-1]}
        # make the run directory for each ensemble member L3
        ENSdir=$outdir  #/`printf "ENS%.2d" "$i_ens"`
          
        # modify config files and send to member directories
        sed -i "s|^exporter_path.*$|exporter_path=$ENSdir|g"  $config
        sed -i "s|^time_init.*$|time_init=${time_init_list[$i_date-1]}|g" $config            
        sed -i "s|^input_path.*$|input_path=$restart_dir|g" $config
        sed -i "s|^basename.*$|basename=${dir_list[$i_date-1]}|g" $config               
        #-------------------------------------
        # cfg=$ENSdir/`basename $config`
        rm -rf $ENSdir
        mkdir -p $ENSdir
        cd $ENSdir
        cp $config .
        cp $pseudo2D .
        
    #    # submit job        
        . $run_script $config 1 -e ~/nextsim.ensemble.src                  
        #   1 - copy nextsim.exec from NEXTSIMDIR/model/bin in order to run
        #   -t test run without submit to fram
        #   -e ~/nextsim.ensemble.src      # envirmonental variables

  #  done   
done
      XPID=$(squeue |grep chengsuk)
      while [[ ${XPID}x != ""x ]]; do
        sleep 20
        XPID=$(squeue |grep chengsuk)
        echo $XPID
      done    
done