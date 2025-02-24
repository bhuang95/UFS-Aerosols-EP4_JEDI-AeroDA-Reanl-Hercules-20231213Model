#!/bin/bash

set -x

#rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-work/RET_ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710.db

RORUNCMD="/apps/contrib/rocoto/1.3.6/bin/rocotorun"
XMLDIR="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/dr-work-mpi/xmlFiles/"
DBDIR="/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/xmlDB/"

    #AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801
    #AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801_Diag

    #AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801
    #AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801_Diag

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
#    AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007
#    AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007_Diag
#
#    AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801
#    AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801_Diag
#
#    AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202007
#    AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202007_Diag


for EXP in ${EXPS}; do
    echo "${RORUNCMD} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db"
    ${RORUNCMD} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db
done

#/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/dr-work-mpi/xmlFiles/job_rcml_failed_gdasefcs_cp_enkfana.sh


hh=$(date +%H)
#mm=$(date +%m)
#if [ "${mm}" = "00" ]; then
evenhrs="00 02 04 06 08 10 12 14 16 18 20 22"
oddhrs="01 03 05 07 09 11 13 15 17 19 21 23"
#for hr in ${evenhrs}; do
#if [ "${hh}" = "${hr}" ]; then
#/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/dr-work-mpi/xmlFiles/job_rcml_failed_gdasefcs_resubmit.sh
#fi
#done
#for hr in ${oddhrs}; do
#if [ "${hh}" = "${hr}" ]; then
#/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/dr-work-mpi/xmlFiles/job_rcml_failed_gdasefcs.sh
#fi
#done
#fi
