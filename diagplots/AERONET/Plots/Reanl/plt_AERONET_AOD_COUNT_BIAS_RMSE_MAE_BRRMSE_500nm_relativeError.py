import sys,os, argparse
from scipy.stats import gaussian_kde
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
from mpl_toolkits.basemap import Basemap
import numpy as np
import math
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mpcrs
import matplotlib.cm as cm

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

def read_aeronet_aod_bias_rmse(datafile):
    f=open(datafile,'r')
    iline=0
    lonvec=[]
    latvec=[]
    cntvec=[]
    obsvec=[]
    hfxvec=[]
    biasvec=[]
    rmsevec=[]
    maevec=[]
    brrmsevec=[]
    for line in f.readlines():
        lon=float(line.split()[0])
        lat=float(line.split()[1])
        cnt=float(line.split()[2])
        obs=float(line.split()[3])
        hfx=float(line.split()[4])
        bias=float(line.split()[5])
        rmse=float(line.split()[6])
        mae=float(line.split()[7])
        brrmse=float(line.split()[8])
        if ~np.isnan(obs):
            lonvec.append(lon)
            latvec.append(lat)
            cntvec.append(cnt)
            obsvec.append(obs)
            hfxvec.append(hfx)
            biasvec.append(bias)
            rmsevec.append(rmse)
            maevec.append(mae)
            brrmsevec.append(brrmse)
        iline=iline+1
    f.close()
    return np.array(lonvec), np.array(latvec), np.array(cntvec), np.array(obsvec), np.array(hfxvec), np.array(biasvec), np.array(rmsevec), np.array(maevec), np.array(brrmsevec)

def read_aeronet_aod_averaged_bias_rmse(datafile):
    f=open(datafile,'r')
    for line in f.readlines():
        biasave = float(line.split()[0])
        rmseave = float(line.split()[1])
        maeave = float(line.split()[2])
        brrmseave = float(line.split()[3])
    f.close()
    return biasave, rmseave, maeave, brrmseave

def plot_map_aeronet_aod_relative_bias_rmse(lons, lats, obss, counts, \
                                   noda_bckg_b, noda_bckg_r, \
                                   da_bckg_b, da_bckg_r, \
                                   da_anal_b, da_anal_r, \
                                   aodcmap, biascmap, rmsecmap, cntcmap, cycle, outpre):
                                   #noda_bckg_b_ave, noda_bckg_r_ave, \
                                   #da_bckg_b_ave, da_bckg_r_ave, \
                                   #da_anal_b_ave, da_anal_r_ave, \
    #cy=str(cyc)[:4]
    #cm=str(cyc)[4:6]
    #cd=str(cyc)[6:8]
    #ch=str(cyc)[8:]

    aodt='AERONET'
    #ptitle='500 nm Aerosol Optical Depth (AOD) bias (left) and RMSE (right) wrt AERONET \n aggregated over 30 days before and at 00%s UTC %s/%s/%s' % (ch, cm, cd, cy)
    fig=plt.figure(figsize=[10,6])
    tfont=11
    mfont=8
    cfont=8
    for ipt in range(4):
        ax=fig.add_subplot(2, 2, ipt+1)
        #if ipt==0:
        #    data=obss
        #    tstr='AERONET 500 nm AOD'
        #if ipt==1:
        #    data=counts
        #    tstr="AERONET 500 nm AOD counts"
        if ipt==0:
            data=noda_bckg_b
            mdata=np.mean(data)
            #mstr='Mean of relative bias = %s' % str("%.4f" % mdata)
            mstr='Mean of relative bias = %s' % str("{:.1%}".format(mdata))
            #mstr='Mean of normalized  bias = %s, %s' % (str("%.4f" % mdata), str("%.4f" % mdata))
            #tstr='(a) NRT-NODA 6hr fcst bias wrt %s \n (%s)' % (aodt, mstr)
            mstr='Mean relative bias = %s' % str("{:.1%}".format(mdata))
            tstr='(a) Relative bias of FreeRun 6hr fcst \n [%s]' % (mstr)
        if ipt==1:
            data=noda_bckg_r
            mdata=np.mean(data)
            #mstr='mean RMSE = %s, %s' % (str("%.4f" % mdata), str("%.4f" % noda_bckg_r_ave))
            #tstr='(b) NRT-NODA 6hr fcst RMSE wrt %s \n (%s)' % (aodt, mstr)
            mstr='Mean relative RMSE = %s' % str("{:.1%}".format(mdata))
            tstr='(b) Relative RMSE of FreeRun 6hr fcst \n [%s]' % (mstr)
        if ipt==200:
            data=da_bckg_b
            mdata=np.mean(data)
            mstr='Mean relative bias = %s' % str("%.4f" % mdata)
            tstr='(c) Relative bias of AeroDA 6hr fcst \n [%s]' % (mstr)
            #mstr='mean bias = %s' % str("%.4f" % da_bckg_b_ave)
            #mstr='mean bias = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_bckg_b_ave))
            #tstr='DA 6hr fcst bias wrt %s \n (%s)' % (aodt, mstr)
            #tstr='(c) NRT-DA-SPE 6hr fcst bias wrt %s \n (%s)' % (aodt, mstr)
            #tstr='(c) Relative bias of NRT-DA-SPE 6hr fcst'# \n wrt %s' % (aodt)
        if ipt==300:
            data=da_bckg_r
            mdata=np.mean(data)
            mstr='Mean relative RMSE = %s' % str("%.4f" % mdata)
            tstr='(d) Relative RMSE of AeroDA 6hr fcst \n [%s]' % (mstr)
            #mstr='mean RMSE = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_bckg_r_ave))
            #tstr='DA 6hr fcst RMSE wrt %s \n (%s)' % (aodt, mstr)
            #tstr='(d) NRT-DA-SPE 6hr fcst RMSE wrt %s \n (%s)' % (aodt, mstr)
            #mstr='mean RMSE = %s' % str("%.4f" % da_bckg_r_ave)
            #tstr='(d) Normalized RMSE of NRT-DA-SPE 6hr fcst' # \n wrt %s' % (aodt)
        if ipt==2:
            data=da_anal_b
            mdata=np.mean(data)
            #mstr='mean bias = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_anal_b_ave))
            #tstr='(c) NRT-DA-SPE analysis bias wrt %s \n (%s)' % (aodt, mstr)
            mstr='Mean Relative bias = %s' % str("{:.1%}".format(mdata))
            tstr='(c) Relative bias of AeroDA analysis \n [%s]' % (mstr)
        if ipt==3:
            data=da_anal_r
            mdata=np.mean(data)
            #mstr='mean RMSE = %s, %s' % (str("%.4f" % mdata), str("%.4f" % da_anal_r_ave))
            #tstr='(d) NRT-DA-SPE analysis RMSE wrt %s \n (%s)' % (aodt, mstr)
            mstr='Mean relative RMSE = %s' % str("{:.1%}".format(mdata))
            tstr='(d) Relative RMSE of AeroDA analysis \n [%s]' % (mstr)
        
        if ipt==100:
            vvend='max'
            ccmap=aodcmap
            bounds=[0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.0]
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
        elif ipt==101:
            vvend='max'
            ccmap=aodcmap
        elif ipt==0 or ipt==2 or ipt==4:
            vvend='both'
            ccmap=biascmap
            #boundpos=[0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30]
            #t1
            #boundpos=[0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.10, 0.11, 0.11, 0.13, 0.14, 0.15] 
            #t2
            #boundpos=[0.01, 0.02, 0.03, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.20, 0.24, 0.28, 0.30, 0.32] 
            #t6
	    #t11
            #boundpos=[0.02, 0.04, 0.06, 0.08, 0.10, 0.13, 0.16, 0.19, 0.22, 0.25, 0.28, 0.31, 0.34, 0.37, 0.40] 
	    #t12
            boundpos=[x*0.06 for x in range(1, 15)]  #[0.02, 0.04, 0.06, 0.08, 0.10, 0.13, 0.16, 0.19, 0.22, 0.25, 0.28, 0.31, 0.34, 0.37, 0.40] 
            boundneg=[-x for x in boundpos]
            boundneg=boundneg[::-1]
            boundneg.append(0.00)
            bounds=boundneg + boundpos
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
        elif ipt==1 or ipt==3 or ipt==5:
            vvend='max'
            ccmap=rmsecmap
            #bounds=[0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40]
            #t1
            #bounds1=[0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40]
            #bounds = [x / 2.0 for x in bounds1]
            #bounds=[0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40]
            #t1
            #bounds=[0.00, 0.015, 0.03, 0.045, 0.06, 0.075, 0.09, 0.105, 0.12, 0.135, 0.150, 0.165, 0.18, 0.195, 0.21, 0.225, 0.25, 0.30, 0.35, 0.40, 0.45]
            #t2
            #bounds=[x*0.01 for x in range(0, 21)]
            #t11
            #bounds=[0.00, 0.010, 0.020, 0.030, 0.040, 0.050, 0.060, 0.070, 0.080, 0.090, 0.100, 0.130, 0.160, 0.190, 0.220, 0.250, 0.280, 0.310, 0.340, 0.370, 0.400]
            #t12
            bounds=boundpos=[x*0.05 for x in range(0, 21)] #[0.00, 0.010, 0.020, 0.030, 0.040, 0.050, 0.060, 0.070, 0.080, 0.090, 0.100, 0.130, 0.160, 0.190, 0.220, 0.250, 0.280, 0.310, 0.340, 0.370, 0.400]
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
           
        #map=Basemap(projection='cyl',llcrnrlat=-60,urcrnrlat=60,llcrnrlon=-130,urcrnrlon=150,resolution='c')
        map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
        map.drawcoastlines(color='grey', linewidth=0.2)
        parallels = np.arange(-90.,90,45.)
        meridians = np.arange(0,360,45.)
        map.drawparallels(parallels,labels=[True,False,False,False],fontsize=mfont, linewidth=0.2,color='grey', dashes=(None,None))
        map.drawmeridians(meridians,labels=[False,False,False,True],fontsize=mfont, linewidth=0.2,color='grey', dashes=(None,None))
        x,y=map(lons, lats)
        if ipt==100:
            cs=map.scatter(lons,lats, s=8, c=data, marker='.', cmap=ccmap)
        else:
            cs=map.scatter(lons,lats, s=10, c=data, marker='o', edgecolors='black', linewidth=0.1, cmap=ccmap, norm=norm,)
            #cs=map.scatter(lons,lats, s=5, c=data, marker='o', cmap=ccmap, norm=norm)
        if ipt==2:
            fig.subplots_adjust(bottom=0.05)
            cbar_ax = fig.add_axes([0.06, 0.040, 0.40, 0.02])
            #cb=fig.colorbar(cs, cax=cbar_ax, orientation='horizontal', ticks=bounds[::4], extend=vvend)
            cb=fig.colorbar(cs, cax=cbar_ax, orientation='horizontal',  extend=vvend)
            cb.ax.set_xticklabels(["{:.1%}".format(i) for i in cb.get_ticks()])
            cb.ax.tick_params(labelsize=cfont)
        if ipt==3:
            fig.subplots_adjust(bottom=0.02)
            cbar_ax = fig.add_axes([0.56, 0.040, 0.40, 0.02])
            cb=fig.colorbar(cs, cax=cbar_ax, orientation='horizontal', extend=vvend)
            cb.ax.set_xticklabels(["{:.1%}".format(i) for i in cb.get_ticks()])
            cb.ax.tick_params(labelsize=cfont)
        #cb=map.colorbar(cs,"right", size="2%", pad="2%", extend=vvend)
        ax.set_title(tstr, fontsize=tfont, fontweight="bold")

    #fig.suptitle(ptitle, fontsize=14,fontweight="bold")
    fig.tight_layout(rect=[0.00, 0.02, 1.00, 1.00])
    figname=f"{outpre}-{cycle}-RelativeError.png"
    plt.savefig(figname, format='png')
    plt.close(fig)


    aodt='AERONET'
    #ptitle='500 nm Aerosol Optical Depth (AOD) MAE (left) and bias-removed RMSE (right) \n wrt AERONET aggregated over 30 days before and at 00%s UTC %s/%s/%s' % (ch, cm, cd, cy)
    fig=plt.figure(figsize=[8,8])
    for ipt in range(2):
        ax=fig.add_subplot(2, 1, ipt+1)
        if ipt==0:
            data=obss
            tstr='(a) AERONET 500 nm AOD'
        if ipt==1:
            data=counts
            tstr="(b) AERONET 500 nm AOD counts"
        
        if ipt==0:
            vvend='max'
            ccmap=aodcmap
            bounds1=[0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.0]
            bounds=[x/2.0 for x in bounds1]
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
        elif ipt==1:
            vvend='max'
            ccmap=cntcmap
           
        map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
        map.drawcoastlines(color='grey', linewidth=0.2)
        parallels = np.arange(-90.,90,45.)
        meridians = np.arange(0,360,45.)
        map.drawparallels(parallels,labels=[True,False,False,False],fontsize=14, linewidth=0.2,color='grey', dashes=(None,None))
        map.drawmeridians(meridians,labels=[False,False,False,True],fontsize=14, linewidth=0.2,color='grey', dashes=(None,None))
        x,y=map(lons, lats)
        if ipt==1:
            #cs=map.scatter(lons,lats, s=5, c=data, marker='o', edgecocmap=ccmap)
            cs=map.scatter(lons,lats, s=15, c=data, marker='o', edgecolors='black', linewidth=0.1, cmap=ccmap) #, norm=norm)
        else:
            cs=map.scatter(lons,lats, s=15, c=data, marker='o', edgecolors='black', linewidth=0.1, cmap=ccmap, norm=norm)
        cb=map.colorbar(cs,"right", size="2%", pad="2%", extend=vvend)
        cb.ax.tick_params(labelsize=14)
        ax.set_title(tstr, fontsize=16, fontweight="bold")

    #fig.suptitle(ptitle, fontsize=14,fontweight="bold")
    fig.tight_layout(rect=[0.00, 0.00, 1.00, 1.00])
    figname=f"{outpre}-{cycle}-AOD.png"
    plt.savefig(figname, format='png')
    plt.close(fig)
    return


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
        type=str, required=True)

    required.add_argument(
        '-p', '--outpre',
        help="Prefix of output file and title",
        type=str, required=True)

    required.add_argument(
        '-x', '--freerun',
        help="FreeRun stat file",
        type=str, required=True)

    required.add_argument(
        '-y', '--dabkg',
        help="DA bckg stat file",
        type=str, required=True)

    required.add_argument(
        '-z', '--daanl',
        help="DA analysis stat file",
        type=str, required=True)

    args = parser.parse_args()
    cycle = args.cycle
    outpre = args.outpre
    freerun = args.freerun
    dabkg = args.dabkg
    daanl = args.daanl

    nbars=21
    cbarname='WhiteBlueGreenYellowRed-v1'
    mpl=0
    white=-1
    reverse=0
    cmapaod=setup_cmap(cbarname,nbars,mpl,white,reverse)

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

    cmaprmse=cmapaod

    nbars=21
    cbarname='MPL_hot'
    mpl=1
    white=100
    reverse=1
    cmapcnt=setup_cmap(cbarname,nbars,mpl,white,reverse)
    #cmaprmse=cmapmae

    datafile=freerun
    noda_bckg_lon, noda_bckg_lat, noda_bckg_cnt, noda_bckg_obs, noda_bckg_hfx, noda_bckg_bias, noda_bckg_rmse, noda_bckg_mae, noda_bckg_brrmse = read_aeronet_aod_bias_rmse(datafile)

    datafile=dabkg
    da_bckg_lon, da_bckg_lat, da_bckg_cnt, da_bckg_obs, da_bckg_hfx, da_bckg_bias, da_bckg_rmse, da_bckg_mae, da_bckg_brrmse = read_aeronet_aod_bias_rmse(datafile)

    datafile=daanl
    da_anal_lon, da_anal_lat, da_anal_cnt, da_anal_obs, da_anal_hfx, da_anal_bias, da_anal_rmse, da_anal_mae, da_anal_brrmse = read_aeronet_aod_bias_rmse(datafile)

    norm=noda_bckg_obs
    plot_map_aeronet_aod_relative_bias_rmse(noda_bckg_lon, noda_bckg_lat, noda_bckg_obs, noda_bckg_cnt, \
                               noda_bckg_bias/norm, noda_bckg_rmse/norm,                                 
                               da_bckg_bias/norm, da_bckg_rmse/norm,                                 
                               da_anal_bias/norm, da_anal_rmse/norm,                                 
                               cmapaod, cmapbias, cmaprmse, cmapcnt, cycle, outpre)
                               #noda_bckg_bias_ave, noda_bckg_rmse_ave,                                 
                               #da_bckg_bias_ave, da_bckg_rmse_ave,                                 
                               #da_anal_bias_ave, da_anal_rmse_ave,                                 
          
exit
