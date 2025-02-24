#!/bin/bash

set -x
echo "Starting at $(date)"
SRCDIR=/work/noaa/wrf-chem/bhuang/
TGTDIR=/work/noaa/gsd-fv3-dev/bhuang/bakWrfChem/

DATENOW=$(date +%Y%m%d%H%M)
TARDIR=${TGTDIR}/${DATENOW}

[[ ! -d ${TARDIR} ]] && mkdir -p ${TARDIR}

cd ${SRCDIR}
SRCFILEL1=$(ls)
cd ${TARDIR}
ICNT=0
for L1 in ${SRCFILEL1}; do
    SRCDIRL2=${SRCDIR}/${L1}
    DETDIRL2=${TARDIR}/${L1}
    [[ ! -d ${DETDIRL2} ]] && mkdir -p ${DETDIRL2}
    cd ${SRCDIRL2}
    SRCFILEL2=$(ls)
    for L2 in ${SRCFILEL2}; do
        tar -cvf ${DETDIRL2}/${L2}.tar ${SRCDIRL2}/${L2}
	#echo "${DETDIRL2}/${L2}.tar"
	#echo "${SRCDIRL2}/${L2}"
	ERR=$?
        ICNT=$((${ICNT}+${ERR}))
	if [ ${ERR} -ne 0 ]; then
            echo "Tar failed: ${SRCDIRL1}/${L2}"
	    exit ${ERR}
	fi
    done
done

if [ ${ICNT} -eq 0 ]; then
    echo "All files are tarred successfully." > ${TGTDIR}/tarRecord.${DATENOW}.successed
else
    echo "Tarring files failed." > ${TGTDIR}/tarRecord.${DATENOW}.failed
fi

echo "Done at $(date)"
exit ${ICNT}
