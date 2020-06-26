#!/bin/bash
# sukun.cheng@nersc.no,  04/20/2019
# PURPOSE:
#   - define variables
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

#   create a namelist of ensemble member directories
    ENSEMBLE=()             
    for (( mem=1; mem<=${ESIZE}; mem++ )); do
        MEMBER=$(printf "%03d" $mem)
        MEMNAME=mem${MEMBER}
        ENSEMBLE+=([${mem}]=${MEMNAME})  
    done 
##----------------------------------------------------------
#   prepare forecast files
    for (( mem=1; mem<=${ESIZE}; mem++ )); do
        MEMPATH=${ENSPATH}/${ENSEMBLE[${mem}]}
	mkdir -p ${MEMPATH}
        cd ${MEMPATH}       
        # pseudo2D.nml
        exporter_path=${MEMPATH}
        input_path=$RUNPATH"/restart"
        sed -e "s;^iopath.*$;iopath = '.';g" \
            -e "s;^randf.*$;randf    = .true.;g" \
            ${RUNPATH}/pseudo2D.nml > ./pseudo2D.nml        # 
	    
        # nextsim.cfg
        sed -e "s;^duration=.*$;duration="${duration}";g" \
            -e "s;^exporter_path=.*$;exporter_path="${exporter_path}";g" \
            -e "s;^output_timestep=.*$;output_timestep="${duration}";g" \
            -e "s;^id=.*$;id=${MEMBER};g" \
            -e "s;^start_from_restart=.*$;start_from_restart=true;g" \
            -e "s;^input_path=.*$;input_path="${input_path}";g" \
            -e "s;^basename.*$;basename=20181111T000000Z;g" \
            ${RUNPATH}/nextsim.cfg > nextsim.cfg
    done

#   prepare analysis files
    if [ ${UPDATE} ]; then
        FILTER=$ENSPATH/filter
        mkdir -p ${FILTER}/prior  # create directory to store prior states
        mkdir -p ${FILTER}/obs    # observation directory
        #
        echo "cd ENSPATH/filter & put reference_grid.nc in it"
        cd $FILTER  
        cp $RUNPATH/reference_grid.nc .
        #    
        echo "get config files from host_machine/enkf-c directory "
        cp ${NEXTSIMDIR}/modules/enkf/enkf-c/cfg/* .  # exclude stats.prm & enoi.prm
        cp ${NEXTSIMDIR}/modules/enkf/enkf-c/bin/enkf_* .
        # modifications in enkf configurations
        sed -i "s;mpirun;mpirun --allow-run-as-root;g" ./Makefile
        sed -i "s;^ENSSIZE.*$;ENSSIZE = "${ESIZE}";g" enkf-global.prm 
        sed -i "s;^ENSSIZE.*$;ENSSIZE = "${ESIZE}";g"  enkf.prm
        sed -i "s;^INFLATION.*$;INFLATION = 1.01;g"  enkf.prm
        sed -i "s;^LOCRAD.*$;LOCRAD = 300;g"  enkf.prm
        sed -i "s;^RFACTOR.*$;RFACTOR = 1;g"  enkf.prm
        sed -i "s;^READER.*$;READER = standard3;g" obs.prm    
    fi
echo "part1 initialize files system, done"
