import sys,os,argparse
from scipy.stats import gaussian_kde
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/Libs/Python')
import mpl_scatter_density
from matplotlib.colors import LinearSegmentedColormap
from astropy.visualization import LogStretch
from astropy.visualization.mpl_normalize import ImageNormalize
from fast_histogram import histogram2d

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

def plot_line(data, xarr, xlab, ylab, pstr):
    tfsize=12
    lfsize=12
    fig = plt.figure(figsize=[8,4])
    ax=fig.add_subplot(111)
    #ax.set_title(f'{plttit}', fontsize = tfsize)
    plt.plot(xarr, data, linewidth=2)
    ax.set_xticks(ax.get_xticks()[::2])
    plt.xlabel(xlab, fontsize=lfsize)
    plt.ylabel(ylab, fontsize=lfsize)
    plt.xticks(fontsize=lfsize)
    plt.yticks(fontsize=lfsize)
    fig.tight_layout()
    plt.savefig(f"{pstr}.png")
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
        '-f', '--fhrs',
        help="fcst hours",
        type=str, required=True)

    args = parser.parse_args()
    cycle = args.cycle
    outpre = args.outpre
    fhrs = args.fhrs

    fhrvec=fhrs.split(' ')

    numvec=[]
    obsvec=[]
    hfxvec=[]
    biasvec=[]
    r2vec=[]
    for fhr in fhrvec:
        #fhrpad=str(fhr.zfill(3))
        fhrpad=str(fhr)
        infile=f"{outpre}_{cycle}-Day{fhrpad}_num_obs_hfx_bias_r2.txt"
        [num, obs, hfx, bias, r2]=readsample(infile)
        numvec.append(num) 
        obsvec.append(obs) 
        hfxvec.append(hfx) 
        biasvec.append(bias) 
        r2vec.append(r2) 

    #numarr=np.array(numvec)
    #obsarr=np.array(obsvec)
    #hfxarr=np.array(jfxvec)
    #biasarr=np.array(biasvec)
    #r2arr=np.array(r2vec)

    xarr=fhrvec
    xlab="Fcst (days)"

    data=numvec
    ylab="AERONET 500nm AOD #"
    print(ylab)
    pstr=f"{outpre}-MeanStats-ObsNum-{cycle}"
    pp=plot_line(data, xarr, xlab, ylab, pstr)

    data=obsvec
    ylab="Mean AERONET 500nm AOD"
    print(ylab)
    pstr=f"{outpre}-MeanStats-Obs-{cycle}"
    pp=plot_line(data, xarr, xlab, ylab, pstr)

    data=hfxvec
    ylab="Mean modeled 500nm AOD"
    print(ylab)
    pstr=f"{outpre}-MeanStats-Hfx-{cycle}"
    pp=plot_line(data, xarr, xlab, ylab, pstr)

    data=biasvec
    ylab="Mean 500nm AOD Bias"
    print(ylab)
    pstr=f"{outpre}-MeanStats-Bias-{cycle}"
    pp=plot_line(data, xarr, xlab, ylab, pstr)

    data=r2vec
    ylab="Mean 500nm AOD R2"
    print(ylab)
    pstr=f"{outpre}-MeanStats-R2-{cycle}"
    pp=plot_line(data, xarr, xlab, ylab, pstr)
