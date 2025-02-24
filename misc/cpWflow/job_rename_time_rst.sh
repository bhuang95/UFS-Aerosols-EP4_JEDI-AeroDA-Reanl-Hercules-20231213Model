#!/bin/bash

#SRCDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/global-workflow/comrot/cycExp_ATMA_warm/gdas.20201220/18/model_data/atmos/restart/
#DETDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/global-workflow/comrot/cycExp_ATMA_warm/gdas.20201220/18/model_data/atmos/restart/
#SRCPRE="20201221.000000.fv_tracer.res"
#DETPRE="20201221.000000.fv_tracer_aeroanl.res"
SRCDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/RET_EP4_SpinUp_C96_202005/dr-data/gdas.20200526/06/model_data/atmos/restart
DETDIR=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/global-workflow/comrot/cycExp_ATMA_warm/gdas.20201220/18/model_data/atmos/restart
SRCPRE="20200526.120000"
DETPRE="20201221.000000"

cd ${SRCDIR}
FILES=$(ls *.nc)

for FILE in ${FILES}; do
    FILE_DET=$(echo "${FILE}" | sed -e "s/${SRCPRE}/${DETPRE}/g")
    echo ${FILE}
    echo ${FILE_DET}
    cp -r  ${SRCDIR}/${FILE} ${DETDIR}/${FILE_DET}
done
