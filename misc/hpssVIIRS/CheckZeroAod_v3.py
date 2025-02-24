import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
import netCDF4 as nc
import numpy as np
from ndate import ndate
import os, argparse
#from datetime import datetime
#from datetime import timedelta
#os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
#import matplotlib
#import matplotlib.pyplot as plt
#import matplotlib.colors as mpcrs
#import matplotlib.cm as cm
#from mpl_toolkits.basemap import Basemap


gmeta = "MetaData"
gobs = "ObsValue"
ghfx = "hofx"
gerr = "ObsError"
geqc = "PreQc"

vlon = "longitude"
vlat = "latitude"
vobs = "aerosolOpticalDepth"

ncfile="NOAA_VIIRS_AOD_npp.2020070106.iodav3.nc"

with nc.Dataset(ncfile, 'r') as ncdata:
    metagrp = ncdata.groups[gmeta]
    obsgrp = ncdata.groups[gobs]
    errgrp = ncdata.groups[gerr]
    eqcgrp = ncdata.groups[geqc]
    lon = metagrp[vlon][:]
    lat = metagrp[vlat][:]
    obs = obsgrp[vobs][:,0]
    err = errgrp[vobs][:,0]
    eqc = eqcgrp[vobs][:,0]

errind = np.where(err == 0)
obsind = np.where(obs < 0)

print('ErrInd')
print(errind)
print('ObsInd')
print(obsind)
print('Err')
print(err[errind])
print('Obs')
print(obs[obsind])
print('PreQC')
print(eqc[errind])

