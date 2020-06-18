#!/bin/sh
# copy data to nextsim/data, copy mesh to nextsim/mesh on host machine
# define host machine related KEYWORDs 
# mesh: small_arctic_10km.msh
host_data='/root/Desktop/data'
host_mesh='/root/Destkop/mesh'   # 
host_nextsim='/root/Destkop/nextsim'
host_output='/root/Destkop/output'

# directories are mounted from host machine to docker
# submit job
# KEYWORDs have been defined by nextsim/Dockerfile in building a nextsim image in docker 
docker run -it --rm \
    --security-opt seccomp=unconfined \
    -v $host_nextsim:/nextsim \
    -v $host_data:/data \
    -v $host_mesh:/mesh \
    -v $host_output:/output \
    nextsim \
    mpirun --allow-run-as-root -np 2 nextsim.exec -mat_mumps_icntl_23 200 --config-files=/output/test.cfg

'
docker run -it --rm \
    --security-opt seccomp=unconfined \
    -v /home/user/nextsim:/nextsim
    -v /Data/sim/data:/data \
    -v /home/user/nextsim/mesh:/mesh \
    -v /home/user/output:/output \
    nextsim \
    mpirun --allow-run-as-root -np 8 nextsim.exec -mat_mumps_icntl_23 200 --config-files=/output/test.cfg
This example will mount the following directories:
* `/home/user/nextsim` on the host with source code and compiled binaries as `/nextsim` in container
* `/Data/sim/data` with all input data as `/data` in container
* `/home/user/nextsim/mesh` with mpp files and links to meshes as `/mesh` in container
* `/home/user/output` with model output as `/output` in container
If your directories (e.g. `/home/user/nextsim/mesh`) contain not the files but symbolic links to files,
you also need to mount the directories where the files are actually residing
(e.g. `-v /Data/sim/data:/Data/sim/data`)

One more option `--security-opt seccomp=unconfined` is apparently needed to run MPI in container.

An example script to run model in a container can be found here:
[run_nextsim_container.sh](https://github.com/nansencenter/nextsim-env/blob/master/machines/maud_antonk/run_nextsim_container.sh)

################################
data are in onedrive, (base) sukeng@Budapest:~/OneDrive - NERSC/others work codes/M.Rabatel et al 2018/Forcing_fields

mesh files maybe in onedrive, otherwise, download files using nextsim-env/ mesh*.sh

neXtSIM_ensemble.env used in *submit.sh (set ensemble size and runs io)

pseudo2D.nml (for wind perturbation)

nextsim.cfg (necessary)

'