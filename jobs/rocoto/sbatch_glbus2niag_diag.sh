#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 8:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./globus2niag.out
#SBATCH -e ./globus2niag.out

set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle

#module load python/3.7.5
module load globus-cli/3.27
source config_hera2hpss

#NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
#NDATE=${HOMEgfs}/misc/ndate/ndate
NDATE=/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate
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

CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}
CYMD=${CDATE:0:8}

CNTLDIR=${ROTDIR}/gdas.${CYMD}/${CH}
ENKFDIR=${ROTDIR}/enkfgdas.${CYMD}/${CH}
DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data-backup/${CDATE}
DATANIAGDIR=${ARCHNIAGDIR}/${PSLOT}/dr-data-backup/${CDATE}

ICNT=0
GLBUSREC=Globus_o2n_${CDATE}.record
cd ${DATAHPSSDIR}
TARFILES=$(ls *.tar)
ERR=$?
ICNT=$((${ICNT}+${ERR}))

cd ${TMPDIR}
GINPUT=GlobusInput.out
GID=GlobusID_${CDATE}.out
GID2=GlobusID_${CDATE}_YES.out
[[ -f ${GINPUT} ]] && ${NRM} ${GINPUT}
for TARFILE in ${TARFILES};do
    echo "${TARFILE}    ${TARFILE}" >> ${GINPUT}
done

globus transfer --notify failed,inactive ${ORIONEP}:${DATAHPSSDIR} ${NIAGEP}:${DATANIAGDIR}  --batch ${GINPUT} >& ${GID}

ERR=$?
ICNT=$((${ICNT}+${ERR}))

GLBUSID=$(tail -n 1 ${GID} | awk '{print $3}')
globus task wait "${GLBUSID}"
ERR=$?
ICNT=$((${ICNT}+${ERR}))

if [ ${ICNT} -eq 0 ]; then
    echo "TAR and GLOBUS is successful at ${CDATE}"
    echo "SUCCESSFUL" > ${DATAHPSSDIR}/${GLBUSREC}
    globus transfer --notify failed,inactive ${ORIONEP}:${DATAHPSSDIR}/${GLBUSREC} ${NIAGEP}:${DATANIAGDIR}/${GLBUSREC} >& ${GID2}

    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
    GLBUSID=$(tail -n 1 ${GID2} | awk '{print $3}')
    globus task wait "${GLBUSID}"
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
if [ ${ICNT} -eq 0 ]; then
    ${NRM} ${CNTLDIR}
    if [ ${AERODA} = "YES" -o ${ENSRUN} = "YES" ]; then
        ${NRM} ${ENKFDIR}
    fi
    echo "YES" > ${TMPDIR}/remove.record
    ${NRM} ${DATAHPSSDIR}

    if [ -f ${GLBUSRECORD}-HERCULES ]; then
        ${NRM} ${GLBUSRECORD}-HERCULES
    fi

    if [ -f ${GLBUSRECORD} ]; then
        ${NRM} ${GLBUSRECORD}
    fi

else
    echo "Globus failed at ${CDATE}" >> ${GLBUSRECORD}
    exit ${ICNT}
fi
else
    echo "Globus failed at ${CDATE}" >> ${GLBUSRECORD}
    exit ${ICNT}
fi

exit ${ICNT}
