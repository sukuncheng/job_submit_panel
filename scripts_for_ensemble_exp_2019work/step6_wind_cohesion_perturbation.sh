# add switches for perturbations of wind and cohesion, thus, this script can cover step4,5,6
# by turning on/off wind/cohesion perturbation in the setting part below
#!/bin/bash
source ./fram_sukun/nextsim.src 
# 
rm nohup.out
# dir_list=("20080101T000000Z" "20080110T000000Z" "20080119T000000Z" "20080128T000000Z" "20080206T000000Z" \
#           "20080215T000000Z" "20080224T000000Z" "20080304T000000Z" "20080313T000000Z" \
#           "20080322T000000Z" "20080331T000000Z" "20080409T000000Z" "20080418T000000Z" ) # "20080427T000000Z"
# time_init_list=("2008-01-01" "2008-01-10" "2008-01-19" "2008-01-28" "2008-02-06" \
#                 "2008-02-15" "2008-02-24" "2008-03-04" "2008-03-13" \
#                 "2008-03-22" "2008-03-31" "2008-04-09" "2008-04-18" )
dir_list="20080110T000000Z"
time_init_list="2008-01-10"
# set evironmetnal variables
cp ./nextsim.cfg_step456 ./nextsim.cfg
config=$Job_sub_dir/nextsim.cfg
run_script=$Job_sub_dir/run.fram.sh  # link of $NEXTSIM_ENV_ROOT_DIR/machines/fram_sukun/run.fram.sh
pseudo2D=$Job_sub_dir/pseudo2D.nml  # link of $NEXTSIMDIR/modules/enkf/perturbation/nml/pseudo2D.nml
opened_script=$Job_sub_dir/`basename $0`  
# restart files io
# 1. send files link to nextsim/data/
# 2. copy files to work directory via nextsim/data/ in slurm.template.sh
restart_dir=$IO_nextsim/neXtSIM_test09_01_winter_step2/restart
########################## changes  #########################################
Output_dir=/neXtSIM_test12_04_winter_step5_cohesion_perturbation
wind_perturbation='no'
cohesion_perturbation='yes'
#
# Output_dir=/neXtSIM_test10_28_winter_step5_cohesion_perturbation
# wind_perturbation='no'
# cohesion_perturbation='yes'
#
# Output_dir=/neXtSIM_test10_26_winter_step6_wind_cohesion_perturbation
# wind_perturbation='yes'
# cohesion_perturbation='yes'
#
# wind force
sed -i --follow-symlinks 's/^iopath.*$/iopath   = "."/g' $pseudo2D
sed -i --follow-symlinks "s;^vwndspd.*$;vwndspd  = 3;g" $pseudo2D
if [ $wind_perturbation == 'yes' ]
then    
    sed -i --follow-symlinks "s;^randf.*$;randf = .true.;g" $pseudo2D
else
    sed -i --follow-symlinks "s;^randf.*$;randf = .false.;g" $pseudo2D
fi
# cohesion
sed -i "s|^C_lab.*$|C_lab=8215800|g"  $config # C_lab=6.8465e+6*30/25 (Pa)
if [ $cohesion_perturbation == 'yes' ]
then
    sed -i "s|^alea_factor.*$|alea_factor=0.333333|g"  $config
else
    sed -i "s|^alea_factor.*$|alea_factor=0.|g"  $config
fi

#############################################################################
for (( i_date=1; i_date<=${#dir_list[@]}; i_date++ )); do #
      if [ $i_date == 1]
            Ne=80
      then
            Ne=20 # ensemble size
      fi
      for (( i_ens =1; i_ens <=$Ne; i_ens++ )); do 
            # # make the output directories L2
            ENSdir=$IO_nextsim$Output_dir/date$i_date/ENS$i_ens
            echo $ENSdir
            # modify config files 
            sed -i "s|^exporter_path.*$|exporter_path=$ENSdir|g"  $config
            sed -i "s|^time_init.*$|time_init=${time_init_list[$i_date-1]}|g" $config            
            sed -i "s|^input_path.*$|input_path=$restart_dir|g" $config
            sed -i "s|^basename.*$|basename=${dir_list[$i_date-1]}|g" $config               

            #create job directory and send to member directories  
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
# #/`printf "ENS%.2d" "$i_ens"`
for (( i_date=1; i_date<= ${#dir_list[@]}; i_date++ )); do
for (( i_ens =1; i_ens <=$Ne; i_ens++ )); do 
      # # make the output directories L2
      ENSdir=$IO_nextsim$Output_dir/date$i_date/ENS$i_ens
      cd $ENSdir
      #
      if !(grep -q "Simulation done" nextsim.log)
      then          
          rm *.nc *bin *.dat 
          . $run_script nextsim.cfg 1 -e ~/nextsim.ensemble.src       # submit job  
      fi
      # a block code to enable sequence job-submitting
      job_list=$(squeue -u chengsukun)
      XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
      while [[ $XPID -ge 10 ]]; do # set the maximum of simultaneous running jobs, don't have to be Ne
            sleep 20
            job_list=$(squeue -u chengsukun)
            XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
      done       
done
done   
