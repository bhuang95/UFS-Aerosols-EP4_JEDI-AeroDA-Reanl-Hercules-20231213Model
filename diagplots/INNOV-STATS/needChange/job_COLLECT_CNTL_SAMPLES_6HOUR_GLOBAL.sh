#!/bin/bash
#SBATCH -J innov_stats
#SBATCH -A wrf-chem
#SBATCH -o /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/innov_stats.out
#SBATCH -e /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/innov_stats.out
#SBATCH -n 1
#SBATCH -p service
#SBATCH -t 00:30:00

set -x
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

curdir=`pwd`
aod=NOAA_VIIRS_npp
cycst=2017100600
cyced=2017102718
spinupcyc=2017101000 # number of cycles
topexpdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc
nodaexp=FreeRun-201710
daexp=ENKF_AEROSEMIS-ON_STOCHINIT-ON-201710
topplotdir=${topexpdir}/${daexp}/diagplots/INNOV-STATS/
rundir=${topplotdir}/${aod}-6hour-global-${cycst}-${cyced}/
#/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/AeroDA-1C192-20C192-201710/diagplots/HOFX-STATS/
expnames="
    ${nodaexp}
    ${daexp}
"

pyclecsamp=COLLECT_CNTL_SAMPLES_6HOUR_GLOBAL.py
pypltstats=PLOT_AOD_STATS_6HOUR_GLOBAL.py

aeroda="True"
emeandiag="True"
for expname in ${expnames}; do
    if [ ${expname} = ${nodaexp} ]; then
        aeroda="False"
        emeandiag="False"
    else
        aeroda="True"
        emeandiag="True"
    fi

    expdir=${rundir}/${expname} 
    [[  -d ${expdir} ]] && rm -rf ${expdir}
    mkdir -p ${expdir}

    echo ${expdir}
    cd ${expdir}
    cp -r ${curdir}/${pyclecsamp} ./

    python ${curdir}/${pyclecsamp} -i ${cycst} -j ${cyced} -a ${aeroda} -m ${emeandiag} -e ${expname} -d ${topexpdir} -t ${aod}
    
#cat << EOF > job_${expname}.s
##!/bin/bash
##SBATCH -J nemsio2nc_run 
##SBATCH -A wrf-chem
##SBATCH -o /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/${expname}_hfxstats.out
##SBATCH -e /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/${expname}_hfxstats.out
##SBATCH -n 1
##SBATCH -q service
##SBATCH -t 00:30:00
#
#set -x
#module load anaconda/latest
#
#echo \`date\`
#python COLLECT_CNTL_SAMPLES_6H.py -i ${cycst} -j ${cyced} -a ${aeroda} -m ${emean} -e ${expname} -d ${topexpdir}
#ERR=\$?
#echo \`date\`
#
#exit \${ERR}
#EOF
#
#sbatch job_${expname}.sh
done

cd ${rundir}
cp ${curdir}/${pypltstats} ./
python ${pypltstats} -i ${cycst} -j ${cyced} -e ${nodaexp} -f ${daexp} -s ${spinupcyc}
[[ $? -ne 0 ]] && exit 100

exit 0

