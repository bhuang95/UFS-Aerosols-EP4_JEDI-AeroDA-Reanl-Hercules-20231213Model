#! /usr/bin/env bash

SRCDIR=/work/noaa/wrf-chem/bhuang/NRTdata_UFS-Aerosols/src_sppt/src_sppt
DETDIR=/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/src_sppt

cd ${SRCDIR}
FILES=$(ls *F90)
for FILE in ${FILES}; do
    diff ${SRCDIR}/${FILE} ${DETDIR}/${FILE}
done

