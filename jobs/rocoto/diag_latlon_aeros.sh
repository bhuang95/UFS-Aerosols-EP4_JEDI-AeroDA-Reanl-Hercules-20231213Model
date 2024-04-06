#!/bin/bash
#SBATCH -n 1
#SBATCH -t 00:30:00
##SBATCH -p hera
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/grid-aeros/latlon_aod.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/grid-aeros/latlon_aod.out

set -x

PSLOT=${PSLOT:-"RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_RETcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl/"}
HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006/dr-data-backup"}
EXPDIR=${EXPDIR:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/"}
TASKRC=${TASKRC:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/TaskRecords/cmplCycle_misc.rc"}
CDATE=${CDATE:-"2020063018"}
CASE_CNTL=${CASE_CNTL:-"C96"}
CASE_ENKF=${CASE_ENKF:-"C96"}
AERODA=${AERODA:-"YES"}
ENSRUN=${ENSRUN:-"NO"}
ENSDIAG=${ENSDIAG:-"NO"}
ENSGRP=${ENSGRP:-"01"}
NMEM_EFCSGRP=${NMEM_EFCSGRP:-"5"}
NMEM_ENKF=${NMEM_ENKF:-"20"}
CYCINTHR=${CYCINTHR:-"6"}
DATAROOT=${DATAROOT:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/grid-aeros/"}
COMPONENT=${COMPONENT:-"model_data/atmos/restart"}

NDATE="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"
AEROLLEXEC=${HOMEgfs}/exec/fv32ll_reanalysis.x
AEROPLLEXEC=${HOMEgfs}/exec/fv32pll.x
#AEROLLEXEC=/scratch1/BMC/chem-var/pagowski/exec/fv32ll_reanalysis.x
#AEROPLLEXEC=/scratch1/BMC/chem-var/pagowski/exec/fv32pll.x
NCORES=1

#Load modules
source ${HOMEjedi}/jedi_module_base.hera.sh
#source /home/Mariusz.Pagowski/.jedi
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 1
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/home/mpagowsk/mapp_2018/libs/fortran-datetime/lib"

jobid="diag_fv3_aeros".$$
DATA1=${DATA:-${DATAROOT}/${jobid}}

ENSED=$((${NMEM_EFCSGRP} * 10#${ENSGRP}))
ENSST=$((ENSED - NMEM_EFCSGRP + 1))
if [ ${ENSED} -gt ${NMEM_ENKF} ]; then
    echo "Member number ${ENSED} exceeds ensemble size ${NMEM_ENKF} and exit."
    exit 100
fi

JEDIUSH=${HOMEgfs}/ush/JEDI/

GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}
GYMD=${GDATE:0:8}
GH=${GDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

### Determine what to field to perform
HOFXFIELDS=""

if [ ${ENSGRP} = "01" ]; then
    HOFXFIELDS="${HOFXFIELDS} cntlbckg"
fi

#if [ ${ENSRUN} = "YES" ]; then
#    if [ ${ENSGRP} = "01" ]; then
#        HOFXFIELDS="${HOFXFIELDS} meanbckg"
#    fi
#    if [ ${ENSDIAG} = "YES" ]; then
#        HOFXFIELDS="${HOFXFIELDS} membckg"
#    fi
#fi

if [ ${AERODA} = "YES" ]; then
    if [ ${ENSGRP} = "01" ]; then
        #HOFXFIELDS="${HOFXFIELDS} cntlanal meananal"
        HOFXFIELDS="${HOFXFIELDS} cntlanal"
    fi
#    if [ ${ENSDIAG} = "YES" ]; then
#        HOFXFIELDS="${HOFXFIELDS} memanal"
#    fi
fi

echo "HOFXFIELDS=${HOFXFIELDS}"

[[ -z ${HOFXFIELDS} ]] && { echo "HOFXFIELDS is empty" ; exit 1; }

for FIELD in ${HOFXFIELDS}; do
    if [ ${FIELD} = "cntlbckg" -o ${FIELD} = "cntlanal" ]; then
        ENKFOPT=""
	CASE=${CASE_CNTL}
    else
        ENKFOPT="enkf"
	CASE=${CASE_ENKF}
    fi

    if [ ${FIELD} = "cntlbckg" -o ${FIELD} = "cntlanal" ]; then
        MEMOPT=""
    elif [ ${FIELD} = "meanbckg" -o ${FIELD} = "meananal" ]; then
	MEMOPT="ensmean"
    else
        MEMOPT="mem"
    fi

    if [ ${FIELD} = "cntlanal" -o ${FIELD} = "meananal" -o ${FIELD} = "memanal" ]; then
        TRCR="fv_tracer_aeroanl"
    else
	TRCR="fv_tracer"
    fi

    if [ ${FIELD} = "membckg" -o ${FIELD} = "memanal" ]; then
        MEMST=${ENSST}
        MEMED=${ENSED}
    else
	MEMST=0
	MEMED=0
    fi

    IMEM=${MEMST}
    while [ ${IMEM} -le ${MEMED} ]; do
	if [ ${IMEM} -ge 1 ]; then
            MEMSTR=`printf %03d ${IMEM}`
	else
            MEMSTR=""
	fi
        RSTDIR=${ROTDIR}/${ENKFOPT}gdas.${GYMD}/${GH}/${MEMOPT}${MEMSTR}/${COMPONENT}/

	ROTDIRBASE=$(basename ${ROTDIR})
	if [ ${ROTDIRBASE} = "dr-data-backup" ]; then
            FV3AEROLLDIR=${ROTDIR}/${ENKFOPT}gdas.${CYMD}/${CH}/diag/aeros_grid_ll/${MEMOPT}${MEMSTR}
            FV3AEROPLLDIR=${ROTDIR}/${ENKFOPT}gdas.${CYMD}/${CH}/diag/aeros_grid_pll/${MEMOPT}${MEMSTR}
	else
            FV3AEROLLDIR=${ROTDIR}/${ENKFOPT}gdas.${CYMD}/${CH}/diag/${MEMOPT}${MEMSTR}
            FV3AEROPLLDIR=${ROTDIR}/${ENKFOPT}gdas.${CYMD}/${CH}/diag/${MEMOPT}${MEMSTR}
	fi

	DATA=${DATA1}/${MEMOPT}${MEMSTR}/${FIELD}

        export HOMEgfs HOMEjedi RSTDIR FV3AEROLLDIR FV3AEROPLLDIR CDATE CASE TRCR NCORES AEROLLEXEC AEROPLLEXEC
	[[ ! -d ${DATA} ]] && mkdir -p  ${DATA}
	cd ${DATA}
	echo "Running run_latlon_aod_LUTs for ${FIELD}-${TRCR}"
        $JEDIUSH/run_latlon_aeros.sh
	ERR=$?
	if [ ${ERR} -ne 0 ]; then
	    echo "run_latlon_aod_LUTs failed for ${FIELD}-${TRCR} and exit"
	    exit 1
	else
	    echo "run_latlon_aod_LUTs completed for ${FIELD}-${TRCR} and move on"
	    #if [ -d ${FV3AODDIR}/FV3AOD_${TRCR} ]; then
	    #    ${NRM} ${FV3AODDIR}/FV3AOD_${TRCR}
	    #fi
	    #${NMV} ${DATA}/FV3AOD ${FV3AODDIR}/FV3AOD_${TRCR}
	    #${NMV} ${DATA}/*.nl ${FV3AODDIR}/
	    ${NRM} ${DATA}
        fi

	IMEM=$((IMEM+1))
    done
done

# Postprocessing
mkdata="YES"
VERBOSE="YES"
[[ $mkdata = "YES" ]] && rm -rf ${DATA1}
echo ${CDATE} > ${TASKRC}
#set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $ERR >&2
fi
exit ${ERR}
