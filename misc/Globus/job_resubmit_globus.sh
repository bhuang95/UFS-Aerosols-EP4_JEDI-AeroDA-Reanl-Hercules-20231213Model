#!/bin/bash

SJOB=sbatch_glbus2niag_ret.sh
TOPDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801/dr-data/HERA2HPSS/

#SJOB=sbatch_glbus2niag_diag.sh
##TOPDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007/dr-data-backup/HERA2HPSS
#TOPDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801/dr-data-backup/HERA2HPSS/
#RECDIR=${TOPDIR}/resubmit.record

CYCS="
2018091500
2018091600
2018091618
2018091700
2018091706
2018091718
2018091800
2018091906
2018091912
2018092000
2018092106
2018092200
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
