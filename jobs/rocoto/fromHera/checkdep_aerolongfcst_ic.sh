#!/bin/bash 
set -x

ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-data-longfcst"}
CDATE=${CDATE:-"2020060100"}
CYCINTHR=${CYCINTHR:-"06"}
NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}

PDATE=$(${NDATE} +${CYCINTHR} ${CDATE})
CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}
CYMD=${CDATE:0:8}

PYMD=${PDATE:0:8}
PH=${PDATE:8:2}

[[ ! -d ${ROTDIR} ]] && mkdir -p ${ROTDIR}
CPLFILE=${ROTDIR}/../dr-data-backup/gdas.${CYMD}/${CH}/model_data/atmos/restart/${PYMD}.${PH}0000.coupler.res

if  test `find ${CPLFILE} -mmin +120` 
then
    ERR=0
    echo "Old enough"
else
    ERR=100
    echo "Not old enough"
fi
echo ${ERR}
exit ${ERR}
