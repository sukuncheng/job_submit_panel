#!/bin/bash
source ./fram_sukun/nextsim.src
rm nohup.out
# 
dir_list="20080101T000000Z" 
time_init_list="2008-01-01"
Ne=80

# set evironmetnal variables
# IO_nextsim=/cluster/work/users/chengsukun/src/IO_nextsim
# Job_sub_dir=~/src/fram_job_submit_panel
config=$Job_sub_dir/nextsim.cfg
run_script=$Job_sub_dir/run.fram.sh  # link of $NEXTSIM_ENV_ROOT_DIR/machines/fram_sukun/run.fram.sh
pseudo2D=$Job_sub_dir/pseudo2D.nml  # link of $NEXTSIMDIR/modules/enkf/perturbation/nml/pseudo2D.nml
opened_script=$Job_sub_dir/`basename $0`  
# restart files io
# 1. send files link to nextsim/data/
# 2. copy files to work directory via nextsim/data/ in slurm.template.sh
restart_dir=$IO_nextsim/neXtSIM_test09_01_winter_step2/restart

# set pseudo2D.nml
sed -i --follow-symlinks 's/^iopath.*$/iopath   = "."/g' $pseudo2D
sed -i --follow-symlinks "s;^randf.*$;randf = .true.;g" $pseudo2D
sed -i --follow-symlinks "s;^vwndspd.*$;vwndspd  = 3;g" $pseudo2D
#
for (( i_date=1; i_date<= ${#dir_list[@]}; i_date++ )); do # ${#dir_list[@]}
for (( i_ens =1; i_ens <=$Ne; i_ens++ )); do
      # make the output directories L2
      ENSdir=$IO_nextsim/neXtSIM_test09_02_winter_step4a_wind_perturbation_vwnd_3_semsemblesize/date$i_date/ENS$i_ens
      
      # modify config files and send to member directories
      sed -i "s|^time_init.*$|time_init=${time_init_list[$i_date-1]}|g" $config       
      sed -i "s|^exporter_path.*$|exporter_path=$ENSdir|g"  $config           
      sed -i "s|^input_path.*$|input_path=$restart_dir|g" $config
      sed -i "s|^basename.*$|basename=${dir_list[$i_date-1]}|g" $config               

      #-----------------------------------
      rm -rf $ENSdir
      mkdir -p $ENSdir
      cd $ENSdir
      cp $pseudo2D .
      cp $run_script . # backup
      cp $opened_script . # backup filepath=$(cd "$(dirname "$0")"; pwd)  

      # should not be simplified cfg, it avoids overwrite and use nextsim.cfg in job_submisson folder in . $run_script $cfg 1 -e ~/nextsim.ensemble.src      
      cfg=$ENSdir/`basename $config`  
      cp $config $cfg          
      # submit job        
      . $run_script $cfg 1 -e ~/nextsim.ensemble.src       
      # a block code to enable sequence job-submitting
      job_list=$(squeue -u chengsukun)
      XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
      echo $XPID    
      while [[ $XPID -ge 10 ]]; do # set the maximum of simultaneous running jobs, don't have to be Ne
            sleep 20
            job_list=$(squeue -u chengsukun)
            XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
      done          

done
done   

#  . $run_script $cfg 1 -e ~/nextsim.ensemble.src                  
  #   1 - copy nextsim.exec from NEXTSIMDIR/model/bin in order to run
  #   -t test run without submit to fram
  #   -e ~/nextsim.ensemble.src      # envirmonental variables

# `pwd` - return of command pwd
#/`printf "ENS%.2d" "$i_ens"`
