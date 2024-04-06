#!/bin/bash

#rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-work/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.db
set -x

RORUNCMD="/apps/contrib/rocoto/1.3.6/bin/rocotorun"
XMLDIR="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/dr-work-mpi/xmlFiles"
DBDIR="/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/xmlDB"

EXP=$1
#for EXP in ${EXPS}; do
    echo "${RORUNCMD} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db"
    ${RORUNCMD} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db
#done

#TASKS="
#       RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710
#       "
#
#       #NRT-prepEmis 
#       #NRT-prepGDAS 
#       #NRT-freeRun 
#       #NRT-aeroDA
#       #NRT-postDiag-aodObs-freeRun
#       #NRT-postDiag-aodObs-aeroDA
#for TASK in ${TASKS}; do
#    echo "Run ${TASK}"
#    ${RORUNCMD} -w ${XMLDIR_DA}/${TASK}.xml -d ${DBDIR_DA}/${TASK}.db
#done
