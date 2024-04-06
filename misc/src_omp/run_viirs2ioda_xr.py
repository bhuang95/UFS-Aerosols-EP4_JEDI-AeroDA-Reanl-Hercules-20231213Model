#!/usr/bin/env python
# run_viirs2ioda.py
# process VIIRS files and produce JEDI/IODA compatible obs files
import os
import subprocess as sp
import datetime as dt
import glob
import xarray as xr

#grid='96'
grid='192'

InRoot='/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/AOT'
OutRoot='/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/AOT/thinned_dev_C'+grid
FV3Grid='/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/fix_fv3/C'+grid
CycleHrs=6

StartCycle=dt.datetime(2018,4,14,6)
#EndCycle=dt.datetime(2018,4,23,0)
EndCycle=dt.datetime(2018,4,14,12)

validtime='2018041406'
OutDir=OutRoot+'/'+validtime

ncfiles = glob.glob(OutDir+'/JRR-AOD_v1r1_npp_*.nc')
#ds = xr.open_mfdataset(outfiles, combine='nested', concat_dim=['nlocs'])
#ds = xr.open_mfdataset(ncfiles, concat_dim=['nlocs'])
ds = xr.open_mfdataset(ncfiles)
#ds.to_netcdf(OutDir+'/viirs_aod_npp_'+validtime+'-Xarray_test.nc', unlimited_dims=['nlocs'])
#ds.to_netcdf(OutDir+'/viirs_aod_npp_'+validtime+'-Xarray_test.nc', encoding = {')
ds.to_netcdf(OutDir+'/viirs_aod_npp_'+validtime+'-Xarray_test.nc')
