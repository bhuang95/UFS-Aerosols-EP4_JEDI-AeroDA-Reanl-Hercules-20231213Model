#!/usr/bin/env python
# run_viirs2ioda.py
# process VIIRS files and produce JEDI/IODA compatible obs files
import os
import subprocess as sp
import datetime as dt
import glob
#import xarray as xr

#grid='96'
grid='192'

InRoot='/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/AOT'
OutRoot='/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/thinned_debiased_test_C'+grid
OutRoot='/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/new_test'
FV3Grid='/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/fix_fv3/C'+grid
CycleHrs=6

StartCycle=dt.datetime(2016,6,2,12)
EndCycle=dt.datetime(2016,6,2,12)


executable='/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec/viirs2ioda.x'
my_env = os.environ.copy()
my_env['OMP_NUM_THREADS'] = '4' # for openmp to speed up fortran call
#./viirs2ioda.x $validtime $fv3dir $infile $outfile

HalfCycle = CycleHrs/2
NowCycle=StartCycle

while NowCycle <= EndCycle:
  print("Processing analysis cycle: "+NowCycle.strftime("%Y-%m-%d_%H:%M UTC"))

  # get +- half of cycle hours
  StartObs = NowCycle - dt.timedelta(hours=HalfCycle)
  EndObs = NowCycle + dt.timedelta(hours=HalfCycle)

  # get possible files to use
  usefiles = []
  dir1 = InRoot+'/'+StartObs.strftime("%Y%m%d")
  dir2 = InRoot+'/'+EndObs.strftime("%Y%m%d")
  files1 = glob.glob(dir1+'/*.nc')
  files2 = glob.glob(dir2+'/*.nc')
  allfiles = set(files1+files2)

  for f in allfiles:
    fshort = f.split('/')[-1].split('_')
    fstart = dt.datetime.strptime(fshort[3][1:-1],"%Y%m%d%H%M%S")
    fend = dt.datetime.strptime(fshort[4][1:-1],"%Y%m%d%H%M%S")

    if (fstart > StartObs) and (fend < EndObs):
      usefiles.append(f)

  validtime=NowCycle.strftime("%Y%m%d%H")
  OutDir = OutRoot+'/'+validtime

  if not os.path.exists(OutDir):
    os.makedirs(OutDir)

  print(validtime)

  for f in usefiles:
    fout = OutDir+'/'+f.split('/')[-1]
    args = ' '+validtime+' '+FV3Grid+' '+f+' '+fout

    cmd = executable+args

    proc = sp.Popen(cmd,env=my_env,shell=True)
    proc.wait() # so that it doesn't overload the system

# concatenate them
  cmd = 'ncrcat -O '+OutDir+'/*.nc '+OutDir+'/viirs_aod_snpp.'+validtime+'.nc'
  proc = sp.Popen(cmd,env=my_env,shell=True)
  proc.wait()  

#creates larger files with confused dimensions
#  ncfiles = glob.glob(OutDir+'/JRR-AOD_v1r1_npp_*.nc')
##ds = xr.open_mfdataset(outfiles, combine='nested', concat_dim=['nlocs'])
#  ds = xr.open_mfdataset(ncfiles, concat_dim=['nlocs'])
##ds = xr.open_mfdataset(ncfiles)
#  ds.to_netcdf(OutDir+'/viirs_aod_snpp.'+validtime+'-Xarray.nc')

  NowCycle = NowCycle + dt.timedelta(hours=CycleHrs)
