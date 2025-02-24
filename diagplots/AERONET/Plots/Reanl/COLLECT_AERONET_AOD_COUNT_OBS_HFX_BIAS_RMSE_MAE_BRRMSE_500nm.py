import sys,os, argparse
from scipy.stats import gaussian_kde
sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/METplus-diag/METplus_pkg//pyscripts/lib')
os.environ['PROJ_LIB'] = '/contrib/anaconda/anaconda3/latest/share/proj'
import numpy as np
import math

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Print AOD and its hofx in obs space and their difference'
        )
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '-i', '--infile',
        help="Input sample file",
        type=str, required=True)

    required.add_argument(
        '-o', '--outfile',
        help="Output sample file",
        type=str, required=True)

    args = parser.parse_args()
    infile = args.infile
    outfile = args.outfile

    aodmin=0.01
    aodmax=5.0

    f=open(infile,'r')
    iline=0
    lonvec=[]
    latvec=[]
    obsvec=[]
    hfxvec=[]
    for line in f.readlines():
        lon=float(line.split()[0])
        lat=float(line.split()[1])
        obs=float(line.split()[2])
        hfx=float(line.split()[3])
        #if ~np.isnan(obs):
        if obs >= aodmin and obs <= aodmax:
            lonvec.append(lon)
            latvec.append(lat)
            obsvec.append(obs)
            hfxvec.append(hfx)
        iline=iline+1
    f.close()
    lonarr=np.array(lonvec)
    latarr=np.array(latvec)
    obsarr=np.array(obsvec)
    hfxarr=np.array(hfxvec)
    
    bias_all=hfxarr-obsarr
    biasm_all=np.nanmean(bias_all)
    maem_all=np.nanmean(np.absolute(bias_all))
    rmsem_all=np.sqrt(np.nanmean(np.square(bias_all)))
    brrmsem_all=np.sqrt(np.nanmean(np.square(bias_all-biasm_all)))
    #meanarr=np.empty([1,4])
    #meanarr[0,:]=[biasm_all, rmsem_all, maem_all, brrmsem_all]

    lonlatarr=np.column_stack([lonarr, latarr])
    
    lonlat_uni,indices_uni=np.unique(lonlatarr, axis=0, return_inverse='True')
    npts=len(lonlat_uni)
    iptarr=np.empty([npts,9])
    for ipt in range(npts):
        lonlat_ipt=lonlat_uni[ipt]
        indice_ipt=np.where(indices_uni==ipt)
        count_ipt=np.size(indice_ipt)  #len(indice_ipt)
        obs_ipt=obsarr[indice_ipt]
        hfx_ipt=hfxarr[indice_ipt]
        obsm_ipt=np.nanmean(obs_ipt)
        hfxm_ipt=np.nanmean(hfx_ipt)
        bias_ipt=hfx_ipt-obs_ipt
        biasm_ipt=np.mean(bias_ipt)
        if count_ipt > 1:
            rmsem_ipt=np.sqrt(np.nanmean(np.square(bias_ipt)))
            brrmsem_ipt=np.sqrt(np.nanmean(np.square(bias_ipt-biasm_ipt)))
        else:
            rmsem_ipt=np.absolute(bias_ipt)
            brrmsem_ipt=0
        maem_ipt=np.mean(np.absolute(bias_ipt))
        iptarr[ipt,:]=[lonlat_ipt[0], lonlat_ipt[1], count_ipt, obsm_ipt, hfxm_ipt, biasm_ipt, rmsem_ipt, maem_ipt, brrmsem_ipt]
    np.savetxt(outfile, iptarr, fmt='%12.6f')
