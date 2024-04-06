import sys,os
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
from mpl_toolkits.basemap import Basemap
import netCDF4 as nc
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mpcrs
import matplotlib.cm as cm
from ndate import ndate
import os, argparse
#from datetime import datetime
#from datetime import timedelta

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


def plot_map_satter_obsonly(lons, lats, obs, cmap, cyc):
    fig=plt.figure(figsize=[8,6])
    ax=fig.add_subplot(111)
    #ax.set_title('VIIRS AOD Obs. at %s' % (str(cyc)), fontsize=16)
    ax.set_title('VIIRS AOD 2018041412-2018041512',fontsize=16)
    map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
    map.drawcoastlines(color='black', linewidth=0.2)
    parallels = np.arange(-90.,90,45.)
    meridians = np.arange(-180,180,45.)
    map.drawparallels(parallels,labels=[True,False,False,False], linewidth=0.0)
    map.drawmeridians(meridians,labels=[False,False,False,True], linewidth=0.0)
    x,y=map(lons, lats)
    cs=map.scatter(lons,lats, s=1, c=obs, marker='.', cmap=cmap, vmin=0.0, vmax=1.0)
    cb=map.colorbar(cs,"right", size="2%", pad="2%")
    plt.savefig('AOD-2DMAP-%s.png' % (str(cyc)))
    return
    

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

def plot_scatter(obs, hofx, hofx1, cyc):
    fig=plt.figure(figsize=[11,5])
    ax=fig.add_subplot(121)
    ax.set_title('AOD Bckg. vs Obs.', fontsize=18)
    plt.scatter(obs, hofx, s=20, marker='.', color='blue')
    plt.xlim(0, 1.5)
    plt.ylim(0, 1.5)
    plt.plot([0.0, 1.5],[0.0, 1.5], color='red', linewidth=4, linestyle='--')
    plt.xlabel('AOD Obs', fontsize=16)
    plt.ylabel('AOD Bckg. HofX', fontsize=16)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

    ax=fig.add_subplot(122)
    ax.set_title('AOD Anal. vs Obs.', fontsize=18)
    plt.scatter(obs, hofx1, s=20, marker='.', color='blue')
    plt.xlim(0, 1.5)
    plt.ylim(0, 1.5)
    plt.plot([0.0, 1.5],[0.0, 1.5], color='red', linewidth=4, linestyle='--')
    plt.xlabel('AOD Obs', fontsize=16)
    plt.ylabel('AOD Anal. HofX', fontsize=16)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

    plt.savefig('AOD-scatter-%s.png' % (str(cyc)))
    return

def plot_hist(obs, hofx, hofx1, innov, innov1, cyc):
    fig = plt.figure(figsize=[14,8])
    ax=fig.add_subplot(231) 
    ax.set_title('AOD Obs', fontsize=20)
    plt.hist(obs, bins=21, range=[0, 1.5], facecolor='blue')
    plt.ticklabel_format(style='sci', axis='y', scilimits=(0,0))
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

    ax=fig.add_subplot(232) 
    ax.set_title('AOD Bckg. Hofx', fontsize=20)
    plt.hist(hofx, bins=21, range=[0, 1.5], facecolor='blue')
    plt.ticklabel_format(style='sci', axis='y', scilimits=(0,0))
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    ax=fig.add_subplot(233) 

    ax.set_title('AOD Bckg. Innov.', fontsize=20)
    plt.hist(innov, bins=21, range=[-1.5, 1.5], facecolor='blue')
    plt.ticklabel_format(style='sci', axis='y', scilimits=(0,0))
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

    ax=fig.add_subplot(234) 
    ax.set_title('AOD Obs', fontsize=20)
    plt.hist(obs, bins=21, range=[0, 1.5], facecolor='blue')
    plt.ticklabel_format(style='sci', axis='y', scilimits=(0,0))
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

    ax=fig.add_subplot(235) 
    ax.set_title('AOD Anal. Hofx', fontsize=20)
    plt.hist(hofx1, bins=21, range=[0, 1.5], facecolor='blue')
    plt.ticklabel_format(style='sci', axis='y', scilimits=(0,0))
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

    ax=fig.add_subplot(236) 
    ax.set_title('AOD Anal. Innov.', fontsize=20)
    plt.hist(innov1, bins=21, range=[-1.5, 1.5], facecolor='blue')
    plt.ticklabel_format(style='sci', axis='y', scilimits=(0,0))
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.savefig('AOD-hist-%s.png' % (str(cyc)))
    return


def concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, cyc, field):
    for itilem1 in range(ntiles):
        itile=itilem1
        filetmp='%s/aod_%s_hofx_3dvar_LUTs_%s_000%s.%s' % (filedir, aodtyp, cyc, str(itile), field)
        print(filetmp)
        nctmp=NetCDFFile(filetmp)
        if ioda == 1:
            varv=nctmp.variables[var][:]
        else:
            varg=nctmp.groups[g2]
            if g2 == 'hofx':
               varv=varg[v2][:,0]
            else:
               varv=varg[v2][:]
        if (itile == 0):
            varvarr=varv.flatten()
        else:
            varvarr=np.concatenate((varvarr, varv.flatten()), axis=0)
        nctmp.close()
    return varvarr


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Print AOD and its hofx in obs space and their difference'
        )
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '-c', '--cycle',
        help="Cycle date in (YYYYMMDDTHH)",
        type=int, required=True)

    required.add_argument(
        '-i', '--increment',
        help="Cycle increment in 6 or 24 hours",
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
        '-p', '--prefix',
        help="Prefix of the output figure names.",
        type=str, required=True)

    required.add_argument(
        '-t', '--topdatadir',
        help="Top directory of the (enkf)gdas.YYYYMMDDHH",
        type=str, required=True)

    args = parser.parse_args()
    cdate = args.cycle
    cinch = args.increment
    aeroda = (args.aeroda == "True" or args.aeroda == "true" or args.aeroda == "TRUE")
    emean = (args.emean == "True" or args.emean == "true" or args.emean == "TRUE")
    prefix = args.prefix
    datadir = args.topdatadir

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


    gmeta = "MetaData"
    gobs = "ObsValue"
    ghfx = "hofx"

    vlon = "longitude"
    vlat = "latitude"
    vobs = "aerosolOpticalDepth"
    vhfx = "aerosolOpticalDepth"

    print(f"HBO-{aeroda}-{emean}")
    print(emean)
    print(type(emean))
    if emean:
        enkfpre =  "enkf"
        meanpre =  "ensmean"
    else:
        enkfpre =  ""
        meanpre =  ""

    if aeroda:
        trcrs = ["fv_tracer", "fv_tracer_aeroanl"]
    else:
        trcrs = ["fv_tracer"]

    cycst = cdate
    cyced = ndate(cdate, cinch)

    if cinch == 6:
        cycpre = str(cdate)
    if cinch == 24:
        cycpre = str(cdate)[0:8]

    for trcr in trcrs:
        ncpre = f"NOAA_VIIRS_npp_obs_hofx_3dvar_LUTs_{trcr}"

        if trcr == "fv_tracer":
            if emean:
                titlepre = f"{prefix}-emeanBkg"
            else:
                titlepre = f"{prefix}-cntlBkg"

        if trcr == "fv_tracer_aeroanl":
            if emean:
                titlepre = f"{prefix}-emeanAnl"
            else:
                titlepre = f"{prefix}-cntlAnl"

        print(f"{enkfpre}-{meanpre}-{titlepre}")

        cyc = cycst
        print(cyc)
        print(cycst)
        print(cyced)
        while cyc < cyced:
            cymd=str(cyc)[:8]
            ch=str(cyc)[8:]
            ncfile = f"{datadir}/{enkfpre}gdas.{cymd}/{ch}/diag/aod_obs/{meanpre}/{ncpre}_{cyc}.nc4"
            print(ncfile)
            with nc.Dataset(ncfile, 'r') as ncdata:
                metagrp = ncdata.groups[gmeta]
                obsgrp = ncdata.groups[gobs]
                hfxgrp = ncdata.groups[ghfx]
                lontmp = metagrp[vlon][:]
                lattmp = metagrp[vlat][:]
                obstmp = obsgrp[vobs][:,0]
                hfxtmp = hfxgrp[vhfx][:,0]

                if cyc == cycst:
                    lon = lontmp
                    lat = lattmp
                    obs = obstmp
                    hfx = hfxtmp
                else:
                    lon = np.concatenate((lon, lontmp), axis=0)
                    lat = np.concatenate((lat, lattmp), axis=0)
                    obs = np.concatenate((obs, obstmp), axis=0)
                    hfx = np.concatenate((hfx, hfxtmp), axis=0)
            cyc = ndate(cyc, 6)

        hfx2obs = hfx - obs
        plot_map_satter_aod_hfx(lon, lat, obs, hfx, hfx2obs, cmap_aod, cmap_bias, titlepre, cycpre)

"""
scyc=2016062100
ecyc=2016062100
inc_h=6
inc_d=24

aodtyp='viirs'
ntiles=6

#cbarname='WhiteBlueGreenYellowRed-v1'
#clridx=np.trunc(np.linspace(0, 250, 250))
#clridx=clridx.astype(int)
#cmap=setup_cmap(cbarname,clridx)

#cbarmax2=100
#nbar2=40
#cbarname2='ViBlGrWhYeOrRe'
#clridx2=np.trunc(np.linspace(0, cbarmax2, nbar2+1))
#clridx2=clridx2.astype(int)
#clridx2[int(nbar2/2-1)]=clridx2[int(nbar2/2)]
#cmap2=setup_cmap(cbarname2,clridx2)

nbars=21
cbarname='WhiteBlueGreenYellowRed-v1'
mpl=0
white=-1
reverse=0
cmap=setup_cmap(cbarname,nbars,mpl,white,reverse)
cmap2=cmap


lcyc=scyc
while (lcyc <= ecyc):
    lcyc_st=lcyc
    lcyc_ed=ndate(lcyc,18)
    lcyc_day=str(lcyc)[:8]
    print(lcyc)
    if lcyc >= 2021071206:
        ioda = 2
    else:
        ioda = 1

    if (lcyc == 2016061000):
        lcyc=ndate(lcyc, inc_d)
        continue
    
    while (lcyc_st <= lcyc_ed):
        lymd=str(lcyc_st)[:8]
        lh=str(lcyc_st)[8:]
        
        filedir = '%s/gdas.%s/%s/obs/' % (datadir, lymd, lh)
        
        field='nc4.ges'

        var='longitude@MetaData'
        print(var)
        g2='MetaData'
        v2='longitude'
        lon=concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, str(lcyc_st), field)

        var='latitude@MetaData'
        print(var)
        g2='MetaData'
        v2='latitude'
        lat=concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, str(lcyc_st), field)

        var='aerosol_optical_depth_4@ObsValue'
        print(var)
        g2='ObsValue'
        v2='aerosol_optical_depth'
        obs=concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, str(lcyc_st), field)

        var='aerosol_optical_depth_4@hofx'
        print(var)
        g2='hofx'
        v2='aerosol_optical_depth'
        hofx_bckg=concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, str(lcyc_st), field)
        hofx_anal=hofx_bckg

        #field='nc4'
        #var='aerosol_optical_depth_4@hofx'
        #print(var)
        #g2='hofx'
        #v2='aerosol_optical_depth'
        #hofx_anal=concat_6tiles_aodhfx(ntiles, var, g2, v2, ioda, filedir, aodtyp, str(lcyc_st), field)

        if (lcyc_st == lcyc):
            lonarr=lon
            latarr=lat
            obsarr=obs
            hofxarr_bckg=hofx_bckg
            hofxarr_anal=hofx_anal
        else:
            lonarr=np.concatenate((lonarr, lon), axis=0)
            latarr=np.concatenate((latarr, lat), axis=0)
            obsarr=np.concatenate((obsarr, obs), axis=0)
            hofxarr_bckg=np.concatenate((hofxarr_bckg, hofx_bckg), axis=0)
            hofxarr_anal=np.concatenate((hofxarr_anal, hofx_anal), axis=0)
        lcyc_st=ndate(lcyc_st, inc_h)
    

    innovarr=hofxarr_anal-hofxarr_bckg
    #plot_map_satter(lonarr, latarr, np.clip(obsarr,0,1.1), np.clip(hofxarr_bckg,0,1.1), np.clip(hofxarr_anal,0,1.1), np.clip(innovarr,-0.3,0.3),cmap,cmap2, lcyc_day)
    plot_map_satter(lonarr, latarr, obsarr, hofxarr_bckg, hofxarr_anal, innovarr, cmap, cmap2, lcyc_day)
    lcyc=ndate(lcyc, inc_d)







#fig = plt.figure(figsize=[16,12])
#nrows=3
#ncols=2
#
#pname='%s-2D-timeMean.png' %(fcstvar)
#ax=fig.add_subplot(nrows, ncols, iplot)
#ax.set_title(tname)
#map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
#map.drawcoastlines(color='grey', linewidth=0.2)
#lons,lats = np.meshgrid(lon,lat)
#lons, pdata = map.shiftdata(lons, datain = pdata, lon_0=0)
#x,y = map(lons,lats)
#clridx=np.trunc(np.linspace(0, cbarmax, n+1))
#clridx=clridx.astype(int)
#if irow == 1:
#    clridx[int(n/2-1)]=clridx[int(n/2)]
#cmap=setup_cmap(cbarname,clridx)
#levels = np.linspace(vmin, vmax, n+1)
#norm = mpcrs.BoundaryNorm(levels,len(levels))
#cs=map.contourf(x,y,pdata,levels,cmap=cmap,norm=norm,extend=cbarextend)
#cb=map.colorbar(cs,"right", size="2%", pad="2%")
##cb.set_label(cbarlab)
#
#plt.savefig(pname)
"""
