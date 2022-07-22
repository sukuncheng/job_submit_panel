#!/usr/bin/env python  # indicate python path

# Script for downloading the ERA5 reanalysis and making it neXtSIM friendly.
# See https://cds.climate.copernicus.eu/api-how-to for the neccesary requirements.
# NB! I had to do pip install requests, in addition to pip install cdsapi

import cdsapi
import os
import sys
import tempfile
from cdo import *
#print('Done importing packages')

# User modifiable: southern boundary of the region - must be a string
slat='57'
# User modifiable: temporal frequency of the data (in hours)
temporal_frequency = 3

# ==== END USER MODIFIABLE PARAMETERS ====

# Module instances
cdo = Cdo()
client = cdsapi.Client()

# Loop parameters
if len(sys.argv) < 4 or len(sys.argv) >4 or sys.argv[1] == "-h" or sys.argv[1] == "--help":
    print('Usage: ' + sys.argv[0] + ' firstYear lastYear product-type')
    sys.exit(1)

firstYear = int(sys.argv[1])
lastYear  = int(sys.argv[2])
# 'ensemble_members', spread
product_type = sys.argv[3]
# Request parameters
product = 'reanalysis-era5-single-levels'
variable = ['10m_u_component_of_wind',
            '10m_v_component_of_wind',
            '2m_dewpoint_temperature',
            '2m_temperature',
            'mean_sea_level_pressure',
            'mean_total_precipitation_rate',
            'mean_surface_downward_short_wave_radiation_flux',
            'mean_surface_downward_long_wave_radiation_flux',
            'mean_snowfall_rate']
#            'surface_solar_radiation_downwards',
#            'surface_thermal_radiation_downwards',

filename = 'ERA5_{}_y{:4d}.nc'
format = 'netcdf'

time = []
for h in range(0,24,temporal_frequency):
    time.append('{0:02d}'.format(h) + ':00')

day = []
for d in range(1,32):
    day.append('{0:02d}'.format(d))

month = []
for m in range(1,13):
    month.append('{0:02d}'.format(m))

# Say what we'll do
print('Will fetch ERA5 '+product_type+' from start of '+str(firstYear)+' to end of '+str(lastYear))
print('Temporal frequency set at '+str(temporal_frequency)+' hours')
print('Southern boundary set at '+slat)

########################################################################
# Loop over years and months
########################################################################
            
for year in range(firstYear,lastYear+1):
    for var in variable:

        print('\nRequesting variable '+var+' for '+str(year)+'\n')

        result = client.retrieve( product,
            {'variable':var,
             'product_type':product_type,
             'year':year,
             'month':month,
             'day':day,
             'time':time,
             'format':format} )

        # Set $TMPDIR, $TEMP, or $TMP to $PWD to write the temporary file in
        # the current directory
        f = tempfile.NamedTemporaryFile(delete=False)
        temp_file = f.name
        f.close()
        result.download(temp_file)

        # Use cdo to select everything north of slat
        short_name = cdo.showname(input=temp_file)
        cdo.sellonlatbox('0,360,'+slat+',90',
            input=temp_file, output=filename.format(short_name[0],year))
        
        # Remove the temp_file
        os.unlink(temp_file)

        print('\nOutput written to '+filename.format(short_name[0],year)+'\n')
