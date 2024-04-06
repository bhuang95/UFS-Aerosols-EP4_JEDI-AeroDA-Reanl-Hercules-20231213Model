#!/bin/bash

SRCDIR=/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/Bo.Huang/RUNDIRS/cycExp_ATMA_warm/2020122100/gdas/fcst.86091/INPUT
DETDIR=/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/Bo.Huang/RUNDIRS/RET_EP4_SpinUp_C96_202005/2020052612/gdas/fcst.104674/INPUT

cd ${SRCDIR}
FILES=$(ls *)

for FILE in ${FILES}; do
    diff ${SRCDIR}/${FILE} ${DETDIR}/${FILE}
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "${FILE} differ ..."
    fi
done
