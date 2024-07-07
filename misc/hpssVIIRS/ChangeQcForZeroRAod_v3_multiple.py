#/work/noaa/wrf-chem/bhuang/expCodes-Hercules/JEDI/V20240115/V20240115/build/jedi***.sh
#ncks file1 to file2
import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
import netCDF4 as nc
import numpy as np
#from ndate import ndate
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
geqc_new = "PreQC"
geqc_orig = "PreQcOrig"

vlon = "longitude"
vlat = "latitude"
vobs = "aerosolOpticalDepth"

cdate="2019031000"
ncfile=f"NOAA_VIIRS_AOD_npp.{cdate}.iodav3.nc"
outfile=f"RecordZeroR.{cdate}.record"

with nc.Dataset(ncfile, 'r+') as ncdata:

    metagrp = ncdata.groups[gmeta]
    obsgrp = ncdata.groups[gobs]
    errgrp = ncdata.groups[gerr]
    eqcgrp = ncdata.groups[geqc]
    lon = metagrp[vlon][:]
    lat = metagrp[vlat][:]
    obs = obsgrp[vobs][:,0]
    err = errgrp[vobs][:,0]
    eqc = eqcgrp[vobs][:,0]


    errind = np.where(err == 0.0)

    with open(outfile, 'w') as f:
        for line in errind[0][:]:
            f.write(f"{line}\n")

    nobsind = np.where(obs < 0.0)
    #ncdata.renameGroup(geqc, geqc_orig)

    #ncdata.createGroup(geqc_new)
    #ncdata.createVariable("PreQC/aerosolOpticalDepth", "int32", ("Location", "Channel",))
    
    #ncdata.groups[geqc_new]["aerosolOpticalDepth"][:] = np.asarray(ncdata.groups[geqc_orig][vobs][:], dtype="int32")  
    #int(ncdata.groups["PreQcOrig"][vobs][:])  #np.where(ncdata.groups[gerr][vobs] == 0.0, 1000, ncdata.groups["PreQcOrig"][vobs])
    #ncdata.groups[geqc_new][vobs][errind] = int(1000)
    #ncdata.groups[geqc_new][vobs].setncattr("_Fill_Value", int(-999))   #set_fill_on(int(-999)) #['_FillValue'] = int(-999)
    ncdata.groups[gerr][vobs][errind] = 0.05

    print(errind)
    print("ZeroError")
    print(err[errind])
    #print("OrigQC")
    #print(ncdata.groups[geqc_orig][vobs][errind])
    print("UpdatedError")
    print(ncdata.groups[gerr][vobs][errind])
    #print("UpdatedQC")
    #print(ncdata.groups[geqc_new][vobs][errind])


    exit()
