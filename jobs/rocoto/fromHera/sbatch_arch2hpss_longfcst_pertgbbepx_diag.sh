#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hera2hpss.out
#SBATCH -e ./hera2hpss.out

set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle

source config_hera2hpss

NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}

module load hpss
#export PATH="/apps/hpss/bin:$PATH"
set -x

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}
CYMD=${CDATE:0:8}

DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data-longfcst-pertgbbepx-backup/${CY}/${CY}${CM}/${CYMD}/
hsi "mkdir -p ${DATAHPSSDIR}"
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "*hsi mkdir* failed at ${CDATE}" >> ${HPSSRECORD}
    exit ${ERR}
fi


# Back up gdas cntl

CNTLDIR_CDATE=${ROTDIR}/gdas.${CYMD}/${CH}
CNTLDIR_ATMOS_CDATE=${CNTLDIR_CDATE}/model_data/
CNTLDIR_DIAG_CDATE=${CNTLDIR_CDATE}/diag/

if [ -s ${CNTLDIR_CDATE} ]; then
    if [ ${TARALLRST} = "YES" ]; then
        cd ${CNTLDIR_ATMOS_CDATE}
        TARFILE=${DATAHPSSDIR}/gdas.longfcst.model_data.${CDATE}.tar
        htar -P -cvf ${TARFILE} *
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "HTAR cntl restart data failed at ${CDATE}" >> ${HPSSRECORD}
            exit ${ERR}
        else
    	    echo "HTAR is complete and remove data"
	fi

        cd ${CNTLDIR_DIAG_CDATE}
        TARFILE=${DATAHPSSDIR}/gdas.longfcst.diag.${CDATE}.tar
        htar -P -cvf ${TARFILE} *
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "HTAR cntl restart data failed at ${CDATE}" >> ${HPSSRECORD}
            exit ${ERR}
        else
    	    echo "HTAR is complete and remove data"
	fi
    else
	echo "This josb was not ready for TASKALLRST=NO. exit now..."
	exit 100
    fi
fi # Done with loop through cntl

if [ ${ERR} -eq 0 ]; then
    ${NRM} ${CNTLDIR_ATMOS_CDATE}
fi
exit ${ERR}
