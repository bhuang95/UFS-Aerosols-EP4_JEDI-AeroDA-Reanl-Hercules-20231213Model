#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 08:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hera2hpss.out
#SBATCH -e ./hera2hpss.out

set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle

source config_hera2hpss

#NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
NDATE=${HOMEgfs}/misc/ndate/ndate
#module load hpss
#export PATH="/apps/hpss/bin:$PATH"
set -x

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})
RMDATE=${GDATE}
RMDIR=${TMPDIR}/../${RMDATE}
RMREC=${RMDIR}/remove.record

#if ( grep YES ${RMREC} ); then
#    ${NRM} ${RMDIR}
#fi

CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}
CYMD=${CDATE:0:8}

GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}
GYMD=${GDATE:0:8}

ICNT=0
DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data-backup/${CDATE}
mkdir -p ${DATAHPSSDIR}
ERR=$?
ICNT=$((${ICNT}+${ERR}))

# Back up gdas cntl
# Copy gridded reanalysis files

CNTLDIR=${ROTDIR}/gdas.${CYMD}/${CH}
cd ${CNTLDIR}
TARFILE=${DATAHPSSDIR}/gdas.${CDATE}.diag.tar
#htar -P -cvf ${TARFILE} *
tar -cvf ${TARFILE} *
ERR=$?
ICNT=$((${ICNT}+${ERR}))

ENKFDIR=${ROTDIR}/enkfgdas.${CYMD}/${CH}

if [ ${AERODA} = "YES" ]; then
    cd ${ENKFDIR}
    TARFILE=${DATAHPSSDIR}/enkfgdas.${CDATE}.diag.tar
    #htar -P -cvf ${TARFILE} *
    tar -cvf ${TARFILE} *
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
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
