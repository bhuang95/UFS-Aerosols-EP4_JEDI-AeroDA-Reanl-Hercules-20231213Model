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
IDATE=${CDATE:-"2020063018"}
CASE_CNTL=${CASE_CNTL:-"C96"}
CASE_ENKF=${CASE_ENKF:-"C96"}
CYCINTHR=${CYCINTHR:-"6"}
DATAROOT=${DATAROOT:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/grid-aeros/"}
COMPONENT=${COMPONENT:-"model_data/atmos/restart"}
FHMIN=${FHMIN:-"0"}
FHOUT=${FHOUT:-"6"}
FHMAX=${FHMAX:-"168"}

#NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
NDATE=${HOMEgfs}/misc/ndate/ndate
AEROLLEXEC=${HOMEgfs}/exec/fv32ll_reanalysis.x
AEROPLLEXEC=${HOMEgfs}/exec/fv32pll.x
NCORES=1

#Load modules
source ${HOMEjedi}/jedi_module_base.hera.sh
#source /home/Mariusz.Pagowski/.jedi
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 1
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/home/mpagowsk/mapp_2018/libs/fortran-datetime/lib"

jobid="diag_fv3_aeros".$$
DATA1=${DATA:-${DATAROOT}/${jobid}}

JEDIUSH=${HOMEgfs}/ush/JEDI/


IYMD=${IDATE:0:8}
IH=${IDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

### Determine what to field to perform
ENKFOPT=""
MEMOPT=""
MEMSTR=""
TRCR="fv_tracer"
RSTFHR=${FHMIN}
while [ ${RSTFHR} -le ${FHMAX} ]; do
    RSTDIR=${ROTDIR}/${ENKFOPT}gdas.${IYMD}/${IH}/${MEMOPT}${MEMSTR}/${COMPONENT}/
    FV3AEROPLLDIR=${ROTDIR}/${ENKFOPT}gdas.${IYMD}/${IH}/diag/aeros_grid_pll/${MEMOPT}${MEMSTR}
    DATA=${DATA1}/${RSTFHR}
    CDATE=$(${NDATE} ${RSTFHR} ${IDATE})
    RSTFHRSTR=`printf %03d ${RSTFHR}`
    CYMD=${CDATE:0:8}
    CH=${CDATE:8:2}

    AEROSRC=${FV3AEROPLLDIR}/fv3_aeros_${TRCR}_${CDATE}_pll.nc
    AEROTGT=${FV3AEROPLLDIR}/fv3_aeros_${TRCR}_${IDATE}_fhr${RSTFHRSTR}_pll.nc
    export HOMEgfs HOMEjedi RSTDIR FV3AEROPLLDIR CDATE CASE TRCR NCORES AEROLLEXEC AEROPLLEXEC
    [[ ! -d ${DATA} ]] && mkdir -p  ${DATA}
    cd ${DATA}
    echo "Running run_latlon_aod_LUTs for ${RSTFHRSTR}-${TRCR}"
    $JEDIUSH/run_latlon_aeros_longfcst_pll.sh
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "run_latlon_aod_LUTs failed for ${RSTFHRSTR}-${TRCR} and exit"
        exit 1
    else
        echo "run_latlon_aod_LUTs completed for ${RSTFHRSTR}-${TRCR} and move on"
        ${NMV} ${AEROSRC} ${AEROTGT}
        ${NRM} ${DATA}
    fi
    RSTFHR=$((${RSTFHR}+${FHOUT}))
done

# Postprocessing
mkdata="YES"
VERBOSE="YES"
[[ $mkdata = "YES" ]] && rm -rf ${DATA1}
echo ${IDATE} > ${TASKRC}
#set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $ERR >&2
fi
exit ${ERR}
