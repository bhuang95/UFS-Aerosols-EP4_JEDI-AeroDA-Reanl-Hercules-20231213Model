#!/bin/bash --login 
#SBATCH -J EC-AOD
#SBATCH -A chem-var
#SBATCH -p service
#SBATCH -n 1
#SBATCH -t 05:29:00
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/EC_AOD.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/EC_AOD.out

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest
module load nco


#SDATE=2020060100
#EDATE=2020071000
SDATE=2017120100
EDATE=2018011000
INC_HR=6
SRCDIR=$(pwd)
DATADIR="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/AOD-Reanl/CAMSiRA"
DATADIR="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/Reanalysis/camseac4"
NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"
ECAPIPY="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/extApps/miniconda3/bin/python3.9"
PYCODE="download_camseac4_aod.py"

[[ ! -d ${DATADIR} ]] && mkdir -p ${DATADIR}

cd ${DATADIR}
cp ${SRCDIR}/${PYCODE} ./

IDATE=${SDATE}
while [ ${IDATE} -le ${EDATE} ]; do
   echo ${IDATE}
   ${ECAPIPY} ${PYCODE}  -c ${IDATE}
   [[ ${ERR} -ne 0 ]] && exit 100
   IDATE=$(${NDATE} ${INC_HR} ${IDATE})
done

exit 0
