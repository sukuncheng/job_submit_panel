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
echo " Initialize files system, write nextsim.cfg, pseudo2D.nml to workpath"
#1. prepare forecast files
	 #s/^input_path=.*$/input_path=${NEXTSIM_DATA_DIR}/g; \
# nextsim.cfg,  #"${duration}" # input_path, basename are defined in slurm.*.template.sh
    sed -i "s/^time_init=.*$/time_init=${time_init}/g; \
         s/^duration=.*$/duration=${duration}/g; \
         s/^dynamics-type=.*$/dynamics-type=bbm/g; \
         s/^output_timestep=.*$/output_timestep=1/g; \
         s/^start_from_restart=.*$/start_from_restart=${start_from_restart}/g; \
         s/^write_final_restart=.*$/write_final_restart=true/g; \
         s/^basename.*$/basename=/g; \
         s/^assimilated_variable.*$/assimilated_variable=${DA_VAR}/g; \
         s/^restart_from_analysis=.*$/restart_from_analysis=${restart_from_analysis}/g" \
        ${JOB_SETUP_DIR}/nextsim.cfg 
        cp ${JOB_SETUP_DIR}/nextsim.cfg  ${ENSPATH}/nextsim.cfg
        
    # # pseudo2D.nml, perturb cohesion C_lab=1.5e6 [±33%]  # s/^C_perturb.*$/C_perturb=0.33/g" 
    # sed -i "s/^iopath.*$/iopath = '.'/g; \
    #         s/^randf.*$/randf    = .$randf./g; \
    #         s/^vwndspd.*$/vwndspd=3/g; \
    #         s/^scorr_dx.*$/scorr_dx=10/g; \
    #         s/^C_lab.*$/C_lab=1.5e6/g; \
    #         s/^C_perturb.*$/C_perturb=0.33/g;" \
    #         ${JOB_SETUP_DIR}/pseudo2D.nml             
    # cp ${JOB_SETUP_DIR}/pseudo2D.nml  ${ENSPATH}/pseudo2D.nml  

    cd ${ENSPATH}
    for (( i=1; i<=${ENSSIZE}; i++ )); do
	    memname=mem${i}
        MEMPATH=${ENSPATH}/${memname}
        mkdir -p $MEMPATH
        sed -e "s;^basename.*$;basename=${memname};g" \
            -e "s;^ensemble_member.*$;ensemble_member=${i};g" \
            -e "s;^exporter_path.*$;exporter_path=${MEMPATH}/;g" \
            ${ENSPATH}/nextsim.cfg > ${MEMPATH}/nextsim.cfg
        cp ${MEMPATH}/nextsim.cfg ${MEMPATH}/nextsim.cfg.backup
    #    cp ${ENSPATH}/pseudo2D.nml $MEMPATH 
    done   


#-----------------------------------------------------------
#2. prepare analysis files
if [[ $UPDATE == 1 ]];then
    FILTER=$ENSPATH/filter
    mkdir -p ${FILTER}/prior  # store prior states

    echo "  get enkf-c configs, check enkf.prm, grid.prm,obs.prm, obsstypes.prm, model.prm & executable files"
    cd $FILTER  
    cp ${JOB_SETUP_DIR}/enkf_cfg_$DA_VAR/* .  #from ${NEXTSIMDIR}/modules/enkf/enkf-c/cfg/* # except stats.prm and enoi.prm
    cp ${NEXTSIMDIR}/modules/enkf/enkf-c/bin/enkf_* .
    # modifications in enkf configurations
    sed -i "s;mpirun;mpirun --allow-run-as-root;g" Makefile
    sed -i "s|^ENSSIZE.*$|ENSSIZE = ${ENSSIZE}|g; \
            s|^INFLATION.*$|INFLATION = ${INFLATION}|g; \
            s|^LOCRAD.*$|LOCRAD = ${LOCRAD}|g;\
            s|^RFACTOR.*$|RFACTOR = ${RFACTOR}|g; \
            s|^KFACTOR.*$|KFACTOR = ${KFACTOR}|g;"  enkf.prm
    #
    sed -i "s;^DATA.*$;DATA =${NEXTSIM_DATA_DIR}/reference_grid.nc;g"  grid.prm
    ln -sf ${NEXTSIM_DATA_DIR}/reference_grid.nc   ${FILTER}/reference_grid.nc   # this file is used by enkf_prep, reader_cs2smos.
    
#   specify observations data for assimilation using EnKF  
    # cs2smos file
    echo "  add observations path to $FILTER/obs.prm"
    A1=`expr "(${duration}-3)"|bc`
    A2=`expr "(${duration}+3)"|bc`
    
    OBSNAME_PREFIX=$NEXTSIM_DATA_DIR/CS2_SMOS_v2.3/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_ 
    OBSNAME_SUFFIX=_r_v203_01_l4sit  
    CS2SMOS_fname=${OBSNAME_PREFIX}$(date +%Y%m%d -d "${time_init} + $A1 day")_$(date +%Y%m%d -d "${time_init} + $A2 day")${OBSNAME_SUFFIX}.nc
    
    OSISAF_fname=$NEXTSIM_DATA_DIR/OSISAF_ice_conc/polstere/$(date +%Y -d "${time_init} + ${duration} day")_nh_polstere/ice_conc_nh_polstere-100_multi_$(date +%Y%m%d -d "${time_init} + ${duration} day")1200.nc
    [ ! -f $CS2SMOS_fname ] && echo "error: ${CS2SMOS_fname} is missing" 
    [ ! -f $OSISAF_fname ] && echo "error:  ${OSISAF_fname} is missing" 
    if [[ "$DA_VAR" == "sit" ]]; then
        sed -i "s;^.*FILE.*$;FILE ="${CS2SMOS_fname}";"  obs.prm 
    elif [[ "$DA_VAR" == "sic" ]]; then
        sed -i "s;^.*FILE.*$;FILE ="${OSISAF_fname}";"  obs.prm 
    elif [[ "$DA_VAR" == "sitsic" ]]; then
        sed -i "s;^.*FILE.*$;FILE ="${CS2SMOS_fname}";"  obs.prm
        sed -i ':a;N;$!ba;s|\(.*\)FILE.*|\1FILE ='${OSISAF_fname}'|'  obs.prm  #edit the last matched keyword        
    fi
fi
