#!/bin/bash
echo "Part 2. Forecast and assimilation"
#------ PART 1: ensemble forecasting ------------
if [ ${time_init} == "2018-11-11" ]; then
    echo "  skip ensemble forecasting"
else
    for (( mem=1; mem<=${ESIZE}; mem++ )); do
        cd ${ENSPATH}/${ENSEMBLE[${mem}]}  #MEMPATH
        # update time_init per time step
        sed -i "s;^time_init=.*$;time_init="${time_init}";g" ./nextsim.cfg
        sed -i "s;^restart_from_analysis=.*$;restart_from_analysis="${restart_from_analysis}";g" ./nextsim.cfg 
        sed -i "s;^start_from_restart=.*$;start_from_restart="${start_from_restart}";g" ./nextsim.cfg       
    done     
fi


#-------  PART 2: enkf - UPDATE ENSEMBLE  ---------
if [[ ${UPDATE} -eq 1 ]]; then
    echo "Start EnKF assimilation" 
    echo "  link mem00*/prior.nc to /filter/prior/mem00*.nc"
    if [ ${time_init} == "2018-11-11" ]; then
        cp -r ${IO_nextsim}/prior ${FILTER}
    else
        for (( mem=1; mem<=${ESIZE}; mem++ )); do
            [ -f ${ENSPATH}/${ENSEMBLE[${mem}]}/prior.nc ] && mv  ${ENSPATH}/${ENSEMBLE[${mem}]}/prior.nc \
                ${FILTER}/prior/${ENSEMBLE[${mem}]}'.nc' # use `ln -sf` in docker cannot link correctly with data on host machine
            if [[ -f ${ENSPATH}/${ENSEMBLE[${mem}]}/*.00 ]];then
                rm -f ${ENSPATH}/${ENSEMBLE[${mem}]}/*.00 ${ENSPATH}/${ENSEMBLE[${mem}]}/*.01
            fi
        done
    fi
    #

    cd $FILTER
    echo "  link observations to ENSPATH/filter/obs, and obs.prm"
    A1=1 # 
    A2=`expr "(${A1}+6)"|bc`
    SMOSOBS=${OBSNAME_PREFIX}$(date +%Y%m%d -d "${time_init} + $A1 day")_$(date +%Y%m%d -d "${time_init} + $A2 day")${OBSNAME_SUFFIX}.nc
    if [ -f ${SMOSOBS} ]; then
        sed -i "s;^.*FILE.*$;FILE ="${SMOSOBS}";g"  obs.prm 
    else
        echo "WARNING: ${SMOSOBS} is not found. "
    fi
    #
    echo "  run enkf, outputs: $filter/prior/*.nc.analysis, $filter/enkf.out" 
    make clean #must clean previous results like observation*.nc
    #    make enkf  ########$NEXTSIMDIR/data:/data##### change data address in .prm files
    ./enkf_prep --no-superobing enkf.prm 2>&1 | tee prep.out
    ./enkf_calc --use-rmsd-for-obsstats enkf.prm 2>&1 | tee calc.out
    ./enkf_update --calculate-spread  enkf.prm 2>&1 | tee update.out    

    #
    echo "  project *.nc.analysis on reference_grid.nc, save to /NEXTSIMDIR/data/ for ensemble forecasting in the next cycle"
    rm -f ${NEXTSIMDIR}/data/*.nc.analysis    
    for (( mem=1; mem<=${ESIZE}; mem++ )); do
        [ ! -f ${FILTER}/prior/${ENSEMBLE[${mem}]}.nc.analysis  ] && sleep 5
        cdo merge ./reference_grid.nc  ./prior/${ENSEMBLE[${mem}]}.nc.analysis ${NEXTSIMDIR}/data/${ENSEMBLE[${mem}]}.nc.analysis 
        # note  enkf and cdo depend on the path of reference_grid.nc
    done
    echo "Enkf done"
    #matlab -nosplash -nodesktop  -nojvm  -softwareopengl  -batch  "create_plots;quit"
fi #UPDATE 



#    . run.fram.sh $cfg 1 -e ~/nextsim.ensemble.src                  
#    1 - copy nextsim.exec from NEXTSIMDIR/model/bin to current path
#   -t test run without submit to fram
#   -e ~/nextsim.ensemble.src      # envirmonental variables

#   #Wait for all jobs to finish, or check "squeue -u chengsukun | grep -q ${JOBID[$mem]}"          
#         XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) 	
#         while [[ $XPID -gt $XPID0 ]]; do 
#             sleep 200
#             XPID=$(squeue -u chengsukun | grep -o chengsuk |wc -l) # number of current running jobs 
#             echo '    '$[$XPID-$XPID0] 'jobs are running'             
#         done 
