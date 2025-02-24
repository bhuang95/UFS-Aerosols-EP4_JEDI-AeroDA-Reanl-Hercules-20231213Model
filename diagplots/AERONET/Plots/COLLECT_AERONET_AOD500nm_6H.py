import sys,os,argparse
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
import netCDF4 as nc
import numpy as np
from ndate import ndate
#from datetime import datetime
#from datetime import timedelta


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Print AOD and its hofx in obs space and their difference'
        )
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '-c', '--cycle',
        help="Cycle in (YYYYMMDDTHH)",
        type=int, required=True)

    required.add_argument(
        '-a', '--aodtype',
        help="AOD type",
        type=str, required=True)

    required.add_argument(
        '-f', '--field',
        help="Input field",
        type=str, required=True)

    required.add_argument(
        '-i', '--indir',
        help="Input data directory",
        type=str, required=True)

    required.add_argument(
        '-o', '--outfile',
        help="Output file.",
        type=str, required=True)

    args = parser.parse_args()
    cycle = args.cycle
    indir = args.indir
    outfile = args.outfile
    aodtype = args.aodtype
    field = args.field

    chanind = 3

    gmeta = "MetaData"
    gobs = "ObsValue"
    ghfx = "hofx"
    geqc = "EffectiveQC"

    vlon = "longitude"
    vlat = "latitude"
    vobs = "aerosolOpticalDepth"
    vhfx = "aerosolOpticalDepth"
    veqc = "aerosolOpticalDepth"


    if field == 'cntlBkg':
        trcr = 'fv_tracer'
    if field == 'cntlAnl':
        trcr = 'fv_tracer_aeroanl'

    ncfile = f"{indir}/{aodtype}_obs_hofx_3dvar_LUTs_{trcr}_{cycle}.nc4"
    
    with nc.Dataset(ncfile, 'r') as ncdata:
        metagrp = ncdata.groups[gmeta]
        obsgrp = ncdata.groups[gobs]
        hfxgrp = ncdata.groups[ghfx]
        eqcgrp = ncdata.groups[geqc]

        lontmp = metagrp[vlon][:]
        lattmp = metagrp[vlat][:]
        obstmp = obsgrp[vobs][:,chanind]
        hfxtmp = hfxgrp[vhfx][:,chanind]
        eqctmp = eqcgrp[veqc][:,chanind]
       
        #fltind = np.where((eqctmp == 0) and (not np.isnan(obstmp)))
        fltind = np.where(eqctmp == 0)
        lon = lontmp[fltind]
        lat = lattmp[fltind]
        obs = obstmp[fltind]
        hfx = hfxtmp[fltind]
        outdata = np.stack((lon, lat, obs, hfx),axis=1)
        np.savetxt(outfile, outdata, fmt='%12.6f')
