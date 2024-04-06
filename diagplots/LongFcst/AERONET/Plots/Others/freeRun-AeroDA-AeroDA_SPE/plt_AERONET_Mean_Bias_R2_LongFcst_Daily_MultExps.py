import sys,os,argparse
from scipy.stats import gaussian_kde
import numpy as np
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

def plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr, izz):
    tfsize=14
    lfsize=16
    fig = plt.figure(figsize=[8,4])
    ax=fig.add_subplot(111)
    #ax.set_title(f'{plttit}', fontsize = tfsize)
    irun=0
    if ypert==1:
        #data = data*100
        #data = [x * 100 for x in data]
        data = [[j*100 for j in i] for i in data]
        #for x in data:
        #    for y in x:
        #        y = y*100
    for idata in data:
        plt.plot(xarr, idata, linewidth=3, marker=pmarks[irun], linestyle=plines[irun], color=pcols[irun],label=plegs[irun])
        irun+=1
    #ax.set_xticks(ax.get_xticks()[::2])
    ax.grid(color='lightgrey', linestyle='--', linewidth=1)
    if ypert==1:
        ax.yaxis.set_major_formatter(mtick.PercentFormatter())
    if izz==1:
        plt.ylim(-0.07, -0.025)
    elif izz ==2:
        plt.ylim(0.2, 0.6)
    plt.xlabel(xlab, fontsize=lfsize)
    plt.ylabel(ylab, fontsize=lfsize)
    plt.xticks(fontsize=lfsize)
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
    '''
    rundir='/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/'
    diagdir_nopert='diagplots/LongFcst/AERONET/AERONET_SOLAR_AOD15/Daily'
    #cycs='2017120800-2017123100'
    cycs='2020060800-2020063000'
    fhrvec=['1', '2', '3', '4', '5']
    aodtype='AERONET_SOLAR_AOD15'
    exp_pert_fake_freerun='RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006_pertGBBEPx'
    exp_pert_real_freerun='RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006'
    exp_pert_fake_aeroda='RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006_pertGBBEPx'
    exp_pert_real_aeroda='RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006'
    diagdir_pert='diagplots/LongFcst/AERONET-pertGBBEPx/AERONET_SOLAR_AOD15/Daily'
    expruns=[
        'RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006',
	'RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006', 
	'RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006'
        ]
    plegs=['FreeRun', 'AeroDA', 'AeroDA-SPE']
    pcols=['black','blue', 'red']
    plines=['-', '-', '-',]
    pmarks=['o', 'o', 'o']

    num2d=[]
    obs2d=[]
    hfx2d=[]
    bias2d=[]
    rmse2d=[]
    r22d=[]
    rebias2d=[]
    rermse2d=[]

    averebias2d=[]
    averermse2d=[]
    for exprun1 in expruns:
        if exprun1 == exp_pert_fake_freerun:
            exprun=exp_pert_real_freerun
            diagdir=diagdir_pert
        elif exprun1 == exp_pert_fake_aeroda:
            exprun=exp_pert_real_aeroda
            diagdir=diagdir_pert
        else:
            exprun=exprun1
            diagdir=diagdir_nopert
        num1d=[]
        obs1d=[]
        hfx1d=[]
        bias1d=[]
        rmse1d=[]
        r21d=[]
        rebias1d=[]
        rermse1d=[]
        averebias1d=[]
        averermse1d=[]
        for fhr in fhrvec:
            #fhrpad=str(fhr.zfill(3))
            fhrpad=fhr
            infile=f"{rundir}/{exprun}/{diagdir}/PLOTS-{cycs}/{exprun}_{cycs}-Day{fhrpad}_num_obs_hfx_bias_rmse_rebias_rermse_r2.txt"
            [num, obs, hfx, bias, rmse, rebias, rermse, r2]=readsample(infile)
            num1d.append(num) 
            obs1d.append(obs) 
            hfx1d.append(hfx) 
            bias1d.append(bias) 
            rmse1d.append(rmse) 
            r21d.append(r2) 
            rebias1d.append(rebias) 
            rermse1d.append(rermse) 
            infile=f"{rundir}/{exprun}/{diagdir}/PLOTS-{cycs}/{aodtype}_{cycs}-Day{fhrpad}_relative_bias_rmse.txt"
            [averebias, averermse]=readsample(infile)
            averebias1d.append(averebias) 
            averermse1d.append(averermse) 
        num2d.append(num1d)
        obs2d.append(obs1d)
        hfx2d.append(hfx1d)
        bias2d.append(bias1d)
        rmse2d.append(rmse1d)
        r22d.append(r21d)
        rebias2d.append(rebias1d)
        rermse2d.append(rermse1d)
        averebias2d.append(averebias1d)
        averermse2d.append(averermse1d)

    xarr=fhrvec
    xlab="Forecast (days)"

    data=bias2d
    ylab="Mean 500nm AOD Bias"
    ypert=0
    print(ylab)
    pstr=f"MeanStats-Bias-{cycs}"
    iz=1
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr, iz)

    data=r22d
    ylab="Mean 500nm AOD R2"
    ypert=0
    print(ylab)
    pstr=f"MeanStats-R2-{cycs}"
    iz=2
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr, iz)
    exit()

    data=num2d
    ylab="# of AERONET 500nm AOD"
    ypert=0
    print(ylab)
    pstr=f"MeanStats-ObsNum-{cycs}"
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr)

    data=obs2d
    ylab="Mean AERONET 500nm AOD"
    ypert=0
    print(ylab)
    pstr=f"MeanStats-Obs-{cycs}"
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr)

    data=hfx2d
    ylab="Mean modeled 500nm AOD"
    ypert=0
    print(ylab)
    pstr=f"MeanStats-Hfx-{cycs}"
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr)


    data=rmse2d
    ylab="Mean 500nm AOD RMSE"
    ypert=0
    print(ylab)
    pstr=f"MeanStats-RMSE-{cycs}"
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr)


    data=rebias2d
    ylab="Mean 500nm AOD Rel. Bias"
    ypert=1
    print(ylab)
    pstr=f"MeanStats-ReBias-{cycs}"
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr)

    data=rermse2d
    ylab="Mean 500nm AOD Rel. RMSE"
    ypert=1
    print(ylab)
    pstr=f"MeanStats-ReRMSE-{cycs}"
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr)

    data=averebias2d
    ylab="Mean 500nm AOD Rel. Bias"
    ypert=1
    print(ylab)
    pstr=f"MeanStats-AveReBias-{cycs}"
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr)

    data=averermse2d
    ylab="Mean 500nm AOD Rel. RMSE"
    ypert=1
    print(ylab)
    pstr=f"MeanStats-AveReRMSE-{cycs}"
    pp=plot_line(data, plegs, pcols, plines, pmarks, xarr, xlab, ylab, ypert, pstr)
