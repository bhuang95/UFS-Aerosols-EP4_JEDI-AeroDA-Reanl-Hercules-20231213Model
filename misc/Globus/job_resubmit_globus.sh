#!/bin/bash

#SJOB=sbatch_glbus2niag_ret.sh
#TOPDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007/dr-data/HERA2HPSS
#TOPDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801/dr-data/HERA2HPSS

SJOB=sbatch_glbus2niag_diag.sh
#TOPDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007/dr-data-backup/HERA2HPSS
TOPDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801/dr-data-backup/HERA2HPSS/
RECDIR=${TOPDIR}/resubmit.record

CYCS="
2018041212
2018041218
2018041300
2018041306
2018041312
2018041318
2018041400
2018041406
"

[[ ! -d ${RECDIR} ]] && mkdir -p ${RECDIR}

for CYC in ${CYCS}; do
    if [ -f ${TOPDIR}/record.failed_GLBUS2NIAG-${CYC} ]; then
	echo ${CYC}
        BAKDIR=${TOPDIR}/${CYC}
        cd ${BAKDIR}
/opt/slurm/bin/sbatch ${SJOB}
        ERR=$?
        if [ ${ERR} -eq 0 ]; then
            mv ${TOPDIR}/record.failed_GLBUS2NIAG-${CYC} ${RECDIR}/
        fi
    fi
done
