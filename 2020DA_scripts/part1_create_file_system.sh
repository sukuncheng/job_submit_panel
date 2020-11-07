#!/bin/bash
# sukun.cheng@nersc.no,  01/11/2020
# PURPOSE: prepare experiment directories and files
#   - create working directory and subdirectories,
#   - copy EnKF package to ENSPATH/filter
#
# Directory structure:
# ENSPATH -- mem001
#         -- mem002
#         -- ...
#         -- mem***
#         -- filter (include EnKF package)
#                     -- obs  (link observations from NEXTIM_DATA_DIR)
#                     -- prior 
echo "Part1 initialize files system"
#1. prepare forecast files
# nextsim.cfg
    sed -e "s;^duration=.*$;duration="${duration}";g" \
        -e "s;^output_timestep=.*$;output_timestep="${duration}";g" \
        -e "s;^start_from_restart=.*$;start_from_restart=true;g" \
        -e "s;^input_path=.*$;input_path=${JOB_SETUP_DIR}/restart;g" \
        -e "s;^basename.*$;basename=20181111T000000Z;g" \
        -e "s;^time_init=.*$;time_init="${time_init}";g" \
        -e "s;^restart_from_analysis=.*$;restart_from_analysis="${restart_from_analysis}";g" \
        -e "s;^start_from_restart=.*$;start_from_restart="${start_from_restart}";g" \
        ${JOB_SETUP_DIR}/nextsim.cfg > ${ENSPATH}/nextsim.cfg

    # pseudo2D.nml      
    sed -e "s;^iopath.*$;iopath = '.';g" \
        -e "s;^randf.*$;randf    = .true.;g" \
        ${JOB_SETUP_DIR}/pseudo2D.nml > ${ENSPATH}/pseudo2D.nml  
    # for (( mem=1; mem<=${ESIZE}; mem++ )); do
    #     MEMPATH=${ENSPATH}/${ENSEMBLE[${mem}]}
	#     mkdir -p ${MEMPATH}  
    # sed -e "s;^iopath.*$;iopath = '.';g" \
    #     -e "s;^randf.*$;randf    = .true.;g" \
    #     ${JOB_SETUP_DIR}/pseudo2D.nml > ${MEMPATH}/pseudo2D.nml  
    # done

#2. prepare analysis files
    FILTER=$ENSPATH/filter
    mkdir -p ${FILTER}/prior  # create directory to store prior states
    mkdir -p ${FILTER}/obs    # observation directory
    #
    echo "  cd ENSPATH/filter & get a copy of reference_grid.nc "
    cd $FILTER  
    cp ${JOB_SETUP_DIR}/reference_grid.nc .
    #    
    echo "  get enkf-c configs, check enkf.prm, grid.prm,obs.prm, obsstypes.prm, model.prm"
    cp ${JOB_SETUP_DIR}/enkf_cfg/* .  #from ${NEXTSIMDIR}/modules/enkf/enkf-c/cfg/* # except stats.prm and enoi.prm
    cp ${NEXTSIMDIR}/modules/enkf/enkf-c/bin/enkf_* .
    # modifications in enkf configurations
    sed -i "s;mpirun;mpirun --allow-run-as-root;g" Makefile
    sed -i "s;^ENSSIZE.*$;ENSSIZE = "${ENSSIZE}";g"  enkf.prm
    sed -i "s;^INFLATION.*$;INFLATION = 1.;g"  enkf.prm
    sed -i "s;^LOCRAD.*$;LOCRAD = 300;g"  enkf.prm
    sed -i "s;^RFACTOR.*$;RFACTOR = 1;g"  enkf.prm

    echo "  add observations path to $FILTER/obs.prm"
    A1=1 
    A2=`expr "(${A1}+6)"|bc`
    SMOSOBS=${OBSNAME_PREFIX}$(date +%Y%m%d -d "${time_init} + $A1 day")_$(date +%Y%m%d -d "${time_init} + $A2 day")${OBSNAME_SUFFIX}.nc
    if [ -f ${SMOSOBS} ]; then
        sed -i "s;^.*FILE.*$;FILE ="${SMOSOBS}";g"  obs.prm 
    else
        echo "Error: ${SMOSOBS} is not found. "
    fi