#!/usr/bin/env bash 
##SBATCH -n 1
##SBATCH -t 00:30:00
##SBATCH -p hera
##SBATCH -q debug
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o ./bump_gfs_c96.out
##SBATCH -e ./bump_gfs_c96.out

set -x

###############################################################
## Abstract:
## Calculate increment of Met. fields for FV3-CHEM
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################


# Source FV3GFS workflow modules
source "${HOMEgfs}/ush/preamble.sh"
#. $HOMEgfs/ush/load_fv3gfs_modules.sh
. $HOMEgfs/ush/load_ufswm_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
configs="base"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done
[[ $status -ne 0 ]] && exit $status

ulimit -s unlimited
###############################################################
export CDATE=${CDATE:-"2017110100"}
export HOMEgfs=${HOMEgfs:-"home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work/"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
export DATAROOT=${DATAROOT:-"/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/Bo.Huang/RUNDIRS/cycExp_ATMA_warm/"}
export assim_freq=${assim_freq:-"6"}
export CDUMP=${CDUMP:-"gdas"}
export SFCANL_RST=${SFCANL_RST:-"YES"}

#export COMPONENT=${COMPONENT:-"atmos"}
COMP_RST="model_data/atmos/restart/"
export job="rplsfc"
export jobid="${job}.$$"
export DATA=${DATA:-${DATAROOT}/${jobid}}
#export DATA=${jobid}

export MISSGDASRECORD=${MISSGDASRECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15/record.chgres_hpss_htar_allmissing_v15"}


if ( grep ${CDATE} ${MISSGDASRECORD} ); then 
    echo "GDAS Met data not avaibale on HPSS and continue"
    export SFCANL_RST="NO"
fi

if [ ${SFCANL_RST} = "NO" ]; then
    echo "SFCANL_RST=${SFCANL_RST}"
    exit 0
fi

mkdir -p $DATA

RPLEXEC=${HOMEgfs}/ush/python/replace_sfc_data_restart.py
NTILES=6

GDATE=`$NDATE -$assim_freq ${CDATE}`

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}
GYMD=${GDATE:0:8}
GH=${GDATE:8:2}

FHR=`printf %03d ${assim_freq}`

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

cd ${DATA}
${NCP} ${RPLEXEC} ./replace_sfc_data_restart.py

BKGDIR=${ROTDIR}/${CDUMP}.${GYMD}/${GH}/${COMP_RST}/
ANLDIR=${ROTDIR}/${CDUMP}.${CYMD}/${CH}/${COMP_RST}/
SFCPRE=${CYMD}.${CH}0000

${NRM} ${DATA}/sfc.* ${DATA}/sfcanl.*

ITILE=1
while [ ${ITILE} -le ${NTILES} ]; do
    RSTBKG=${BKGDIR}/${SFCPRE}.sfc_data.tile${ITILE}.nc
    RSTBKG_RPL=${BKGDIR}/${SFCPRE}.sfc_data_com_sfcanl.tile${ITILE}.nc 
    RSTANL=${ANLDIR}/${SFCPRE}.sfcanl_data.tile${ITILE}.nc 
    ${NCP} ${RSTBKG} ${RSTBKG_RPL}
    ${NLN} ${RSTBKG_RPL} sfc.mem001.tile${ITILE}
    ${NLN} ${RSTANL} sfcanl.mem001.tile${ITILE}
    ITILE=$((ITILE+1))
done

srun --export=all -n 1 python replace_sfc_data_restart.py  -a sfcanl -b sfc -i 1 -j 1
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

rm -rf ${DATA}
exit ${ERR}
###############################################################

###############################################################
# Exit cleanly
