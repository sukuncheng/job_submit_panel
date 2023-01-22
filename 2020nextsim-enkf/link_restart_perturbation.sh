#!/bin/bash 

# todo: fix restart_path in getFilename. statevector.restart_path is not used, which has a bug in nextsim

function link_perturbation(){ 
    # note the index 180=45*4 correspond to the last perturbation used in the end of spinup run
    echo "links perturbation files to input_path/Perturbation using input file id"
    # The number is calculated ahead as Nfiles +1
    ENSSIZE=$1
    Perturbation_source=$2
    input_path=$3
    duration=$4
    iperiod=$5   
    day0=$6
# active duration2 for@sic1sit7
#    duration=1
#    duration2=3
# otherwise    
    duration2=$duration

    [ ! -d ${input_path}/Perturbations ] && mkdir -p ${input_path}/Perturbations || rm -f ${input_path}/Perturbations/*.nc

    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}    
        # link data sources based on different loading frequencies
        # atmoshphere
        Nfiles=$(( $duration*4+1))  # number of perturbations to be skipped 
        Nfiles2=$(( $duration2*4+1))  # number of perturbations to link
        for (( j=0; j<=${Nfiles2}; j++ )); do  #+1 is because an instance could end at 23:45 or 24:00 for different members due to ? +1 corresponds to the longer one.
            ln -sf ${Perturbation_source}/${memname}/synforc_$((${j}+$day0*4 + ($iperiod-1)*($Nfiles-1) )).nc  ${input_path}/Perturbations/AtmospherePerturbations_${memname}_series${j}.nc
        done
        # ocean 
        Nfiles=$duration+1  # topaz data is loaded at 12:00pm. 
        Nfiles2=$duration2+1  # topaz data is loaded at 12:00pm. 
        for (( j=0; j<=${Nfiles2}; j++ )); do
            ln -sf ${Perturbation_source}/${memname}/synforc_$((${j}+$day0 + ($iperiod-1)*$Nfiles)).nc  ${input_path}/Perturbations/OceanPerturbations_${memname}_series${j}.nc
        done
    done
}

function link_restarts(){ #$ENSSIZE   $restart_source  $input_path $analysis_source
    #echo "project *.nc.analysis on reference_grid.nc, links restart files to $input_path for next DA cycle"
    ENSSIZE=$1  
    restart_source=$2
    input_path=$3
    [ ! -d $input_path ] && mkdir -p ${input_path}
    [ $# -eq 4 ] && analysis_source=$4
    rm -f  ${input_path}/{field_mem* mesh_mem* WindPerturbation_mem* *.nc.analysis}

    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}
        ln -sf ${restart_source}/${memname}/restart/field_final.bin  $input_path/field_${memname}.bin
        ln -sf ${restart_source}/${memname}/restart/field_final.dat  $input_path/field_${memname}.dat
        ln -sf ${restart_source}/${memname}/restart/mesh_final.bin   $input_path/mesh_${memname}.bin
        ln -sf ${restart_source}/${memname}/restart/mesh_final.dat   $input_path/mesh_${memname}.dat
    done  

# link reanalysis
    [ ! -d ${analysis_source} ] && return;    
    for (( i=1; i<=${ENSSIZE}; i++ )); do
        memname=mem${i}    
        [ ! -f ${analysis_source}/${memname}.nc.analysis ] && cdo merge ${NEXTSIM_DATA_DIR}/reference_grid.nc  ${analysis_source}/$(printf "mem%.3d" $i).nc.analysis  ${analysis_source}/${memname}.nc.analysis        
        #todo: dataset.cpp reads analysis from NEXTSIM_DATA_DIR by hardcode. one way to reset NEXTSIM_DATA_DIR in the requested node (cons:lost trace of linked files), the other way is to modify dataset.cpp (todo, and all data related to the run are linked to input_path).
        # ln -sf ${analysis_source}/${memname}.nc.analysis          ${input_path}/${memname}.nc.analysis
        ln -sf ${analysis_source}/${memname}.nc.analysis          ${NEXTSIM_DATA_DIR}/${memname}.nc.analysis 
    done
}
