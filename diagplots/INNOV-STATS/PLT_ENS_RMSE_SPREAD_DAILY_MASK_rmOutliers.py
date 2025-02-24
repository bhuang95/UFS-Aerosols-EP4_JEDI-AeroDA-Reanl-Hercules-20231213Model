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
#from ndate import ndate
#from datetime import datetime
#from datetime import timedelta

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

def get_spinupcyc_num(inpre, mask, ind, spinupcyc):
    infile = f"{inpre}{mask}.txt"
    data1d = []
    with open(infile, 'r') as fin:
        for line in fin.readlines():
            data = float(line.split()[ind])
            data1d.append(data)
    return data1d.index(float(spinupcyc))


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
        sdata1=spread[iplt, spnum:]
        rdata1=rmse[iplt, spnum:]
        vind=np.where(rdata1<=0.35)
        sdata=sdata1[vind]
        rdata=rdata1[vind]
        plt.scatter(sdata, rdata, s=20, marker='o', color=cols[iplt])
    sarr1=spread[:,spnum:].flatten()
    rarr1=rmse[:,spnum:].flatten()
    vind=~np.isnan(sarr1)
    sarr2=sarr1[vind]
    rarr2=rarr1[vind]
    vind=np.where(rarr2<=0.35)
    sarr=sarr2[vind]
    rarr=rarr2[vind]
    m, b=np.polyfit(sarr, rarr, 1)
    num = sarr.size
    mspread = np.nanmean(sarr)
    mrmse = np.nanmean(rarr)
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


    args = parser.parse_args()
    dayst = args.stday
    dayed = args.edday
    expname = args.expname
    rundir = args.toprundir
    aod = args.aodtype
    daysp = str(args.spinupday)[0:8]
    datadir = f"{rundir}/{expname}/dr-data-backup/"

    nandayss = [""]

    fields=['ememBkg']
    masks=['GLOBAL', 'NAFRME', \
           'CONUS', 'EASIA', 'SAFRTROP', 'RUSC2S', \
           'NATL', 'NPAC', 'SATL', 'SPAC', 'INDOCE']
    cols=['goldenrod', \
	 'red', 'firebrick', 'lightcoral', 'tomato', \
	 'dodgerblue', 'lightskyblue', 'cadetblue', 'steelblue', 'darkturquoise']

    field = 'cntlBkg'
    inpre_cntl = f"./output/{expname}_{field}_day_nloc_mobs_mhfx_merr2_mbias_mmse_{dayst}_{dayed}_"

    field = 'emeanBkg'
    inpre_emean = f"./output/{expname}_{field}_day_nloc_mobs_mhfx_merr2_mbias_mmse_{dayst}_{dayed}_"

    field = 'ememBkg'
    inpre_emem = f"./output/{expname}_{field}_day_nloc_merr2_mvar_mvartot_{dayst}_{dayed}_"
    
    spnum = get_spinupcyc_num(inpre_cntl, 'GLOBAL', 0, daysp)
    print(spnum)
    print(daysp)

    cntlarr = coll_samples(inpre_cntl, masks, 6)
    emeanarr = coll_samples(inpre_emean, masks, 6)

    eerrarr = coll_samples(inpre_emem, masks, 2)
    evararr = coll_samples(inpre_emem, masks, 3)
    evartotarr = coll_samples(inpre_emem, masks, 4)

    nmasks, ndays = cntlarr.shape
    print(nmasks, ndays)
    clos = ['blue', 'red', 'magenta', 'orange']
    clegs = ['MSE', 'VARTOT', 'EVar', 'R2']
    for im in range(nmasks): 
        mask = masks[im]
        data = np.array([emeanarr[im, :], evartotarr[im, :], evararr[im, :], eerrarr[im, :]])
        plttit = f'{expname}-{mask}'
        plot_err_var_vartot(mask, data, clos, clegs, plttit)
        mdata = np.nanmean(data[:,spnum:], axis=1)
        outfile=f'mean-mse-vartot-var-err2-{dayst}-{dayed}-{mask}.txt'
        with open(outfile, 'w') as fp:
            fp.write('\t'.join(clegs))
            fp.write('\n')
            fp.write('\t'.join(str(item) for item in mdata))

    cntlarr = np.sqrt(cntlarr)
    emeanarr = np.sqrt(emeanarr)
    evartotarr = np.sqrt(evartotarr)
    
    print(cntlarr.shape)
    vmax =  0.4
    expleg = f'{expname}-cntlbkg'
    plot_scatter(cntlarr[1:,:], evartotarr[1:,:], expleg, spnum, vmax)

    expleg = f'{expname}-emeanbkg'
    plot_scatter(emeanarr[1:,:], evartotarr[1:,:], expleg, spnum, vmax)



#plot_bargrp(grmsem, gspreadm)
#ratio=gspreadm/grmsem
#print(ratio)
    #quit()
