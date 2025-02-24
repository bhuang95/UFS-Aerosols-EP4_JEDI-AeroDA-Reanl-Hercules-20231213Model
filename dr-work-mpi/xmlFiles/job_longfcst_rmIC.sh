#!/bin/bash

#rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-work/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.db
#set -x

RUNDIR="/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/"
NDATE="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/misc/ndate/ndate"
EXPS="
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801
AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007
AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202007
"

ICS_201801="
2018100100 
2018101500
"

ICS_202007="
2021040100 
2021041500
"

#EXP=$1
for EXP in ${EXPS};do
if ( echo ${EXP} | grep 201801); then
    ICS=${ICS_201801}
fi
if ( echo ${EXP} | grep 202007); then
    ICS=${ICS_202007}
fi
for IC in ${ICS};do
    IC1=$(${NDATE} -6 ${IC})
    IC1DIR=${RUNDIR}/${EXP}/dr-data-fromHPSS/${IC1}
    ICDIR=${RUNDIR}/${EXP}/dr-data-fromHPSS/${IC}
    echo ${IC1DIR}
    echo ${ICDIR}
    rm -rf ${IC1DIR}
    rm -rf ${ICDIR}
done
done
