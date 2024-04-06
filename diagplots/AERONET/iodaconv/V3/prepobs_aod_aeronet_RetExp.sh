#!/bin/bash --login 
#SBATCH -A chem-var
#SBATCH -q batch
#SBATCH -n 1
#SBATCH -J aeronet_ioda
#SBATCH -p service
#SBATCH -t 00:59:00
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/tmprun/aeronet_ioda.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/tmprun/aeronet_ioda.out

set -x

SDATE=2020071006   #2018011006  #2017120100
EDATE=2020073118  #2018013118  #2018011000
CYCINC=6

PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_RETcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl"}
HOMEioda=${HOMEioda:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/ioda-bundle/ioda-bundle-20230809/build"}
EXPDIR=${EXPDIR:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/"}
TASKRC=${TASKRC:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/TaskRecords/cmplCycle_misc.rc"}
OBSDIR_NRT=${OBSDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/AODObs"}
CDATE=${CDATE:-"2023080400"}
CDUMP=${CDUMP:-"gdas"}
CYCINTHR=${CYCINTHR:-"6"}
PYEXE=${HOMEgfs}/ush/python/aeronet_lunar_aod2ioda_v3_Intp550nm.py
NDATE='/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate'

AODTYPE=${AODTYPE:-"AERONET"}
AODLEV=${AODLEV:-"AOD15"}
AODWINHR=${AODWINHR:-"1"}
AODLIGHT=${AODLIGHT:-"SOLAR"}
AOD550NM=${AOD550NM:-"YES"}
MISS_AERONET_RECORD=${MISS_VIIRS_RECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/TaskRecords/record.miss_AERONET_AOD16"}
OBSDIR_NRT=${OBSDIR_NRT}/${AODTYPE}_${AODLIGHT}_${AODLEV};

if [ ${AODLIGHT} = 'SOLAR' ]; then
    AODLUNAR='NO'
elif [ ${AODLIGHT} = 'LUNAR' ]; then
    AODLUNAR='YES'
else
    echo "Define AODLIGHT as SOLAR or LUNAR only"
    exit 100
fi


source ${HOMEioda}/jedi_module_base.hera.sh
status=$?
[[ $status -ne 0 ]] && exit $status

export PYTHONPATH=${PYTHONPATH}:"${HOMEioda}/lib/"
export PYTHONPATH=${PYTHONPATH}:"${HOMEioda}/lib/python3.9/"
export PYTHONPATH=${PYTHONPATH}:"${HOMEioda}/iodaconv/src"
export PYTHONPATH=${PYTHONPATH}:"${HOMEgfs}/ush/python/libs/pytspack/"

#STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
#export RUNDIR="$STMP/RUNDIRS/$PSLOT"
#export DATA="$RUNDIR/$CDATE/$CDUMP/prepaodobs_AERONET_$$"
DATA=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/tmprun/aeronet_aod


CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA 
TGTDIR=${OBSDIR_NRT}/${CDATE}
TGTFILE=${AODTYPE}_${AODLIGHT}_${AODLEV}_AOD.${CDATE}.iodav3.nc
[[ ! -d ${TGTDIR} ]] && mkdir -p ${TGTDIR}

/bin/cp -r ${PYEXE} aeronet_iodav3.py
python aeronet_iodav3.py -t ${CDATE} -w ${AODWINHR} -l ${AODLUNAR} -q ${AODLEV} -p ${AOD550NM} -o aeronet_iodav3.nc

ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "aeronet.py failed at ${CDATE} and exit!"
    exit 1
else
    echo "aeronet.py succeeded at ${CDATE} and proceed to next step!"
    /bin/mv aeronet_iodav3.nc ${TGTDIR}/${TGTFILE}
fi

rm -rf ${DATA}
CDATE=$(${NDATE} ${CYCINC} ${CDATE})
done
#echo ${CDATE} > ${TASKRC}
#exit ${ERR}
