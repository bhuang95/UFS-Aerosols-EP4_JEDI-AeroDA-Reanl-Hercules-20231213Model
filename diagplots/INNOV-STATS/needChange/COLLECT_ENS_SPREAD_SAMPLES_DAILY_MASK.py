import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
import netCDF4 as nc
import numpy as np
from ndate import ndate
import os, argparse
#from datetime import datetime
#from datetime import timedelta

def nc_file_dir(aod, field, datadir):
    if 'Bkg' in field:
        trcr = 'fv_tracer'
    elif 'Anl' in field:
        trcr = 'fv_tracer_aeroanl'
    else:
        print('field has to contain Bkg or Anl. Exit now.')
        exit(100)

    if 'cntl' in field:
        enkfpre =  ""
        mempre =  ""
        loopens = False
    elif 'emean' in field:
        enkfpre =  "enkf"
        mempre =  "ensmean"
        loopens = False
    elif 'emem' in field: 
        enkfpre =  "enkf"
        mempre =  "mem"
        loopens = True
    else: 
        print('field has to contain cntl, emean or emem. Exit now.')
        exit(100)

    ncpre = f"{datadir}/{enkfpre}gdas."
    ncmid = f"/diag/aod_obs/{mempre}"
    ncsuf = f"/{aod}_obs_hofx_3dvar_LUTs_{trcr}_"
    return ncpre, ncmid, ncsuf

def clec_ens_var_daily(nmem, day, outappend, ncpre, ncmid,ncsuf, outpre, missing):

    if missing:
        outdata = [str(day)[0:8], np.nan, np.nan, np.nan, np.nan]
        outdata_str =  ' '.join(str(i) for i in outdata)
        for mask in masks:
            outfile = f"{outpre}{mask}.txt"
        
            if outappend:
                with open(outfile, 'a+') as fout:
                    fout.write(f'{outdata_str}\n')
            else:
                with open(outfile, 'w') as fout:
                    fout.write(f'{outdata_str}\n')
        return

    gmeta = "MetaData"
    gobs = "ObsValue"
    ghfx = "hofx"
    gerr = "ObsError"
    geqc = "EffectiveQC"

    vlon = "longitude"
    vlat = "latitude"
    vobs = "aerosolOpticalDepth"

    cycst = day
    cyced = ndate(cycst, 18)
    cyc = cycst

    while cyc <= cyced:
        cymd=str(cyc)[:8]
        ch=str(cyc)[8:]

        for imem in range(1, nmem+1):
            memstr=str(imem).zfill(3)
            ncfile = f"{ncpre}{cymd}/{ch}/{ncmid}{memstr}/{ncsuf}{cyc}.nc4"
            print(ncfile)
       	     
            with nc.Dataset(ncfile, 'r') as ncdata:
                metagrp = ncdata.groups[gmeta]
                obsgrp = ncdata.groups[gobs]
                hfxgrp = ncdata.groups[ghfx]
                errgrp = ncdata.groups[gerr]
                eqcgrp = ncdata.groups[geqc]
                lon1 = metagrp[vlon][:]
                lat1 = metagrp[vlat][:]
                obs1 = obsgrp[vobs][:,0]
                hfx1 = hfxgrp[vobs][:,0]
                err1 = errgrp[vobs][:,0]
                eqc = eqcgrp[vobs][:,0]
            eqcind = np.where(eqc == 0)
            
            nsize = obs1[eqcind].size
            if imem == 1:
                lon = lon1[eqcind]
                lat = lat1[eqcind]
                obs = obs1[eqcind]
                err = err1[eqcind]
                hfx = hfx1[eqcind].reshape(nsize,1)
            else:
                hfx = np.concatenate((hfx, hfx1[eqcind].reshape(nsize,1)), axis=1)

        if cyc == cycst:
            lonarr = lon
            latarr = lat
            obsarr = obs
            errarr = err
            hfxarr = hfx
        else:
            lonarr = np.concatenate((lonarr, lon))
            latarr = np.concatenate((latarr, lat))
            obsarr = np.concatenate((obsarr, obs))
            errarr = np.concatenate((errarr, err))
            hfxarr = np.concatenate((hfxarr, hfx), axis=0)
        cyc = ndate(cyc, 6)

    for mask in masks:
        outfile = f"{outpre}{mask}.txt"
        if mask == 'GLOBAL':
            mslon = lonarr
            mslat = latarr
            msobs = obsarr
            mserr = errarr
            mshfx = hfxarr
        else: 
            msfile = f"masks/{mask}.mask"
            #msarr=[]
            #with open(msfile) as msf:
            #    for line in msf.readlines():
            #        msarr.append(float(line))
            msarr=np.loadtxt(msfile)
            minlat, maxlat, minlon, maxlon, clon180 = msarr[:]

            if clon180 == 1.0:
                lonind = np.where(((lonarr <= minlon) & (lonarr >= -180)) | ((lonarr >= maxlon) & (lonarr <= 180)))
            else:
                lonind = np.where((lonarr >= minlon) & (lonarr <= maxlon))

            latind = np.where((latarr >= minlat) & (latarr <= maxlat))
            llind = np.intersect1d(latind, lonind)

            mslon = lonarr[llind]
            mslat = latarr[llind]
            msobs = obsarr[llind]
            mserr = errarr[llind]
            mshfx = hfxarr[llind, :]

        titlepre=f"{day}-{mask}"
        cycpre=f"{day}-{mask}"
        #plot_map_satter_aod_hfx(mslon, mslat, msobs, mshfx, mshfx-msobs, cmap_aod, cmap_bias, titlepre, cycpre)	

        nloc = msobs.size
        if nloc > 0:
            #msbias = mshfx - msobs
            mserr2 = np.square(mserr)
            msvar = np.var(mshfx, axis=1, ddof=1)
            mmobs = np.nanmean(msobs)
            mmerr2 = np.nanmean(mserr2)
            mmvar = np.nanmean(msvar) 
            mmvartot = np.nanmean(msvar + mserr2)
        else:
            print(f'No data avaialble at {mask} and {day}')
            mmerr2 = np.nan
            mmvar = np.nan 
            mmvartot = np.nan

        outdata = [str(day)[0:8], nloc,  mmerr2, mmvar, mmvartot]
        outdata_str =  ' '.join(str(i) for i in outdata)
    
        if outappend:
            with open(outfile, 'a+') as fout:
                fout.write(f'{outdata_str}\n')
        else:
            with open(outfile, 'w') as fout:
                fout.write(f'{outdata_str}\n')
    return

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Print AOD and its hofx in obs space and their difference'
        )
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '-i', '--stday',
        help="Cycle date in (YYYYMMDD00)",
        type=int, required=True)

    required.add_argument(
        '-j', '--edday',
        help="Cycle date in (YYYYMMDD00)",
        type=int, required=True)

    required.add_argument(
        '-e', '--expname',
        help="Name of experiment",
        type=str, required=True)

    required.add_argument(
        '-d', '--toprundir',
        help="Upper-level directory of expname",
        type=str, required=True)

    required.add_argument(
        '-a', '--aodtype',
        help="AOD type",
        type=str, required=True)

    args = parser.parse_args()
    dayst = args.stday
    dayed = args.edday
    expname = args.expname
    rundir = args.toprundir
    aod = args.aodtype
    datadir = f"{rundir}/{expname}/dr-data-backup/"


    nandayss = [""]

    fields=['ememBkg']
    masks=['GLOBAL', 'NAFRME', 'CONUS', 'EASIA', 'SAFRTROP', 'RUSC2S', 'NATL', 'NPAC', 'SATL', 'SPAC', 'INDOCE']
    nmem = 20

    print(fields)
    for field in fields:
        ncpre, ncmid, ncsuf = nc_file_dir(aod, field, datadir)
        day = dayst
        while day <= dayed:
            if day == dayst:
                outappend = False
            else:
                outappend = True

            outpre = f"./output/{expname}_{field}_day_nloc_merr2_mvar_mvartot_{dayst}_{dayed}_"
            if day not in nandayss:
                #coll_stats_1day(day, outappend, ncpre, ncsuf, outpre) 
                clec_ens_var_daily(nmem, day, outappend, ncpre, ncmid,ncsuf, outpre, False)
                #coll_stats_1day(day, outappend, ncpre, ncsuf, outpre, cmap_aod, cmap_bias) 
            else:          
                clec_ens_var_daily(nmem, day, outappend, ncpre, ncmid,ncsuf, outpre, True)
            day = ndate(day, 24)
