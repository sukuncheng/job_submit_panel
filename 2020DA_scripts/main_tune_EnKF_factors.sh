#!/bin/bash
set -e
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR
## Tune factors (refer to Todo 9)
# 1. Incresing R-factor decreases the impact of observation. Ensemble spread/sqrt(R-factor)
# 2. Incresing K-factor increases the impact of ensemble spread. background check. 2.7.3. 
#    Modifies observation error so that the increment for this observation would not exceed KFACTOR * <ensemble spread> (all in observation space) after assimilating this observation only.
# 3. Inflation . The ensemble anomalies (A=E-x.1') for any model state element will be inflated to avoid collapses. 
#     (x_a - x\bar)*inflation + x\bar
#     capping of inflation: inflation = 1+inflation*( std_f/std_a-1)
# 4. localisation radii defines the impact area size of observation. Increasing it increases the number of local observations

INFLATIONs=("1" "1.5" "2")
LOCRADs=("100" "400" "800")
RFACTORs=("1" "1.5" "2")
KFACTORs=("1" "500" "1000")
# INFLATION=${INFLATIONs[0]}
# LOCRAD=${LOCRADs[0]}
# RFACTOR=${RFACTORs[0]}
# KFACTOR=${KFACTORs[0]}    
# source main_job_submit.sh
#
for (( i=0; i<${#INFLATIONs[@]}; i++ )); do
for (( j=0; j<${#LOCRADs[@]};    j++ )); do
for (( k=0; k<${#RFACTORs[@]};   k++ )); do
for (( m=0; m<${#KFACTORs[@]};   m++ )); do
    INFLATION=${INFLATIONs[$i]}
    LOCRAD=${LOCRADs[$j]}
    RFACTOR=${RFACTORs[$k]}
    KFACTOR=${KFACTORs[$m]}    
    source main_job_submit.sh
    
    # wait for all jobs to finish
    while [[ $Nruns -ge 1 ]]; do 
        sleep 200
        XPID=$((squeue -u chengsukun) | grep -o chengsuk |wc -l) # number of current running jobs 
    done   
done
done
done
done