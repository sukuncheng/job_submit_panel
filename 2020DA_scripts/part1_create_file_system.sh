#!/bin/bash
# sukun.cheng@nersc.no,  01/11/2020
# PURPOSE: prepare experiment directories and files
#   - create working directory and subdirectories,
#   - copy EnKF package to ENSPATH/filter
#
# Directory structure:
# ENSPATH->MEMPATH: mem001
#         -- mem002
#         -- ...
#         -- mem***
#         -- filter (include EnKF package)
#                     -- obs  (link observations from NEXTIM_DATA_DIR)
#                     -- prior 
echo "Part1 initialize files system, write nextsim.cfg, pseudo2D.nml to workpath"
#1. prepare forecast files
# nextsim.cfg,  #"${duration}" # input_path, basename are defined in slurm.*.template.sh
    sed -i "s/^time_init=.*$/time_init=${time_init}/g; \
         s/^duration=.*$/duration=${duration}/g; \
         s/^output_timestep=.*$/output_timestep=1/g; \
         s/^start_from_restart=.*$/start_from_restart=${start_from_restart}/g; \
         s/^write_final_restart=.*$/write_final_restart=true/g; \
         s/^input_path=.*$/input_path=/g; \
         s/^basename.*$/basename=/g; \
         s/^restart_from_analysis=.*$/restart_from_analysis="${restart_from_analysis}"/g" \
        ${JOB_SETUP_DIR}/nextsim.cfg 
        cp ${JOB_SETUP_DIR}/nextsim.cfg  ${ENSPATH}/nextsim.cfg
        
    # pseudo2D.nml, perturb cohesion C_lab=1.5e6 [±33%]  # s/^alea_factor.*$/alea_factor=0.33/g" 
    sed -i "s/^iopath.*$/iopath = '.'/g; \
            s/^randf.*$/randf    = .$randf./g; \
            s/^scorr_grid_resolution.*$/scorr_grid_resolution=30/g; \
            s/^C_lab.*$/C_lab=1.5e6/g;" \
            ${JOB_SETUP_DIR}/pseudo2D.nml 
            
    cp ${JOB_SETUP_DIR}/pseudo2D.nml  ${ENSPATH}/pseudo2D.nml  

    # cd ${ENSPATH}
    # for (( i=1; i<=${ENSSIZE}; i++ )); do
	#     memname=mem${i}
    #     MEMPATH=${ENSPATH}/${memname}
    #     mkdir -p $MEMPATH
    #     sed -e "s;^id.*$;id=$i;g" \
    #         -e "s;^basename.*$;basename=${memname};g" \
    #         ${ENSPATH}/nextsim.cfg > ${MEMPATH}/nextsim.cfg  
    
    #     cp ${ENSPATH}/pseudo2D.nml $MEMPATH 
    # done   

# if [ ${UPDATE} -eq 1 ]; then
#2. prepare analysis files
    FILTER=$ENSPATH/filter
    mkdir -p ${FILTER}/prior  # create directory to store prior states
    #
    echo "  cd ENSPATH/filter & get a copy of reference_grid.nc "
    cd $FILTER  
    cp ${JOB_SETUP_DIR}/reference_grid.nc ${FILTER}
    #    
    echo "  get enkf-c configs, check enkf.prm, grid.prm,obs.prm, obsstypes.prm, model.prm"
    cp ${JOB_SETUP_DIR}/enkf_cfg/* .  #from ${NEXTSIMDIR}/modules/enkf/enkf-c/cfg/* # except stats.prm and enoi.prm
    cp ${NEXTSIMDIR}/modules/enkf/enkf-c/bin/enkf_* .
    # modifications in enkf configurations
    sed -i "s;mpirun;mpirun --allow-run-as-root;g" Makefile
    # sed -i "s;^ENSSIZE.*$;ENSSIZE = ${ENSSIZE};g"  enkf.prm
    # sed -i "s;^INFLATION.*$;INFLATION = ${INFLATION};g"  enkf.prm
    # sed -i "s;^LOCRAD.*$;LOCRAD = ${LOCRAD};g"  enkf.prm
    # sed -i "s;^RFACTOR.*$;RFACTOR = ${RFACTOR};g"  enkf.prm
    # sed -i "s;^KFACTOR.*$;KFACTOR = ${KFACTOR};g"  enkf.prm
    #
    echo "  add observations path to $FILTER/obs.prm"
    A1=${duration} 
    A2=`expr "(${A1}+6)"|bc`
    SMOSOBS=${OBSNAME_PREFIX}$(date +%Y%m%d -d "${time_init} + $A1 day")_$(date +%Y%m%d -d "${time_init} + $A2 day")${OBSNAME_SUFFIX}.nc
    if [ -f ${SMOSOBS} ]; then
        sed -i "s;^.*FILE.*$;FILE ="${SMOSOBS}";g"  obs.prm 
    else
        echo "[Waring] ${SMOSOBS} is not found. "
    fi
# fi
