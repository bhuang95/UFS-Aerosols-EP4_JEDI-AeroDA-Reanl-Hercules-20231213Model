#!/bin/bash

#rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-work/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.db
#set -x

RUNDIR="/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/"

EXPS="
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801
AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007
AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202007
"

FIELDS="
dr-data-longfcst
dr-data-longfcst-backup
"

#EXP=$1
for EXP in ${EXPS};do
for FIELD in ${FIELDS};do
    EXPDIR=${RUNDIR}/${EXP}/${FIELD}
    echo "****************************************"
    echo ${EXPDIR}
    cd ${EXPDIR}/HERA2HPSS
    ls record*
done
done
