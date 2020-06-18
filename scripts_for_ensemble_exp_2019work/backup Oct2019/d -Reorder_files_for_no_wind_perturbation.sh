#!/bin/bash

#old_dir=$Rdir/neXtSIM_test10_10_winter_step5_cohesion_perturbation
new_dir=$Rdir/neXtSIM_test10_10_winter_step5_cohesion_perturbation_reorder
#rm -rf $new_dir
#
#for (( i_date=1; i_date<= 14; i_date++ )); do
#for (( i_ens =1; i_ens <= 6; i_ens++ )); do 
#      mkdir -p $new_dir/ENS$i_ens/date$i_date/ENS1
#      cp -r $old_dir/date$i_date/ENS$i_ens/* $new_dir/ENS$i_ens/date$i_date/ENS1
#done
#done   

for (( i_ens =1; i_ens <= 20; i_ens++ )); do 
      mv $new_dir/ENS$i_ens $new_dir/array$i_ens 
done
