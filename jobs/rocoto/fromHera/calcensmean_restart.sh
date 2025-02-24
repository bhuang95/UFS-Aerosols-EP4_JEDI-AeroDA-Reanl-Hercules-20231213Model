#! /usr/bin/env bash

source "${HOMEgfs}/ush/preamble.sh"

###############################################################
# Source FV3GFS workflow modules
#. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
. ${HOMEgfs}/ush/load_ufswm_modules.sh
status=$?
[[ ${status} -ne 0 ]] && exit ${status}

export job="ensmean_restart"
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
export ITILE=${ITILE:-"1"}
export NMEM=${NMEM_ENKF:-"80"}
export MEANEXEC=${HOMEgfs}/ush/python/calc_ensmean_restart.py
export MEANTRCRVARS=${MEANTRCRVARS:-""}
export MEANCOREVARS=${MEANCOREVARS:-""}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NLN="/bin/ln -sf"

FDATE=$(date +%Y%m%d%H -d "${CDATE:0:8} ${CDATE:8:2} + ${assim_freq} hours")

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}

FYMD=${FDATE:0:8}
FH=${FDATE:8:2}

FENSDIR=${ROTDIR}/enkfgdas.${CYMD}/${CH}
FENSMEANRTDIR=${ROTDIR}/enkfgdas.${CYMD}/${CH}/ensmean/${COMP_MOD_ATM_RST}/
ANLPREFIX=${FYMD}.${FH}0000

[[ ! -d ${FENSMEANRTDIR} ]] && mkdir -p ${FENSMEANRTDIR}

# Calculate  mean for fv3_tracer and _core files
TILEFILES="fv_tracer.res.tile${ITILE}.nc  fv_core.res.tile${ITILE}.nc"
#TILEFILES="fv_tracer.res.tile${ITILE}.nc_anl"
for TILEFILE in ${TILEFILES}; do
    rm -rf ${DATA}/*
    TILEDIR=${DATA}/TILE${ITILE}
    [[ ! -d ${TILEDIR} ]] && mkdir -p ${TILEDIR}

# All variables separated by comma, but don't add comma at the end of the string
    if [[ ${TILEFILE} == *"fv_tracer"* ]]; then
        #INVARS="sphum,bc1,bc2,oc1,oc2,so4,dust1,dust2,dust3,dust4,dust5,seas1,seas2,seas3,seas4,seas5"
        INVARS=${MEANTRCRVARS}
    elif [[ ${TILEFILE} == *"fv_core"* ]]; then
        #INVARS="T,delp"
        INVARS=${MEANCOREVARS}
    else
	echo "Add variables for ${TILEFILE} and exit"
        exit 1
    fi

    cd ${TILEDIR}
    echo ${INVARS} > INVARS.nml
    ${NCP} ${MEANEXEC} ./calc_ensmean_restart.py

    IMEM=1
    while [ ${IMEM} -le ${NMEM} ]; do
        MEMSTR="mem"`printf %03d ${IMEM}`
        MEMFILE_IN=${FENSDIR}/${MEMSTR}/${COMP_MOD_ATM_RST}/${ANLPREFIX}.${TILEFILE}
        MEMFILE_OUT=${TILEDIR}/${MEMSTR}.${TILEFILE}
        if [ ${IMEM} -eq 1 ]; then
            ${NCP} ${MEMFILE_IN} ${TILEDIR}/ensmean.${TILEFILE}
        fi

        ${NLN} ${MEMFILE_IN} ${MEMFILE_OUT}
        IMEM=$((IMEM+1))
    done

    python calc_ensmean_restart.py -f ${TILEFILE} -n ${NMEM} -v "INVARS.nml" 

    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    
    ${NMV} ensmean.${TILEFILE}  ${FENSMEANRTDIR}/${ANLPREFIX}.${TILEFILE}
done

if [ ${ITILE} -eq 1 ]; then
    ${NCP} ${FENSDIR}/mem001/${COMP_MOD_ATM_RST}/${ANLPREFIX}.coupler.res ${FENSMEANRTDIR}/
    ${NCP} ${FENSDIR}/mem001/${COMP_MOD_ATM_RST}/${ANLPREFIX}.fv_core.res.nc ${FENSMEANRTDIR}/
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
fi

if [ ${ERR} -eq 0 ]; then
    rm -rf ${DATA}
fi
exit ${ERR}
