#!/bin/bash

#rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-work/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.db

RORUNCMD="/apps/rocoto/1.3.3/bin/rocotoboot"
XMLDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_RETcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl/dr-work-mpi/xmlFiles/"
DBDIR="/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/"

#EXPS="
#        RET_EP4_SpinUp_41M_C96_202005
#        RET_EP4_SpinUp_41M_C96_201711
#"

EXP=$1
TASK=$2
#for EXP in ${EXPS}; do
    echo "${RORUNCMD} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}/dr-work/${EXP}.db"
    ${RORUNCMD} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}/dr-work/${EXP}.db ${TASK}
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
