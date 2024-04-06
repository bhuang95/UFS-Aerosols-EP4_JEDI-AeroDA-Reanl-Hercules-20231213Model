#!/bin/bash --login
#SBATCH --account=chem-var
#SBATCH --qos=debug
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
#SBATCH --time=00:29:00
#SBATCH --job-name=timeSeries
#SBATCH --output=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog//nrt_NASAECMWF.log


export OMP_NUM_THREADS=1
set -x 

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

ulimit -s unlimited
module purge
module load intel/2022.1.2
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

CURDIR=$(pwd)
SDATE="2020060800"
EDATE="2020063000"
RUNDIR="/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/"
EXPRUNS="
   RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006 
   RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006
   RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006
"
LFCSTTYPE="longfcst"
DIAGDIR="diagplots/LongFcst/AODReana/PLOTS-${LFCSTTYPE}-${SDATE}-${EDATE}"
CAMS="camseac4"
MERRA2="merra2"
FHMIN=0
FHMAX=120
FHOUT=24

PYCODE="plt_nasa_ec_aod_2dmap_550nm.py"

for EXPRUN in ${EXPRUNS}; do
    OUTDIR=${RUNDIR}/${EXPRUN}/${DIAGDIR}/Figures
    [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
    cd ${OUTDIR}
    cp ${CURDIR}/${PYCODE} ./
    FHR=${FHMIN}
    while [ ${FHR} -le ${FHMAX} ]; do
        FHRPAD=$(printf "%03d" ${FHR})
	FLEAD="fhr${FHRPAD}"
	CAMSDATA=${RUNDIR}/${EXPRUN}/${DIAGDIR}/${CAMS}/fv3_${CAMS}_AODSTAT_2D_${FLEAD}.nc
	MERRA2DATA=${RUNDIR}/${EXPRUN}/${DIAGDIR}/${MERRA2}/fv3_${MERRA2}_AODSTAT_2D_${FLEAD}.nc
	python ${PYCODE} -l ${FLEAD} -n ${MERRA2DATA} -e ${CAMSDATA}
	
	ERR=$?
        [[ ${ERR} -ne 0 ]] && exit ${ERR}
	mv FCST_MERRA2_CAMS_AOD.png ${EXPRUN}_FCST_MERRA2_CAMS_AOD_${FLEAD}.png
	FHR=$((${FHR} + ${FHOUT}))
    done
done

