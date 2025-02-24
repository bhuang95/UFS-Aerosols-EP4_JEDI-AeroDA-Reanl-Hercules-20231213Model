import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
import netCDF4 as nc
import numpy as np
from ndate import ndate
import os, argparse
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
        '-i', '--stcycle',
        help="Cycle date in (YYYYMMDDTHH)",
        type=int, required=True)

    required.add_argument(
        '-j', '--edcycle',
        help="Cycle date in (YYYYMMDDTHH)",
        type=int, required=True)

    required.add_argument(
        '-a', '--aeroda',
        help="AeroDA or not",
        type=str, required=True)

    required.add_argument(
        '-m', '--emean',
        help="Plot for ensemble mean or not",
        type=str, required=True)

    required.add_argument(
        '-e', '--expname',
        help="Name of experiment",
        type=str, required=True)

    required.add_argument(
        '-d', '--topdatadir',
        help="Upper-level directory of expname",
        type=str, required=True)

    required.add_argument(
        '-t', '--aodtype',
        help="AOD type",
        type=str, required=True)

    args = parser.parse_args()
    cycst = args.stcycle
    cyced = args.edcycle
    aeroda = (args.aeroda == "True" or args.aeroda == "true" or args.aeroda == "TRUE")
    emean = (args.emean == "True" or args.emean == "true" or args.emean == "TRUE")
    expname = args.expname
    datadir = args.topdatadir
    aod = args.aodtype

    inc_h = 6

    nancycs = [""]
    gmeta = "MetaData"
    gobs = "ObsValue"
    ghfx = "hofx"
    geqc = "EffectiveQC"

    vlon = "longitude"
    vlat = "latitude"
    vobs = "aerosolOpticalDepth"

    print(f"HBO-{aeroda}-{emean}")
 
    fields=['cntlBkg']

    if aeroda:
        fields.append('cntlAnl')

    if emean:
        fields.append('emeanBkg')

    if emean and aeroda:
        fields.append('emeanAnl')

    print(fields)
    for field in fields:

        if field in ['cntlBkg', 'emeanBkg']:
            trcr = 'fv_tracer'
        if field in ['cntlAnl', 'emeanAnl']:
            trcr = 'fv_tracer_aeroanl'

        if field in ['cntlBkg', 'cntlAnl']:
            enkfpre =  ""
            meanpre =  ""
        if field in ['emeanBkg', 'emeanAnl']:
            enkfpre =  "enkf"
            meanpre =  "ensmean"

        ncpre = f"{aod}_obs_hofx_3dvar_LUTs_{trcr}"
        outfile = f"{expname}_{field}_cyc_nloc_mobs_mhfx_mbias_mmse_{cycst}_{cyced}.txt"
        
        print(outfile)

        cyc = cycst
        print(f'{expname}-{field}-{enkfpre}-{meanpre}')
        while cyc <= cyced:
            if cyc not in nancycs:
                cymd=str(cyc)[:8]
                ch=str(cyc)[8:]
                ncfile = f"{datadir}/{expname}/dr-data-backup/{enkfpre}gdas.{cymd}/{ch}/diag/{meanpre}/{ncpre}_{cyc}.nc4"
                print(ncfile)
                with nc.Dataset(ncfile, 'r') as ncdata:
                    #metagrp = ncdata.groups[gmeta]
                    obsgrp = ncdata.groups[gobs]
                    hfxgrp = ncdata.groups[ghfx]
                    eqcgrp = ncdata.groups[geqc]
                    #lontmp = metagrp[vlon][:]
                    #lattmp = metagrp[vlat][:]
                    obs1 = obsgrp[vobs][:,0]
                    hfx1 = hfxgrp[vobs][:,0]
                    eqc = eqcgrp[vobs][:,0]
                    eqcind = np.where(eqc == 0)
                    obs = obs1[eqcind]
                    hfx = hfx1[eqcind]
                    
                    nloc = obs.size
                    bias = hfx - obs
                    bias2 = np.square(bias)
                    mobs = np.nanmean(obs) 
                    mhfx = np.nanmean(hfx) 
                    mbias = np.nanmean(bias) 
                    mmse = np.nanmean(bias2) 
            else:          
                nloc = np.nan
                mobs = np.nan
                mhfx = np.nan
                mbias = np.nan 
                mmse = np.nan

            outdata = [cyc, nloc, mobs, mhfx, mbias, mmse]
            outdata_str =  ' '.join(str(i) for i in outdata)
            
            if cyc == cycst:
                with open(outfile, 'w') as f:
                    f.write(f'{outdata_str}\n')
            else:
                with open(outfile, 'a+') as f:
                    f.write(f'{outdata_str}\n')
            cyc = ndate(cyc, inc_h)
