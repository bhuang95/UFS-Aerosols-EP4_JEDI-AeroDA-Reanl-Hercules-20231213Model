#!/bin/bash
##SBATCH -N 1
##SBATCH -t 00:30:00
###SBATCH -p hera
##SBATCH -q debug
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o latlon_aod.out
##SBATCH -e latlon_aod.out

set -x

PSLOT=${PSLOT:-"RET_FreeRun_NoEmisStoch_C96_202006"}
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/RET_FreeRun_NoEmisStoch_C96_202006/dr-data-longfcst-backup"}
TASKRC=${TASKRC:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp-C96-LongFcst/TaskRecords/cmplCycle_freeRun_noEmisstoch_longfcst_diag.rc"}
IDATE=${CDATE:-"2020060100"}
CASE=${CASE:-"C96"}
DATAROOT=${DATAROOT:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/grid-aod/tests/"}
FHMIN=${FHMIN:-"0"}
FHOUT=${FHOUT:-"6"}
FHMAX=${FHMAX:-"120"}
#RSTFHRS=${RSTFHRS:-"06 12 18 24 30 36 42 48 54 60 66 72 78 84 90 96 102 108 114 120"}
#RSTFHRS="00 ${RSTFHRS}"
COMPONENT="model_data/atmos/restart"

NDATE="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"
FV3AODEXEC=${HOMEgfs}/exec/gocart_aod_fv3_mpi_LUTs.x
LLAODEXEC=${HOMEgfs}/exec/fv3aod2ll.x
NCORES=40

#Load modules
source ${HOMEjedi}/jedi_module_base.hera.sh
#source /home/Mariusz.Pagowski/.jedi
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 1
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/home/mpagowsk/mapp_2018/libs/fortran-datetime/lib"

jobid="diag_fv3_aod".$$
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
TRCR="fv_tracer"
RSTFHR=${FHMIN}
while [ ${RSTFHR} -le ${FHMAX} ]; do
#for RSTFHR in ${RSTFHRS}; do
        RSTDIR=${ROTDIR}/${ENKFOPT}gdas.${IYMD}/${IH}/${MEMOPT}${MEMSTR}/${COMPONENT}
        FV3AODDIR=${ROTDIR}/${ENKFOPT}gdas.${IYMD}/${IH}/diag/aod_grid/${MEMOPT}${MEMSTR}
	DATA=${DATA1}/${RSTFHR}
	CDATE=$(${NDATE} ${RSTFHR} ${IDATE})
        RSTFHRSTR=`printf %03d ${RSTFHR}`
        CYMD=${CDATE:0:8}
        CH=${CDATE:8:2}

	AODSRC=${FV3AODDIR}/fv3_aod_LUTs_${TRCR}_${CDATE}_ll.nc
	AODTGT=${FV3AODDIR}/fv3_aod_LUTs_${TRCR}_${IDATE}_fhr${RSTFHRSTR}_ll.nc
	FV3AODSRC=${DATA}/FV3AOD
	FV3AODTGT=${FV3AODDIR}/FV3AOD_${TRCR}_${IDATE}_fhr${RSTFHRSTR}
	echo ${AODSRC}
	echo ${AODTGT}
        export HOMEgfs HOMEjedi RSTDIR FV3AODDIR CDATE CASE  TRCR NCORES FV3AODEXEC LLAODEXEC
	[[ ! -d ${DATA} ]] && mkdir -p  ${DATA}
	cd ${DATA}
	echo "Running run_latlon_aod_LUTs for ${RSTFHR}"
        $JEDIUSH/run_latlon_aod_nasaluts.sh
	ERR=$?
	if [ ${ERR} -ne 0 ]; then
	    echo "run_latlon_aod_LUTs failed for ${RSTFHR} and exit"
	    exit 1
	else
	    echo "run_latlon_aod_LUTs completed for ${RSTFHR} and move on"
	    ${NMV} ${AODSRC} ${AODTGT}
	    ${NMV} ${FV3AODSRC} ${FV3AODTGT}
	    #[[ ! -d ${FV3AODTGT} ]] && mkdir -p ${FV3AODTGT}
	    #itile=1
	    #while [ ${itile} -le 6 ]; do
	    #    TILESRC=${FV3AODSRC}/${CYMD}.${CH}0000.fv_aod_LUTs.${TRCR}.res.tile${itile}.nc
	    #    TILETGT=${FV3AODTGT}/${IYMD}.${IH}0000.fhr${RSTFHRSTR}.fv_aod_LUTs.${TRCR}.res.tile${itile}.nc
	    #    ${NMV} ${TILESRC} ${TILETGT}
	    #	itile=$((${itile}+1))
	    #done
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
