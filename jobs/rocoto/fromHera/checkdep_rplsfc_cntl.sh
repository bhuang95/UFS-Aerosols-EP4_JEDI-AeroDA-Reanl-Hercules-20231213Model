#!/bin/bash 
set -x
CDATE=${CDATE:-"2023062400"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
CYCINTHR=${CYCINTHR:-"06"}
NTILES=${NTILES:-"6"}
NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}

NTOT=${NTILES}

GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})

CYY=$(echo "${CDATE}" | cut -c1-4)
CMM=$(echo "${CDATE}" | cut -c5-6)
CDD=$(echo "${CDATE}" | cut -c7-8)
CHH=$(echo "${CDATE}" | cut -c9-10)


GYY=$(echo "${GDATE}" | cut -c1-4)
GMM=$(echo "${GDATE}" | cut -c5-6)
GDD=$(echo "${GDATE}" | cut -c7-8)
GHH=$(echo "${GDATE}" | cut -c9-10)

ecode=0
nfiles=$(ls ${ROTDIR}/gdas.${CYY}${CMM}${CDD}/${CHH}/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.sfcanl_data.tile?.nc | wc -l)
if [ ${nfiles} != ${NTOT} ]; then
    ecode=$((ecode+1))
fi

nfiles=$(ls ${ROTDIR}/gdas.${GYY}${GMM}${GDD}/${GHH}/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.sfc_data.tile?.nc | wc -l)
if [ ${nfiles} != ${NTOT} ]; then
    ecode=$((ecode+1))
fi

exit ${ecode}
