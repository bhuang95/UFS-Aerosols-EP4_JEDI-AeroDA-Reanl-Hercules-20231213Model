#!/bin/bash

#SRCDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/global-workflow/comrot/cycExp_ATMA_warm/gdas.20201220/18/model_data/atmos/restart/
#DETDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/global-workflow/comrot/cycExp_ATMA_warm/gdas.20201220/18/model_data/atmos/restart/
#SRCPRE="20201221.000000.fv_tracer.res"
#DETPRE="20201221.000000.fv_tracer_aeroanl.res"
SRCDIR=/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/RET_EP4_AeroDA_YesSPE_41M_C96_201712/dr-data/gdas.20171130/18/model_data/atmos/restart
DETDIR=${SRCDIR}
SRCPRE="20171201.000000.fv_tracer.res"
DETPRE="20171201.000000.fv_tracer_aeroanl.res"

NTILES=6

[[ ! -d ${DETDIR} ]] && mkdir -p ${DETDIR}

NCP="/bin/cp -r"
ITILE=1
while [ ${ITILE} -le ${NTILES} ]; do
    SRCFILE=${SRCDIR}/${SRCPRE}.tile${ITILE}.nc 
    DETFILE=${DETDIR}/${DETPRE}.tile${ITILE}.nc 
    echo ${SRCFILE}
    echo ${DETFILE}
    ${NCP} ${SRCFILE} ${DETFILE}
    ERR=$?
    echo ${ERR}
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    ITILE=$((ITILE+1))
done
