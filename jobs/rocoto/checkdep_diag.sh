#!/bin/bash 
set -x
CDATE=${CDATE:-"2023062400"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
NTILES=${NTILES:-"6"}
CYCINTHR=${CYCINTHR:-"06"}
ENSRUN=${ENSRUN:-"YES"}
AERODA=${AERODA:-"YES"}
#NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
NDATE=${HOMEgfs}/misc/ndate/ndate

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

ntiles1=$(ls ${ROTDIR}/gdas.${GYY}${GMM}${GDD}/${GHH}/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.fv_tracer.res.tile?.nc | wc -l)
if [ ${ntiles1} != ${NTILES} ]; then
    ecode=$((ecode+1))
fi

if [ ${AERODA} = "YES" ]; then
    ntiles1=$(ls ${ROTDIR}/gdas.${GYY}${GMM}${GDD}/${GHH}/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.fv_tracer_aeroanl.res.tile?.nc | wc -l)
    if [ ${ntiles1} != ${NTILES} ]; then
        ecode=$((ecode+1))
    fi
fi

#if [ ${ENSRUN} = "YES" ]; then
#    ntiles1=$(ls ${ROTDIR}/enkfgdas.${GYY}${GMM}${GDD}/${GHH}/ensmean/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.fv_tracer.res.tile?.nc | wc -l)
#    if [ ${ntiles1} != ${NTILES} ]; then
#        ecode=$((ecode+1))
#    fi

#    if [ ${AERODA} = "YES" ]; then
#        ntiles1=$(ls ${ROTDIR}/enkfgdas.${GYY}${GMM}${GDD}/${GHH}/ensmean/model_data/atmos/restart/${CYY}${CMM}${CDD}.${CHH}0000.fv_tracer_aeroanl.res.tile?.nc | wc -l)
#        if [ ${ntiles1} != ${NTILES} ]; then
#             ecode=$((ecode+1))
#        fi
#    fi
#fi

exit ${ecode}
