#! /usr/bin/env bash

source "${HOMEgfs}/ush/preamble.sh"

###############################################################
# Source FV3GFS workflow modules
#. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
. ${HOMEgfs}/ush/load_ufswm_modules.sh
module load python/3.7.5
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
export NMEM_ENKF=${NMEM_ENKF:-"20"}
export RECENTEREXEC="${HOMEgfs}/ush/python/recenter_enkf_aeroanl_restart.py"
export RPLTRCRVARS=${RPLTRCRVARS:-""}

export SLURM_EXACT=1
export SLURM_MEM_PER_NODE=0
unset SLURM_MEM_PER_CPU 
unset SLURM_MEM_PER_GPU

if [ ${RECENTER_ENKF_AERO} = "YES" ]; then
    RECENTEREXEC="${HOMEgfs}/ush/python/recenter_enkf_aeroanl_restart.py"
else
    RECENTEREXEC="${HOMEgfs}/ush/python/replace_aeroanl_restart.py"
fi

ENSST=1
ENSED=${NMEM_ENKF}

if [ ${ENSED} -lt ${ENSST} ]; then
    echo "ENSED smaller than ENSST and please check first before continuing."
    exit 100
fi

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"
NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
#GDATE=$(date +%Y%m%d%H -d "${CDATE:0:8} ${CDATE:8:2} - ${assim_freq} hours")
GDATE=$(${NDATE} -${assim_freq} ${CDATE})

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
CNTLDIR="${GDIR}/${COMP_MOD_ATM_RST}"
EMEANDIR="${GENSDIR}/ensmean/${COMP_MOD_ATM_RST}/"

NTHREADS_AEROANL=${NTHREADS_AEROANL:-"1"}
ncmd=${ncmd:-"1"}
export OMP_NUM_THREADS=$NTHREADS_AEROANL
IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    MEMSTR="mem"`printf %03d ${IMEM}`
    MEMDIR="${GENSDIR}/${MEMSTR}/${COMP_MOD_ATM_RST}/"

    RCELOG=${ROTDIR}/logs/${CDATE}/finaeroanl_${MEMSTR}
    TGTDIR=${DATA}/${MEMSTR}
    [[  -d ${TGTDIR} ]] && ${NRM} ${TGTDIR}
    [[ ! -d ${TGTDIR} ]] && mkdir -p ${TGTDIR}
    cd ${TGTDIR}

    ${NCP} ${RECENTEREXEC} ./finalize_ens_aeroanl_restart.py
    echo ${INVARS} > INVARS.nml

    ITILE=1
    while [ ${ITILE} -le 6 ]; do
        TILESTR="tile${ITILE}"

        CNTLFILE_IN=${CNTLDIR}/${ANLPREFIX}.${TRCRANL}.res.${TILESTR}.nc
        EMEANFILE_IN=${EMEANDIR}/${ANLPREFIX}.${TRCRANL}.res.${TILESTR}.nc
        CNTLFILE_OUT=${CNTLPREFIX}.${TILESTR}
        EMEANFILE_OUT=${EMEANPREFIX}.${TILESTR}
        CMMFILE_OUT=${CMMPREFIX}.${TILESTR}
        ${NLN} ${CNTLFILE_IN} ${CNTLFILE_OUT}
        ${NLN} ${EMEANFILE_IN} ${EMEANFILE_OUT}
        ${NCP} ${EMEANFILE_IN} ${CMMFILE_OUT}

        MEMFILE_IN_BKG=${MEMDIR}/${ANLPREFIX}.${TRCRBKG}.res.${TILESTR}.nc
        MEMFILE_IN_JEDI=${MEMDIR}/${ANLPREFIX}.${TRCRTMPANL}.res.${TILESTR}.nc
        MEMFILE_IN_RPL=${MEMDIR}/${ANLPREFIX}.${TRCRANL}.res.${TILESTR}.nc
        MEMFILE_IN_RCE=${MEMDIR}/${ANLPREFIX}.${TRCRRCEANL}.res.${TILESTR}.nc

        MEMFILE_OUT_JEDI=${TGTDIR}/${JEDIPREFIX}.${MEMSTR}.${TILESTR}
        MEMFILE_OUT_RPL=${TGTDIR}/${RPLPREFIX}.${MEMSTR}.${TILESTR}
        MEMFILE_OUT_RCE=${TGTDIR}/${RCEPREFIX}.${MEMSTR}.${TILESTR}

	${NCP} ${MEMFILE_IN_BKG} ${MEMFILE_IN_RPL}
	${NLN} ${MEMFILE_IN_JEDI} ${MEMFILE_OUT_JEDI}
	${NLN} ${MEMFILE_IN_RPL} ${MEMFILE_OUT_RPL}
        if [ ${RECENTER_ENKF_AERO} = "YES" ]; then
	    ${NCP} ${MEMFILE_IN_BKG} ${MEMFILE_IN_RCE}
	    ${NLN} ${MEMFILE_IN_RCE} ${MEMFILE_OUT_RCE}
        fi

        ITILE=$((ITILE+1))
    done
    { srun --export=all -n ${ncmd} python finalize_ens_aeroanl_restart.py -i ${IMEM} -j ${IMEM} -v "INVARS.nml" >& ${RCELOG}; echo "$?" > extcode.out; } & 
    IMEM=$((IMEM+1))
done
wait

IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    MEMSTR="mem"`printf %03d ${IMEM}`
    TGTDIR=${DATA}/${MEMSTR}
    cd ${TGTDIR}

    ERR=$(cat extcode.out)
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    IMEM=$((IMEM+1))
done

${NRM} ${DATA}

exit ${ERR}
