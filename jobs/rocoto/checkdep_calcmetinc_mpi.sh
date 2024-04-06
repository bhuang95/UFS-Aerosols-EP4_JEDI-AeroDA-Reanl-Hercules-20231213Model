#!/bin/bash 
set -x
CDATE=${CDATE:-"2023062400"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
METDIR_NRT=${METDIR_NRT:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/test/"}
NMEM_ENKF=${NMEM_ENKF:-"20"}
CASE_ENKF=${CASE_ENKF:-"C192"}
CYCINTHR=${CYCINTHR:-"06"}
ENSRUN=${ENSRUN:-"YES"}
NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}

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
[[ ! -f ${ROTDIR}/gdas.${CYY}${CMM}${CDD}/${CHH}/analysis/atmos/gdas.t${CHH}z.atmanl.nc ]] && ecode=$((ecode+1))

[[ ! -f ${ROTDIR}/gdas.${GYY}${GMM}${GDD}/${GHH}/model_data/atmos/history/gdas.t${GHH}z.atmf006.nc ]] && ecode=$((ecode+1))

if [ ${ENSRUN} = "YES" ]; then

    nfiles=$(ls ${ROTDIR}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/mem???/analysis/atmos/enkfgdas.t${CHH}z.ratmanl.nc | wc -l)
    if [ ${nfiles} != ${NMEM_ENKF} ]; then
        ecode=$((ecode+1))
    fi

    nfiles=$(ls ${ROTDIR}/enkfgdas.${GYY}${GMM}${GDD}/${GHH}/mem???/model_data/atmos/history/enkfgdas.t${GHH}z.atmf006.nc | wc -l)
    if [ ${nfiles} != ${NMEM_ENKF} ]; then
        ecode=$((ecode+1))
    fi
fi

exit ${ecode}
