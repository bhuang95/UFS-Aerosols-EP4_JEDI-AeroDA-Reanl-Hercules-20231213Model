import sys,os,argparse
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
from mpl_toolkits.basemap import Basemap
from netCDF4 import Dataset as NetCDFFile
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.colors as mpcrs

def open_ncfile(ncfile):
    print('Open file: ', ncfile)
    try:
        ncind=NetCDFFile(ncfile)
    except OSError:
        print('Cannot open file: ', ncfile)
        quit()
    return ncind

def aod_cmap(mpl_in, white_in, reverse_in):
    nbars=21
    cbarname='WhiteBlueGreenYellowRed-v1'
    mpl=mpl_in
    white=white_in
    reverse=reverse_in
    cmapaod=setup_cmap(cbarname,nbars,mpl,white,reverse)
    return cmapaod

def aodbias_cmap():
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

    return cmapbias


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

def plot_map_contourf_12(lon, lat, anal, nodabckg, dabckg, daanal, \
                       nodabckg_bias, dabckg_bias, daanal_bias, \
                       nodabckg_rmse, dabckg_rmse, daanal_rmse, \
		       model, cyc, cmapaod, cmapbias, cmaprmse):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    ptitle='Comparison with %s analyzed 550 nm Aerosol Optical Depth (AOD) \n valid at %s/%s/%s (0000-0018 UTC)' % (model, cm, cd, cy)
    pname='%s-AOD.png' %(model)
    fig = plt.figure(figsize=[16,12])
    for ipt in range(12):
        if ipt!=0 and ipt!=2:
            ax=fig.add_subplot(4, 3, ipt+1)
            if ipt==1:
                data=anal
                tstr='%s analysis' % (model)
            if ipt==3:
                data=nodabckg
                tstr='NODA 6hr fcst'
            if ipt==4:
                data=dabckg
                tstr='DA 6hr fcst'
            if ipt==5:
                data=daanal
                tstr='DA analysis'
            if ipt==6:
                data=nodabckg_bias
                tstr='NODA 6hr fcst bias'
            if ipt==7:
                data=dabckg_bias
                tstr='DA 6hr fcst bias'
            if ipt==8:
                data=daanal_bias
                tstr='DA analysis bias'
            if ipt==9:
                data=nodabckg_rmse
                tstr='NODA 6hr fcst RMSE'
            if ipt==10:
                data=dabckg_rmse
                tstr='DA 6hr fcst RMSE'
            if ipt==11:
                data=daanal_rmse
                tstr='DA analysis RMSE'

            if ipt<6:
                ccmap=cmapaod
                cbarextend='max'
                bounds=[0.0, 0.1, 0.16, 0.23, 0.29, 0.36, 0.42, 0.49, 0.55, 0.61, 0.68, 0.74, 0.81, 0.87, 1]
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            elif ipt<9:
                ccmap=cmapbias
                cbarextend='both'
                boundpos=[0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
                boundneg=[-x for x in boundpos]
                boundneg=boundneg[::-1]
                print(type(boundpos))
                print(type(boundneg))
                boundneg.append(0.00)
                bounds=boundneg + boundpos
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            else:
                ccmap=cmaprmse
                cbarextend='max'
                bounds=[0.0, 0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)

            map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=0,urcrnrlon=360,resolution='c')
            map.drawcoastlines(color='black', linewidth=0.2)
            parallels = np.arange(-90.,90,15.)
            meridians = np.arange(0,360,45.)
            map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
            map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
            lons,lats = np.meshgrid(lon,lat)
            #lons, data = map.shiftdata(lons, datain = data, lon_0=0)
            x,y = map(lons,lats)
            cs=map.contourf(x,y,data,bounds,cmap=ccmap,norm=norm,extend=cbarextend)
            cb=map.colorbar(cs,"right", size="2%", pad="2%")
            ax.set_title(tstr, fontsize=18, fontweight="bold")

    fig.suptitle(ptitle, fontsize=18, fontweight="bold")
    fig.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig(pname)
    plt.close(fig)
    return

"""
def plot_map_contourf_18(lon, lat, nasa, ec, nodabckg, dabckg, daanal, \
                       nodabckg_nasa_bias, dabckg_nasa_bias, daanal_nasa_bias, \
                       nodabckg_nasa_rmse, dabckg_nasa_rmse, daanal_nasa_rmse, \
                       nodabckg_ec_bias, dabckg_ec_bias, daanal_ec_bias, \
                       nodabckg_ec_rmse, dabckg_ec_rmse, daanal_ec_rmse, \
		       nasamod, ecmod, cyc, cmapaod, cmapbias, cmaprmse):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    #ptitle='Comp. with %s and %s \n analyzed 550nm Aerosol Optical Depth \n valid at %s/%s/%s (0000-0018 UTC)' % (nasamod, ecmod, cm, cd, cy)
    ptitle='550nm Aerosol Optical Depth \n valid at %s/%s/%s (0000-0018 UTC)' % (cm, cd, cy)
    #pname='TwoModels-AOD-%s%s%s.png' % (cy,cm,cd)
    pname='f12-MET-AOD-bias-rmse.png'
    fig = plt.figure(figsize=[19, 21])
    for ipt in range(18):
        ax=fig.add_subplot(6, 3, ipt+1)
        if ipt==0:
            text_kwargs = dict(ha='center', va='center', fontsize=17, fontweight="bold")
            plt.text(0.5, 0.5, ptitle, **text_kwargs)
            ax.set_axis_off()
        else:	
            if ipt==1:
                data=nasa
                tstr='%s analysis' % (nasamod)
            if ipt==2:
                data=ec
                tstr='%s analysis' % (ecmod)
            if ipt==3:
                data=nodabckg
                tstr='NODA 6hr fcst'
            if ipt==4:
                data=dabckg
                tstr='DA 6hr fcst'
            if ipt==5:
                data=daanal
                tstr='DA analysis'
            if ipt==6:
                data=nodabckg_nasa_bias
                tstr='Bias [NODA 6hr fcst - NASA/GEOS]'
            if ipt==7:
                data=dabckg_nasa_bias
                tstr='Bias [DA 6hr fcst - NASA/GEOS]'
            if ipt==8:
                data=daanal_nasa_bias
                tstr='Bias [DA analysis - NASA/GEOS]'
            if ipt==9:
                data=nodabckg_ec_bias
                tstr='Bias [NODA 6hr fcst - ECMWF/CAMS]'
            if ipt==10:
                data=dabckg_ec_bias
                tstr='Bias [DA 6hr fcst - ECMWF/CAMS]'
            if ipt==11:
                data=daanal_ec_bias
                tstr='Bias [DA analysis - ECMWF/CAMS]'
            if ipt==12:
                data=nodabckg_nasa_rmse
                tstr='RMSE [NODA 6hr fcst - NASA/GEOS]'
            if ipt==13:
                data=dabckg_nasa_rmse
                tstr='RMSE [DA 6hr fcst - NASA/GEOS]'
            if ipt==14:
                data=daanal_nasa_rmse
                tstr='RMSE [DA analysis - NASA/GEOS]'
            if ipt==15:
                data=nodabckg_ec_rmse
                tstr='RMSE [NODA 6hr fcst - ECMWF/CAMS]'
            if ipt==16:
                data=dabckg_ec_rmse
                tstr='RMSE [DA 6hr fcst - ECMWF/CAMS]'
            if ipt==17:
                data=daanal_ec_rmse
                tstr='RMSE [DA analysis - ECMWF/CAMS]'

            if ipt<6:
                ccmap=cmapaod
                cbarextend='max'
                #bounds=[0.0, 0.1, 0.16, 0.23, 0.29, 0.36, 0.42, 0.49, 0.55, 0.61, 0.68, 0.74, 0.81, 0.87, 1]
                bounds=[0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.0]
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            elif ipt<12:
                ccmap=cmapbias
                cbarextend='both'
                #boundpos=[0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
                #boundpos=[0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30]
                #boundpos=[0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, 0.30, 0.33, 0.36, 0.39, 0.42, 0.45]
                boundpos1=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
                boundpos=[x*0.035 for x in boundpos1]
                boundneg=[-x for x in boundpos]
                boundneg=boundneg[::-1]
                print(type(boundpos))
                print(type(boundneg))
                boundneg.append(0.00)
                bounds=boundneg + boundpos
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            else:
                ccmap=cmaprmse
                cbarextend='max'
                #bounds=[0.0, 0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
                #bounds=[0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40]
                #bounds=[0.0, 0.02, 0.04, 0.06, 0.08, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60]
                bounds1=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
                bounds=[x*0.04 for x in bounds1]
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)

            map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
            map.drawcoastlines(color='black', linewidth=0.2)
            parallels = np.arange(-90.,90,15.)
            meridians = np.arange(-180,180,45.)
            map.drawparallels(parallels,labels=[True,False,False,False],linewidth=0.2,color='grey', dashes=(None,None))
            map.drawmeridians(meridians,labels=[False,False,False,True],linewidth=0.2,color='grey', dashes=(None,None))
            lons,lats = np.meshgrid(lon,lat)
            lons, data = map.shiftdata(lons, datain = data, lon_0=0)
            x,y = map(lons,lats)
            ax.set_title(tstr, fontsize=16, fontweight="bold")
            cs=map.contourf(x,y,data,bounds,cmap=ccmap,norm=norm,extend=cbarextend)
            if ipt==5:
                fig.subplots_adjust(right=0.9)
                cbar_ax = fig.add_axes([0.94, 0.70, 0.01, 0.25])
                cb=fig.colorbar(cs, cax=cbar_ax)
                cb.ax.tick_params(labelsize=16)
            elif ipt==11:
                fig.subplots_adjust(right=0.9)
                cbar_ax = fig.add_axes([0.94, 0.37, 0.01, 0.25])
                cb=fig.colorbar(cs, cax=cbar_ax)
                cb.ax.tick_params(labelsize=16)
            elif ipt==17:
                fig.subplots_adjust(right=0.9)
                cbar_ax = fig.add_axes([0.94, 0.04, 0.01, 0.25])
                cb=fig.colorbar(cs, cax=cbar_ax)
                cb.ax.tick_params(labelsize=16)
            #cb=map.colorbar(cs,"right", size="2%", pad="2%")

    #fig.suptitle(ptitle, fontsize=18, fontweight="bold")
    fig.tight_layout(rect=[0.0, 0.0, 0.94, 1.0])
    plt.savefig(pname)
    plt.close(fig)
    return
"""

def plot_map_contourf_8(lon, lat, merra2, cams, fcst, 
                       fcst_merra2_bias, fcst_merra2_rmse, \
                       fcst_cams_bias, fcst_cams_rmse, \
		       nasamod, ecmod, fcstmod, cmapaod, cmapbias, cmaprmse):
    fsize1=9
    fsize2=9
    fsize3=8
    fig = plt.figure(figsize=[8, 8.5])
    for ipt in range(8):
        ax=fig.add_subplot(4, 2, ipt+1)
        if ipt==100:
            text_kwargs = dict(ha='center', va='center', fontsize=17, fontweight="bold")
            plt.text(0.5, 0.5, ptitle, **text_kwargs)
            ax.set_axis_off()
        else:	
            if ipt==0:
                data=merra2
                tstr=f'(a) {nasamod} analysis'
            if ipt==1:
                data=cams
                tstr=f'(b) {ecmod} analysis'
            if ipt==2:
                data=fcst
                tstr=f'(c) {fcstmod}'
            if ipt==3:
                data=fcst
                tstr=f'(d) {fcstmod}'
            if ipt==4:
                data=fcst_merra2_bias
                tstr=f'(e) Bias w/ {nasamod}'
            if ipt==5:
                data=fcst_cams_bias
                tstr=f'(f) Bias w/ {ecmod}'
            if ipt==6:
                data=fcst_merra2_rmse
                tstr=f'(g) RMSE w/ {nasamod}'
            if ipt==7:
                data=fcst_cams_rmse
                tstr=f'(h) w/ {ecmod}'

            if ipt<4:
                ccmap=cmapaod
                cbarextend='max'
                #bounds=[0.0, 0.1, 0.16, 0.23, 0.29, 0.36, 0.42, 0.49, 0.55, 0.61, 0.68, 0.74, 0.81, 0.87, 1]
                bounds=[0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.0]
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            elif ipt<6:
                ccmap=cmapbias
                cbarextend='both'
                #boundpos=[0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
                #boundpos=[0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30]
                #boundpos=[0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, 0.30, 0.33, 0.36, 0.39, 0.42, 0.45]
                boundpos1=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
                boundpos=[x*0.03 for x in boundpos1]
                boundneg=[-x for x in boundpos]
                boundneg=boundneg[::-1]
                print(type(boundpos))
                print(type(boundneg))
                boundneg.append(0.00)
                bounds=boundneg + boundpos
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)
            else:
                ccmap=cmaprmse
                cbarextend='max'
                #bounds=[0.0, 0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
                #bounds=[0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40]
                #bounds=[0.0, 0.02, 0.04, 0.06, 0.08, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60]
                bounds1=[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
                bounds=[x*0.05 for x in bounds1]
                norm=mpcrs.BoundaryNorm(bounds, ccmap.N)

            map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
            map.drawcoastlines(color='grey', linewidth=0.2)
            parallels = np.arange(-90.,90,45.)
            meridians = np.arange(-180,180,45.)
            map.drawparallels(parallels,labels=[True,False,False,False],linewidth=0.2, fontsize=fsize3, color='grey', dashes=(None,None))
            map.drawmeridians(meridians,labels=[False,False,False,True],linewidth=0.2, fontsize=fsize3, color='grey', dashes=(None,None))
            lons,lats = np.meshgrid(lon,lat)
            lons, data = map.shiftdata(lons, datain = data, lon_0=0)
            x,y = map(lons,lats)
            ax.set_title(tstr, fontsize=fsize1)#, fontweight="bold")
            cs=map.contourf(x,y,data,bounds,cmap=ccmap,norm=norm,extend=cbarextend)
            if ipt==1:
                fig.subplots_adjust(right=0.92)
                cbar_ax = fig.add_axes([0.91, 0.62, 0.012, 0.25])
                cb=fig.colorbar(cs, cax=cbar_ax)
                cb.ax.tick_params(labelsize=fsize2)
            elif ipt==5:
                fig.subplots_adjust(right=0.92)
                cbar_ax = fig.add_axes([0.91, 0.28, 0.012, 0.18])
                cb=fig.colorbar(cs, cax=cbar_ax)
                cb.ax.tick_params(labelsize=fsize2)
            elif ipt==7:
                fig.subplots_adjust(right=0.92)
                cbar_ax = fig.add_axes([0.91, 0.02, 0.012, 0.18])
                cb=fig.colorbar(cs, cax=cbar_ax)
                cb.ax.tick_params(labelsize=fsize2)
            #cb=map.colorbar(cs,"right", size="2%", pad="2%")

    #fig.suptitle(ptitle, fontsize=18, fontweight="bold")
    fig.tight_layout(rect=[0.0, 0.0, 0.92, 1.0])
    #fig.tight_layout()
    pname='FCST_MERRA2_CAMS_AOD.png'
    plt.savefig(pname, format='png')
    plt.close(fig)
    return

def plot_map_contourf_aod(lon, lat, aod, aodmod, cmapaod):
    tstr=f'VIIRS AOD Clim at {aodmod}'
    fig = plt.figure(figsize=[8, 6])
    ax=fig.add_subplot(1,1,1)
    ccmap=cmapaod
    cbarextend='max'
    bounds=[0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.0]
    norm=mpcrs.BoundaryNorm(bounds, ccmap.N)

    map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
    map.drawcoastlines(color='grey', linewidth=0.2)
    parallels = np.arange(-90.,90,45.)
    meridians = np.arange(-180,180,45.)
    map.drawparallels(parallels,labels=[True,False,False,False],linewidth=0.2, color='grey', dashes=(None,None))
    map.drawmeridians(meridians,labels=[False,False,False,True],linewidth=0.2, color='grey', dashes=(None,None))
    lons,lats = np.meshgrid(lon,lat)
    #lons, data = map.shiftdata(lons, datain = aod, lon_0=0)
    x,y = map(lons,lats)
    ax.set_title(tstr, fontsize=12)#, fontweight="bold")
    #cs=map.contourf(x,y,data,bounds,cmap=ccmap,norm=norm,extend=cbarextend)
    cs=map.scatter(lons,lats, s=1, c=aod, marker='.', cmap=ccmap, vmin=0.0, vmax=1.0)
    cb=map.colorbar(cs,"right", size="2%", pad="2%")

    #fig.subplots_adjust(right=0.90)
    #cbar_ax = fig.add_axes([0.90, 0.15, 0.015, 0.6])
    #cb=fig.colorbar(cs, cax=cbar_ax)
    cb.ax.tick_params(labelsize=14)

    #fig.tight_layout(rect=[0.0, 0.0, 0.90, 0.90])
    pname=f'VIIRS_AOD_CLIM_{aodmod}.png'
    plt.savefig(pname)
    plt.close(fig)
    return

def plot_map_contourf_bias(lon, lat, mnasa, mec, \
                nodab_na_b, dab_na_b, daa_na_b, \
                nodab_ec_b, dab_ec_b, daa_ec_b, \
		nasamod, ecmod, cyc, cmapbias):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    ptitle='550 nm Aerosol Optical Depth (AOD) Bias wrt NASA/GEOS (left) \n and ECMWF/CAMS (right) Analysis on %s/%s/%s' % (cm, cd, cy)
    if mnasa=="YES":
        ptitle='550 nm Aerosol Optical Depth (AOD) Bias wrt NASA/GEOS (unavailable, left) \n and ECMWF/CAMS (right) Analysis on %s/%s/%s' % (cm, cd, cy)
    if mec=="YES":
        ptitle='550 nm Aerosol Optical Depth (AOD) Bias wrt NASA/GEOS (left) \n and ECMWF/CAMS (unavailable, right) Analysis on %s/%s/%s' % (cm, cd, cy)

    fsize1=14
    fsize2=14
    fsize3=14
    fig = plt.figure(figsize=[10, 8])
    for ipt in range(6):
        ax=fig.add_subplot(3, 2, ipt+1)
        #if ipt==100:
        if (ipt==100) or (ipt%2==0 and mnasa=="YES") or (ipt%2==1 and mec=="YES"):
            #text_kwargs = dict(ha='center', va='center', fontsize=17, fontweight="bold")
            #plt.text(0.5, 0.5, ptitle, **text_kwargs)
            ax.set_axis_off()
        else:	
            if ipt==0:
                data=nodab_na_b
                tstr='NODA 6hr fcst bias wrt NASA/GEOS'
            if ipt==1:
                data=nodab_ec_b
                tstr='NODA 6hr fcst bias wrt ECMWF/CAMS'
            if ipt==2:
                data=dab_na_b
                tstr='DA 6hr fcst bias wrt NASA/GEOS'
            if ipt==3:
                data=dab_ec_b
                tstr='DA 6hr fcst bias wrt ECMWF/CAMS'
            if ipt==4:
                data=daa_na_b
                tstr='DA analysis bias wrt NASA/GEOS'
            if ipt==5:
                data=daa_ec_b
                tstr='DA analysis bias wrt ECMWF/CAMS'

            ccmap=cmapbias
            cbarextend='both'
            #boundpos=[0.03, 0.06, 0.10, 0.12, 0.20, 0.25, 0.30, 0.35, 0.40, 0.44, 0.48, 0.52, 0.56, 0.60]
            #boundpos=[0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30]
            #boundpos=[0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, 0.30, 0.33, 0.36, 0.39, 0.42, 0.45]
            boundpos1=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
            boundpos=[x*0.05 for x in boundpos1]
            boundneg=[-x for x in boundpos]
            boundneg=boundneg[::-1]
            print(type(boundpos))
            print(type(boundneg))
            boundneg.append(0.00)
            bounds=boundneg + boundpos
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)

            map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
            map.drawcoastlines(color='grey', linewidth=0.2)
            parallels = np.arange(-90.,90,45.)
            meridians = np.arange(-180,180,45.)
            map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2, color='grey', dashes=(None,None))
            map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2, color='grey', dashes=(None,None))
            lons,lats = np.meshgrid(lon,lat)
            lons, data = map.shiftdata(lons, datain = data, lon_0=0)
            x,y = map(lons,lats)
            ax.set_title(tstr, fontsize=fsize1)#, fontweight="bold")
            cs=map.contourf(x,y,data,bounds,cmap=ccmap,norm=norm,extend=cbarextend)

            fig.subplots_adjust(right=0.90)
            cbar_ax = fig.add_axes([0.90, 0.15, 0.015, 0.6])
            cb=fig.colorbar(cs, cax=cbar_ax)
            cb.ax.tick_params(labelsize=fsize2)

    fig.suptitle(ptitle, fontsize=14, fontweight="bold")
    fig.tight_layout(rect=[0.0, 0.0, 0.90, 0.90])
    pname='NASA-ECMWF-AOD-BIAS_full_0m_f000.png'
    plt.savefig(pname)
    plt.close(fig)
    return

def plot_map_contourf_rmse(lon, lat, mnasa, mec, \
                nodab_na_b, dab_na_b, daa_na_b, \
                nodab_ec_b, dab_ec_b, daa_ec_b, \
		nasamod, ecmod, cyc, cmaprmse):
    cy=str(cyc)[:4]
    cm=str(cyc)[4:6]
    cd=str(cyc)[6:8]
    ch=str(cyc)[8:]

    ptitle='550 nm Aerosol Optical Depth (AOD) RMSE wrt NASA/GEOS (left) \n and ECMWF/CAMS (right) analysis on %s/%s/%s' % (cm, cd, cy)
    if mnasa=="YES":
        ptitle='550 nm Aerosol Optical Depth (AOD) RMSE wrt NASA/GEOS (unavailable, left) \n and ECMWF/CAMS (right) Analysis on %s/%s/%s' % (cm, cd, cy)
    if mec=="YES":
        ptitle='550 nm Aerosol Optical Depth (AOD) RMSE wrt NASA/GEOS (left) \n and ECMWF/CAMS (unavailable, right) Analysis on %s/%s/%s' % (cm, cd, cy)

    fsize1=14
    fsize2=14
    fsize3=14
    fig = plt.figure(figsize=[10, 8])
    for ipt in range(6):
        ax=fig.add_subplot(3, 2, ipt+1)
        if (ipt==100) or (ipt%2==0 and mnasa=="YES") or (ipt%2==1 and mec=="YES"):
            #text_kwargs = dict(ha='center', va='center', fontsize=17, fontweight="bold")
            #plt.text(0.5, 0.5, ptitle, **text_kwargs)
            ax.set_axis_off()
        else:	
            if ipt==0:
                data=nodab_na_b
                tstr='NODA 6hr fcst RMSE wrt NASA/GEOS'
            if ipt==1:
                data=nodab_ec_b
                tstr='NODA 6hr fcst RMSE wrt ECMWF/CAMS'
            if ipt==2:
                data=dab_na_b
                tstr='DA 6hr fcst RMSE wrt NASA/GEOS'
            if ipt==3:
                data=dab_ec_b
                tstr='DA 6hr fcst RMSE wrt ECMWF/CAMS'
            if ipt==4:
                data=daa_na_b
                tstr='DA analysis RMSE wrt NASA/GEOS'
            if ipt==5:
                data=daa_ec_b
                tstr='DA analysis RMSE wrt ECMWF/CAMS'

            ccmap=cmaprmse
            cbarextend='max'
            bounds1=[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
            bounds=[x*0.05 for x in bounds1]
            norm=mpcrs.BoundaryNorm(bounds, ccmap.N)

            map=Basemap(projection='cyl',llcrnrlat=-90,urcrnrlat=90,llcrnrlon=-180,urcrnrlon=180,resolution='c')
            map.drawcoastlines(color='grey', linewidth=0.2)
            parallels = np.arange(-90.,90,45.)
            meridians = np.arange(-180,180,45.)
            map.drawparallels(parallels,labels=[False,False,False,False],linewidth=0.2, color='grey', dashes=(None,None))
            map.drawmeridians(meridians,labels=[False,False,False,False],linewidth=0.2, color='grey', dashes=(None,None))
            lons,lats = np.meshgrid(lon,lat)
            lons, data = map.shiftdata(lons, datain = data, lon_0=0)
            x,y = map(lons,lats)
            ax.set_title(tstr, fontsize=fsize1)#, fontweight="bold")
            cs=map.contourf(x,y,data,bounds,cmap=ccmap,norm=norm,extend=cbarextend)

            fig.subplots_adjust(right=0.90)
            cbar_ax = fig.add_axes([0.90, 0.15, 0.015, 0.6])
            cb=fig.colorbar(cs, cax=cbar_ax)
            cb.ax.tick_params(labelsize=fsize2)

    fig.suptitle(ptitle, fontsize=14, fontweight="bold")
    fig.tight_layout(rect=[0.0, 0.0, 0.90, 0.90])
    pname='NASA-ECMWF-AOD-RMSE_full_0m_f000.png'
    plt.savefig(pname)
    plt.close(fig)
    return


if __name__ == '__main__':
    '''
    parser = argparse.ArgumentParser(
        description=(
            'Plot diags against NASA and EC AOD reanalysis.'
        )
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '-n', '--merra2',
        help="Input NASA diag files",
        type=str, required=True)

    required.add_argument(
        '-e', '--cams',
        help="Input EC diag files",
        type=str, required=True)

    required.add_argument(
        '-l', '--lead',
        help="Fcst lead time",
        type=str, required=True)

    args = parser.parse_args()
    merra2 = args.merra2
    cams = args.cams
    fhr = args.lead
    '''
    mpl = 0; white = -1; reverse = 0
    cmapaod=aod_cmap(mpl, white, reverse)
    cmapbias=aodbias_cmap()
    cmaprmse=cmapaod
    cmapmae=cmapaod

    datadir='/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/DATA/OBS/VIIRS/AWS_gridded_monthly'
    months=['dec_2012-2020_excl_2017', 'june_2012-2019']

    for month in months:
        ncfile=f'{datadir}/viirs_aod_monthly_snpp_0.250_deg_{month}.nc'
        ncind=open_ncfile(ncfile)
        lat=ncind.variables['lat'][:]
        lon=ncind.variables['lon'][:]
        aod=ncind.variables['aod'][:]
        ncind.close()

        #lon = ((360 + (lon % 360)) % 360)

        aodmod=month
        pp = plot_map_contourf_aod(lon, lat, aod, aodmod, cmapaod)

"""
plot_map_contourf_aod(lon, lat, miss_nasa, miss_ec, nasa_aod, ec_aod, nodabckg_aod, dabckg_aod, daanal_aod, \
                     nasamod, ecmod, cyc, cmapaod)

plot_map_contourf_bias(lon, lat, miss_nasa, miss_ec, \
                nodabckg_nasa_bias, dabckg_nasa_bias, daanal_nasa_bias, \
                nodabckg_ec_bias, dabckg_ec_bias, daanal_ec_bias, \
                nasamod, ecmod, cyc, cmapbias)

plot_map_contourf_rmse(lon, lat, miss_nasa, miss_ec, \
                nodabckg_nasa_rmse, dabckg_nasa_rmse, daanal_nasa_rmse, \
                nodabckg_ec_rmse, dabckg_ec_rmse, daanal_ec_rmse, \
                nasamod, ecmod, cyc, cmaprmse)
"""
