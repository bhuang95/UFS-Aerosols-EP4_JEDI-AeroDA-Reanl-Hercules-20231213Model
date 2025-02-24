#!/bin/bash

#module load rocoto
RUNDIR="/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl"
XMLDIR="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/dr-work-mpi/xmlFiles"
DBDIR="${RUNDIR}/xmlDB/"
NDATE="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/misc/ndate/ndate"

#AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801
#AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801
EXPS="
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007

AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202007
"

FIELDS="
dr-data
dr-data-backup
"


for EXP in ${EXPS}; do
    #CDATE=$(cat ${XMLDIR}/../TaskRecords/cmplCycle_${EXP}.rc)
    LOGS=$(ls -d ${RUNDIR}/${EXP}/dr-data/logs/20???????? | tail -n 1)
    CDATE=$(basename ${LOGS})
    echo "Check DEAD task for ${EXP}-${CDATE}"
    /apps/contrib/rocoto/1.3.6/bin/rocotostat -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db > ${DBDIR}/rstat.log
    DEADTASK=$(grep "DEAD" ${DBDIR}/rstat.log)
    if [ ! -z "${DEADTASK}" ]; then
        echo "#####"
	echo ${DEADTASK}
	echo "#####"
    fi

    #CDATE=${XMLDIR}/../TaskRecords/cmplCycle_${EXP}_Diag.rc
    #CDATE=$(cat ${XMLDIR}/../TaskRecords/cmplCycle_${EXP}_diag.rc)
    LOGS=$(ls -d ${RUNDIR}/${EXP}/dr-data-backup/logs/20???????? | tail -n 1)
    CDATE=$(basename ${LOGS})
    echo "Check DEAD task for ${EXP}_Diag-${CDATE}"
    /apps/contrib/rocoto/1.3.6/bin/rocotostat -w ${XMLDIR}/${EXP}_Diag.xml -d ${DBDIR}/${EXP}_Diag.db > ${DBDIR}/rstat.log
    DEADTASK=$(grep "DEAD" ${DBDIR}/rstat.log)
    if [ ! -z "${DEADTASK}" ]; then
        echo "#####"
	echo ${DEADTASK}
	echo "#####"
    fi
done

exit
for EXP in ${EXPS}; do
    for FIELD in ${FIELDS}; do
	echo "Check failed hera2hpss transfer at ${EXP}-${FIELD}"
	if [ -f ${RUNDIR}/${EXP}/${FIELD}/HERA2HPSS/record.failed_* ]; then
	    FAILEDTASK=$(ls ${RUNDIR}/${EXP}/${FIELD}/HERA2HPSS/record.failed_*)
            echo "#####"
	    echo ${FAILEDTASK}
	    echo "#####"
	fi
    done
done 
