#!/bin/bash

#rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-work/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.db
#set -x

RORUNCMD="/apps/contrib/rocoto/1.3.6/bin/rocotostat"
XMLDIR="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/dr-work-mpi/xmlFiles"
DBDIR="/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/xmlDB"

EXPS="
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801_LongFcst
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801_LongFcst_Diag
AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801_LongFcst
AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801_LongFcst_Diag
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007_LongFcst
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007_LongFcst_Diag
AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202007_LongFcst
AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202007_LongFcst_Diag
"

#EXP=$1
for EXP in ${EXPS};
do
#echo "${RORUNCMD} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db"
echo ${EXP}
#${RORUNCMD} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db | less
${RORUNCMD} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db
done
