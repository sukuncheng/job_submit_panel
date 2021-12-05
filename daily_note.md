# research proposal
assess the implementation of EnKF assimilating ice thickness and concentration in esemble neXtSIM forecast

# Experimental design

# Todo
~~1. DONE: add a script-block to resubmit crashed job. Waiting all jobs are finished before moving to enkf~~
~~2. DONE: stop daily output of .bin and .dat, only output the final. output_per_day=0 in nextsim.cfg~~
~~3. DONE. increate time step in nextsim.cfg in the latest nextsim version. from 200 to 400~~
~~4. DONE. investigate prior.nc size puzzle. duplication of outputing statevectors is fixed~~
~~6. Run more periods to reducing results dependence on the initial dates.~~
~~7. DONE. merge branch to enkf_interface or others. merged develop branch~~
~~8. discard: add damage to Moorings.nc~~

~~10. DONE. Job array, implement Ali's changes of submitting enkf job on slurm. Modify the scripts for submitting jobs~~
~~11. DONE retrieve subdomain charged by each processor by index, to apply the correct perturbation~~
~~12. CANCELLED. Save perturbations (synforc and randfld) in restart file (of each ensemble member). Reason:externaldata structure is initialized after readRestart(). It would be complicated to stick with one restart file. reate a function import and export_WindPerturbations in c++ replace old on in fortran~~
~~13.  make dataset links in NEXTSIMDIR/data~~
~~14. member_analysis, restart file, for each member are linked to NEXTSIMDIR/data for  ensemble forecasts in the next DA cycle.~~
~~15. CANCELLED. add [statevector]restart_path in nextsim.cfg. restart_path is set as restart. input_path~~
~~16.  DONE Consider change studied time from winter 2018 to winter **2019**. TOPAZ in 12.2018 is not completed.
~~17.  DONE. Adjust ECMWF data air drag coefficient?
~~18.  DONE. Tune factors (R, K, inflation, localisation radii) in enkf
~~19  DONE Assimilate ice thickness, concentration indpendently and ajointly. There is a bug in assimilating concentration.
5. merge enkf_interface_sukun to enkf_interface and develop
   update the asr code in nextsim based on the ecmwf ec2_...


# Enkf - c
## Compile  
  make clean;make; cp ./bin/* example_filter/; cd example_filter/; make clean; 
  keywords in code related to spread: UPDATE_DOANALYSISSPREAD， &fields[i - bufindex], "write analysis spread" 
## reference_grid.nc 
  - truncated from ORCA, adopted from NEMO,  for exchange model status with enkf
  - Grid size: 528*522
  - Covered area:
  longitude: -180 to 180
  latitude: N 40.137 to 90 

## Tune factors 
1. R-factor: Incresing R-factor decreases the impact of observation. Ensemble spread/sqrt(R-factor)
2. K-factor: Incresing K-factor increases the impact of ensemble spread. background check. 2.7.3. 
   Modifies observation error so that the increment for this observation would not exceed KFACTOR * <ensemble spread> (all in observation space) after assimilating this observation only.
3. Inflation: The ensemble anomalies (A=E-x.1') for any model state element will be inflated to avoid collapses. 
    (x_a - x\bar)*inflation + x\bar
    capping of inflation: inflation = 1+inflation*( std_f/std_a-1)
4. Localization radius: it defines the impact area size of observation. Increasing it increases the number of local observations

# knowledges
Divergence of the Kalman filter: if the ensemble collapses, the Kalman gain tends to zero and the assimilation system behaves as one – expensive – free run.
good data assimilation system helps monitor status of observation system
innovation : observation -background, or called background departures
Q: flow-dependent correction, forecast range dependency
NWP: Numerical weather prediction 

# neXtSIM repositories
## nextsim-env
The repository includes subfolders:
  - config for machines
  - config for model runs
  - data download scripts
  
## nextsim-tools
  - pynextsim, visualize and analysis   docker build . -t pynextsim
  - matlab
  - bamg, mapx by python binding
## nextsimf
  - pynextsimf - run forecast


# Questions & answer:
- nextsim.cfg in job array is emptied in work path
  A: unknow reason. backup nextsim.cfg in the slurm.jobarray.template.sh

- try to define std::string restart_path = vm["restart.input_path"].as<std::string>(); in externaldata.cpp
  
-  Are mesh|field_final.bin/dat and restart/field|mesh_final.bin/dat the same? Is it necessary to use write_final_restart?
  A: No, although sharing the same file names.

- TOPAZ dataset -TOPAZ4RC_daily is not complete in Dec. 2018. It is operational forecast dataset downloaded from met? Missing file can be replaced by file of the nearby dates

- model crash: ERROR in gmshmesh.cpp line 454: invalid file format entry 

- difference between TOPAZ4RC_daily and TP4DAILY

# 2021
All data assimilation methods are baded on the Bayes's theory  
The theorem leads the problem to least-square inverse problem with Gaussian error distribution


# run python in singularity
singularity exec --bind /nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun:/plot --cleanenv /cluster/projects/nn2993k/sim/singularity_image_files/pynextsim-no-code.sif  python /plot/plot_summary_time_series.py

Or
add SINGULARITY_BINDPATH+=",/nird/projects/nird/NS2993K/NORSTORE_OSL_DISK/NS2993K/chengsukun" in 
~/pynextsim.sing.src
singularity exec --cleanenv /cluster/projects/nn2993k/sim/singularity_image_files/pynextsim-no-code.sif python $work_path/file  

persistent field is meant to be the initial conditions (ie the restart), with the idea that comparing its evaluation with the forecast tells you if the model is helping. We take a bit of a shortcut and use the first day of the moorings file (or maybe the first record)

investigate DA sic on 10-25-2019
using Yumeng's python code based on pynextsimf
forecast std in prior 0.013425477828866423
analysis std in prior 0.009236595317403553
Mooring DAsic std before DA (2019d297) 0.014722677178171457
Mooring freerun std before DA (2019d297) 0.013344032832063563
Mooring DAsic std after DA (2019d298) 0.012371694701988201
Mooring freerun std after DA (2019d298) 0.013571240514265859

exportStateVector->stateVectorAppendNetcdf

loadGrid

add sst, sss to statevector output to enkf-c, 
M_sst    Sea surface temperature 
M_sss    Sea surface salinity

get_ensmean.py   collect moorings from a run result to a new folder 
compare_DA.py     
plot_bias_RMSE.py


# 29-11
enkf_prep in enkf-c is not paralleled, which cost >95% time for DA. Thus, I move it to preprocessing. The result of code are submited as one job for 26 periods.
there is no cs2smos data in the end of date26 
# 1-Oct
- obviously larger bias of SIT from map view in DAsic compare to others, mainly observed in Chukchi Sea, and less in Beaufort Sea and Laptev Sea
- 


# 30-Sep.
- correlation between sic and sit. The relation for sit>1 is not reliable
- display bias map
- check the impact of high assimilating frequency of sic on the bias and rmse
- 


# 7-Sep.
- the same nudging coefficient is used for SST and SSS
- 8-nudging
- draft a subsection about the functioning of the couple neXtSIM - TOPAZ is. What variables are exchanged and how. Possibly including an illustration. 
- only marginal advantages from DA are seen on the full Arctic, but larger improvements on the IIEE and RMSE are visible
- setup on Betzy HPC

# 11-Aug
(what is analysis or reanalysis) if it is forecast,the forecast is just free run of TOPAZ initialized from when. 
        if we are using the reanalysis, it means we use the data twice to some extend. 

  - Whether the quality of the forecast obtained arbitrary time is constant.
  
  - It is not a standard experiment setup if we use reanalysis TOPAZ + sea ice system (instead, we use forecast topaz).  
    Because TOPAZ has already assimilated concentration and thickness. As the ocean forcing, the constraint concentration and thickness are already going through the simulation with assimilation. At least for concentration. 
  - We understood the system better and expect from assimilating ice concentration cannot be very visible and effective when one looks at the skills of our stand-alone system over 1-2 day after assimilation.

  - if one assimilates ice thickness in a system forced by ocean that has seen a constain sea ice itself is constraint by data being concentration and thickness like TOPAZ, then the thickness is constraint in TOPAZ. 
    Therefore, the temperature of the ocean and energy flux through the ice in TOPAZ, exacted from the ocean, is already seeing the change of thickness being constraint. 
    If we force the ocean with TOPAZ, we still be a bit attractived in the solution of TOPAZ in terms of sea ice thickness. 

# 23-June
scatter plot sic vs sit using one member forecast/analysis
1. sic bias (model -obs.) is larger (a jump) after 1-day forecast from restarting.
2. spread of sic is not reducued as expected.  
May due to the bias/rmse difference defined between pynextsim and enkf-c
3. investigate one enkf, prior/forecast
4.  values of variables in OW are 0.
5. ensure it is not necessary to assimilate sss and sst
6. use inflation to tune dfs and srf.
7. compare the root-meansquare error of the ensemble mean to the average ensemble spread. two different and inconsistent methodologies have been used over the last few years in the meteorology and hydrology literature to compute the average ensemble spread. 
   1.  the square root of average ensemble variance 
   2.  the average of ensemble standard deviation . The second option is incorrect. 

# 21 june
error in using reanalysis sit&sic to restart forecasting. the loaded analyzed sic is different from M_conc preloaded from other sources. The run crashed quickly. 
fix scale factor in loading analyzed concentration
is it necessary to count for the classification oof thin, and thick ice when loading concentration? M_conc_thin and M_conc. Would it affect the formation of ridge in code?

# 9-June
assimilate osisaf ice concentration
/cluster/projects/nn2993k/sim/data/OSISAF_ice_conc/polstere/2019_nh_polstere
variable names:
  ice_conc
  total_uncertainty

https://spaces.awi.de/display/CS2SMOS/CryoSat-SMOS+Merged+Sea+Ice+Thickness
2019-10-18, 2020-4-12

# 19-5
- apply the drag correction, run one member with and without perturbations for 1 month 
and verify if the damage variable is overall larger in the perturbed run than in the unperturbed run. 
  - I want firstly tune the air drag coefficient.
  - ensure that air drag coefficient = air drag coefficient*drag_correction_ratio
  - The uncertainty of air drag coefficient is larger than the amplification in wind pertturbation. Therefore, In the calculation of wind-ice stress tau_a =rhoa*air_drag_coef*|U|*U, the amplification can be ignored.
- ensure variance of wind speed using 3m/s. DONE
- when to perturb the cohension. ONLY AT THE INITLIZATION OF SPINUP EXPERIMENT
- what is free run    == deterministic one

ask Gullium cohesion in leads

# 29-4
enkf-c is updated to v2.8
enkf_calc crashes using ETKF  
add geographic=yes in grid.prm
cs2smos data can be readed by editing xy_grided in obs.prm
correct uncertainty (std) of SIT from cs2smos, using Xie's new formula 2019

# 27-4
- DONE. We should discard the SIT closer than 50km from the coast to
account for differences of coastlines between the model and observations.
  *   We use grid: reference_grid.nc created from OCRA grid, used in NEMO. 
 *   The grid use variable mask to indicate land and ocean.
 *   mask is modified that the ocean area is limited with the nextsim domain by its output prior.nc sit, that mask(isnan(sit))=0



# 20-4
obs_distance2coast函数里，利用min_distance2coast_km删除了靠近coast 30km。调节min_distance2coast_km大小，可以把一些陆地上的观测也删掉。
另外我还删除了lat<70的观测点，所以good observations少了很多

# 15-4
- analysis DA experiments from Oct-15 to Jan-6-2020
  - output the coordinates of statistics in enkf_diag.nc
  - dfs, srf interpretation
  - 

- reference_grid_coast.nc is redefined by m_coast.mat from m_map/private. The old file created from Moorings boundary is insufficient to filter out observations far outside of the Moorings area. It implies the necessary of rerun DA experiments

# 25-3
generating inhomogenous cohesion field is not applied as supposed. Because the amplitude of varying the cohesion is changed by name:alea_factor to C_perturb in nextsim

Fram has File system Error, unable to compile nextsim or edit files.

# 23-3
synforc is return, temporal-spatial correlation in perturbation is carried out by randfld


# 21-3
set spinup 42-day run 
1. wind perturbations
2. atmosphere perturbations
3. atm+cohesion perturbations
# 19-3
average of snow depth and longwave heat flux over the simulation

the reason of perturbing cohesion.

check wind perturbiation magnitude


# 11-3
applied perturbations for uwind, vwind, snowfall and dwlongw. wait in queue for verifying
improve slurm script for submitting job, and nextsim_data_dir, envfile.  reducing the copying of data
may need a singularity for ensemble run. fight for unknown errors occur sometimes.
prepare e-poster for Arctic Science Summit Week 2021


# 9-3
dwlongw(perturb) = Qlw_in="derivative_of_surface_downwelling_longwave_flux_in_air_wrt_time"

snowfall="derivative_of_snowfall_amount_wrt_time"

# 4-3
Q: Load generic_atm_....nc is loaded twice for a given time, one for variables saved on elements, one for nodes
  how frequency does the wind field be loaded? too frequent
  compilation failed when one includes export SINGULARITYENV_USE_ENSEMBLE=1  in pynextsim.sing.**src**

Todo: wind perturbation
      - wind speed, u,v
      - long waves
      - snow fall rate (precipation), wait for Laurent to convert snow accumulation perturbation to snow rate perturbation

# 25-2
I guess the executable file tries to access your home directory.
nextsim.exec: error while loading shared libraries: libmpicxx.so.12: cannot open shared object file: No such file or directory
>
> to see what happens when we have exactly the same forcing files and executable, can you set
>
> export NEXTSIM_DATA_DIR=/cluster/projects/nn2993k/sim/sukun_test/nextsim_data_dir
>
> and use /cluster/projects/nn2993k/sim/sukun_test/nextsim.exec inside singularity?
>
> You can also try writing to $SCRATCH or not.
>
> I have tried with these (not writing to scratch) and again had no problem with 81N.
>
> Cheers
> Tim
# 24-2
high latitude hole is found for latitude>81, which only occurred on my fram account. 
Tried to use singularity (general platform for super computer), I still have this problem.
docker on my laptop is set up. Runs on docker give reasonable results.

# 17-2
raw wind data is loaded by 32 processors, where each one only saves a subgrid. The subgrids are plotted. It is difficult to save the subgrids coordinates using netcdf, because of the conflict in writing by multi-processors. But it is more efficient to only export the limits of longitude and latitudes into the log file. It is a shame that I find it after one day try and error.

https://drive.google.com/drive/folders/1pgo7CsbLDnX2BJOnXoecJLtx1UB_P2hp?usp=sharing

free drift, ice-air stress, ocean-ice stress

# 14-2
roll back to old git commits in develop branch. It is still observed the crack at 81 degree latitude using ec2. It only disappears for constant atmosphere or free drift.

find no ice drift for latitude >81 degree. 
draw sketch map of the ec2 longitude-latitude grid and cartesian grid to show the necessary for interpolation.

# 9-2
X- and Y- directions of the polar stereographic grid
U and V wind components are in the meridional(northward) and zonal(eastward) directions (you can guess that from the singularity at the North Pole)
http://tornado.sfsu.edu/geosciences/classes/m430/Wind/WindDirection.html

# 3-2
notice  a long lead in all the ensemble runs along a latitude near 81 from all ensembble members. 
- rerun a deterministic run using develop branch  : bmeb has renamed by bbm. It needs to merge with the develop branch 
- save coorinates information in windperturbation output, in order to check the reliability of the perturbations.
# 1-2
ask Yiguo and Xie how to use enkf_diag.nc, especially SRF and DFS

apply a corrected uncertainty (std) of cs2smos by Xie et al. (2017) Eq. (4)
  if (strcmp(meta->type,"sea_ice_thickness") == 0) {
      o->value = (double) (sit[it][i][j]*sit_scale_factor);
      // o->std   = (double) (error_std[it][i][j]*estd_scale_factor);
      o->std   = (double) (min(0.5, 0.1 + 0.15*sit[it][i][j])*estd_scale_factor);
  }

ERROR: enkf: CPU #0: dgesvd(): lapack_info = 29 at (i, j) = (290, 100)

# 26-1
review enkf user manual
EnKF-C uses the popular polynomial **taper function** by Gaspari and Cohn (1999), see section 2.7.9.

# 25-1

improve the google doc https://docs.google.com/document/d/1nSXNX0ezZJMMOC751ecD3mtcFxNyRdmTD1syclT_7KQ/edit#
set E_a(<0) = 0 in enkf-c, update.c
    for (e = 0; e < nmem; ++e)
    {
        if(v_a[e]<0)
            v_a[e] = 0;
        vvv[e][j][i] = v_a[e];
    }
reset 3-month assimilation.
    error config files *.prm are copied from nextsim directory to date2/filter.
save enkf indices  to enkf_diag.nc

yiguo, check nlobs_max
    In enkf-c, if the maximum number of observation is not assigned.  nlobs_max=INT_MAX=2^31 in code.
check reference grid distribution. resolution?

cs2smos v2.2 description https://earth.esa.int/eogateway/documents/20142/37627/CryoSat-2-SMOS-Merged-Product-Description-Document-PDD.pdf



# 19-1
Compare [(ensemble spread)^2 + Variance of observation error]/(Variance of innovation) 


# 15-1 
see conclusion https://nerscno-my.sharepoint.com/:w:/g/personal/sukun_cheng_nersc_no/EZVWvrO-2nZDg5ixt3y8R4MBovIXJBcuBplc7dr_UaDZdA?email=Sukun.Cheng%40nersc.no&e=BwbAXM
reference_grid.nc doesn't contain coast information. Thus, it cannot filter data near coastline in grid_xy2fij() by
if (g->numlevels[j1][i1] == 0 && g->numlevels[j1][i2] == 0 && g->numlevels[j2][i1] == 0 && g->numlevels[j2][i2] == 0) {
        *fi = NAN;
        *fj = NAN;
        return STATUS_LAND;
    }

# 11-1
large negative values in s_f  ---- _FillValue    = -100000000376832 in mem001.nc, are loaded and changed by function H in ensobs.c line 200:
  H(das, nobs_tomap, obsids, fname, e + 1, INT_MAX, das->S[e]);
  I guess the code load nan as random large float. 

  H functions to calculate forecast observations from the model state, basically -- 2D and 3D linear interpolators.
   use H_surf_standard

  _FillValue is assigned by M_miss_val in gridoutput.cpp: data.putAtt("_FillValue", netCDF::ncFloat, M_miss_val);
  double M_miss_val = -1e+14; is defined in gridoutput.hpp

# 8-1
  assimilate ice thickness gives significant correction. Near the ice edge, analyzed thickness are mostly negative. If the negatives are all set as 0 in the forecasts of the next DA cycle, large ice covered area could be gone.

  tune enkf parameter based on the first week's forecasts.

# 5-1

  estimate ensemble size - done. >30-40 is sufficient
  run da cycle
  analysis osisaf, cs2smos comparison


# 2020
# 29-12
date of the two files are wrong.
  Equally_Spaced_Drifters_20190903.nc
  IABP_Drifters_20190903.txt

# 19-12
perturbation atmospheric variables:
    1 wind
    2 longwave/clouds. Einar said you could use cloud cover to parameterise incoming longwave - but we've stopped doing this.
    3 precip/snow
    4 air temp
    5 dew point and shortwave
variable 1 is saved on nodes. While others are saved on elements.
neXtSIM load variables saved on elements first, and then load variable saved on nodes separately from the same external dataset.



* **important**, is it necessary to use the same set of perturbations when using different combination of enkf parameters?


# **variables in elements and nodes are processed sequentially**


## Plan A (a large restart file, and two small temporal files)
In elements
  * if(NOT exist WindPerturbation.nc) 
    {        
      create previous perturbation in fortran
    }
    else
    {
      
      load WindPerturbation.nc
      if (do perturbation on elements) 
      {broadcast *previous* perturbation & add to relevant fields}
      save perivous perturbation to synwind_node_previous.nc.
    }
  * **create current perturbation (fortran)**
  * **save dimensinal perturbations for variables on nodes to a temporal smaller file synwind_node01.nc**
  
  * if (do perturbation on elements) {broadcast current perturbation & add to relevant fields}

In nodes
  if( do perturbation on nodes)
  {

    (it would be better if synwind can be called from Mwind_element)
    load previous perturbation synwind_node_previous.nc
    broadcast previous perturbation & add to relevant fields

    load current  perturbation synwind_node01.nc
    broadcast current  perturbation & add to relevant fields
  }

export perturbations (dimensional and nondimensional fields) to WindPerturbation.nc at the end of simulation

Pros: light weigh on IO
Cons: more complicated coding, harder for maintaining.

## Plan B (two large restart files, follow Ali's idea, heavy IO)
In elements
  * if (no exist WindPerturbation01.nc) 
    {create previous perturbation in fortran}
    else
    {load WindPerturbation01.nc}
    if (do perturbation on elements) {broadcast *previous* perturbation & add to relevant fields}

  * **create current (& previous) perturbation (fortran)**
  * move WindPerturbation01.nc to WindPerturbation00.nc
  * **save dimensinal/nondimensional perturbations to WindPerturbation01.nc**
  
  * if (do perturbation on elements) {broadcast current perturbation & add to relevant fields}

In nodes
  if( do perturbation on nodes)
  {
    load previous perturbation WindPerturbation00.nc 
    broadcast previous perturbation & add to relevant fields
    load current perturbation WindPerturbation01.nc 
    broadcast current  perturbation & add to relevant fields
  }

# Plan C
one can do the perturbations offline. 
Pros: save simulation time when tuning enkf, more flexible coding. 
Cons: huge dataset, independent module w.r.t nextsim

## Summary ( 5-12 to 18-12 )
#### Experiment setup
- The studied time is chosen from 9-2019 to 4-2020, in order to assimilate the ice thickness from CS2SMOS product [ref]. CS2SMOS is available during the winter since 2010. In our case, the CS2SMOS data is from 15-10-2019 to 30-4-2020.
   
- Two sets of ensemble forecasts are conducted during the period. We spin up for an ensemble forecast from 3-9-2019 to 15-10-2019 (the first observations from CS2SMOS) without assimilation, in order to have sufficient spread. The ensemble forecast are initialized from a single restart file from neXtSIM forecast on 3-9-2019. 50 members are then spun up for 42 days with perturbations of surface wind fields (and other surface boundary fields). 
  hope the 6-weeks spinup time allow the perturbation to grow into sufficiently large spread of ice thickness/concentration, snow depth, etc for data assimilation purpose.
  
- The following ensemble forecast period reduce to a week from 15-10-2019 to 30-4-2020, with a process of assimilating CS2SMOS ice thickness. Diversity among ensemble members comes from the perturbation of wind forcing.
  
#### Troubleshooting
1.  Incomplete ocean forcing from TOPAZ4.  
    TOPAZ4RC_daily is operational forecast products downloaded from met.no,ftp://mftp.cmems.met.no/Core/ARCTIC_ANALYSIS_FORECAST_PHYS_002_001_a/dataset-topaz4-arc-myoceanv2-be.
    TOPAZ4RC_daily have missing files on Johansen. Jiping doesn't have those files. 
    Tim suggested to replace the missing file with file of the closest dates.
  
2. find a bug when using TOPAZ4RC_daily in neXtSIM. 
   Tim fixed the bug on 15th: only use the 1st day of atmospheric forecast forcing file. issue#495
    "bug for forecast.true_forecast = false (when using forecast forcings for a "free run")
    Should move onto the next forecast after 1 day but is instead finishing the file.
    This will give a worse free run."
   It leads to abort of previous simulations (three weeks ensemble forecasts), since the misused of wind forcing

3. HPC slurm
   develop option: SBATCH --qos=devel for highest priory, limited by 0.5 hours. The maximum number of running jobs is limited by 1 on Fram. (QOSMaxJobsPerUserLimit: Upon reaching the per user running job limit for a **partition**, any further jobs submitted to that same partition by the same user will be shown as state Pending (PD) with the Reason set as QOSMaxJobsPerUserLimit.)
   short job option:  SBATCH --qos=short for high priory, limited by   2 hours. The maximum number of running jobs is limited by 2 from time to time.
   Noraml job squeue is too long.

4. 35-day forecasts mostly crashed with ERROR in gmshmesh.cpp line 454: invalid file format entry.
   Tried several different starting date, still get this error from time to time. Restart file is from the neXtSIM forecast: /Data/sim/tim/forecasts/arctic_forecast_cmems.ma10km.nfram_tim.bbm/20??????/restart
   It's not the latest version of the code though (the newest version is much better) - you could maybe do a free run to get to the date you want. the forecast is not too bad in Septemper. 

5. Another way is to split 35 day forecast into 5 short forecasts with restarts. More freuqent job submissions also leads to more waiting time.
   
6. Modification in wind perturbation of neXtSIM.
   Update nextsim:mod_random_forcing.F90 from Gaussian version to Lognormal version, see https://svn.nersc.no/hycom/changeset/298/HYCOM_2.2.37/CodeOnly/src_2.2.37/nersc/mod_random_forcing.F
  **In nextsim version, the perturbations for clouds, precipitation, relative humidity, pseudo air temperature, sea level pressure are calcualted but not used.**
  todo: add some of those perturbations in c++ routine (externaldata.cpp).

   assimilate atmospheric variables: 
   u & v compont of wind speed,
   clouds, use **lognormal** version
   precipitation
   relative humidity
   pseudo air temperature
   sea level pressure


----------------
   By the way Einar, I wonder if the air temperature and cloud cover perturbations make sense for neXtSIM or if you use other inputs to your surface heat fluxes scheme. 
    It depends a bit on the forcing used. But the input parameters should be

    * wind
    * air temperature
    * humidity/dew point
    * incoming longwave
    * incoming shortwave
    * rain/total precip
    * snowfall

    I'm fairly certain that you use cloud cover to parameterise incoming longwave - but we've stopped doing this. So, in some order of importance I'd perturb
    1 wind
    2 shortwave
    3 precip/snow
    4 air temp
    5 dew point and shortwave
  comparing nextsim:mod_random_forcing.F90 and https://svn.nersc.no/hycom/browser/HYCOM_2.2.37/CodeOnly/src_2.2.37/nersc/mod_random_forcing.F
  **In nextsim version, the perturbations for clouds, precipitation, relative humidity, pseudo air temperature, sea level pressure are calcualted but not used.**
  todo: add some of those perturbations in c++ routine (externaldata.cpp).

  - confirm that perturbations are generated using nondimensional fields (randfld), but not using the dimensional fields (saved in synforc). 

##### Todo: 
-  ice extent, spread of snow depth, ice thickness/concentration
-  Adjust ECMWF data air drag coefficient.
-  Tune factors (R, K, inflation, localisation radii) in enkf
-  Assimilate ice thickness, concentration indpendently and ajointly. There is a bug in assimilating concentration.
-  merge enkf_interface_sukun to enkf_interface and develop
  
  

##

# 17-12
long waiting time on Fram. The best is to use qos=short running two cases simultaneously. 

# 15-12
- use SBATCH --qos=short for high priory queue, limited by 2 hours.
- Upon reaching the per user running job limit for a partition, any further jobs submitted to that same partition by the same user will be shown as state Pending (PD) with the Reason set as QOSMaxJobsPerUserLimit.

# 14-12
 - a bug in nextsim, waiting for Tim who mentioned to fix it. 
 - add perturbation of precipation

TOPAZ4RC_daily in johansen missing many files that needs to be retrieved from some where.
ECMWF_forecast_arctic is used.  /Data/sim/data/ECMWF_forecast_arctic from 2017
others are available from 2010

- Get restarts from the neXtSIM forecast:
/Data/sim/tim/forecasts/arctic_forecast_cmems.ma10km.nfram_tim.bbm/20??????/restart
It's not the latest version of the code though (the newest version is much better) - you could maybe do a free run to get to the date you want. the forecast is not too bad in Septemper. 
Restart dates are from 2018-10-31

- CS2SMOS from 2181015

thus, use restart of 2018-9-1

# 9-12
proof reading of paper, create a graphical abstract
submit an abstract to Arctic science summit week.

# 6-12
only do inflation of observations 
different between TOPAZ4RC_daily and TP4DAILY
2018 or 2019. 
TO run one year simulation, where to save forcing dataset

## Summary (11-10 to 4-12)

Done.
1.  Modify wind pertubation interface due to an update in nextsim/develop. Apply perturbation to  subdomains of the field saved by different processor.(perturbation indicates random forcing generated by fortran routine.)
   - CANCELLED. Save perturbations (synforc and randfld) in restart file (of each ensemble member). Reason:externaldata structure is initialized after readRestart(). It would be complicated to stick with one restart file. 
   create a function import and export_WindPerturbations in c++ replace old on in fortran
   -
   - In previous version, wind perturbation routine 
   1. reads forcing fields from synforc01, randfld01.
   2. copy synforc01, randfld01 to synforc00, randfld00
   3. generate perturbations based on loaded forcing fields.
   4. save perturbations to synforc01, randfld01
2. Modify workflow of script on HPC. 
   1. Job array, implement Ali's changes of submitting enkf job on slurm. Modify the scripts for submitting jobs.
   2. member_analysis, restart file, for each member are linked to NEXTSIMDIR/data for  ensemble forecasts in the next DA cycle.
3. check completeness of datasets. make dataset links in NEXTSIMDIR/data

Todo:
1.  Consider change studied time from winter 2018 to winter 2019. TOPAZ in 12.2018 is not completed.
2.  Adjust ECMWF data air drag coefficient?
3.  Tune factors (R, K, inflation, localisation radii) in enkf
4.  Assimilate ice thickness, concentration indpendently and ajointly. There is a bug in assimilating concentration.
5.  merge enkf_interface_sukun to enkf_interface and develop

6. Perturbations are generated based on randfld01. If so, synforc in the fortran arguments can be deleted.






# 1-4.12
Minor revision of ensemble forecast paper.
push and complete code debugging progress. 

# 29-11
- **Error** terminate called after throwing an instance of 'netCDF::exceptions::NcBadId' -- netcdf file is not readed correctly.
  mem***.nc.analysis created by cdo merge may not be performed correctly. 
  It is due to dataset.cpp $ifdef ENSEMBLE, include 2 variables. But mem001.nc.analysis only includes sit. 
        std::vector<Variable> variables_tmp(2);
        variables_tmp[0] = thickness;
        variables_tmp[1] = conc;
  Temporarily I remove conc to only analyze ice thickness. 

- **Error** enkf_prep reports no sea ice concentration data, that needs further study, related to obs.prm, obstypes.prm. dataset.cpp, cs2smos_read.cpp
  one should keep variables to be assimilated consistently in obs.prm, obstypes.prm, model.prm


# 25-11
create a function import_export_WindPerturbations
   M_external_data_nodes.10U->{synforc, randfld}

todo: merge Dockerfile in enkf_interface_sukun

add [statevector]restart_path in nextsim.cfg


# 16-11
transfer data from Johansen
  topaz forecasts is  /Data/sim/data/TOPAZ4RC_daily
  ecmwf forecast is   /Data/sim/data/ECMWF_forecast_arctic/0.1deg
- mem*.nc.analysis is loaded as initial state for sit, maybe also others.   
- synforce and randfld may be saved in mem*.nc.analysis too. (CANCELLED)

# 14-11
du -h --max-depth=0 test_Ne25_T4_D7
find . -name 'core.*' | xargs rm -rf

# 9-11
In model/dataset.cpp find "else if (strcmp (DatasetName, "enkf_analysis_elements") == 0)” (should be line 5508) and try changing (lines 5512 - 5513)

        Dimension dimension_x={
            name:"y",    // this setting works!   dimension_x <-> y, while dimension_y <-> x
to 
        Dimension dimension_x={
            name:”x”,
and (lines 5516 - 5517)
        Dimension dimension_y={
            name:"x",
to
        Dimension dimension_y={
            name:”y”,


- revise paper (@pierre)
- adopt job array feature
- test enkf cycle. Cannot restart cycle
  two restart sets: mem??.nc.analysis (due to enkf)
                synforc in restart (due to wind perturbation)
  **Error**: compare initstatevector and initmooring
    [DEBUG] : initStateVector
    terminate called after throwing an instance of 'netCDF::exceptions::NcEdge'
      what():  NetCDF: Start+count exceeds dimension bound
    file: ncVar.cpp  line:1622

Correct a typo: latitute in Environment::vm()["statevector.grid_latitude"].as<std::string>(), in finiteelement.cpp

# 04-11
apply job array. Revise Ali's job array script to run ensemble in task. 
It is different from my original thoughts that one can request some nodes from Fram, and the simulations are automatically assigned to nodes. 
In the job array, the script applies N nodes, where N equals to the ensemble size. sbatch settings of each ensemble simulation is as same as that in the normal sbatch submission

- run error occurs, related to netcdf badID, when use statevector in nextsim.cfg
  error disappeared after Fram maintenance.

- test job array function to run cycles of N ensemble runs and enkf
- review results
- optimize parameters of enkf method.

# 30-10
revise script to run a series of simulations and enkf in one task
Note: A parallel job will get one, shared scratch directory ($SCRATCH), not separate directories for each node! This means that if more than one process or thread write output to disk, they must use different file names, or put the files in different subdirectories.
alternatively, it is better to use array-jobs. This is useful if you have a lot of data-sets which you want to process in the same way with the same job-script:

# 29-10
Using bmem causes failure since last week, when I wanted to rerun the 2007-2008 deterministic run in the submitted paper using the new settings in neXtSIM suggested by Einar. It is mainly to test the new settings and the changes in wind perturbation routines in the short forecasts later.

# 19-10
revise manuscript
learn to use FindTime to poll meeting time
try to resolve problem that compile source code linux for using in windows
install ww3 

# 13-10
FOCUS meeting talk
paper revision.


# 9-10 
see note __13-9__ related to "enkf_analysis_elements". Ask Ali.
see note __23-9__ for submitting enkf to slurm

## Summary (1-9 to 10-10)
fram is in maintainance.
The process of loading external data is updated in neXtSIM develop branch recently. Therefore, the wind perturbation interface needs to be updated for consistency. Specially, the procedure related to wind perturbation in the latest version is addressed as following, 
1. Load wind field, each processor load a subdomain from the external fields, instead of a full field in previous version.
2. Generate wind perturbation when new input is avaiable, but not consider the effect of remesh.
3. Add perturbation to input wind velocities for previous time
4. Perturbation of whole domain of wind field is generated by root processor.
5. Broadcast the perturbations generated by item 4 to all processors.
6. Each processor retrieves and adds perturbation to wind velocity on its assigned submain at current time.
7. For a restart simulation, the previous perturbation (randfld, synforc?) is generated in the last perturbation of a previous simulation. Thus, at the end of simulation, randfld are saved in restart file: exportResults, and read from another simulation readRestart(). 

Denote:
1. perturbation indicates random forcing generated by fortran routine.
2. Dimensional and nondimensional perturbations of full domain are saved as synforc, randfld.
3. Use 00, 01 indates previous and current times. 

Note:
1. Summary:items 1,3,6 refers to M_dataset->variables[i]->loaded_data, where M_dataset refers to real argument M_wind.
2. synforc, randfld are defined in dataset structure for all processors. Have tried different data structures, including vector, vector<vector>, 1d pointer (use malloc) for saving synforc, randfld (All work).
3. Both previous and current wind fields are loaded in item 1 of Summary. Thus, it needs Summary:items 2 and 6.

4. In Summary:item 4, synforc, randfld are transfered as arguments between c++ and fortran interface, instead of save-read files. It is expected to save time.

5. After merging from develop branch and fixed consistency issue, time cost of a 7 day simulation is surprisely slow down from 25min to 50 min. (check again after turning off synforc output)
6. Wind speed is scaled during spinup for clean run, but not for restart simulation.    
    M_factor=(M_current_time-M_StartingTime)/M_SpinUpDuration;
    value =  M_factor*M_dataset->variables.... But I don't understand value return from ExternalData::get()



In previous version, wind perturbation routine 
   1. reads forcing fields from synforc01, randfld01.
   2. copy synforc01, randfld01 to synforc00, randfld00
   3. generate perturbations based on loaded forcing fields.
   4. save perturbations to synforc01, randfld01

To_be_confirm: 
 1. Perturbations are generated based on randfld01. If so, synforc in the fortran arguments can be deleted.
 



Todo:
  change precison from double to float for perturbations in fortran routine.


 

# 7-10
- identify a bug in externaldata.cpp that causes loaded ecmwf and perturbation at every time step after the first 6 hours. 
  Due to remesh, M_dataset->loaded is set to 0. check_and_reload() is executed after the remeshing process.Becuase remesh occurs more frequent than ECMWF data frequency. THe wind perturbations are independent on nextsim mesh. We can change to code to avoid too frequency remesh, which will also create rapid changes in the wind fields.
  The underlying reason is due to a mistake of reading wrong order of loading randfld and synforc in fortran routine

# 4-10
- check: synforc saved in fortran is transfered through c++ interface correctly (index)
- lon(x domension, N_full) = 3600, lat(y domension, M_full) = 501
- remove temporal 1d array for broadcasting perturbation. The previous error is because that M_dataset->variables are claimed in root processor only. 

- dataset->variables[j].dimensions.size()
Dimension 0(time), start/count = 0/1
Dimension 1(lat), start/count = 107/58     - y domain
Dimension 2(lon), start/count = 208/279    - x domain
For a subgrid loaded from a netcdf in loadDataset(), data are loaded by slides in x-domain for fixed each y. It reads all data at different longitudes first for each latitude, then for time.  As data structure is time(lattitude (longitude))


- Todo: check if perturbation is applied often. ec2.nc for contains 10-day forcasts

- in loadDataset(), ecmwf(ec2_nodes) and topaz data are loaded previous, current, and next times. Search "if(filename_prev!="")" in externaldata.cpp.
Because an ecmwf files contains multiple time steps, the codes read data from previous and current time steps.

- read [DEBUG].
  ECMWF is loaded twice. One for ec2_elements. One for ec2_nodes, which contains wind speeds u,v. 
  [DEBUG] : checkReloadDatasets for variable 0: 10U of dataset ec2_nodes
# 2-10
- wind perturbation is supposed to be scaled.
  M_factor=(M_current_time-M_StartingTime)/M_SpinUpDuration;
  value =  M_factor*M_dataset->variables.... But I don't understand value return from ExternalData::get()

- It seems ec2 load too many times.

# 1-10
grid index saved in a processor is changed in the latest version of nextsim edited by function addHalo in dataset.cpp. This has the draw back that data must be loaded more frequently, but at least on datarmor the parallelised code is much faster.

# 29-9
How grid index is assigned for each processors by mpi?

Is wind velocity reduced due to spinup after adding perturbation? If so, it needs to save perturbations for restarting. The saving processing is proposed to be added into the funciton of saving state vecotor.

How M_wind is called by check_and_reload()

# 27-9 
It is completed for using 1d pointer instead of 2d vectors. 1d pointer is easier to maintain in c++, and the mpi only takes 1d array in broadcast function.
It is done for transfering perturbations online instead of save/read from files.
model crashed after several perturbation. It is related to the wrong indecies of submain saved in multiple threads. Need to check with Einar again.


# 25-9
the primarily work is  done. 2d vectors are used to save random forcing. Temporal 1d array is defined in c++ to transfer data between the 2d vectors in c++ and 2d array in fortran.

# 23-9
Because some similuations of an ensemble may crash, the following enkf calculation is then failed.  Ali's job-submitting script becomes not efficiency. The enkf part is seperated from the scipt.

# 21-9
the changes are able to be compiled.
test on the new code
1. 2D array in C++ as vector<vector> can be passed to fortran with correct content, vice versa.
2. perturbations returned to c++ are identical to the perturbations saved in files.


# 15 to 17-9

I think the perturbation codes only uses variables randfld to generate perturbations, and output perturbed variables in synforc
    nondimensional variables in ran and ran1 (randfld00, randfld01) are updated. 
   In previous version, wind perturbation routine 
   - reads forcing fields from synforc01, randfld01.
   - copy synforc01, randfld01 to synforc00, randfld00
   - generate perturbations based on loaded forcing fields.
   - save perturbations to synforc01, randfld01
questions:
0. the perturbation is charged by root processor 0, not in parallel.
1. why adding synforc00 to wind source in addperturbation() (previous perturbations synforc00 are added to wind fields), is it also applied in TOPAZ?
     
2. how to keep 2D array in nextsim: synforc,randfld
it needs to save synforc_prev and randfld_prev in data structure
- externaldata.cpp includes all functions in namespace Nextsim
- M_dataset is called from  FiniteElement::readStateVector()  (wrong, M_dataset refers to real argument M_wind.) 
      {M_enkf_analysis_elements_dataset=DataSet("enkf_analysis_elements");
      external_data M_analysis_thick=ExternalData(&M_enkf_analysis_elements_dataset, M_mesh, 0, false, time_init); }   
  M_dataset is an object of a class DataSet defined in dataset.hpp
3. because wind inputs is scaled due to spinup (from day 0 to day 1 usually), it is not necessary to have good perturbed field at day0.
  saving this perturbed field at the end of forecasting costs challenge in coding since perturbations will be only kept in simulations.
  rewrite randfld_wr, synforc_wr
  remove synforc_rd, randfld_rd
4. fortran: is it correct to set inputs as public variables?
  global variables issue is solved by including all subroutines in a module in fortran. however, it is unknown how to give inputs to the global variables in module mod_random_forcing
  

5. add the following commented? 
   !      synuwind = synuwind - compute_mean(synuwind)
   !      synvwind = synvwind - compute_mean(synvwind)
6. variables->loaded_data, how variables are defined in dataset.cpp
- synforc00,synforc01, (also randfld00 maybe) xdim, ydim is set as inputs to fortran
- move function limits_randf （read pseudo.nm）inside function init_rand_update(bad name )


 run->init->step 6) checkReloadMainDatasets->checkReloadDatasets->check_and_reload(RX, RY, CRtime, M_comm, pcpt*time_step, cpl_time_step);



void ensemble::synopticPerturbation(std::vector<std::vector<double>> &synforc00,std::vector<std::vector<double>> &synforc01,int const& M_full, int const& N_full)
  perturbation.synopticPerturbation(synforc00,synforc01,M_full,N_full);
# 13-9
1. fram system failed to load modules this morning. 
2. Found a bug. For forecasting as after data assimiltion, it should turn start_from_restart=false, while restart_from_analysis=true. So far, the code can only load thickness but not concentration.
Maybe the reanalysis data only contains analyzed thickness. Check it. 

FiniteElement::init()->M_restart_from_analysis->readStateVector
                                                   
                                                   
FiniteElement::readStateVector()
{

    M_enkf_analysis_elements_dataset=DataSet("enkf_analysis_elements");

    external_data M_analysis_thick=ExternalData(&M_enkf_analysis_elements_dataset, M_mesh, 0, false, time_init); (see externaldata.cpp line35)
//    external_data M_analysis_conc=ExternalData(&M_enkf_analysis_elements_dataset, M_mesh, 1, false, time_init);

    external_data_vec external_data_tmp;
    external_data_tmp.push_back(&M_analysis_thick);
**//    external_data_tmp.push_back(&M_analysis_conc);**
    this->checkReloadDatasets(external_data_tmp, time_init, RX, RY);
# 10-9

final decision for submission
Journal referees
-Helge Goessling from AWI Germany: helge.goessling@awi.de
-Jean-François Lemieux from EC Canada: Jean-Francois.Lemieux@ec.gc.ca
-francois Massonet from UCL Belgium: francois.massonnet@uclouvain.be
- Axel Schweiger from UW United States: axel@apl.washington.edu 

# 9-9
new procedure:
  synforcPerturbation, do perturbation on full domain, save file
  loadPerturbation,    read file
  mpi::broadcast perturbation()
  addPerturbation by all processors, select and add perturbations to relevantsubdomain 

PS：it takes about 1 minute to copy data to job path
# 8-9 
ran  saves randfld00
ran1 saves randfld01 
- to simplify the problem, temporarily I don't consider save file at the final and read file at the start.
  just return synforc and randfld
  let c++ to decide when to read/save synforc and randfld. 
  rewrite  randfld_wr(),synforc_wr(), delete randfld_rd(), synforc_rd() 
synforc_rd is only used once at the start of simulation

this->loadDataset includes start and count of each subdomain associated with processors
    start/count:  index_start[k], index_count[k]
    k=1,2  longitude/latitude
    int y_start = M_dataset->grid.dimension_y_start;
    int x_start = M_dataset->grid.dimension_x_start;
    int y_count = M_dataset->grid.dimension_y_count;
    int x_count = M_dataset->grid.dimension_x_count;    
it needs nextsim to keep synforc00, synforc01  in memory

[synforc00, synforc01] = perturbation(synforc, randfld)
synforc has 8 variables including perturbed wind
randfld has 10 variables.

rand_update()

# 6-9
Due to structure change in nextsim, the wind perturbation interface needs to be adjusted accordingly. THe main issue is the change of wind input mesh size. 
In the latest version, the procedure is 
  1. read in the raw wind field
  2. truncate or interpolate into a subdomain (wrong, see final summary)
  3. split the sbudomain with mutiple processors
  4. create perturbations of the raw wind field domain by the root processor 
  5. save perturbations to file for backup and read in again by the root processor.
  6. broadcast perturbations to all processors by the root processor.
   The error occurs at step 6 while the underlying reason is due to step2. (I guess step2 was after step 6 in the previous version)
ToDO: 1. change step 5 to online data transfer with save/read on at the end/beginning of simulations.
      2. retrieve subdomain charged by each processor by index, to apply the correct perturbation

# 2-9
In externaldata.cpp The size of matrix of wind velocity is M_full*N_full=1803600, but after iterator>273600, either u or v components of the velocity becomes zeros, very large, which implies only the first 273600 values are useful.

# 31-8 
compiled nextsim program crashed in wind perturbation part. Try to location the error in code

*** Error in `/cluster/work/jobs/736388/bin/nextsim.exec': corrupted double-linked list: 0x00000000048ae7b0 ***
*** Error in `/cluster/work/jobs/736388/bin/nextsim.exec': malloc(): memory corruption: 0x000000000224f400 ***
The errors are actived at by code in externaldata.cpp:
boost::mpi::broadcast(M_comm, & M_dataset->variables[ii].loaded_data[jj][0], MN_full, 0);

# 28-8
writing work about experiment plan, literature reivew, etc 


# 27-8
fixed errors in loading compilers. Merged enkf branch with develop branch again.
new errors in submitting jobs. root files are copied to job path. It needs to solve now.

# 24-8
Encountered failed cases are all due to hitting the wall time after a long stuck time. In those cases, output information in nextsim.log file stoped at 96%. The reason is unknown. 
to save computational time, we willonly output prior.nc   
mooring is turned off, and only be turned.on when utput fonal result.
Thus, in nextsim.cfg, output_per_day=0 & use_moorings=false

# 21-8 
task lost on Fram that nohup *.sh is not in the job list, thus it cannot be terminated. While the job is running.
Task Crashs more freuqenctly in the later periods. For example, in the ensemble size test, 3/4 tasks are failed in the fourth period.


# 17-8
The cost of running a neXtSIM instance is reduced to 25 mins due to using binary format IO (60->40) in wind perturbation and using 32 cpus instead of 16 cpus in the debug mode (40 mins-> 25mins).

# 12-8
data in SIDNEPx buoy project is included in IABP. Thus, IABP dataset is used as an observation source to valid the simulation.

# 10-8
To reduce computational time <1 hour, changes are made in nextsim.cfg, such as step=900, dynamics-type=bmeb, dynamic->substeps=120
use_sidfex_drifters=true



# 8-8 
create a script to generate runs for optimizing EnKF parameters using enumeration method


# 17-7
 lost records in 2 weeks
 finished test 1 (assimilate sit), and test2 (assimilate sic and sit)
 save results from test 2 in .docx document.
 increase time step in nextsim.cfg from 200 to 400 and change output_per_day=0

Investigate the possible mutual interuption in sic and sit assimilation
prior/mem***.nc + obs. -> prior/mem***.analysis.nc
# Todo
 - redo test2 using 7 day forecasts instead of 6 day
 

# 3-7
create read_cs2smos.c from read_smos.c
needs to change:  allreaders.c/h, reader_smos.c, add reader_cs2smos.c to Makefile,
     obs.prm(product, reader)

ice concentration >1 seems not an error (maximum of analysis is about 1.2~1.4 in ensemble members). 
nextim/finiteelement.cpp 
- update() has a correction script limits concentration <=1
   M_conc[cpt] = std::min(1.,std::max(M_conc[cpt],0.));
- initIce() has several ice source options, e.g. a command in topazAmsr2Ice() below
  M_conc[i] = std::min(1., M_init_conc[i]);

a comment says "after the advection the concentration can be higher than 1, meaning that ridging should have occured" in finiteelement.cpp

# 2-7
 if a data file is listed in the observation data parameter file, then observations from  this  file  are  assimilated.
add ice concentration to enk-c
-  obstypes.prm
-  obs.prm
- add concentration in reader_smos.c, refer to reader_cars.c
- model.prm

# 30-6
7.5 km resolution. 
what is the scaled cohesion value
("dynamics.C_lab", po::value<double>()->default_value( 6.8465e+6 ), "Pa")   // Cohesion value at the lab scale (10^6 Pa is the order of magnitude determined by Schulson).
# 27-6
- Test 1 is done. Ne20_T4_D7.
- set 4 cores in rum.fram.sh is not done.

# 26-6
- Correct time domain size in prior.nc from 2 to 1. It fixes the bug of all-zeros sit in .nc.analysis 
  Remove duplicate stateVectorAppendNetcdf , which is called inside of updateStateVector() located in exportStateVector()ahead.
  No need to change in enkf-c/common/utils.c, line 861: start[0] = 0; //dimlen[0] - 1;

- change output directories structure: OUTPUTPATH-> time -> members. Thus, all middle results are solved
- write a script to find crashed nextsim instants and resubmit before doing enkf
- TODO
  - matlab to batch process analysis results 
  - remove .dat .bin outputs, check with Tim to see if it is already done.

# 25-6
- several failures of incomplete output of prior.nc. It needs to investigate why variables are not saved to prior.nc when duration >1 with wind pertubation. The issue maybe related to the following warning in nextsim.log
Reading nextsim.cfg...
[INFO] : -----------------------Simulation started on 2020-Jun-25 03:19:28
[INFO] : TIMESTEP= 200
[INFO] : DURATION= 604800
pseudo-random forcing is active for ensemble generation
 Using FFTW for Fourier transform
 Feel the power of the Fastest Fourier Transform in the West!
--------------------------------------------------------------------å------
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

# 25-6
- Incomplete output of prior.nc. 
  prior.nc doesn't save data when duration =7 day
  It needs to investigate why variables are not saved to prior.nc when duration >1 with wind pertubation. The issue maybe related to the following warning in nextsim.log. (searching the waring online, it may be related memory size, try smaller memory size for each run.
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

# issues errors
issue1_error_multi-tasks_1node is on situation 2
Suspect the error is due to confliction of accessing common mesh file from multiple core
Small_arctic_10km.msh

> It should access par32small_arctic_10km.msh, but this mesh is copied to out directory, thus no in the working directory, where is the code for this.
> move small_arctic_10km.msh  *.mpp from sim/mesh to my own data directory chengsukun/src/data, and then softlink them to nextsim/data. remote nextsim_mesh_dir in cp -a $NEXTSIMDIR/data/* $NEXTSIM_DATA_DIR/* $SCRATCH/data in slurm.template.sh
>active debugging in nextsim.cfg [debugging]


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

## Other notes
-Reduce writing/reading in wind perturbation.
  Because of many times of writing/reading operations in the simulation, the computational efficiency depends on the hard disk capability. Using m.2 ssd harddive with 2Gb/s read/write capability could save considerable time.  
- The master core occupies most of the computer memory, increasing as duration increasing. Other cores occupy equally amount of memory with small fluctuation arround a constant. 

# git 
## discard location changes and pull from remote repository
  git fetch --all
  git reset --hard origin/master


## Moorings and prior (refer to Todo - 4)
-                  grid size            data size (initial size,  final size, tested duration 2 or 7day)
  Moorings.nc       501x391                  1589306,   7891730      
  prior.nc          522x528                  2224737,  19898089

- same name:output_timestep is in moorings and statevector
- restart data is recognized by basename=final  (field_basename.bin/dat)
 In this study, we will use prior.nc to study variables' spatial distribution, which data resolution is higher. 
mooring is turned off.
