#!/bin/bash

#module load rocoto

set -x 

RUNDIR="/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl"
RUNTMP="/work/noaa/zrtrr/bohuang/RUNDIRS"
XMLDIR="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/dr-work-mpi/xmlFiles"
DBDIR="${RUNDIR}/xmlDB/"
NDATE="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/misc/ndate/ndate"
rstat="/apps/contrib/rocoto/1.3.6/bin/rocotostat"
rcmpl="/apps/contrib/rocoto/1.3.6/bin/rocotocomplete"
rboot="/apps/contrib/rocoto/1.3.6/bin/rocotoboot"

#AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801
EXPS="
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007
"

for EXP in ${EXPS}; do
    RECDIR=${XMLDIR}/FAILED_GDASEFCS
    [[ ! -d ${RECDIR} ]] && mkdir -p ${RECDIR}
    EXPREC=${RECDIR}/FAILED_GDASEFCS_${EXP}.record
    LOGS=$(ls -d ${RUNDIR}/${EXP}/dr-data/logs/20???????? | tail -n 1)
    CDATE=$(basename ${LOGS})
    GDATE=$(${NDATE} -6 ${CDATE})
    if [ -d ${RUNTMP}/${EXP}/${GDATE} ]; then
        rm -rf ${RUNTMP}/${EXP}/${GDATE}
    fi
    CYMD=${CDATE:0:8}
    CH=${CDATE:8:2}
    ENKFDIR=${RUNDIR}/${EXP}/dr-data/enkfgdas.${CYMD}/${CH}/
    EXPDIR=${RUNDIR}/${EXP}/dr-data/FAILED_GDASEFCS
    [[ ! -d ${EXPDIR} ]] && mkdir -p ${EXPDIR}
    cd ${EXPDIR}
    if ( ! grep ${CDATE} rstat_resubmit.record ); then
    
${rstat} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db -c ${CDATE}00 -m gdasefmn > rstat_resubmit.log
	
        grep "DEAD" rstat_resubmit.log > failed.log

        FNUM=$(cat failed.log | wc -l)

	ITOT=0
        if [ ${FNUM} -ne 0 ]; then
		echo "${CDATE} at $(date)" >> ${EXPREC}
                IL=1
	        while [ ${IL} -le ${FNUM} ]; do
                    FTASK=$(sed -n ${IL}p failed.log | awk -F " " '{print $2}')
		    FGRP=${FTASK:(-2)}
                        ${rboot} -w ${XMLDIR}/${EXP}.xml -d  ${DBDIR}/${EXP}.db -c ${CDATE}00 -t gdasefcs${FGRP}
                        ERR=$?
		        echo "${CDATE}" > rstat_resubmit.record
	                if [ ${ERR} -ne 0 ]; then
	                    echo "FAILED rocotoboot gdasefcs${FGRP}"
			    echo "    ** FAILED:     rocotoboot gdasefcs${FGRP}" >> ${EXPREC}
	                fi
	            IL=$((${IL}+1))
		done
	fi
    fi
done # EXP
