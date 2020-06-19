# fram_job_submit_panel
Situation 1  - one test with multiple nodes
Situation 2 - parallel run multiple tests, each test uses one node
Situation 3 - parallel run multiple tests, each test uses multiple nodes

###
issue1_error_multi-tasks_1node is on situation 2
Suspect the error is due to confliction of accessing common mesh file from multiple core
Small_arctic_10km.msh

> It should access par32small_arctic_10km.msh, but this mesh is copied to out directory, thus no in the working directory, where is the code for this.
> move small_arctic_10km.msh  *.mpp from sim/mesh to my own data directory chengsukun/src/data, and then softlink them to nextsim/data. remote nextsim_mesh_dir in cp -a $NEXTSIMDIR/data/* $NEXTSIM_DATA_DIR/* $SCRATCH/data in slurm.template.sh
>active debugging in nextsim.cfg [debugging]


# discard location changes and pull from remote repository
git fetch --all
git reset --hard origin/master
git pull 
