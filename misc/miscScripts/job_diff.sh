#! /usr/bin/env bash

SRCDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801/dr-data/gdas.20180831/06/model_data/atmos/restart
#/work/noaa/wrf-chem/bhuang/NRTdata_UFS-Aerosols/src_sppt/src_sppt
DETDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801/dr-data/gdas.20180831/faild-12-fcst/06/model_data/atmos/restart
#/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/src_sppt

cd ${SRCDIR}
FILES=$(ls *)
for FILE in ${FILES}; do
    diff ${SRCDIR}/${FILE} ${DETDIR}/${FILE}
done

