#!/bin/bash
source ./fram_sukun/nextsim.src
# 
job_list=$(squeue -u chengsukun)
XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
echo $XPID    
while [[ $XPID -ge 1 ]]; do # set the maximum of simultaneous running jobs, don't have to be Ne
      sleep 20
      job_list=$(squeue -u chengsukun)
      XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
done     

rm nohup.out
dir_list=("20080101T000000Z" "20080110T000000Z" "20080119T000000Z" "20080128T000000Z" "20080206T000000Z" \
          "20080215T000000Z" "20080224T000000Z" "20080304T000000Z" "20080313T000000Z" \
          "20080322T000000Z" "20080331T000000Z" "20080409T000000Z" "20080418T000000Z" "20080427T000000Z")
time_init_list=("2008-01-01" "2008-01-10" "2008-01-19" "2008-01-28" "2008-02-06" \
                "2008-02-15" "2008-02-24" "2008-03-04" "2008-03-13" \
                "2008-03-22" "2008-03-31" "2008-04-09" "2008-04-18" "2008-04-27" )

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
sed -i --follow-symlinks "s;^randf.*$;randf = .false.;g" $pseudo2D
ASR_air_drag=(0.0025 0.003 0.0035 0.004 0.0045 0.005 0.0055 0.006 0.0065 0.007 0.0075 0.008 0.0085 0.009)
#
for (( i_date=1; i_date<=${#dir_list[@]}; i_date++ )); do # ${#dir_list[@]}
for (( i_air=1; i_air<=${#ASR_air_drag[@]}; i_air++ )); do  # ${#ASR_air_drag[@]}
        # make the output directories L2
        ENSdir=$IO_nextsim/neXtSIM_test09_01_winter_step3_airdragcoefs/date$i_date/ENS$i_air #$airdrag${ASR_air_drag[$i_air-1]}
          
        # modify config files and send to member directories        
        sed -i "s|^time_init.*$|time_init=${time_init_list[$i_date-1]}|g" $config            
        sed -i "s|^exporter_path.*$|exporter_path=$ENSdir|g"  $config
        sed -i "s|^input_path.*$|input_path=$restart_dir|g" $config
        sed -i "s|^basename.*$|basename=${dir_list[$i_date-1]}|g" $config              
        sed -i "s|^ASR_quad_drag_coef_air.*$|ASR_quad_drag_coef_air=${ASR_air_drag[$i_air-1]}|g" $config    

        #-----------------------------------
        rm -rf $ENSdir
        mkdir -p $ENSdir
        cd $ENSdir
        cp $pseudo2D .
        cp $run_script . # backup
        cp $opened_script . # backup

        # should not be simplified cfg, it avoids overwrite and use nextsim.cfg in job_submisson folder in . $run_script $cfg 1 -e ~/nextsim.ensemble.src      
        cfg=$ENSdir/`basename $config`  
        cp $config $cfg          
        # submit job        
        . $run_script $cfg 1 -e ~/nextsim.ensemble.src                 
      # a block code to enable sequence job-submitting
      job_list=$(squeue -u chengsukun)
      XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
      echo $XPID    
      while [[ $XPID -ge 15 ]]; do # set the maximum of simultaneous running jobs, don't have to be Ne
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
