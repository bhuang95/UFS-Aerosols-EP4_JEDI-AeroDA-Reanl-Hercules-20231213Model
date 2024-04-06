#!/bin/bash 
set -x
CDATE=${CDATE:-"2023062400"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
METDIR_NRT=${METDIR_NRT:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/test/"}
NMEM_ENKF=${NMEM_ENKF:-"20"}
NTILES=${NTILES:-"6"}
CYCINTHR=${CYCINTHR:-"6"}
NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
SFCANL_RST=${SFCANL_RST:-"YES"}
ENSRUN=${ENSRUN:-"YES"}
MISSGDASRECORD=${MISSGDASRECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15/record.chgres_hpss_htar_allmissing_v15"}

if ( grep ${CDATE} ${MISSGDASRECORD} ); then
    echo "GDAS Met data not avaibale on HPSS and continue"
    SFCANL_RST="NO"
fi

if [ ${SFCANL_RST} = "NO" ]; then
    echo "SFCANL_RST=${SFCANL_RST}"
    exit 0
fi

GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})

CYY=$(echo "${CDATE}" | cut -c1-4)
CMM=$(echo "${CDATE}" | cut -c5-6)
CDD=$(echo "${CDATE}" | cut -c7-8)
CHH=$(echo "${CDATE}" | cut -c9-10)


GYY=$(echo "${GDATE}" | cut -c1-4)
GMM=$(echo "${GDATE}" | cut -c5-6)
GDD=$(echo "${GDATE}" | cut -c7-8)
GHH=$(echo "${GDATE}" | cut -c9-10)

NTOT=${NTILES}
ecode=0
nfiles=$(ls ${ROTDIR}/gdas.${CYY}${CMM}${CDD}/${CHH}/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.sfcanl_data.tile?.nc | wc -l)
if [ ${nfiles} != ${NTOT} ]; then
    ecode=$((ecode+1))
fi

nfiles=$(ls ${ROTDIR}/gdas.${GYY}${GMM}${GDD}/${GHH}/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.sfc_data.tile?.nc | wc -l)
if [ ${nfiles} != ${NTOT} ]; then
    ecode=$((ecode+1))
fi

if [ ${ENSRUN} = "YES" ]; then
    NTOT=$((NMEM_ENKF * NTILES))
    ecode=0
    nfiles=$(ls ${ROTDIR}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}//mem???/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.sfcanl_data.tile?.nc | wc -l)
    if [ ${nfiles} != ${NTOT} ]; then
        ecode=$((ecode+1))
    fi

    nfiles=$(ls ${ROTDIR}/enkfgdas.${GYY}${GMM}${GDD}/${GHH}//mem???/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.sfc_data.tile?.nc | wc -l)
    if [ ${nfiles} != ${NTOT} ]; then
        ecode=$((ecode+1))
    fi
fi

exit ${ecode}
