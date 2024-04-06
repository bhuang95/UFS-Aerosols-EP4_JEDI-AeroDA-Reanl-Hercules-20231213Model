#! /usr/bin/env bash

source "${HOMEgfs}/ush/preamble.sh"

###############################################################
# Source FV3GFS workflow modules
#. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
. ${HOMEgfs}/ush/load_ufswm_modules.sh
status=$?
[[ ${status} -ne 0 ]] && exit ${status}

export job="rce_ens_aeroanl"
export jobid="${job}.$$"
export DATA=${DATA:-${DATAROOT}/${jobid}}

source "${HOMEgfs}/ush/jjob_header.sh" -e "aeroanlrun" -c "base aeroanlrun"

##############################################
# Set variables used in the script
##############################################
export CDATE=${CDATE:-"2021021900"}
export assim_freq=${assim_freq:-"6"}
export CDUMP=${CDUMP:-${RUN:-"gdas"}}
export COMP_MOD_ATM_RST="model_data/atmos/restart"
export ROTDIR=${ROTDIR:-""}
export ENSGRP=${ENSGRP:-"01"}
export RECENTER_ENKF_AERO=${RECENTER_ENKF_AERO:-"YES"}
export NMEM_EFCSGRP=${NMEM_EFCSGRP:-"2"}
export NMEM_ENKF=${NMEM_ENKF:-"20"}
export RECENTEREXEC="${HOMEgfs}/ush/python/recenter_enkf_aeroanl_restart.py"
export RPLTRCRVARS=${RPLTRCRVARS:-""}

if [ ${RECENTER_ENKF_AERO} = "YES" ]; then
    RECENTEREXEC="${HOMEgfs}/ush/python/recenter_enkf_aeroanl_restart.py"
else
    RECENTEREXEC="${HOMEgfs}/ush/python/replace_aeroanl_restart.py"
fi

ENSED=$((${NMEM_EFCSGRP} * 10#${ENSGRP}))
ENSST=$((ENSED - NMEM_EFCSGRP + 1))

if [ ${ENSED} -gt ${NMEM_ENKF} ] || [ ${ENSST} -lt 0 ]; then
    echo "Member ${ENSST}-${ENSED} range is not right and exit."
    exit 100
fi

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDATE=$(date +%Y%m%d%H -d "${CDATE:0:8} ${CDATE:8:2} - ${assim_freq} hours")

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}

GYMD=${GDATE:0:8}
GH=${GDATE:8:2}

GDIR=${ROTDIR}/gdas.${GYMD}/${GH}
GENSDIR=${ROTDIR}/enkfgdas.${GYMD}/${GH}
ANLPREFIX=${CYMD}.${CH}0000
CNTLPREFIX="CNTL"
EMEANPREFIX="EMEAN"
CMMPREFIX="CMM"
JEDIPREFIX="JEDITMP"
RPLPREFIX="RPL"
RCEPREFIX="RCE"
INVARS=${RPLTRCRVARS}
TRCRBKG="fv_tracer"
TRCRANL="fv_tracer_aeroanl"
TRCRTMPANL="fv_tracer_aeroanl_tmp"
TRCRRCEANL="fv_tracer_raeroanl"

# Link ensemble tracer file
IMEM=${ENSST}
CNTLDIR="${GDIR}/${COMP_MOD_ATM_RST}"
EMEANDIR="${GENSDIR}/ensmean/${COMP_MOD_ATM_RST}/"
while [ ${IMEM} -le ${ENSED} ]; do
    MEMSTR="mem"`printf %03d ${IMEM}`
    MEMDIR="${GENSDIR}/${MEMSTR}/${COMP_MOD_ATM_RST}/"

    ITILE=1
    while [ ${ITILE} -le 6 ]; do
        TILESTR="tile${ITILE}"

        if [ ${IMEM} -eq ${ENSST} ]; then
            CNTLFILE_IN=${CNTLDIR}/${ANLPREFIX}.${TRCRANL}.res.${TILESTR}.nc
            EMEANFILE_IN=${EMEANDIR}/${ANLPREFIX}.${TRCRANL}.res.${TILESTR}.nc
            CNTLFILE_OUT=${CNTLPREFIX}.${TILESTR}
            EMEANFILE_OUT=${EMEANPREFIX}.${TILESTR}
            CMMFILE_OUT=${CMMPREFIX}.${TILESTR}
            ${NLN} ${CNTLFILE_IN} ${CNTLFILE_OUT}
            ${NLN} ${EMEANFILE_IN} ${EMEANFILE_OUT}
            ${NCP} ${EMEANFILE_IN} ${CMMFILE_OUT}
        fi

        MEMFILE_IN_BKG=${MEMDIR}/${ANLPREFIX}.${TRCRBKG}.res.${TILESTR}.nc
        MEMFILE_IN_JEDI=${MEMDIR}/${ANLPREFIX}.${TRCRTMPANL}.res.${TILESTR}.nc
        MEMFILE_IN_RPL=${MEMDIR}/${ANLPREFIX}.${TRCRANL}.res.${TILESTR}.nc
        MEMFILE_IN_RCE=${MEMDIR}/${ANLPREFIX}.${TRCRRCEANL}.res.${TILESTR}.nc

        MEMFILE_OUT_JEDI=${DATA}/${JEDIPREFIX}.${MEMSTR}.${TILESTR}
        MEMFILE_OUT_RPL=${DATA}/${RPLPREFIX}.${MEMSTR}.${TILESTR}
        MEMFILE_OUT_RCE=${DATA}/${RCEPREFIX}.${MEMSTR}.${TILESTR}

	${NCP} ${MEMFILE_IN_BKG} ${MEMFILE_IN_RPL}
	${NLN} ${MEMFILE_IN_JEDI} ${MEMFILE_OUT_JEDI}
	${NLN} ${MEMFILE_IN_RPL} ${MEMFILE_OUT_RPL}
        if [ ${RECENTER_ENKF_AERO} = "YES" ]; then
	    ${NCP} ${MEMFILE_IN_BKG} ${MEMFILE_IN_RCE}
	    ${NLN} ${MEMFILE_IN_RCE} ${MEMFILE_OUT_RCE}
        fi

        ITILE=$((ITILE+1))
    done
    IMEM=$((IMEM+1))
done

cd ${DATA}
cp -r ${RECENTEREXEC} ./finalize_ens_aeroanl_restart.py
echo ${INVARS} > INVARS.nml

srun --export=all -n 1 python finalize_ens_aeroanl_restart.py -i ${ENSST} -j ${ENSED} -v "INVARS.nml" 

ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

${NRM} ${DATA}

exit ${ERR}
