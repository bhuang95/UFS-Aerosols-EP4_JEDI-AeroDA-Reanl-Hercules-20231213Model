#!/bin/bash

module load rocoto

set -x 

RUNDIR="/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl"
RUNTMP="/work/noaa/zrtrr/bohuang/RUNDIRS"
XMLDIR="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/dr-work-mpi/xmlFiles"
DBDIR="${RUNDIR}/xmlDB/"
NDATE="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/misc/ndate/ndate"
rstat="/apps/contrib/rocoto/1.3.6/bin/rocotostat"
rcmpl="/apps/contrib/rocoto/1.3.6/bin/rocotocomplete"
rboot="/apps/contrib/rocoto/1.3.6/bin/rocotoboot"

MEMGRP=5
NTASKS=8
NTRIES=3

EXPS="
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007
"
#AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801
#AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007

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
    #if [ ! -f rstat.log ]; then
    if ( grep ${CDATE} rstat_resubmit.record ); then
${rstat} -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db -c ${CDATE}00 -m gdasefmn > rstat.log
	
        grep "DEAD" rstat.log > failed.log
        grep "SUCCEEDED" rstat.log > succeeded.log

        FNUM=$(cat failed.log | wc -l)
        SNUM=$(cat succeeded.log | wc -l)
	FSNUM=$((${FNUM} + ${SNUM}))

	ITOT=0
        if [ ${FNUM} -ne 0 ] && [ ${FSNUM} -eq ${NTASKS} ] ; then
	    echo "${CDATE} at $(date)" >> ${EXPREC}
            if [ ${FNUM} -le ${SNUM} ]; then
                IL=1
	        while [ ${IL} -le ${FNUM} ]; do
                    FTASK=$(sed -n ${IL}p failed.log | awk -F " " '{print $2}')
                    STASK=$(sed -n ${IL}p succeeded.log | awk -F " " '{print $2}')
		    FGRP=${FTASK:(-2)}
		    SGRP=${STASK:(-2)}
		    FGRP10=$((10#${FGRP}))
		    SGRP10=$((10#${SGRP}))
	            DGRP=$((${SGRP10} - ${FGRP10}))
            
	            FMEM_ED=$((${FGRP10} * ${MEMGRP}))
	            FMEM_ST=$((${FMEM_ED} - ${MEMGRP} + 1))
	            #FMEM_INC=$((10#${DGRP} * 10#${MEMGRP}))
	            FMEM_INC=$((${DGRP} * ${MEMGRP}))
	            FEFCS=${ENKFDIR}/efcs.grp${FGRP}
	    
	            IMEM=${FMEM_ST}
	            ICNT=0
	            while [ ${IMEM} -le ${FMEM_ED} ]; do
		        IMEM_RPL=$((${IMEM} + ${FMEM_INC}))
		        IMEM3D=$(printf %03d ${IMEM})
		        IMEM3D_RPL=$(printf %03d ${IMEM_RPL})
		        FMEM="mem${IMEM3D}"
		        FMEM_RPL="mem${IMEM3D_RPL}"

		        FMEM_PASS="MEMBER ${IMEM3D} : PASS"
		        if ( ! grep "${FMEM_PASS}" ${FEFCS} ); then
			    #echo "HBO-mv ${ENKFDIR}/${FMEM} ${ENKFDIR}/${FMEM}-FAILED"
			    #echo "HBO-cp -r ${ENKFDIR}/${FMEM_RPL} ${ENKFDIR}/${FMEM}"
		            mv ${ENKFDIR}/${FMEM} ${ENKFDIR}/${FMEM}-FAILED
		            cp -r ${ENKFDIR}/${FMEM_RPL} ${ENKFDIR}/${FMEM}
			    echo "${FMEM_PASS}" >> ${FEFCS}
			   
                            ERR=$?
		            ICNT=$((${ICNT}+${ERR}))
			    if [ ${ERR} -eq 0 ]; then
			        echo "    ** SUCCEEDED: grp${FGRP}-${FMEM} replaced by grp${SGRP}-${FMEM_RPL}" >> ${EXPREC}
				break
			    else
			        echo "    ** FAILED:    grp${FGRP}-${FMEM} replaced by grp${SGRP}-${FMEM_RPL}" >> ${EXPREC}
			    fi
		        fi
	                IMEM=$((${IMEM}+1))
		    done

                    if [ ${ICNT} -eq 0 ]; then
			#echo "HBO-rocotocomplete -w ${XMLDIR}/${EXP}.xml -d ${DBDIR}/${EXP}.db -c ${CDATE}00 -t gdasefcs${FGRP}"
			echo "Reboot gdasefcs${FGRP}" >> ${EXPREC}
${rboot} -w ${XMLDIR}/${EXP}.xml -d  ${DBDIR}/${EXP}.db -c ${CDATE}00 -t gdasefcs${FGRP}
                        ERR=$?
		        ICNT=$((${ICNT}+${ERR}))
	                if [ ${ERR} -ne 0 ]; then
	                    echo "FAILED rocotoboot gdasefcs${FGRP}"
			    echo "    ** FAILED:     rocotoboot gdasefcs${FGRP}" >> ${EXPREC}
	                fi
	            else
	                echo "Failed copying all failed members in ${CDATE}00-gdasefcs${FGRP}"
                        echo "    ** FAILED:     copy all failed members at gdasefcs${FGRP}" >> ${EXPREC}
	            fi
		    ITOT=$((${ITOT} + ${ICNT}))
	            IL=$((${IL}+1))
		done
	    else
		    ITOT=$((${ITOT} + 1))
                    echo "FNUM=${FNUM} larger than SNUM=${SNUM} at ${CDATE}00"
                    echo "    ** FAILED: replace failed members due to FNUM=${FNUM} larger than SNUM=${SNUM}" >> ${EXPREC}
	    fi
        fi
	if [ ${ITOT} -eq 0 ]; then
	    #echo "HBO-rm -rf rstat.log"
	    rm -rf rstat.log
	fi
    fi
    #fi
done # EXP
