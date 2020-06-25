# Experiment Setup

- Exp.1: Deterministic run
  
- Exp.2: Ensemble run with wind-perturbation
  
- Exp.3: Ensemble run wiht wind-perturbation_run & EnKF assimilated ice thickness

- Postprocess is to present the difference between Exp. 2 and Exp. 3, then discuss based on the comparison

## Exp.1: Deterministic run

- Simulation Duration is set as 7 days from 11-11 to 2018-11-18.   
  - Use restart file on 2018-11-11 from 1-year determinsitic run created by Timothy
  
## Exp.2: Ensemble run with wind-perturbation

- Same as Exp. 1
  
- Plan to run 20 ensemble members.
  
- Run two members at one time with 6 cpu cores for each member. 12 CPU cores in total.
  
- Notice the nextsim occupies more memory as duration increases. For a 7-day simulation, a run occupies almost 17 Gb in the end. Thus, members are run one by one.
  spinup_duration=0
  duration=7    # nextsim duration in a forecast-analysisf cycle, which is usually CS2SMOS frequency
  tduration=1   # number of nextsim-enkf (forecast-analysis) cycle. 
  UPDATE=0      # UPDATE=0 indicates forecast is executed without EnKF
## Exp.3: Ensemble run with wind-perturbation_run & EnKF assimilated ice thickness

- Same as Exp. 2
- Because memory is released after each forecast-analysis cycle, the computer has more avaiable memory to run multiple members in parallel.
- However, short duration of nextsim in each DA cycle leads to insuitable to study buoy trajectories of buoys like in the ensemble prediction study.
- ensemble runs on the next day are initialized using the analysis results that generated based on all the ensemble runs at this time slot. Thus, it cannot change ensemble size when doing Exp.3. It is less flexible compared with Exp. 2.
- Unknow crash occurs several times when running Exp. 3
- Key Parameters Settings
  duration=1
  tduration=7
  UPDATE=1
  ensemble size=20
  cpu core=7, 2 members at one time.
  Exp.3 is expected to cost 14 hours.

## Settings

- Modifications of __nextsim.cfg__ are added in job_submit script. 
- Set ECMWF data size as xdim, ydim in __pseudo2D.nml__
  
## Data sources

- ice-type=topaz
    /data/20181129_dm-metno-MODEL-topaz4-ARC-b20181120-fv02.0
- ocean-type=topaz
- atmosphere-type=ec2
       /data/ECMWF_forecast_arctic/ec2_start20181115
- bathymetry-type=etopo
    /data/ETOPO_Arctic_2arcmin

- Assimilation data: CS2SMOS ice thickness,e.g.,
    W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_20181112_20181118_r_v202_01_l4sit

## Forecast-Analysis Cycle (neXtSIM-EnKF)

- Generally, a Forecast-Analysis Cycle is 
  - Forecast: neXtSIM restart with analysis data (except the very first time)
  - Analysis: assimilate neXtSIM output with CS2SMOS ice thickness
  
- in .sh, tduration*duration is the total simulation time in days

## Todo
-Adjust ECMWF data air drag coefficient.
-Run more periods to reducing results dependence on initial dates.
-merge enkf_interface to developer branch of nextsim
-operate netcdf files in ensemble members, e.g., extract ice thickness and save ensemble mean .
-add damage to Moorings.nc


## Ohter notes
-Reduce writing/reading in wind perturbation.
  Because of many times of writing/reading operations in the simulation, the computational efficiency depends on the hard disk capability. Using m.2 ssd harddive with 2Gb/s read/write capability could save considerable time.
  
- The master core occupies most of the computer memory, increasing as duration increasing. Other cores occupy equally amount of memory with small fluctuation arround a constant. 

- different data size 
  Moorings.nc 501x391, prior.nc & .nc.analysis 522x528

- same name:output_timestep is in moorings and statevector
- restart data is recognized by basename=final  (field_basename.bin/dat)


# Errors
## 4-June-2020, all-zero output from EnKF-c
  __data directory is host machine, which is unknown in a docker container running enkf-c__
  changes:
  in main_job_submit.sh
        OBS_DIR = /data/CS2SMOS (for docker)
  in part2_core.sh: 
        docker run --rm -v $FILTER:/docker_io $NEXTSIM_DATA_DIR:/data $docker_image \
            sh -c  "cp /nextsim/modules/enkf/enkf-c/bin/enkf_* . &&  make enkf > enkf.out"
  also check FILE in obs.prm
  Because CS2SMOS data is 2D, while Ali studied SMOS data is 1D, the difference could be the reason of all-zero-output from EnKF-c.
  notice filter/obs is empty. Using make enkf_prep to write observations-orig.nc based on observation data specified in obs.prm.
  enkf-prep doesn't find valid observation from the observation data file.
  Path of the observation data is valid. 
  Enkf-c doesn't have a debug option.
# fram_job_submit_panel
Situation 1  - one test with multiple nodes
Situation 2 - parallel run multiple tests, each test uses one node
Situation 3 - parallel run multiple tests, each test uses multiple nodes

# issues errors
issue1_error_multi-tasks_1node is on situation 2
Suspect the error is due to confliction of accessing common mesh file from multiple core
Small_arctic_10km.msh

> It should access par32small_arctic_10km.msh, but this mesh is copied to out directory, thus no in the working directory, where is the code for this.
> move small_arctic_10km.msh  *.mpp from sim/mesh to my own data directory chengsukun/src/data, and then softlink them to nextsim/data. remote nextsim_mesh_dir in cp -a $NEXTSIMDIR/data/* $NEXTSIM_DATA_DIR/* $SCRATCH/data in slurm.template.sh
>active debugging in nextsim.cfg [debugging]


# discard location changes and pull from remote repository
git fetch --all
git reset --hard origin/master

# 25-6
- several failures of incomplete output of prior.nc. It needs to investigate why variables are not saved to prior.nc when duration >1 with wind pertubation. The issue maybe related to the following warning in nextsim.log
Reading nextsim.cfg...
[INFO] : -----------------------Simulation started on 2020-Jun-25 03:19:28
[INFO] : TIMESTEP= 200
[INFO] : DURATION= 604800
pseudo-random forcing is active for ensemble generation
 Using FFTW for Fourier transform
 Feel the power of the Fastest Fourier Transform in the West!
--------------------------------------------------------------------------
A process has executed an operation involving a call to the
"fork()" system call to create a child process.  Open MPI is currently
operating in a condition that could result in memory corruption or
other system errors; your job may hang, crash, or produce silent
data corruption.  The use of fork() (or system() or other calls that
create child processes) is strongly discouraged.

The process that invoked fork was:

  Local host:          [[2549,0],0] (PID 159425)

If you are *absolutely sure* that your application will successfully
and correctly survive a call to fork(), you may disable this warning
by setting the mpi_warn_on_fork MCA parameter to 0.
--------------------------------------------------------------------------
[INFO] :  ---------- progression: ( 0%) ---------- time spent: 00:01:25

# 22-6
install m_map on fram
put matlab file on fram

cd $FILTER
cdo merge /home/cheng/Desktop/data/reference_grid.nc  /home/cheng/Desktop/nextsim/data/prior/mem001.nc.analysis /home/cheng/Desktop/data/mem001.nc.analysis


# 17-6
  error in interpolate ensemble observation from background field
  set latitudes of observations >N85 in int grid_xy2fij


  interpolate_2d_obs  obsids,  src-> dst
    -> out[ii](=dst) = interpolate2d(o->fi, o->fj, ni, nj, **v(=src)**, mask, periodic_i);

  design a workflow to optimize LOCARD as well as other parameters with matlab.
  need to determine optimization function
  1. optimize one parameter like LOCARD by enumeration method

# 16-6
 locate the calculations of ensemble spread/innovation, increment in code. 
 take note of calc/update flowchart.

# 14-6
error found: prep_utils, line209            enkf_printf("        %d observations above allowed maximum of %.4g\n", nmax, ot->allowed_max);
allowed_max = dbl_max=10. dbl_max indicates the maxmium digits number for double variable. It is mistakenly used as the upper bound of obs. value.
for this case, observed sit>10 are ignored.

# 13-6 
  Tracking the issue: the shape of spread seems ok. about the amplitude is too small O(1.e-7)
  update.c ->das_writespread  ncw_copy_vardef

# 12-6
  get data from step2 wind perturabation run with ensemble size 17 done before
  assimilate the forecasts with one single observation.
  Observed small increment at the location
  change the observation location, try again. Encounter error of failed to find the cell containing the observatio location
  the shape of spread seems ok. about the amplitude is too small O(1.e-7)

# 11-6
  run 20 ensemble members with wind perturbation for one day
  observe spread in spread.nc. But zero increment. Ali suggested to try forecast with longer duration to have larger spread. And it is worthy to use inflation=2 then. 


# 10-6
run()->init()->initStateVector()
     ->exportStateVector()->initStateVector() (deleted, as prior.nc has been created in init())
                          ->updateStateVector->stateVectorAppendNetcdf(),  output_time=init_time (time here is wrong)
                          ->stateVectorAppendNetcdf() (Is it necessary? )

# 9-6
error: zero-values in **.nc.increment from enkf_update 
reason: enkf_update reads 2nd value of time dimension of the forecast data mem001.nc, which contains all zeros. It is resolved by reading from the 1st time slot. Considering no change of enkf-c code, it needs to change the nextsim/model/finiteelement.cpp->exportStateVector->stateVectorAppendNetcdf
  M_statevector.appendNetCDF(M_statevector_file, output_time);
M_statevector_file = prior.nc
output_time = ?


# 8-6
error: zero-values in **.nc.increment from enkf_update

# 7-6
outcome from make enkf is all zero. X5 is not zero.
source code of enkf_in_nextsim  is from nextsim. It is the enkf part of one_step_nextsim_enkf. Merge the two paths.Or copy the compiled executable files from enkf_in_nextsim to one_step_nextsim_enkf/filter
observation.nc from enkf_prep is empty, all obervations are marked as bad value.
track obs->nrange (bade value)  
  prep: main->obs_calcstats->&obs->data[i]->status=STATUS_RANGE  (error found)
  main->obs_add-> "common check": &obs->data[i]->status = STATUS_RANGE;  (original error)
solution: it needs to change the variable type in standard3 according to the cs2smos user manual description
        bug fixed, modify arry claim and index in smos_standard3


copy /gridutils-c/gridutils/*.h to enkf_in_nextsim to compile


# 6-6
realize standards in reader_smos.c are related to the sources of SMOS data. 
Thus, define a new standard - standard3 for the cs2smos data that going to be assimilated
reader_smos_standard3
    -> not recognize variables
      specify variable name based on the dataset
    -> ncw_get_att_int->nc_get_att_int   
      give the right keyword from the .nc file
      
# 5-6 
filename given in obs.prm is corrected.
glob_err in if-statement in glob() is changed to glob_nomatched in utils.c
find error in reading file (obs_add->readobs()->reader()->get_obsfiles->find_files->reader_smos_standard2->ncw_dim_exists->nc_inq_dimid )


fatal: unable to access 'http://github.com/nansencenter/nextsim/': Recv failure: Connection reset by peer
solution:  git config --global url."https://".insteadOf http://


Reference_grid :
  grid size: 528*522
  longitude: -180 to 180
  latitude: N 40.137 to 90 

make clean;make; cp ./bin/* example_filter/; cd example_filter/; make clean; 
keywords related to spread： UPDATE_DOANALYSISSPREAD， &fields[i - bufindex], "write analysis spread" 

Modifies observation error so that the increment for this observation would not exceed KFACTOR * <ensemble spread> (all in observation space) after assimilating this observation only.

1. Incresing R-factor decreases the impact of observation. Ensemble spread/sqrt(R-factor)
2. Incresing K-factor increases the impact of ensemble spread. background check. 2.7.3. 
3. Inflation . The ensemble anomalies (A=E-x.1') for any model state element will be inflated to avoid collapses. 
    (x_a - x\bar)*inflation + x\bar
    capping of inflation: inflation = 1+inflation*( std_f/std_a-1)

4. localisation radii defines the impact area size of observation. Increasing it increases the number of local observations


# 
array=(1 2 3 4 5)
${#array[@]}  length of array
${array[*]}   get of elements in the array

cat -n 文件名|grep '关键字'|awk '{print $1}'

# changes in enkf-c
start[0] = 0; //dimlen[0] - 1;