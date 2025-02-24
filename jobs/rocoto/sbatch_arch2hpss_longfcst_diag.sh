#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 07:59:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hera2hpss.out
#SBATCH -e ./hera2hpss.out

set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle

source config_hera2hpss

NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"

#module load hpss
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

ICNT=0
DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data-longfcst-backup/${CDATE}  #${CY}/${CY}${CM}/${CYMD}/
#hsi "mkdir -p ${DATAHPSSDIR}"
mkdir -p ${DATAHPSSDIR}
ERR=$?
ICNT=$((${ICNT}+${ERR}))

if [ ${ERR} -ne 0 ]; then
    echo "*hsi mkdir* failed at ${CDATE}" >> ${HPSSRECORD}
    exit ${ERR}
fi


# Back up gdas cntl

CNTLDIR_CDATE=${ROTDIR}/gdas.${CYMD}/${CH}
CNTLDIR_ATMOS_CDATE=${CNTLDIR_CDATE}/model_data/
CNTLDIR_DIAG_CDATE=${CNTLDIR_CDATE}/diag/

cd ${CNTLDIR_ATMOS_CDATE}
TARFILE=${DATAHPSSDIR}/gdas.longfcst.model_data.${CDATE}.tar
#htar -P -cvf ${TARFILE} *
tar -P -cvf ${TARFILE} *
ERR=$?
ICNT=$((${ICNT}+${ERR}))
if [ ${ERR} -ne 0 ]; then
    echo "HTAR cntl restart data failed at ${CDATE}" >> ${HPSSRECORD}
    exit ${ERR}
else
    echo "HTAR is complete and remove data"
fi

cd ${CNTLDIR_DIAG_CDATE}
TARFILE=${DATAHPSSDIR}/gdas.longfcst.diag.${CDATE}.tar
#htar -P -cvf ${TARFILE} *
tar -P -cvf ${TARFILE} *
ERR=$?
ICNT=$((${ICNT}+${ERR}))
if [ ${ERR} -ne 0 ]; then
    echo "HTAR cntl restart data failed at ${CDATE}" >> ${HPSSRECORD}
    exit ${ERR}
else
    echo "HTAR is complete and remove data"
fi

if [ ${ICNT} -ne 0 ]; then
    echo "HTAR cntl data failed at ${CDATE}" >> ${HPSSRECORD}
    exit ${ICNT}
else
    echo "HTAR diag at ${CDATE} passed and exit now".
    cd ${TMPDIR}
#/opt/slurm/bin/sbatch sbatch_glbus2niag_diag.sh
echo "Globus failed at ${CDATE}" > ${GLBUSRECORD}
fi
exit ${ICNT}

