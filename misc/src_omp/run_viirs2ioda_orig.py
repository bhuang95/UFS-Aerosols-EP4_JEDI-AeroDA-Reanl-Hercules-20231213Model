#!/usr/bin/env python
# run_viirs2ioda.sh
# process VIIRS files and produce JEDI/IODA compatible obs files
import os
import subprocess as sp
import datetime as dt
import glob

grid='96'

InRoot='/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/AOT/'
OutRoot='/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/AOT/thinned_C'+grid
FV3Dir='/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/fix_fv3/C'+grid
CycleHrs=6

StartCycle=dt.datetime(2018,4,14,06)
EndCycle=dt.datetime(2018,4,16,00)

viirs2ioda='/home/Mariusz.Pagowski/MAPP_2018/src/viirs2ioda.x'

my_env = os.environ.copy()
my_env['OMP_NUM_THREADS'] = '10' # for openmp to speed up fortran call
#./viirs2ioda --validtime=$validtime --gridpath=$fv3dir $infile $outfile
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
  for f in usefiles:
    fout = OutDir+'/'+f.split('/')[-1]
    args = ' --validtime='+validtime+' --gridpath='+FV3Dir+' '+f+' '+fout
    print(args)
    cmd = viirs2ioda+args
    proc = sp.Popen(cmd,env=my_env,shell=True)
    proc.wait() # so that it doesn't overload the system
    # delete empty files because they will cause ncrcat to fail
    if os.path.getsize(fout) < 100:
      os.remove(fout)
  # concatenate them
  cmd = 'ncrcat -O '+OutDir+'/*.nc '+OutDir+'/viirs_aod_npp_'+validtime+'.nc'
  proc = sp.Popen(cmd,env=my_env,shell=True)
  proc.wait()  
  NowCycle = NowCycle + dt.timedelta(hours=CycleHrs)
