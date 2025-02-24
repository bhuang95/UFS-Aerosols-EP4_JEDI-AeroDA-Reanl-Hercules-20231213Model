import sys,os,argparse
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
#from mpl_toolkits.basemap import Basemap
#from netCDF4 import Dataset as NetCDFFile
import numpy as np
import matplotlib
matplotlib.use('agg')
import matplotlib.pyplot as plt
#import matplotlib.cm as cm
from matplotlib import gridspec
from matplotlib.dates import (DAILY, DateFormatter,
                              rrulewrapper, RRuleLocator)
from ndate import ndate
from datetime import datetime
from datetime import timedelta
import matplotlib.dates as mdates


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

def get_spinupcyc_num(infile, ind, spinupcyc):
    infile = f"{infile}"
    data1d = []
    with open(infile, 'r') as fin:
        for line in fin.readlines():
            data = float(line.split()[ind])
            data1d.append(data)
    return data1d.index(float(spinupcyc))

def plot_err_var_vartot(mask, data, cols, clegs, plttit):
    nvars, ndays = data.shape
    fsize = 14
    xarr = range(1, ndays+1)
    fig = plt.figure(figsize=[8,4])
    ax=fig.add_subplot(111)
    ax.set_title(f'{plttit}', fontsize = fsize)
    for iv in range(nvars):
        plt.plot(xarr, data[iv, :], color=clos[iv], label=clegs[iv], linewidth=2)
    plt.legend(loc='upper right')
    plt.xlabel('Days', fontsize=fsize)
    plt.xticks(fontsize=fsize)
    plt.yticks(fontsize=fsize)
    #plt.xlim(0, ndays)
    fig.tight_layout()
    plt.savefig('%s-TimeSeries-err_var_vartot.png' % (plttit), format='png')

def plt_aod_bias_rmse_mask_daily(obs, hfx, bias, rmse, spnum, dates, formatter,
		pltcolor1, pltcolor2, leglist1, leglist2, mask, dayst, dayed):
    ndays, nexps = obs.shape
    obshfx = np.concatenate((obs[:,0].reshape(ndays, 1), hfx), axis=1)  	
    mobshfx = np.nanmean(obshfx[spnum:,:], axis=0)
    mbias = np.nanmean(bias[spnum:,:], axis=0)
    mrmse = np.sqrt(np.nanmean(np.square(rmse[spnum:,:]), axis=0))

    fig=plt.figure(figsize=(12, 10))
    gs = gridspec.GridSpec(3, 2, width_ratios=[3, 1]) 
    for ipt in range(0,6):
        print(ipt)
        ax=plt.subplot(gs[ipt])  #plt.subplot(3,1,ipt)
        #ax.set_prop_cycle(color=pltcolor, linestyle=pltstyle)
        if ipt==100:
           print('HBO')
        else:
            if ipt==0:
                data=obshfx
                title='(a) 550 nm AOD'
                ylab='AOD'
                pltcolor=pltcolor1
                leglist=leglist1
            elif ipt==1:
                data=mobshfx
                title='(d) Mean AOD'
                pltcolor=pltcolor1
                leglist=leglist1
            elif ipt==2:
                data=bias
                title='(b) Bias against VIIRS 550 nm AOD'
                ylab='Bias'
                pltcolor=pltcolor2
                leglist=leglist2
            elif ipt==3:
                data=mbias
                title='(e) Mean AOD bias'
                pltcolor=pltcolor2
                leglist=leglist2
            elif ipt==4:
                data=rmse
                title='(c) RMSE against VIIRS 550 nm AOD'
                ylab='RMSE'
                pltcolor=pltcolor2
                leglist=leglist2
            elif ipt==5:
                data=mrmse
                title='(f) Mean AOD RMSE'
                ylab='RMSE'
                pltcolor=pltcolor2
                leglist=leglist2
    
            if np.mod(ipt, 2) == 0:
                ax.set_prop_cycle(color=pltcolor)
                ax.plot(dates,data, lw=2)
                ax.xaxis.set_major_formatter(formatter)
                ax.xaxis.set_tick_params(labelsize=12)
                ax.yaxis.set_tick_params(labelsize=12)
                ax.set_ylabel(ylab,fontsize=12)
                ax.grid(color='lightgrey', linestyle='--', linewidth=1)
                ax.set_title(title, loc='center',fontsize=14)
                if ipt==0:
                    #ax.set_ylim(0.02, 0.32)
                    lgd=ax.legend(leglist, fontsize=12, loc='upper left', ncol=3, frameon=False)
                #lgd=ax.legend(leglist,fontsize=14, ncol=3, bbox_to_anchor=(0.5, -0.12), loc='upper center', frameon=False)
            else:
                print(leglist)
                print(data)
                meanfile=f'mean_{ylab}_{dayst}_{dayed}_{mask}.txt'
                with open(meanfile, 'w') as fp:
                    fp.write('\t'.join(leglist))
                    fp.write('\n')
                    fp.write('\t'.join(str(item) for item in data))
                ax.bar(leglist, data, color=pltcolor)
                ax.set_title(title, loc='center',fontsize=14)
                plt.xticks(rotation=270)
    fig.tight_layout()
    fig.savefig(f'aod_bias_rmse_{mask}.png', format='png',bbox_inches='tight')
    return

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

def plot_scatter(rmse, spread, expleg, spnum, vmax):
    nmasks, ndays = rmse.shape
    fsize=14
    fig=plt.figure(figsize=[6,6])
    ax=fig.add_subplot(111)
    ax.set_title(expleg, fontsize=fsize)
    for iplt in range(nmasks):
        plt.scatter(spread[iplt, spnum:], rmse[iplt, spnum:], s=20, marker='o', color=cols[iplt])
    m, b=np.polyfit(spread[:,spnum:].flatten(), rmse[:,spnum:].flatten(), 1)
    num = len(rmse[:,spnum:])
    mspread = np.mean(spread[:,spnum:])
    mrmse = np.mean(rmse[:,spnum:])
    ms2r=mspread/mrmse
    afit=np.array([0.0, vmax])
    plt.plot(afit, m*afit+b, color='gray', linewidth=2, linestyle='--')
    plt.xlim(0, vmax)
    plt.ylim(0, vmax)
    plt.plot([0.0, vmax],[0.0, vmax], color='black', linewidth=2, linestyle='--')

    lm=str("%.4f" % m)
    lb=str( "%.4f" % b)
    ln=str(num)
    ls=str("%.4f" % mspread)
    lr=str("%.4f" % mrmse)
    ls2r=str("%.4f" % ms2r)

    txt=f'num = {ln}'
    plt.text(vmax*0.5, vmax*0.26, txt, fontsize=fsize)
    txt=f'mSPREAD = {ls}'
    plt.text(vmax*0.5, vmax*0.20, txt, fontsize=fsize)
    txt=f'mRMSE = {lr}'
    plt.text(vmax*0.5, vmax*0.14, txt, fontsize=fsize)
    txt=f'mS2R = {ls2r}'
    plt.text(vmax*0.5, vmax*0.08, txt, fontsize=fsize)
    txt=f'Y = {lm} X + {lb}'
    plt.text(vmax*0.5, vmax*0.02, txt, fontsize=fsize)
    plt.grid(alpha=0.5)
    plt.xlabel('Spread', fontsize=fsize)
    plt.ylabel('RMSE', fontsize=fsize)
    plt.xticks(fontsize=fsize)
    plt.yticks(fontsize=fsize)
    plt.savefig('%s-err-spread-scatter.png' % (expleg), format='png')
    return

def plot_bargrp(data1,data2):
    #nbars=len(xleg)
    #['DA', 'DA-SPE', 'DA-SPE3']
    xlegs = ['DA', 'DA-SPE', 'DA-SPE3']
    x=np.arange(len(xlegs))
    width=0.35
    fig, ax=plt.subplots()
    rs1=ax.bar(x-width/2,data1,width, label='RMSE', color='black')
    rs2=ax.bar(x+width/2,data2,width, label='Spread', color='grey')
    ax.set_ylabel('AOD RMSE/Spread', fontsize=16)
    ax.set_title('Globally Ave. BckgEns AOD RMSE/Spread', fontsize=14)
    ax.set_xticks(x)
    ax.set_xticklabels(xlegs, fontsize=18)
    ax.legend(fontsize=12)

    #ax.bar_label(rs1, padding=3)
    #ax.bar_label(rs2, padding=3)

    #plt.grid(linestyle='-', linewidth=0.2, color='grey')
    plt.ylim(0.10, 0.16)
    plt.yticks(fontsize=14)
    plt.grid(alpha=0.5)
    
    #fig.tight_layout()
    plt.savefig('RMSE-Spread-Bar.png', format='png')

    return

def plot_bar_scatter(rmse, spread, rmsem, spreadm, expleg, nmasks, cols):
    fig=plt.figure(figsize=[8,8])
    fsize1=12
    fsize2=14
    for ipt in range (4):
        ax=fig.add_subplot(2,2,ipt+1)
        if ipt==0:
            xlegs=['RET-DA', 'RET-DA-SPE', 'RET-DA-SPE3']
            x=np.arange(len(xlegs))
            width=0.35
            print(rmsem)
            print(spreadm)
            rs1=ax.bar(x-width/2,rmsem,width, label='RMSE', color='green')
            rs2=ax.bar(x+width/2,spreadm,width, label='Spread', color='blue')
            ax.set_ylabel('AOD RMSE/Spread', fontsize=fsize1)
            ax.set_title('(a) Mean AOD RMSE/Spread', fontsize=fsize2)
            ax.set_xticks(x)
            ax.set_xticklabels(xlegs, fontsize=fsize1)
            #ax.legend(fontsize=fsize1)
            ax.legend(ncol=2,loc="upper right", frameon=False, fontsize=fsize1)
            plt.ylim(0.10, 0.17)
            plt.yticks(fontsize=fsize1)
            plt.xticks(rotation=-20)
            plt.grid(alpha=0.5)
        else:
            for imask in range(nmasks):
                plt.scatter(spread[:,imask,ipt-1], rmse[:,imask,ipt-1], s=10, marker='o', color=cols[imask])
            m, b=np.polyfit(spread[:,:,ipt-1].flatten(), rmse[:,:,ipt-1].flatten(), 1)
            afit=np.array([0.0, 0.5])
            plt.plot(afit, m*afit+b, color='gray', linewidth=2, linestyle='--')
            lm=print("%.4f" % m)
            lb=print( "%.4f" % b)
            fitfun='Y = %s X + %s' % (str("%.4f" % m), str("%.4f" % b))
            plt.xlim(0, 0.5)
            plt.ylim(0, 0.5)
            plt.plot([0.0, 0.5],[0.0, 0.5], color='black', linewidth=2, linestyle='--')
            plt.grid(alpha=0.5)
            plt.text(0.1, 0.02, fitfun, fontsize=fsize2)
            plt.xlabel('Spread', fontsize=fsize1)
            plt.ylabel('RMSE', fontsize=fsize1)
            plt.xticks(fontsize=fsize1)
            plt.yticks(fontsize=fsize1)
            ax.set_title(expleg[ipt-1], fontsize=fsize2)
    plt.tight_layout()
    plt.savefig('F07-rmse-spread.eps', format='eps')
    plt.close(fig)
    return

"""
expdir='/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/'
expnames=[\
	  'VIIRSAOD_JEDI_ENVAR_LETKF_yesRecenter_C96_C96_M20_CCPP2_noEmisSPPT_noPert_noAmp_test1_201606', \
          'VIIRSAOD_JEDI_ENVAR_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606', \
          'VIIRSAOD_JEDI_ENVAR_VTSM3_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606' \
		]
explegs=['(b) RET-DA', '(c) RET-DA-SPE', '(d) RET-DA-SPE3']
masks=[ 'NAFRME', \
       'CONUS', 'EASIA', 'SAFRTROP', 'RUSC2S', \
       'NATL', 'NPAC', 'SATL', 'SPAC', 'INDOCE']
cols=['goldenrod', \
	 'red', 'firebrick', 'lightcoral', 'tomato', \
	 'dodgerblue', 'lightskyblue', 'cadetblue', 'steelblue', 'darkturquoise']

aodtyp='VIIRS'
cyc1='runs_VIIRS_2016060100_2021063018'
cyc2='2016060100-2021063018'
nexps=len(expnames)
nmasks=len(masks)
ns=7


grmse=np.zeros((29,nexps),dtype='float')
gspread=np.zeros((29,nexps),dtype='float')
armse=np.zeros((22,nmasks,nexps),dtype='float')
aspread=np.zeros((22,nmasks,nexps),dtype='float')
for iexp in range(nexps):
    expname=expnames[iexp]
    expleg=explegs[iexp]
    rmse=np.zeros((29,nmasks),dtype='float')
    spread=np.zeros((29,nmasks),dtype='float')
    for imask in range(nmasks):
        mask=masks[imask]
        if expname == 'VIIRSAOD_JEDI_ENVAR_VTSM3_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606':
            datafile='%s/%s/diagnostics/mask-spread/%s/VTSM-%s-M60-ensmBkg-%sAOD-nloc-obs-hofx-R-bias-mse-HPH-HPHplusR-Cyc-%s_%s.txt' \
                      % (expdir, expname, cyc1, expname, aodtyp, cyc2, mask)
            #datafile='%s/%s/diagnostics/mask-spread/%s/%s-M20-ensmBkg-%sAOD-nloc-obs-hofx-R-bias-mse-HPH-HPHplusR-Cyc-%s_%s.txt' \
	    #         % (expdir, expname, cyc1, expname, aodtyp, cyc2, mask)
        else:
            datafile='%s/%s/diagnostics/mask-spread/%s/%s-M20-ensmBkg-%sAOD-nloc-obs-hofx-R-bias-mse-HPH-HPHplusR-Cyc-%s_%s.txt' \
	             % (expdir, expname, cyc1, expname, aodtyp, cyc2, mask)
        print(datafile)
        f=open(datafile,'r')
        iline=0
        for line in f.readlines():
            rmse[iline,imask]=float(line.split()[5])
            spread[iline,imask]=float(line.split()[7])
            iline=iline+1
        f.close()
    rmse=np.sqrt(rmse)
    spread=np.sqrt(spread)
    armse[:,:,iexp]=rmse[ns:,:]
    aspread[:,:,iexp]=spread[ns:,:]
    
    mask='GLOBAL'
    if expname == 'VIIRSAOD_JEDI_ENVAR_VTSM3_LETKF_yesRecenter_C96_C96_M20_CCPP2_yesEmisSPPT_yesPert_yesAmp_test1_201606':
        datafile='%s/%s/diagnostics/mask-spread/%s/VTSM-%s-M60-ensmBkg-%sAOD-nloc-obs-hofx-R-bias-mse-HPH-HPHplusR-Cyc-%s_%s.txt' \
                  % (expdir, expname, cyc1, expname, aodtyp, cyc2, mask)
    else:
        datafile='%s/%s/diagnostics/mask-spread/%s/%s-M20-ensmBkg-%sAOD-nloc-obs-hofx-R-bias-mse-HPH-HPHplusR-Cyc-%s_%s.txt' \
                 % (expdir, expname, cyc1, expname, aodtyp, cyc2, mask)
    print(datafile)
    f=open(datafile,'r')
    iline=0
    for line in f.readlines():
        grmse[iline,iexp]=float(line.split()[5])
        gspread[iline,iexp]=float(line.split()[7])
        iline=iline+1
    f.close()
grmse1=grmse[ns:,:]
gspread1=gspread[ns:,:]
grmsem=np.sqrt(grmse1.mean(axis=0))
gspreadm=np.sqrt(gspread1.mean(axis=0))
plot_bar_scatter(armse, aspread, grmsem, gspreadm,  explegs, nmasks, cols)
"""

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
        help="Name of da experiment",
        type=str, required=True)

    required.add_argument(
        '-f', '--nodaexp',
        help="Name of noda experiment",
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


    args = parser.parse_args()
    dayst = args.stday
    dayed = args.edday
    daexp = args.daexp
    nodaexp = args.nodaexp
    rundir = args.toprundir
    aod = args.aodtype
    daysp = str(args.spinupday)[0:8]

    nandayss = [""]

    leglist1=['VIIRS', 'FreeRun',  'DA-cntlBkg', 'DA-cntlAnl', 'DA-emBkg', 'DA-emAnl']
    leglist2=['FreeRun',  'DA-cntlBkg', 'DA-cntlAnl', 'DA-emBkg', 'DA-emAnl']
    pltcolor1=['gray', 'black', 'blue', 'red',  'green', 'darkorange']
    pltcolor2=['black', 'blue', 'red',  'green', 'darkorange']

    masks=['GLOBAL', 'NAFRME', \
           'CONUS', 'EASIA', 'SAFRTROP', 'RUSC2S', \
           'NATL', 'NPAC', 'SATL', 'SPAC', 'INDOCE']


    inc_h=24
    sdate1=dayst #(sdate,-1.*inc_h)
    edate1=ndate(dayed, inc_h)
    syy=int(str(sdate1)[:4]); smm=int(str(sdate1)[4:6])
    sdd=int(str(sdate1)[6:8]); shh=int(str(sdate1)[8:10])
    eyy=int(str(edate1)[:4]); emm=int(str(edate1)[4:6])
    edd=int(str(edate1)[6:8]); ehh=int(str(edate1)[8:10])

    date1 = datetime(syy,smm,sdd)
    date2 = datetime(eyy,emm,edd)
    delta = timedelta(hours=inc_h)
    dates = mdates.drange(date1, date2, delta)

    rule = rrulewrapper(DAILY, byhour=0, interval=2)
    #rule = rrulewrapper(DAILY, count=8)
    loc = RRuleLocator(rule)
    formatter = DateFormatter('%Y %h %n %d')

    print(date1)
    print(date2)
    print(delta)
    print(dates)
    
    chkspnum = True
    for mask in masks:
        obsarr=[]
        hfxarr=[]
        biasarr=[]
        msearr=[]
        chkapp = False
        for expname in [nodaexp, daexp]:
            datadir = f"{rundir}/{expname}/dr-data-backup/"
            if expname == nodaexp:
                fields=['cntlBkg']
            elif expname == daexp:
                fields=['cntlBkg', 'cntlAnl', 'emeanBkg', 'emeanAnl']
            else:
                print('Define expname properly and exit now')
                exit(100)

            for field in fields:
                infile = f"./output/{expname}_{field}_day_nloc_mobs_mhfx_merr2_mbias_mmse_{dayst}_{dayed}_{mask}.txt"
            
                if chkspnum:
                    spnum = get_spinupcyc_num(infile, 0, daysp)
                    chkspnum = False
                datatmp = np.loadtxt(infile)
                obs1, hfx1, bias1, mse1 = datatmp[:,2], datatmp[:,3], datatmp[:,5], datatmp[:,6]
                ncols = obs1.size
                obs = obs1.reshape(ncols,1)
                hfx = hfx1.reshape(ncols,1)
                bias = bias1.reshape(ncols,1)
                mse = mse1.reshape(ncols,1)
                if not chkapp:
                    obsarr, hfxarr, biasarr, msearr = obs, hfx, bias, mse
                    chkapp = True
                else:
                    obsarr = np.concatenate((obsarr, obs), axis=1)
                    hfxarr = np.concatenate((hfxarr, hfx), axis=1)
                    biasarr = np.concatenate((biasarr, bias), axis=1)
                    msearr = np.concatenate((msearr, mse), axis=1)
                    print(obsarr.shape)
        rmsearr = np.sqrt(msearr)   
        plt_aod_bias_rmse_mask_daily(obsarr, hfxarr, biasarr, rmsearr, spnum, dates, formatter,
      	        pltcolor1, pltcolor2, leglist1, leglist2, mask, str(dayst)[0:8], str(dayed)[0:8])


