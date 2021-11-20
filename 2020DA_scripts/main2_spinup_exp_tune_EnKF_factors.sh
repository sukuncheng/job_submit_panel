#!/bin/bash
set -eux
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR
function WaitforTaskFinish(){
    # ------ wait the completeness in this cycle.
    XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 	
    while [[ $XPID -gt $1 ]]; do 
        sleep 60
        XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) # number of running jobs 
    done
}
## Tune factors (refer to Todo 9)
# 1. Incresing R-factor decreases the impact of observation. Ensemble spread/sqrt(R-factor). Specifying R-factor equal k produces the same increment as reducing the ensemble spread by k1/2 times.
# 2. Incresing K-factor increases the impact of ensemble spread. background check. 2.7.3. 
#    Modifies observation error so that the increment for this observation would not exceed KFACTOR * <ensemble spread> (all in observation space) after assimilating this observation only.
# 3. Inflation . The ensemble anomalies (A=E-x.1') for any model state element will be inflated to avoid collapses. 
#     (x_a - x\bar)*inflation + x\bar
#     capping of inflation: inflation = 1+inflation*( std_f/std_a-1)
# 4. Increasing the localisation radius increases the number of local observations and hence the overall impact of observations. To compensate this in a system with horizontal localisation one has to change the R-factor as the square of the localisation radius.
# Covariance localization remedies sampling errors due to limited ensemble size in ensemble data assimilation


# reference settings
# KFACTORs=("2" "1")  # default as 2 in topaz
# RFACTORs=("2" "1")   #1
# LOCRADs=("100" "300" "600")  # meaning, radius 2.3*
# INFLATIONs=("1" "1.03" "1.09")  # <1.1 for 100 members
JOB_SETUP_DIR=$(cd `dirname $0`;pwd)
>nohup.out  # empty this file

ENSPATH=/cluster/work/users/chengsukun/simulations/test_spinup_2019-09-03_45days_x_1cycles_memsize40_offline_perturbations/date1
for VAR in sic sit sitsic; do #sic sit sitsic
    #set enkf parameters
    KFACTORs=("2")  # default as 2 in topaz
    # RFACTORs=("1" "1.2" "1.4" "1.6" "1.8" "2")   #1
    #LOCRADs=( "100" "300" "600")  # meaning, radius 2.3*
    RFACTORs=("2") #("1" "1.2" "1.4" "1.6" "1.8" "2" "2.2" "2.4" "3") 
    LOCRADs=( "300" )  # meaning, radius 2.3*
    INFLATIONs=("1" )  # <1.1 for 100 members
    ENSSIZE=40

    # cd /cluster/home/chengsukun/src/nextsim; make -j8
    cd $JOB_SETUP_DIR
    FILTER=${ENSPATH}/filter
    [ ! -d $FILTER/prior ] && mkdir -p $FILTER/prior
    ln -sf  $NEXTSIM_DATA_DIR/reference_grid.nc ${FILTER}/reference_grid.nc

    cp $JOB_SETUP_DIR/enkf_cfg_$VAR/* $FILTER/
    cp ${NEXTSIMDIR}/modules/enkf/enkf-c/bin/enkf_* $FILTER/
    script=${ENSPATH}/slurm.enkf.template.sh
    cp ${NEXTSIM_ENV_ROOT_DIR}/slurm.enkf.template.sh $script
    # >${JOB_SETUP_DIR}/result.md
    # echo "parameters combination     type  NumberofObs.  [for.inn.]  [an.inn.]   for.inn.   an.inn.  for.spread    an.spread" > result.md
    #
    for (( k1=0; k1<${#KFACTORs[@]};   k1++ )); do
    for (( r1=0; r1<${#RFACTORs[@]};   r1++ )); do
    for (( l1=0; l1<${#LOCRADs[@]};    l1++ )); do
    for (( i1=0; i1<${#INFLATIONs[@]}; i1++ )); do
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            memname=mem${i}
            [ -f ${ENSPATH}/$memname/prior.nc ] && mv ${ENSPATH}/$memname/prior.nc  ${FILTER}/prior/$(printf "mem%.3d" ${i}).nc
        done

    # edit enkf settings
        cd ${FILTER}
        INFLATION=${INFLATIONs[$i1]}
        LOCRAD=${LOCRADs[$l1]}
        RFACTOR=${RFACTORs[$r1]}
        KFACTOR=${KFACTORs[$k1]}  
        sed -i "s|^ENSSIZE.*$|ENSSIZE = ${ENSSIZE}|g; \
                s|^INFLATION.*$|INFLATION = ${INFLATION}|g; \
                s|^LOCRAD.*$|LOCRAD = ${LOCRAD}|g;\
                s|^RFACTOR.*$|RFACTOR = ${RFACTOR}|g; \
                s|^KFACTOR.*$|KFACTOR = ${KFACTOR}|g;"  enkf.prm
        sed -i "s|^FILE=.*$|FILE=$NEXTSIM_DATA_DIR/OSISAF_ice_conc/polstere/2019_nh_polstere/ice_conc_nh_polstere-100_multi_201910181200.nc|g; "  obs.prm
        sed -i "s|^DATA=.*$|DATA=reference_grid.nc|g; "  grid.prm
        # sbatch $script; wait   # run enkf
        make clean
        ./enkf_prep --no-superobing enkf.prm 2>&1 | tee prep.out
        mpirun -np 16 ./enkf_calc --use-rmsd-for-obsstats --ignore-no-obs enkf.prm 2>&1 | tee calc.out
        mpirun -np 16 ./enkf_update --calculate-spread enkf.prm 2>&1 | tee update.out
        
        for (( i=1; i<=${ENSSIZE}; i++ )); do
            memname=mem${i}
            cdo merge reference_grid.nc  ${FILTER}/prior/$(printf "mem%.3d" $i).nc.analysis  ${FILTER}/prior/${memname}.nc.analysis   
        done
        # 
        # string=$( tail -3 ${FILTER}/calc.out|head -1 )
        # echo "I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}  $string" >> ${JOB_SETUP_DIR}/result.md
        # OUTPUT_DIR=${FILTER}/size${ENSSIZE}_I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}_DA_sit_osisaf
        OUTPUT_DIR=${FILTER}/size${ENSSIZE}_I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}_DA$VAR
        [ -d $OUTPUT_DIR ] &&  rm -r  $OUTPUT_DIR
        mkdir $OUTPUT_DIR
        mv ${FILTER}/*.out ${OUTPUT_DIR}
        mv ${FILTER}/prior/*.analysis ${OUTPUT_DIR}
        mv ${FILTER}/*.nc  ${OUTPUT_DIR}
        mv ${FILTER}/*.prm ${OUTPUT_DIR}
        # mv ${FILTER}/slurm.*.log ${OUTPUT_DIR}
        mv ${OUTPUT_DIR}/reference_grid.nc ${FILTER}
    done
    done
    done
    done
done
cp ${JOB_SETUP_DIR}/nohup.out  ${OUTPUT_DIR} 
echo "finished"
