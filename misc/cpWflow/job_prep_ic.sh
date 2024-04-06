#!/bin/bash

DATADIR=/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/RET_EP4_SpinUp_NoSfcanl_v15_0delz_41M_C96_202005/dr-data
ICDIR=/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/RET_EP4_SpinUp_41M_C96_202005/dr-data/IC/CHGRES/
CYCLE="2020052606"
CYMD=${CYCLE:0:8}
CH=${CYCLE:8:2}
NMEM=40

mkdir -p ${DATADIR}/../dr-work

IMEM=0
while [ ${IMEM} -le ${NMEM} ]; do
    if [ ${IMEM} -eq '0' ]; then
        MEMSTR=""
        ENKOPT=""
    else
        MEMSTR=mem`printf %03d ${IMEM}`
        ENKOPT="enkf"
    fi
    SRCDIR=${ICDIR}/${ENKOPT}gdas.${CYMD}/${CH}/atmos/${MEMSTR}/INPUT
    TGTDIR=${DATADIR}/${ENKOPT}gdas.${CYMD}/${CH}/${MEMSTR}/model_data/atmos/input

    [[ ! -d ${TGTDIR} ]] && mkdir -p ${TGTDIR}
    echo ${SRCDIR} 
    echo ${TGTDIR}
    cp ${SRCDIR}/* ${TGTDIR}/

    IMEM=$((IMEM+1))
done
