#!/bin/bash
#------ PART 1: ensemble forecast ------------
echo "ensemble runs start"
for (( mem=1; mem<=${ESIZE}; mem++ )); do
    MEMPATH=${ENSPATH}/${ENSEMBLE[${mem}]}
    # update time_init per time step
    sed -i "s;^time_init=.*$;time_init="${time_init}";g" ${MEMPATH}/nextsim.cfg
    sed -i "s;^restart_from_analysis=.*$;restart_from_analysis="${restart_from_analysis}";g" ${MEMPATH}/nextsim.cfg          
done # ensemble loop
echo "run ensemble instants in a docker container"
# # submit job. Note `cd /docker_io` to use /docker_io/pseudo2D.nml; DO NOT USE &> in docker command
    docker run -it \
        --security-opt seccomp=unconfined \
        -v $NEXTSIM_DATA_DIR:/data \
        -v $NEXTSIM_MESH_DIR:/mesh \
        -v $ENSPATH:/docker_io \
        $docker_image # sh -c "cd /docker_io && ./ensemble_in_docker.sh"
#             sh -c  "cp /nextsim/modules/enkf/enkf-c/bin/enkf_* . &&  make enkf > enkf.out"
echo "ensemble forecast done"        


# #-------  PART 2: enkf - UPDATE ENSEMBLE  ---------
# if [ ${UPDATE} -gt 0 ]; then
#     echo "link mem00*/prior.nc to /filter/prior/mem00*.nc"
#     for (( mem=1; mem<=${ESIZE}; mem++ )); do
#         mv  ${ENSPATH}/${ENSEMBLE[${mem}]}/prior.nc \
#             ${FILTER}/prior/${ENSEMBLE[${mem}]}'.nc' # use `ln -sf` in docker cannot link correctly with data on host machine
#         rm ${ENSPATH}/${ENSEMBLE[${mem}]}/*.00 ${ENSPATH}/${ENSEMBLE[${mem}]}/*.01
#     done

#     #
#     cd $FILTER
#     echo "link observations to ENSPATH/filter/obs, and obs.prm"
#     tind=${duration} # $(echo "(${duration}+1)/1"|bc)
#     #  for (( tind = 0; tind < ${???}; tind++ )); do
#     SMOSOBS=${OBSNAME_PREFIX}$(date +%Y%m%d -d "${time_init} + ${tind} day")_$(date +%Y%m%d -d "${time_init} + ${tind+7} day")${OBSNAME_SUFFIX}.nc
#     if [ -f ${SMOSOBS} ]; then
#         sed -i "s;^.*FILE.*$;FILE ="${SMOSOBS}";g"  obs.prm 
#     else
#         echo "WARNING: ${SMOSOBS} is not found. "
#     fi
#     #  done #    
#     echo "run enkf, outputs: $filter/prior/*.nc.analysis, $filter/enkf.out" 
#     #rm $FILTER/observation*.nc  # clean previous results by enkf_prep
#     docker run --rm -v $FILTER:/docker_io $NEXTSIM_DATA_DIR:/data $docker_image \
#             sh -c  "cp /nextsim/modules/enkf/enkf-c/bin/enkf_* . &&  make enkf > enkf.out"
    
    
#     #
#     echo "merge reference_grid.nc and *.nc.analysis /NEXTSIM_DATA_DIR/"
#     # nextsim will read /NEXTSIM_DATA_DIR/**.nc.analysis data in next DA cycle
#     echo ${ENSPATH}/DAdata/${time_init}
#     mkdir -p ${ENSPATH}/DAdata/${time_init}
#     rm ${NEXTSIM_DATA_DIR}/*.nc.analysis
#     for (( mem=1; mem<=${ESIZE}; mem++ )); do
#         cdo merge ${FILTER}/reference_grid.nc  ${FILTER}/prior/${ENSEMBLE[${mem}]}.nc.analysis ${NEXTSIM_DATA_DIR}/${ENSEMBLE[${mem}]}.nc.analysis
#         cp ${NEXTSIM_DATA_DIR}/${ENSEMBLE[${mem}]}.nc.analysis ${ENSPATH}/DAdata/${time_init}/${ENSEMBLE[${mem}]}.nc.analysis
#     done
#     echo "enkf done"
# fi #UPDATE 
