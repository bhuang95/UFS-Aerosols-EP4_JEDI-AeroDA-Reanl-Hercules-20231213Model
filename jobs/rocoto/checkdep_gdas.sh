#!/bin/bash 
set -x
CDATE=${CDATE:-"2023062400"}
CHGRESHPSSDIR=${CHGRESHPSSDIR:-"/work/noaa/rstprod/bohuang/DataTransfer/FromNiag/AeroReanl/ChgresGDAS/chgres-v15"}
CASE_CNTL=${CASE_CNTL:-"C192"}
CASE_ENKF=${CASE_ENKF:-"C192"}
ENSRUN=${ENSRUN:-"YES"}
NMEMSGRPS=${NMEMSGRPS:-"01-40"}
MISSGDASRECORD=${MISSGDASRECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15/record.chgres_hpss_htar_allmissing_v15"}


if ( grep ${CDATE} ${MISSGDASRECORD} ); then
    echo "GDAS Met data not avaibale on HPSS and continue"
    exit 0
fi

CYY=$(echo "${CDATE}" | cut -c1-4)
CMM=$(echo "${CDATE}" | cut -c5-6)
CDD=$(echo "${CDATE}" | cut -c7-8)
CHH=$(echo "${CDATE}" | cut -c9-10)

CNTLFILE=${CHGRESHPSSDIR}/GDAS_CHGRES_NC_${CASE_CNTL}/${CYY}/${CYY}${CMM}/${CYY}${CMM}${CDD}/gdas.${CDATE}.${CASE_CNTL}.NC.tar
ENKFFILE=${CHGRESHPSSDIR}/ENKFGDAS_CHGRES_NC_${CASE_ENKF}/${CYY}/${CYY}${CMM}/${CYY}${CMM}${CDD}/enkfgdas.${CDATE}.${CASE_ENKF}.NC.${NMEMSGRPS}.tar

ecode=0
#[[ ! -f ${CNTLFILE} ]] && ecode=$((ecode+1))
if test $(find "${CNTLFILE}" -mmin +120)
then
    echo "${CNTLFILE} old enough"
else
    ecode=$((ecode+1))
fi

if [ ${ENSRUN} = "YES" ]; then
#    [[ ! -f ${ENKFFILE} ]] && ecode=$((ecode+1))
    if test $(find "${ENKFFILE}" -mmin +120)
    then
        echo "${CNTLFILE} old enough"
    else
        ecode=$((ecode+1))
    fi
fi

exit ${ecode}
