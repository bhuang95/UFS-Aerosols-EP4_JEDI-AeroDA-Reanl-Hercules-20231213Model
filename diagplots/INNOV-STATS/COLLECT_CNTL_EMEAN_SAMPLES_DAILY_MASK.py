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

def setup_cmap(name,nbar,mpl,whilte,reverse):
    nclcmap='/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg/pyscripts/colormaps/'
    cmapname=name
    f=open(nclcmap+'/'+cmapname+'.rgb','r')
    a=[]
    for line in f.readlines():
        if ('ncolors' in line):
            clnum=int(line.split('=')[1])
        a.append(line)
    f.close()
    b=a[-clnum:]
    c=[]

    selidx=np.trunc(np.linspace(0, clnum-1, nbar))
    selidx=selidx.astype(int)

    for i in selidx[:]:
        if mpl==1:
            c.append(tuple(float(y) for y in b[i].split()))
        else:
            c.append(tuple(float(y)/255. for y in b[i].split()))

    
    if reverse==1:
        ctmp=c
        c=ctmp[::-1]
    if white==-1:
        c[0]=[1.0, 1.0, 1.0]
    if white==1:
        c[-1]=[1.0, 1.0, 1.0]
    elif white==0:
        c[int(nbar/2-1)]=[1.0, 1.0, 1.0]
        c[int(nbar/2)]=c[int(nbar/2-1)]

    d=mpcrs.LinearSegmentedColormap.from_list(name,c,selidx.size)
    return d

def plot_map_satter_aod_hfx(lons, lats, obs, hfx, hfx2obs, cmap_aod, cmap_bias, titlepre, cycpre):
    vvend1='max'
    ccmap1=cmap_aod
    bounds=[0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.0]
    norm1=mpcrs.BoundaryNorm(bounds, ccmap1.N)

    vvend2='both'
    ccmap2=cmap_bias
    boundpos1=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    boundpos=[x*0.04 for x in boundpos1]
    boundneg=[-x for x in boundpos]
    boundneg=boundneg[::-1]
    boundneg.append(0.00)
    bounds=boundneg + boundpos
    norm2=mpcrs.BoundaryNorm(bounds, ccmap2.N)
    
    fig=plt.figure(figsize=[6, 8])
    for ipt in range(3):
        ax=fig.add_subplot(3,1,ipt+1)
        if ipt==0:
            data=obs
            tstr=f"(a) VIIRS/S-NPP 550 nm AOD at {cycpre}"
            vvend=vvend1
            cmap=ccmap1
            norm=norm1
        elif ipt==1:
            data=hfx
            #tstr='(b) Diff. of RET-NODA 6-hour fcst' 
            tstr=f"(b) {titlepre} [hfx] at {cycpre}"
            vvend=vvend1
            cmap=ccmap1
            norm=norm1
        elif ipt==2:
            data=hfx2obs
            tstr=f"(c) {titlepre} [hfx - obs] at {cycpre}"
            vvend=vvend2
            cmap=ccmap2
            norm=norm2

        font1=12
        font2=10
        font3=10
        
        if ipt==100:
            ax.set_axis_off()
        else:
            #map=Basemap(projection='cyl',llcrnrlat=-45,urcrnrlat=45,llcrnrlon=-45,urcrnrlon=45,resolution='c')
            #parallels = np.arange(-45.,45,45.)
            #meridians = np.arange(-45,45,45.)
            map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
            parallels = np.arange(-90.,90,45.)
            meridians = np.arange(-180,180,90.)
            map.drawcoastlines(color='black', linewidth=0.2)
            map.drawparallels(parallels,labels=[True,False,False,False],linewidth=0.2, fontsize=font2, color='grey', dashes=(None,None))
            map.drawmeridians(meridians,labels=[False,False,False,True],linewidth=0.2, fontsize=font2, color='grey', dashes=(None,None))
            x,y=map(lons, lats)
            cs=map.scatter(lons,lats, s=1, c=data, marker='.', cmap=cmap, norm=norm)
            cb=map.colorbar(cs,"right", size=0.1, pad=0.02, extend=vvend)
            cb.ax.tick_params(labelsize=font2)
            ellblack = matplotlib.patches.Ellipse(xy=map(10,22), width=56, height=23, color='black',linewidth=3,fill=False)
            ellred = matplotlib.patches.Ellipse(xy=map(17,-2), width=23, height=15, color='red',linewidth=3,fill=False)
            ellblue = matplotlib.patches.Ellipse(xy=map(-25,10), width=27, height=21, color='blue',linewidth=3,fill=False)
            #ax.add_patch(ellblack)
            #ax.add_patch(ellred)
            #ax.add_patch(ellblue)
        #ax.autoscale()
        
            ax.set_title(tstr, fontsize=font1)
        #if ipt==2:     
        #    fig.subplots_adjust(bottom=0.04)
        #    cbar_ax = fig.add_axes([0.06, 0.04, 0.4, 0.02])
        #    cb=fig.colorbar(cs, cax=cbar_ax, orientation='horizontal', ticks=bounds[::3], extend=vvend)
        #    cb.ax.tick_params(labelsize=font2)


    #fig.tight_layout(rect=[0.0, 0.05, 1.0, 1.0])
    #fig.tight_layout(rect=[0.0, 0.04, 1.0, 1.0])
    fig.tight_layout()
    pname = f"{titlepre}-{cycpre}.png"
    plt.savefig(pname, format='png')
    plt.close(fig)
    return

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

#def coll_stats_1day (day, outappend, ncpre, ncsuf, outpre, cmap_aod, cmap_bias): 
def clec_stats_1day(day, outappend, ncpre, ncmid, ncsuf, outpre, missing): 

    if missing:
        outdata = [str(day)[0:8], np.nan, np.nan, np.nan, np.nan, np.nan, np.nan]
        outdata_str =  ' '.join(str(i) for i in outdata)
        for mask in masks:
            outfile = f"{outpre}{mask}.txt"
            if not outappend:
                with open(outfile, 'w') as fout:
                    fout.write(f'{outdata_str}\n')
            else:
                with open(outfile, 'a') as fout:
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

        ncfile = f"{ncpre}{cymd}/{ch}/{ncmid}{ncsuf}{cyc}.nc4"
	     
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

        if cyc == cycst:
            lon = lon1[eqcind]
            lat = lat1[eqcind]
            obs = obs1[eqcind]
            hfx = hfx1[eqcind]
            err = err1[eqcind]
        else:
            lon = np.concatenate((lon, lon1[eqcind]))
            lat = np.concatenate((lat, lat1[eqcind]))
            obs = np.concatenate((obs, obs1[eqcind]))
            hfx = np.concatenate((hfx, hfx1[eqcind]))
            err = np.concatenate((err, err1[eqcind]))
        cyc = ndate(cyc, 6)

    for mask in masks:
        outfile = f"{outpre}{mask}.txt"
        if mask == 'GLOBAL':
            mslon = lon
            mslat = lat
            msobs = obs
            mshfx = hfx
            mserr = err
        else: 
            msfile = f"masks/{mask}.mask"
            #msarr=[]
            #with open(msfile) as msf:
            #    for line in msf.readlines():
            #        msarr.append(float(line))
            msarr=np.loadtxt(msfile)
            minlat, maxlat, minlon, maxlon, clon180 = msarr[:]

            if clon180 == 1.0:
                lonind = np.where(((lon <= minlon) & (lon >= -180)) | ((lon >= maxlon) & (lon <= 180)))
            else:
                lonind = np.where((lon >= minlon) & (lon <= maxlon))

            latind = np.where((lat >= minlat) & (lat <= maxlat))
            llind = np.intersect1d(latind, lonind)

            mslon = lon[llind]
            mslat = lat[llind]
            msobs = obs[llind]
            mshfx = hfx[llind]
            mserr = err[llind]

        titlepre=f"{day}-{mask}"
        cycpre=f"{day}-{mask}"
        #plot_map_satter_aod_hfx(mslon, mslat, msobs, mshfx, mshfx-msobs, cmap_aod, cmap_bias, titlepre, cycpre)	

        nloc = msobs.size
        if nloc > 0:
            msbias = mshfx - msobs
            msbias2 = np.square(msbias)
            mserr2 = np.square(mserr)
            mmobs = np.nanmean(msobs) 
            mmhfx = np.nanmean(mshfx) 
            mmbias = np.nanmean(msbias) 
            mmmse = np.nanmean(msbias2) 
            mmerr2 = np.nanmean(mserr2) 
        else:
            print(f'No data avaialble at {mask} and {day}')
            mmobs = np.nan
            mmhfx = np.nan
            mmerr2 = np.nan
            mmbias = np.nan 
            mmmse = np.nan

        outdata = [str(day)[0:8], nloc, mmobs, mmhfx, mmerr2, mmbias, mmmse]
        outdata_str =  ' '.join(str(i) for i in outdata)
    
        if not outappend:
            with open(outfile, 'w') as fout:
                fout.write(f'{outdata_str}\n')
        else:
            with open(outfile, 'a') as fout:
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
        '-e', '--daexp',
        help="Name of DA experiment",
        type=str, required=True)

    required.add_argument(
        '-f', '--nodaexp',
        help="Name of NODA experiment",
        type=str, required=True)

    required.add_argument(
        '-d', '--toprundir',
        help="Upper-level directory of expname",
        type=str, required=True)

    required.add_argument(
        '-a', '--aodtype',
        help="AOD type",
        type=str, required=True)

    """
    nbars=21
    cbarname='WhiteBlueGreenYellowRed-v1'
    mpl=0
    white=-1
    reverse=0
    cmap_aod=setup_cmap(cbarname,nbars,mpl,white,reverse)

    lcol_bias=[[115,  25, 140], [  50, 40, 105], [  0,  18, 120], [   0,  35, 160], \
               [  0,  30, 210], [  5,  60, 210], [  4,  78, 150], \
               [  5, 112, 105], [  7, 145,  60], [ 24, 184,  31], \
               [ 74, 199,  79], [123, 214, 127], [173, 230, 175], \
               [222, 245, 223], [255, 255, 255], [255, 255, 255], \
               [255, 255, 255], [255, 255, 210], [255, 255, 150], \
               [255, 255,   0], [255, 220,   0], [255, 200,   0], \
               [255, 180,   0], [255, 160,   0], [255, 140,   0], \
               [255, 120,   0], [255,  90,   0], [255,  60,   0], \
               [235,  55,   35], [190,  40, 25], [175,  35,  25], [116,  20,  12]]
    acol_bias=np.array(lcol_bias)/255.0
    tcol_bias=tuple(map(tuple, acol_bias))
    cmapbias_name='aod_bias_list'
    cmapbias=mpcrs.LinearSegmentedColormap.from_list(cmapbias_name, tcol_bias, N=32)
    cmap_bias=cmapbias
    """    

    args = parser.parse_args()
    dayst = args.stday
    dayed = args.edday
    daexp = args.daexp
    nodaexp = args.nodaexp
    rundir = args.toprundir
    aod = args.aodtype

    inc_h=24

    nandayss = [""]

    fields=['cntlBkg', 'cntlAnl', 'emeanBkg', 'emeanAnl']
    masks=['GLOBAL', 'NAFRME', 'CONUS', 'EASIA', 'SAFRTROP', 'RUSC2S', 'NATL', 'NPAC', 'SATL', 'SPAC', 'INDOCE']

    print(fields)
    for expname in [daexp, nodaexp]:
        if expname == nodaexp:
            fields=['cntlBkg']
        elif expname == daexp:
            fields=['cntlBkg', 'cntlAnl', 'emeanBkg', 'emeanAnl']
        else:
            print('expname not properly defined and exit now')
            exit(100)

        datadir = f"{rundir}/{expname}/dr-data-backup/"

        for field in fields:
            ncpre, ncmid, ncsuf = nc_file_dir(aod, field, datadir)
            day = dayst
            while day <= dayed:
                if day == dayst:
                    outappend = False
                else:
                    outappend = True

                outpre = f"./output/{expname}_{field}_day_nloc_mobs_mhfx_merr2_mbias_mmse_{dayst}_{dayed}_"
                if day not in nandayss:
                    clec_stats_1day(day, outappend, ncpre, ncmid, ncsuf, outpre, False) 
                    #coll_stats_1day(day, outappend, ncpre, ncsuf, outpre, cmap_aod, cmap_bias) 
                else:          
                    clec_stats_1day(day, outappend, ncpre, ncmid, ncsuf, outpre, True) 

                day = ndate(day, inc_h)
