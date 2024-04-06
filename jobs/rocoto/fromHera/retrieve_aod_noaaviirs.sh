#!/bin/bash --login
#SBATCH -J dr-data-1
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH --mem=5g
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./dr-data-1-out.txt
#SBATCH -e ./dr-data-1-out.txt

module load hpss
set -x


HPSSPASS=${HPSSPASS:-"NO"}
if [ ${HPSSPASS} = "YES" ]; then
    echo "HPSSPASS=YES"
    exit 0
fi
TASKRC=${TASKRC:-"./record.retviirs_aod"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/Prep_VIIRSAOD_202007/dr-data"}
PSLOT=${PSLOT:-"Prep_VIIRSAOD_202007"}
CDATE=${CDATE:-"2020070100"}
AODSAT=${AODSAT:-"npp"}
NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}


NRM="/bin/rm -rf"

LDATE=$(${NDATE} -24 ${CDATE})

if ( ! ls ${ROTDIR}/${LDATE}/*.nc ); then
    LDATES="${LDATE} ${CDATE}"
else
    LDATES="${CDATE}"
fi

ECNT=0
for IDATE in ${LDATES}; do
    IY=${IDATE:0:4}
    IM=${IDATE:4:2}
    ID=${IDATE:6:2}
    HPSSDIR=/BMC/fdr/Permanent/${IY}/${IM}/${ID}/data/sat/nesdis/viirs/aod/conus
    HERADIR=${ROTDIR}/${IDATE}
    HPSSFILE=${HPSSDIR}/${IDATE}00.zip

    [[ ! -d ${HERADIR} ]] && mkdir -p ${HERADIR}
    cd ${HERADIR}

    hsi "get ${HPSSFILE}"
    ERR=$?
    ECNT=$((${ECNT}+${ERR}))
    unzip ${IDATE}00.zip "*_${AODSAT}_*.nc"
    ERR=$?
    ECNT=$((${ECNT}+${ERR}))
    if [ ${ECNT} -ne 0 ]; then
        echo "There is an error and exit now"
	exit ${ECNT}
    else
	${NRM} ${HERADIR}/${IDATE}00.zip
    fi
done

exit ${ECNT}
