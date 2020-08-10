#!/bin/bash
#------ PART 1: ensemble forecast ------------
for (( mem=1; mem<=${ESIZE}; mem++ )); do
    cd ${ENSPATH}/${ENSEMBLE[${mem}]}  #MEMPATH
    # update time_init per time step
    sed -i "s;^time_init=.*$;time_init="${time_init}";g" ./nextsim.cfg
    sed -i "s;^restart_from_analysis=.*$;restart_from_analysis="${restart_from_analysis}";g" ./nextsim.cfg       
done 

echo "ensemble runs start"
for (( j=1; j<=5; j++ )); do  # this loop is supposed to find and resubmit crashed jobs.
    # submit jobs from member paths
    for (( mem=1; mem<=${ESIZE}; mem++ )); do
        cd ${ENSPATH}/${ENSEMBLE[${mem}]}  #MEMPATH
        # submit job        
	if [ grep -q "Simulation done" slurm.nextsim.*.log ] 
	then
	    echo ${ENSEMBLE[${mem}]} "is done"
	else
	    source $ENVFRAM/run.fram.sh ./nextsim.cfg 1 -e $ENVFRAM/nextsim.src       
        fi
        job_list=$(squeue -u chengsukun)
        XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
        #
        while [[ $XPID -ge $maximum_instants ]]; do # maximum of running instants
            sleep 20
            job_list=$(squeue -u chengsukun)
            XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
        done    
    done
        
    # wait for all jobs to finish
    while [[ $XPID -ge 1 ]]; do 
        sleep 200
        job_list=$(squeue -u chengsukun)
        XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
    done    
    if [ $j -ge 2 ]; then 
        break
    fi
done
echo "ensemble forecast done" 
#    . run.fram.sh $cfg 1 -e ~/nextsim.ensemble.src                  
#    1 - copy nextsim.exec from NEXTSIMDIR/model/bin to current path
#   -t test run without submit to fram
#   -e ~/nextsim.ensemble.src      # envirmonental variables


#-------  PART 2: enkf - UPDATE ENSEMBLE  ---------
if [ ${UPDATE} -gt 0 ]; then
    echo "link mem00*/prior.nc to /filter/prior/mem00*.nc"
    for (( mem=1; mem<=${ESIZE}; mem++ )); do
        mv  ${ENSPATH}/${ENSEMBLE[${mem}]}/prior.nc \
            ${FILTER}/prior/${ENSEMBLE[${mem}]}'.nc' # use `ln -sf` in docker cannot link correctly with data on host machine
        if [[ -f ${ENSPATH}/${ENSEMBLE[${mem}]}/*.00 ]];then
            rm ${ENSPATH}/${ENSEMBLE[${mem}]}/*.00 ${ENSPATH}/${ENSEMBLE[${mem}]}/*.01
        fi
    done
    #
    cd $FILTER
    echo "link observations to ENSPATH/filter/obs, and obs.prm"
    A1=${duration} # 
    A2=`echo "(${duration}+6)"|bc`
#  for (( tind = 0; tind < ${???}; tind++ )); do
    SMOSOBS=${OBSNAME_PREFIX}$(date +%Y%m%d -d "${time_init} + $A1 day")_$(date +%Y%m%d -d "${time_init} + $A2 day")${OBSNAME_SUFFIX}.nc
    echo ${time_init} '   '  ${tind} '   ' $duration 
    if [ -f ${SMOSOBS} ]; then
        sed -i "s;^.*FILE.*$;FILE ="${SMOSOBS}";g"  obs.prm 
    else
        echo "WARNING: ${SMOSOBS} is not found. "
    fi
    #  done   

    echo "run enkf, outputs: $filter/prior/*.nc.analysis, $filter/enkf.out" 
    make clean #must clean previous results like observation*.nc
#    make enkf  ########$NEXTSIMDIR/data:/data##### change data address in .prm files
    ./enkf_prep --no-superobing enkf.prm 2>&1 | tee prep.out
    ./enkf_calc --use-rmsd-for-obsstats enkf.prm 2>&1 | tee calc.out
    ./enkf_update --calculate-spread  enkf.prm 2>&1 | tee update.out    
    #
    echo "project *.nc.analysis on reference_grid.nc, save to /NEXTSIMDIR/data/"
    # nextsim will read /NEXTSIMDIR/data/**.nc.analysis data in next DA cycle    
    rm ${NEXTSIMDIR}/data/*.nc.analysis
    for (( mem=1; mem<=${ESIZE}; mem++ )); do
        [ ! -f ${FILTER}/prior/${ENSEMBLE[${mem}]}.nc.analysis  ] && sleep 5
        cdo merge ./reference_grid.nc  ./prior/${ENSEMBLE[${mem}]}.nc.analysis ${NEXTSIMDIR}/data/${ENSEMBLE[${mem}]}.nc.analysis 
        # note  enkf and cdo depend on the path of reference_grid.nc
    done
    echo "enkf done, create plots"
    # plots 
    cp $RUNPATH/create_plots.m . #in $FILTER
#    matlab -nosplash -nodesktop  -nojvm  -softwareopengl  -batch  "create_plots;quit"
fi #UPDATE 
