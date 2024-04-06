#! /usr/bin/env bash

source "${HOMEgfs}/ush/preamble.sh"
ulimit -s unlimited

###############################################################
# Source FV3GFS workflow modules
#. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
. ${HOMEgfs}/ush/load_ufswm_modules.sh
module load python/3.7.5
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
export NTILES=${NTILES:-"6"}
export NMEM=${NMEM_ENKF:-"80"}
export MEANEXEC=${HOMEgfs}/ush/python/calc_ensmean_restart.py
export MEANTRCRVARS=${MEANTRCRVARS:-""}
export MEANCOREVARS=${MEANCOREVARS:-""}

export SLURM_EXACT=1
export SLURM_MEM_PER_NODE=0
unset SLURM_MEM_PER_CPU 
unset SLURM_MEM_PER_GPU

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NLN="/bin/ln -sf"
NRM="/bin/rm -rf"

NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
#FDATE=$(date +%Y%m%d%H -d "${CDATE:0:8} ${CDATE:8:2} + ${assim_freq} hours")
FDATE=$(${NDATE} +${assim_freq} ${CDATE})
CYMD=${CDATE:0:8}
CH=${CDATE:8:2}

FYMD=${FDATE:0:8}
FH=${FDATE:8:2}

FENSDIR=${ROTDIR}/enkfgdas.${CYMD}/${CH}
FENSMEANRTDIR=${ROTDIR}/enkfgdas.${CYMD}/${CH}/ensmean/${COMP_MOD_ATM_RST}/
ANLPREFIX=${FYMD}.${FH}0000

[[ ! -d ${FENSMEANRTDIR} ]] && mkdir -p ${FENSMEANRTDIR}

# Calculate  mean for fv3_tracer and _core files
TILEFILES="fv_tracer fv_core"
#TILEFILES="fv_tracer.res.tile${ITILE}.nc_anl"

ITILE=1
while [ ${ITILE} -le 6 ]; do
    for TILEFILE in ${TILEFILES}; do
	MRSTLOG=${ROTDIR}/logs/${CDATE}/meanrst_${ITILE}_${TILEFILE}
        TGTDIR=${DATA}/TILE_${ITILE}_${TILEFILE}
	TGTFILE=${FYMD}.${FH}0000.${TILEFILE}.res.tile${ITILE}.nc
        [[ -d ${TGTDIR} ]] && ${NRM} ${TGTDIR}
        [[ ! -d ${TGTDIR} ]] && mkdir -p ${TGTDIR}
        cd ${TGTDIR}
        # All variables separated by comma, but don't add comma at the end of the string
        if [ ${TILEFILE} = "fv_tracer" ]; then
            #INVARS="sphum,bc1,bc2,oc1,oc2,so4,dust1,dust2,dust3,dust4,dust5,seas1,seas2,seas3,seas4,seas5"
            INVARS=${MEANTRCRVARS}
        elif [ ${TILEFILE} = "fv_core" ]; then
            #INVARS="T,delp"
            INVARS=${MEANCOREVARS}
        else
	    echo "Add variables for ${TILEFILE} and exit"
            exit 100
        fi

        echo ${INVARS} > INVARS.nml
        ${NCP} ${MEANEXEC} ./calc_ensmean_restart.py

        IMEM=1
        while [ ${IMEM} -le ${NMEM} ]; do
            MEMSTR="mem"`printf %03d ${IMEM}`
            MEMFILE_IN=${FENSDIR}/${MEMSTR}/${COMP_MOD_ATM_RST}/${TGTFILE}
            MEMFILE_OUT=${TGTDIR}/${MEMSTR}.${TGTFILE}
            if [ ${IMEM} -eq 1 ]; then
                ${NCP} ${MEMFILE_IN} ${TGTDIR}/ensmean.${TGTFILE}
            fi

            ${NLN} ${MEMFILE_IN} ${MEMFILE_OUT}
            IMEM=$((IMEM+1))
        done

        { srun --export=all -n 1 python calc_ensmean_restart.py -f ${TGTFILE} -n ${NMEM} -v "INVARS.nml" >& ${MRSTLOG}; echo "$?" > extcode.out; } &
        #{ srun --export=all --exact -n 1 -c 1 --mem-per-cpu=1000M python calc_ensmean_restart.py -f ${TGTFILE} -n ${NMEM} -v "INVARS.nml" >& ${MRSTLOG}; echo "$?" > extcode.out; } &
    done
    ITILE=$((ITILE+1))
done
wait

ITILE=1
while [ ${ITILE} -le 6 ]; do
    for TILEFILE in ${TILEFILES}; do
        TGTDIR=${DATA}/TILE_${ITILE}_${TILEFILE}
	TGTFILE=${FYMD}.${FH}0000.${TILEFILE}.res.tile${ITILE}.nc
        cd ${TGTDIR}
        ERR=$(cat extcode.out)
        [[ ${ERR} -ne 0 ]] && exit ${ERR}
	[[ -f ${FENSMEANRTDIR}/${TGTFILE} ]] && ${NRM} ${FENSMEANRTDIR}/${TGTFILE}
        ${NMV} ensmean.${TGTFILE} ${FENSMEANRTDIR}/${TGTFILE}
    done
    ITILE=$((ITILE+1))
done



${NCP} ${FENSDIR}/mem001/${COMP_MOD_ATM_RST}/${ANLPREFIX}.coupler.res ${FENSMEANRTDIR}/
${NCP} ${FENSDIR}/mem001/${COMP_MOD_ATM_RST}/${ANLPREFIX}.fv_core.res.nc ${FENSMEANRTDIR}/
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}


if [ ${ERR} -eq 0 ]; then
    rm -rf ${DATA}
fi
exit ${ERR}
