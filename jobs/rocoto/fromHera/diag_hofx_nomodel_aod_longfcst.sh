#!/bin/bash
##SBATCH -N 2
##SBATCH -t 00:30:00
###SBATCH -p hera
##SBATCH -q debug
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o hfx_aod.out
##SBATCH -e hfx_aod.out

set -x

export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
export EXPDIR=${EXPDIR:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp-C96-LongFcst/"}
source ${EXPDIR}/config.aeroanlrun
export DATAROOT=${DATAROOT:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/TestScripts/grid-aod/tests/"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/RET_FreeRun_NoEmisStoch_C96_202006/dr-data-longfcst-backup"}
export HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build/"}
#export HOMEjedi="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/build/fv3-bundle"
export TASKRC=${TASKRC:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work-RetExp-C96-LongFcst/TaskRecords/cmplCycle_freeRun_noEmisstoch_longfcst_hfx_diag.rc"}
export OBSDIR_NRT=${OBSDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/AODObs/AERONET_SOLAR_AOD15/"}
export IDATE=${CDATE:-"2020060100"}
export CDUMP=${CDUMP:-"gdas"}
export CASE=${CASE:-"C96"}
export AODTYPE=${AODTYPE:-"AERONET_SOLAR_AOD15"}
export NCORES=${ncore_hofx:-"48"}
export LAYOUT=${layout_hofx:-"2,4"}
export LEVS=${LEVS:-"128"}
export IO_LAYOUT=${io_layout_hofx:-"1,1"}
export NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
FHMIN=${FHMIN:-"0"}
FHOUT=${FHOUT:-"6"}
FHMAX=${FHMAX:-"120"}
#RSTFHRS=${RSTFHRS:-"06 12 18 24 30 36 42 48 54 60 66 72 78 84 90 96 102 108 114 120"}
#export RSTFHRS="00 ${RSTFHRS}"
COMPONENT="model_data/atmos/restart"

export job="diag_hofx"
export jobid="${job}.$$"
export DATA1=${DATA:-${DATAROOT}/${jobid}}


source ${HOMEjedi}/jedi_module_base.hera.sh
#source /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20230312/build//jedi_module_base.hera.Mariusz.sh
status=$?
[[ $status -ne 0 ]] && exit $status
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"
export OMP_NUM_THREADS=1
ulimit -s unlimited

if ( echo ${AODTYPE} | grep -q "NASA" ); then
    echo "NASA VIIRS AOD retrievals not avaiable and skip"
    exit 0
fi

JEDIUSH=${HOMEgfs}/ush/JEDI/

IYMD=${IDATE:0:8}
IY=${IDATE:0:4}
IM=${IDATE:4:2}
ID=${IDATE:6:2}
IH=${IDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

mkdir -p ${DATA1}
cd ${DATA1}

ENKFOPT=""
MEMOPT=""
TRCR="fv_tracer"
MEMSTR=''
#for RSTFHR in ${RSTFHRS}; do
RSTFHR=${FHMIN}
while [ ${RSTFHR} -le ${FHMAX} ]; do
        RSTDIR=${ROTDIR}/${ENKFOPT}gdas.${IYMD}/${IH}/${MEMOPT}${MEMSTR}/${COMPONENT}
	HOFXDIR=${ROTDIR}/${ENKFOPT}gdas.${IYMD}/${IH}/diag/aod_obs/${MEMOPT}${MEMSTR}
	CDATE=$(${NDATE} ${RSTFHR} ${IDATE})
	DATA=${DATA1}/${MEMOPT}${MEMSTR}/${RSTFHR}
        RSTFHRSTR=`printf %03d ${RSTFHR}`

	AODSRC=${HOFXDIR}/${AODTYPE}_obs_hofx_3dvar_LUTs_${TRCR}_${CDATE}.nc4
	AODTGT=${HOFXDIR}/${AODTYPE}_obs_hofx_3dvar_LUTs_${TRCR}_${IDATE}_fhr${RSTFHRSTR}.nc4

	export HOMEjedi DATA  ROTDIR OBSDIR_NRT AODTYPE RSTDIR TRCR HOFXDIR CDATE CASE LEVS NCORES LAYOUT IO_LAYOUT
	[[ ! -d ${HOFXDIR} ]] && mkdir -p  ${HOFXDIR}
	[[ ! -d ${DATA} ]] && mkdir -p  ${DATA}
	echo "Running run_hofx_nomodel_AOD_LUTs for ${RSTFHR}"
	echo ${RSTDIR}
	echo ${HOFXDIR}
	echo ${AODSRC}
	echo ${AODTGT}
        $JEDIUSH/run_jedi_hofx_nomodel_nasaluts.sh
	ERR=$?
	if [ ${ERR} -ne 0 ]; then
	    echo "run_hofx_nomodel_AOD_LUTs failed for ${FIELD}-${TRCR} and exit"
	    exit 1
	else
	    echo "run_hofx_nomodel_AOD_LUTs completed for ${FIELD}-${TRCR} and move on"
	    if ( echo ${AODTYPE} | grep "AERONET" ); then
	        ${NMV} ${AODSRC} ${AODTGT}
	    else
		echo "Please make sure the correct numbers of files based on your AODTYPE. Exit now..."
		exit 100
            fi
	    ${NRM} ${DATA}
        fi
    RSTFHR=$((${RSTFHR}+${FHOUT}))
done

###############################################################
# Postprocessing
mkdata="YES"
[[ $mkdata = "YES" ]] && rm -rf ${DATA1}
echo ${CDATE} > ${TASKRC}
#set +x
#if [ $VERBOSE = "YES" ]; then
#   echo $(date) EXITING $0 with return code $ERR >&2
#fi
exit ${ERR}
