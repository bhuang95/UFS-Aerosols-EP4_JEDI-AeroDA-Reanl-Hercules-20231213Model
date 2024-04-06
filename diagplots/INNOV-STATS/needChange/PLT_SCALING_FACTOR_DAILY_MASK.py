import sys,os, argparse
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
from mpl_toolkits.basemap import Basemap
#from netCDF4 import Dataset as NetCDFFile
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mpcrs
import matplotlib.cm as cm
from matplotlib.patches import Polygon
from matplotlib.collections import PatchCollection
#import matplotlib.cm as cm
#from ndate import ndate
#from datetime import datetime
#from datetime import timedelta

def get_spinupcyc_num(inpre, mask, ind, spinupcyc):
    infile = f"{inpre}{mask}.txt"
    data1d = []
    with open(infile, 'r') as fin:
        for line in fin.readlines():
            data = float(line.split()[ind])
            data1d.append(data)
    return data1d.index(float(spinupcyc))

def coll_samples(inpre, masks, ind):
    data2d = []
    for mask in masks:
        infile = f"{inpre}{mask}.txt"
        data1d = []
        with open(infile, 'r') as fin:
            for line in fin.readlines():
                data = float(line.split()[ind])
                data1d.append(data)
        data2d.append([data1d])

    return np.squeeze(np.array(data2d))

def setup_cmap(name,selidx):
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
    for i in selidx[:]:
        c.append(tuple(float(y)/255. for y in b[i].split()))

    d=mpcrs.LinearSegmentedColormap.from_list(name,c,selidx.size)
    return d

def plot_scatter(rmse, spread, expleg, nmasks, cols):
    fig=plt.figure(figsize=[6,6])
    ax=fig.add_subplot(111)
    ax.set_title('%s EnsMean AOD Spread vs RMSE' % (expleg), fontsize=14)
    for iplt in range(nmasks):
        plt.scatter(spread[8:,iplt], rmse[8:,iplt], s=20, marker='o', color=cols[iplt])
    m, b=np.polyfit(spread[8:,:].flatten(), rmse[8:,:].flatten(), 1)
    print('HBO1')
    print(expleg)
    print(m)
    print(b)
    afit=np.array([0.0, 0.5])
    print(afit)
    plt.plot(afit, m*afit+b, color='gray', linewidth=2, linestyle='--')
    lm=print("%.4f" % m)
    lb=print( "%.4f" % b)
    fitfun='Y = %s X + %s' % (str("%.4f" % m), str("%.4f" % b))
    plt.xlim(0, 0.5)
    plt.ylim(0, 0.5)
    plt.plot([0.0, 0.5],[0.0, 0.5], color='black', linewidth=2, linestyle='--')
    print(fitfun)
    #plt.grid(alpha=0.5)
    plt.text(0.2, 0.02, fitfun, fontsize=16)
    plt.xlabel('Spread', fontsize=16)
    plt.ylabel('RMSE', fontsize=16)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.savefig('%s-scatter.png' % (expleg), format='png')
    return

#plot_all(masks, mhfx[:,0], mobs[:,0], mhfx[:,1],rmse[:,0],spread[:,0], rmse[:,1],spread[:,1],aodtyp,masks1,color1,latmin,latmax,latmid,lonmax,lonmin,lonmid)
#def plot_all(masks, mhfx, mobs, mhfx1, rmse, spread, rmse1, spread1, aodtyp,
#             masks1, color1, latmin, latmax, latmid, lonmax, lonmin, lonmid):
def plot_all(ptitle, masks, mobs, mhfx_bkg, mhfx_anl, aodtyp,
             masks1, color1, latmin, latmax, latmid, lonmax, lonmin, lonmid):
    x=np.arange(len(masks))
    fig=plt.figure(figsize=(8,10))

    ax=fig.add_subplot(211)
    #ax.set_title('VIIRS AOD 2018041412-2018041512',fontsize=16)
    map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
    map.drawcoastlines(color='black', linewidth=0.2)
    parallels = np.arange(-90.,90,45.)
    meridians = np.arange(-180,180,45.)
    map.drawparallels(parallels,labels=[True,False,False,False], linewidth=0.0, fontsize=13)
    map.drawmeridians(meridians,labels=[False,False,False,True], linewidth=0.0, fontsize=13)
    #x,y=map(lons, lats)
    #cs=map.scatter(lons,lats, s=1, c=obs, marker='.', cmap=cmap, vmin=0.0, vmax=1.0)
    #cb=map.colorbar(cs,"right", size="2%", pad="2%")

    patches=[]
    pcolors=[]
    nmask=len(masks1)
    for imask in range(nmask):
        fcolor=fcolors[imask]
        if loncross[imask] == 1:
            ll=[lonmin[imask], latmin[imask]]
            lm1=[-179.99,          latmin[imask]]
            lm2=[-179.99,          latmax[imask]]
            lm3=[lonmin[imask], latmax[imask]]
            lm4=ll
    
            ur=[lonmax[imask], latmax[imask]]
            um1=[179.99,           latmax[imask]]
            um2=[179.99,           latmin[imask]]
            um3=[lonmax[imask], latmin[imask]]
            um4=ur
            zone1=np.array([lm1, lm2, lm3, ll, lm1])
            zone2=np.array([um2, um3, ur, um1, um2])
            pg1=Polygon(zone1)
            pg2=Polygon(zone2)
            patches.append(pg1)
            patches.append(pg2)
            pcolors.append(fcolor)
            pcolors.append(fcolor)
        else: 
            ll=[lonmin[imask], latmin[imask]]
            lr=[lonmax[imask], latmin[imask]]
            ur=[lonmax[imask], latmax[imask]]
            ul=[lonmin[imask], latmax[imask]]
            zone=np.array([ll, lr, ur, ul])
            pg=Polygon(zone)
            patches.append(pg)
            pcolors.append(fcolor)

    conus_zone=np.loadtxt('/contrib/met/9.1/share/met/poly/CONUS.poly', unpack=True, skiprows=1)
    conus_zone_arr=np.flip(np.array(conus_zone).transpose(), axis=1)
    pg=Polygon(conus_zone_arr)
    patches.append(pg)
    pcolors.append('red')
    ax.set_title('(a) Domain splitting', fontsize=16)

    ax.add_collection(PatchCollection(patches, facecolor=pcolors, edgecolor='k', linewidths=0.5, alpha=0.8))
    
    for imask in range(nmask):
        print(imask,nmask)
        if masks1[imask] == 'TROP':
            lonmid[imask]=-50
    
        if masks1[imask] == 'SOCEAN':
            lonmid[imask]=135
    
        if loncross[imask] == 1:
            #lonabs1=abs(180-lonmin[imask])
            #lonabs2=abs(180-lonmax[imask])
            #if lonabs1 > lonabs2:
            #    tlon=-170
            #else:
            #    tlon=170
            tlon1=0.5*(-180+lonmin[imask])
            tlon2=0.5*(180+lonmax[imask])
            ax.annotate(masks1[imask], (tlon1, latmid[imask]), ha='center', va='center')
            ax.annotate(masks1[imask], (tlon2, latmid[imask]), ha='center', va='center')
        else:
            ax.annotate(masks1[imask], (lonmid[imask], latmid[imask]), ha='center', va='center')
    
    ax.annotate('CONUS', (-100, 35), ha='center', va='center')

    #plt.xlabel('Longitude', labelpad=40, fontsize=8)
    #plt.ylabel('Latitude', labelpad=40, fontsize=8)

    ax=fig.add_subplot(212)
    width=0.2
    #ax1=fig.add_axes([0.1, 0.2, 0.8, 0.8])
    #print(data1.shape)
    #print(data1)
    rs1=ax.bar(x-1*width,mhfx_bkg,width, label='HFX-Bkg', color='green')
    rs2=ax.bar(x+0*width,mobs,width, label='VIIRS', color='red')
    rs1=ax.bar(x+1*width,mhfx_anl,width, label='HFX-Anl', color='blue')
    #rs3=ax.bar(x+1*width,mhfx1,width, label='AOD hofx with SPE', color='blue')
    ax.set_ylabel('AOD', fontsize=14)
    ax.set_title('(b) VIIRS vs HOFX AOD', fontsize=16)
    ax.set_xticks(x)
    ax.set_xticklabels(masks, fontsize=14,rotation=-45)
    ax.plot([0.5, 0.5], [0, 0.5], "k--")
    ax.annotate('Dust', (1.0, 0.45), ha='center', va='center', fontsize=16)
    ax.plot([1.5, 1.5], [0, 0.5], "k--")
    ax.annotate('Anthro.', (2.5, 0.45), ha='center', va='center', fontsize=16)
    ax.plot([3.5, 3.5], [0, 0.5], "k--")
    ax.annotate('Wildfire', (4.5, 0.45), ha='center', va='center', fontsize=16)
    ax.plot([5.5, 5.5], [0, 0.5], "k--")
    ax.annotate('Sea salt', (8, 0.45), ha='center', va='center', fontsize=16)
    ax.legend(fontsize=14, loc='right')#, frameon=False)
    plt.ylim(0.0, 0.5)
    plt.yticks(fontsize=14)
    
    """
    ax=fig.add_subplot(313)
    width=0.4
    #ax=fig.add_axes([0.1, 0.2, 0.8, 0.8])
    rs1=ax.bar(x-3*width/4,rmse,width/2, label='RMSE without SPE', color='lime')
    rs1=ax.bar(x-1*width/4,spread,width/2, label='spread without SPE', color='green')
    rs1=ax.bar(x+1*width/4,rmse1,width/2, label='RMSE with SPE', color='cyan')
    rs2=ax.bar(x+3*width/4,spread1,width/2, label='spread with SPE', color='blue')
    ax.set_ylabel('AOD HOFX RMSE and Spread', fontsize=14)
    ax.set_title('(c) AOD HOFX RMSE and spread with/without SPE', fontsize=16)
    ax.set_xticks(x)
    ax.set_xticklabels(masks, fontsize=14,rotation=-45)
    ax.plot([0.5, 0.5], [0, 0.5], "k--")
    ax.annotate('Dust', (1.0, 0.45), ha='center', va='center', fontsize=16)
    ax.plot([1.5, 1.5], [0, 0.5], "k--")
    ax.annotate('Anthro.', (2.5, 0.45), ha='center', va='center', fontsize=16)
    ax.plot([3.5, 3.5], [0, 0.5], "k--")
    ax.annotate('Wildfire', (4.5, 0.45), ha='center', va='center', fontsize=16)
    ax.plot([5.5, 5.5], [0, 0.5], "k--")
    ax.annotate('Sea salt', (8, 0.45), ha='center', va='center', fontsize=16)
    ax.legend(fontsize=14, loc='right')#, frameon=False)
    plt.ylim(0.00, 0.5)
    plt.yticks(fontsize=14)

"""

    plt.tight_layout()
    #plt.savefig('masks-map.png')
    plt.savefig(f'{ptitle}.png', format='png')
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

    required.add_argument(
        '-s', '--spinupday',
        help="Cycle to start stats",
        type=int, required=True)

    required.add_argument(
        '-f', '--aeroda',
        help="AERODA",
        type=str, required=True)

    args = parser.parse_args()
    dayst = args.stday
    dayed = args.edday
    expname = args.expname
    rundir = args.toprundir
    aod = args.aodtype
    aeroda = args.aeroda
    daysp = str(args.spinupday)[0:8]
    datadir = f"{rundir}/{expname}/dr-data-backup/"

    #dayst = 2017100600
    #dayed = 2017102700
    #daysp = 2017101000
    #expname = 'FreeRun-201710'
    #aod = 'NOAA_VIIRS_npp'
    #field = 'cntlBkg'
    #daysp = str(daysp)[0:8]
    #rundir = f'/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-OFF-201710/diagplots/INNOV-STATS/{aod}-daily-{dayst}-{dayed}'

    masks=['GLOBAL', 'NAFRME', \
           'CONUS', 'EASIA', 'SAFRTROP', 'RUSC2S', \
           'NATL', 'NPAC', 'SATL', 'SPAC', 'INDOCE']


    inpre = f"./output/{expname}_cntlBkg_day_nloc_mobs_mhfx_merr2_mbias_mmse_{dayst}_{dayed}_"
    spnum = get_spinupcyc_num(inpre, 'GLOBAL', 0, daysp)

    obs_bkg = coll_samples(inpre, masks, 2)
    hfx_bkg = coll_samples(inpre, masks, 3)
    mobs_bkg = np.nanmean(obs_bkg[:,spnum:],axis=1)
    mhfx_bkg = np.nanmean(hfx_bkg[:,spnum:],axis=1)
    mratio_bkg = mobs_bkg/mhfx_bkg

    if aeroda == "YES":
        inpre = f"./output/{expname}_cntlAnl_day_nloc_mobs_mhfx_merr2_mbias_mmse_{dayst}_{dayed}_"
    else:
        inpre = f"./output/{expname}_cntlBkg_day_nloc_mobs_mhfx_merr2_mbias_mmse_{dayst}_{dayed}_"

    obs_anl = coll_samples(inpre, masks, 2)
    hfx_anl = coll_samples(inpre, masks, 3)
    mobs_anl = np.nanmean(obs_anl[:,spnum:],axis=1)
    mhfx_anl = np.nanmean(hfx_anl[:,spnum:],axis=1)
    mratio_anl = mobs_anl/mhfx_anl

    outfile = f'{expname}_cntlBkg_mean_aod_hfx_ratio.txt'
    with open(outfile, 'w') as fp:
        fp.write('\t'.join(masks))
        fp.write('\n')
        fp.write('\t'.join(str(item) for item in mobs_bkg))
        fp.write('\n')
        fp.write('\t'.join(str(item) for item in mhfx_bkg))
        fp.write('\n')
        fp.write('\t'.join(str(item) for item in mratio_bkg))
        fp.write('\n')

    if aeroda == "YES":
        outfile = f'{expname}_cntlAnl_mean_aod_hfx_ratio.txt'
        with open(outfile, 'w') as fp:
            fp.write('\t'.join(masks))
            fp.write('\n')
            fp.write('\t'.join(str(item) for item in mobs_anl))
            fp.write('\n')
            fp.write('\t'.join(str(item) for item in mhfx_anl))
            fp.write('\n')
            fp.write('\t'.join(str(item) for item in mratio_anl))
            fp.write('\n')


    fcolors=['goldenrod', \
        'red', 'firebrick', 'lightcoral', 'tomato', \
        'dodgerblue', 'lightskyblue', 'cadetblue', 'steelblue', 'darkturquoise']

    
    masks1=['EASIA', 'RUSC2S', 'NAFRME','SAFRTROP', \
          'NATL', 'SATL',  'NPAC', 'SPAC', 'INDOCE']
    fcolors=['firebrick', 'tomato', 'goldenrod', 'lightcoral', \
             'dodgerblue', 'cadetblue', 'lightskyblue', 'steelblue', 'darkturquoise']


    maskdir='./masks'
    nmask1=len(masks1)
    latmin=np.zeros((nmask1), dtype='float')
    latmax=np.zeros_like(latmin)
    lonmin=np.zeros_like(latmin)
    lonmax=np.zeros_like(latmin)
    loncross=np.zeros_like(latmin)

    for imask in range(nmask1):
        maskfile="%s/%s.mask" % (maskdir, masks1[imask])
        latmin[imask], latmax[imask], lonmin[imask], lonmax[imask], loncross[imask]=np.loadtxt(maskfile, unpack=True)
    
    latmid=0.5*(latmin+latmax)
    lonmid=0.5*(lonmin+lonmax)

    ptitle=f'{expname}_mean_aod_hfx_ratio'
    plot_all(ptitle,masks,mobs_bkg,mhfx_bkg,mhfx_anl,aod,masks1,fcolors,latmin,latmax,latmid,lonmax,lonmin,lonmid)
#plot_bargrp3(mhfx[:,0], mobs[:,0], mhfx[:,1], aodtyp)
#plot_bargrp2(spread[:,0], spread[:,1],aodtyp)
#plot_bargrp2_rmse_spread(rmse[:,0], spread[:,0],aodtyp)
#plot_bargrp4(rmse[:,0],spread[:,0], rmse[:,1],spread[:,1],aodtyp)
