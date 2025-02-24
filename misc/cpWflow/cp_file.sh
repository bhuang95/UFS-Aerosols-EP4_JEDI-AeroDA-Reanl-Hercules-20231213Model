#!/bin/bash

SRCDIR=$1
DETDIR=$2
FILES=$3

NCP="/bin/cp -r"
echo ${SRCDIR}
echo ${DETDIR}
echo ${FILES}
[[ ! -d ${DETDIR} ]] && mkdir -p ${DETDIR}
for FILE in ${FILES}; do
    echo ${FILE}
    ${NCP} ${SRCDIR}/${FILE}* ${DETDIR}/
    ERR=$?
    echo ${ERR}
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
done

exit ${ERR}
