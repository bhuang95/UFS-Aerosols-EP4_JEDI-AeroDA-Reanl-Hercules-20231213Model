#!/bin/bash
#SBATCH -J innov_stats
#SBATCH -A wrf-chem
#SBATCH -o /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/innov_stats.out
#SBATCH -e /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/innov_stats.out
#SBATCH -n 1
#SBATCH -p service
#SBATCH -t 05:30:00

set -x
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

curdir=`pwd`
aod=NOAA_VIIRS_npp
#cycst=2017100600 # Starting cycle
#cyced=2017102700 # Ending cycle
#spcyc=2017101000 # Starting cycle to perform averaging in the stats 
cycst=2020060100 # Starting cycle
cyced=2020062300 # Ending cycle
spcyc=2020060800 # Starting cycle to perform averaging in the stats 
topexpdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/
        # Define run directory

# It plots time-series and bars for AOD, bias and RMSE, scattering plot of RMSE vs spread over different regions. 
# In this diagnostics, ${nodaexp} and ${daexp} are both needed. All four cycles at 00/06/12/18Z at a certain day
# 	has to be available. Otherwise, it will crash. 
#nodaexp=FreeRun-201710 
nodaexp=RET_FreeRun_NoEmisStoch_C96_202006
	# Define free experiment. 
        # If using my free run, link /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/FreeRun-201710/dr-data-backup/ to your ${topexpdir}
#daexps="
#	ENKF_AEROSEMIS-ON_STOCH_MODIFIED_INIT-ON-201710_bc_1.5
#	"
daexps="
	RET_AeroDA_NoEmisStoch_C96_202006
	RET_AeroDA_YesEmisStoch-CNTL-ENKF_C96_202006_bc1.5
	"

        #ENKF_AEROSEMIS-OFF-201710 
        #ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710
        #ENKF_AEROSEMIS-ON_STOCHINIT-ON-201710 
	#ENKF_AEROSEMIS-ON_STOCH_MODIFIED_INIT-ON-201710
	# Define your DA experiments.
	# If using my ENKF_AEROSEMIS-OFF-201710, ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710, 
	# link their dr-data-backup under /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ to your ${topexpdir}. 

pycleccntl=COLLECT_CNTL_EMEAN_SAMPLES_DAILY_MASK.py
pyclecens=COLLECT_ENS_SPREAD_SAMPLES_DAILY_MASK.py
pypltens=PLT_ENS_RMSE_SPREAD_DAILY_MASK.py
pypltcntl=PLT_AOD_STATS_DAILY_MASKS.py
pypltscaling=PLT_SCALING_FACTOR_DAILY_MASK.py

for daexp in ${daexps}; do
    expdir=${topexpdir}/${daexp}
    plotdir=${expdir}/diagplots/INNOV-STATS/${aod}-daily-masks-${cycst}-${cyced}/


    [[ ! -d ${plotdir} ]] && mkdir -p ${plotdir}
    cd ${plotdir}

    ln -sf ${curdir}/masks ./
    [[ ! -d output ]] && mkdir -p output

    # Collect cntl and emean obs, hfx, bias, mse over masks
    cp -r ${curdir}/${pycleccntl} ./
    python ${pycleccntl} -i ${cycst} -j ${cyced} -e ${daexp} -f ${nodaexp} -d ${topexpdir} -a ${aod} 
    [[ $? -ne 0 ]] && exit 100

    # Collect ensemble spread samples over masks
    cp -r ${curdir}/${pyclecens} ./
    python ${pyclecens} -i ${cycst} -j ${cyced} -e ${daexp} -d ${topexpdir} -a ${aod}
    [[ $? -ne 0 ]] && exit 100

    # Plot ensemble spread-error consistency over masks
    cp -r ${curdir}/${pypltens} ./
    python ${pypltens} -i ${cycst} -j ${cyced} -e ${daexp} -d ${topexpdir} -a ${aod} -s ${spcyc}
    [[ $? -ne 0 ]] && exit 100
    [[ ! -d figures ]] && mkdir -p figures
    mv *.png ./figures/
    mv *.txt ./figures/

    # Plot cntl and ensemean stats over masks
    cp -r ${curdir}/${pypltcntl} ./
    python ${pypltcntl} -i ${cycst} -j ${cyced} -e ${daexp} -f ${nodaexp} -d ${topexpdir} -a ${aod} -s ${spcyc}
    [[ $? -ne 0 ]] && exit 100
    [[ ! -d figures ]] && mkdir -p figures
    mv *.png ./figures/
    mv *.txt ./figures/

    # Plot AOD and HFX bar plot for scaling plot 
    cp -r ${curdir}/${pypltscaling} ./
    AERODA=YES
    python ${pypltscaling} -i ${cycst} -j ${cyced} -e ${daexp} -f ${AERODA} -d ${topexpdir} -a ${aod} -s ${spcyc}
    [[ $? -ne 0 ]] && exit 100
    [[ ! -d figures ]] && mkdir -p figures
    mv *.png ./figures/
    mv *.txt ./figures/

    # Plot AOD and HFX bar plot for scaling plot 
    cp -r ${curdir}/${pypltscaling} ./
    AERODA=NO
    python ${pypltscaling} -i ${cycst} -j ${cyced} -e ${nodaexp} -f ${AERODA} -d ${topexpdir} -a ${aod} -s ${spcyc}
    [[ $? -ne 0 ]] && exit 100
    [[ ! -d figures ]] && mkdir -p figures
    mv *.png ./figures/
    mv *.txt ./figures/
done
exit 0


