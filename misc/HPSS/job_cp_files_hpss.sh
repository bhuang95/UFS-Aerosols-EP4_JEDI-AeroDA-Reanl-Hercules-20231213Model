#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/tmprun/hera2hpss.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/tmprun/hera2hpss.out

# Back up cycled data to HPSS at ${CDATE}-6 cycle

SDATE=2018010100
EDATE=2018010200
CYCINTHR=6
NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"

HPSS_SRC=/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/UFS-Aerosols_RETcyc/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801/dr-data/
HPSS_TGT=/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201801/dr-data/

module load hpss
#export PATH="/apps/hpss/bin:$PATH"
#set -x

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"


FILES="
diag.cntlenkf.0000000000.tar
enkfgdas.0000000000.ensmean.tar


enkfgdas.0000000000.grp1.tar
enkfgdas.0000000000.grp2.tar 
enkfgdas.0000000000.grp3.tar
enkfgdas.0000000000.grp4.tar

gdas.0000000000.tar
"

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}
    CYMD=${CDATE:0:8}

    DIR_SRC="${HPSS_SRC}/${CY}/${CY}${CM}/${CYMD}"
    DIR_TGT="${HPSS_TGT}/${CY}/${CY}${CM}/${CYMD}"
    hsi "mkdir -p ${DIR_TGT}"

    ICNT=0
    for FILE in ${FILES}; do
        FILE_NEW=${FILE/0000000000/${CDATE}}
	echo ${FILE}
	echo ${FILE_NEW}
	hsi "cp ${DIR_SRC}/${FILE_NEW} ${DIR_TGT}/${FILE_NEW}"
	ERR=$?
        ICNT=$((${ICNT}+${ERR}))
    done
    if [ ${ICNT} -ne 0 ]; then
       echo "HSI copy failed and exit now"
       exit ${ICNT}
    fi
    CDATE=$(${NDATE} ${CYCINTHR} ${CDATE})
done

exit ${ICNT}
