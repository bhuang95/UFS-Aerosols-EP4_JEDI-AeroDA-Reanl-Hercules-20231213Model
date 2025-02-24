import sys,os,argparse
from scipy.stats import gaussian_kde
import numpy as np
from netCDF4 import Dataset as NetCDFFile
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/Libs/Python')
import mpl_scatter_density
from matplotlib.colors import LinearSegmentedColormap
from astropy.visualization import LogStretch
from astropy.visualization.mpl_normalize import ImageNormalize
from fast_histogram import histogram2d

def open_ncfile(ncfile):
    print('Open file: ', ncfile)
    try:
        ncind=NetCDFFile(ncfile)
    except OSError:
        print('Cannot open file: ', ncfile)
        quit()
    return ncind

def readsample(datafile):
    
    try: 
        f=open(datafile,'r')
    except OSError:
        print('Cannot open file: ', datafile)
        quit()
    datavec=[]
    for line in f.readlines():
        data=float(line.split()[0])
        datavec.append(data)
    f.close()
    return datavec

def plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr):
    tfsize=14
    lfsize=14
    fig = plt.figure(figsize=[8,4])
    ax=fig.add_subplot(111)
    #ax.set_title(f'{plttit}', fontsize = tfsize)
    irun=0
    if ypert==1:
        #data = data*100
        #data = [x * 100 for x in data]
        data = [[j*100 for j in i] for i in data]
        data = data * 100
        #for x in data:
        #    for y in x:
        #        y = y*100
    print('HBO2')
    print(data.shape)
    nx, ny = data.shape
    for ix in range(nx):
        plt.plot(xarr, data[ix,:], linewidth=2, marker=pmarks[irun], linestyle=plines[irun], color=pcols[irun],label=plegs[irun])
        irun+=1
    #ax.set_xticks(ax.get_xticks()[::2])
    ax.grid(color='lightgrey', linestyle='--', linewidth=1)
    if ypert==1:
        ax.yaxis.set_major_formatter(mtick.PercentFormatter())
    plt.xlabel(xlab, fontsize=lfsize)
    plt.ylabel(ylab, fontsize=lfsize)
    plt.xticks(xarr, fontsize=lfsize)
    ax.set_xticks(ax.get_xticks()[::2])
    plt.yticks(fontsize=lfsize)
    plt.legend(loc="best", fontsize=lfsize, frameon=False)
    fig.tight_layout()
    plt.savefig(f"{pstr}.png")
    return

if __name__ == '__main__':
    '''
    parser = argparse.ArgumentParser(
        description=(
            'Print AOD and its hofx in obs space and their difference'
        )
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '-e', '--expname',
        help="Expname",
        type=str, required=True)

    required.add_argument(
        '-o', '--calstat',
        help="Calculate stats",
        type=str, required=True)

    required.add_argument(
        '-p', '--fpre',
        help="File prefix",
        type=str, required=True)

    args = parser.parse_args()
    expname = args.expname
    calcstat = args.expname == "YES"
    fpre = args.fpre
    '''

   # datadir='/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/conferencePlots/202401AMS/LongFcst/ACC/data'
    datadir='/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/R/outdata_acc'
    expruns=[
        'RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006',
	'RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006',
        'RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006'
        ]
#	'RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006',
#	'RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006'
    plegs=['FreeRun', 'AeroDA', 'AeroDA-SPE']
    pcols=['black','blue', 'red']
    plines=['-', '-', '-',]
    pmarks=['o', 'o', 'o']

    fhmin=0
    fhmax=120+1
    fhout=6

    fvars = [
       'ACCMean',
        ]
    data2d=[]
    for exprun in expruns:
        ncfile=f'{datadir}/acc_{exprun}.nc'
        ncind=open_ncfile(ncfile)
        data1d=ncind.variables['ACCMean'][:]
        ncind.close()
        data2d.append(data1d)
        
    arr2d = np.array(data2d)

    data=arr2d
    xarr=[*range(fhmin, fhmax, fhout)]
    xarrstr=str(xarr)
    xlab="Forecast (hours)"
    ylab="ACC"
    pstr="ACC"
    ypert= 0
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr)
