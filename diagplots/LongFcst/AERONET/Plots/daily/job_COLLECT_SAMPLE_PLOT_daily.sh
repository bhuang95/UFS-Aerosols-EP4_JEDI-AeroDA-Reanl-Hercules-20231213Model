#!/bin/bash
#SBATCH -n 1
#SBATCH -t 03:30:00
#SBATCH -p service
##SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J AERONET-PLOT
#SBATCH -D ./
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/plotAeronet.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/plotAeronet.out

export OMP_NUM_THREADS=1
set -x 

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

CURDIR=$(pwd)

# Plot scattering plot and relative bias and RMSE against AERONET for noda and da expariment
# Both freerun and da experiments are needed. 
#SDATE=2017120800 # Starting cycle. Here not using cycels before 2017101000 for spinup purpose
#EDATE=2017123100 # Ending cycle
SDATE=2020060800 # Starting cycle. Here not using cycels before 2017101000 for spinup purpose
EDATE=2020063000 # Ending cycle
MISS_AERONET=${CURDIR}/Record_AeronetHfxMissing.info
CINC=24
PMONTH=False
AODTYPE='AERONET_SOLAR_AOD15'
TOPEXPDIR=/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc
#TOPEXPDIR=/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/MariuszRun
	# run dir
EXPS="
    RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006
    "
#    RET_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201712
#    RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201712
#    RET_EP4_AeroDA_NoSPE_YesSfcanl_v14_0dz0dp_41M_C96_201712
#    RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006
#    RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006
#    RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006
#    RET_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201712
#    RET_EP4_AeroDA_NoSPE_YesSfcanl_v14_0dz0dp_41M_C96_201712
#    RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006
FHMIN=0
FHOUT=6
FHMAX=120
PLOT_DAYS="1 2 3 4 5"
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

PYCLECSAMP=COLLECT_AERONET_AOD500nm_LongFcst.py
PYCLECSAMP_STATION=COLLECT_AERONET_AOD_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_LongFcst.py
PYPLTPDF=plt_AERONET_AOD_OBS_HFX_MPL_PDF_500nm_LongFcst.py
PYPLTMEANSTATS=plt_AERONET_Mean_Bias_R2_LongFcst_Daily.py
PYPLTMAP=plt_AERONET_AOD_COUNT_BIAS_RMSE_MAE_BRRMSE_500nm_relativeError_LongFcst.py 

for EXP in ${EXPS}; do
    TOPDIAGDIR=${TOPEXPDIR}/${EXP}/diagplots/LongFcst/AERONET/${AODTYPE}
    SAMPDIR=${TOPDIAGDIR}/SAMPLES
    PLOTTMPDIR=${TOPDIAGDIR}/Daily/PLOTS-${SDATE}-${EDATE}

    [[ ! -d ${PLOTTMPDIR} ]] && mkdir -p ${PLOTTMPDIR}

    cd ${PLOTTMPDIR}
    cp ${CURDIR}/${PYCLECSAMP} ./${PYCLECSAMP}
    cp ${CURDIR}/${PYCLECSAMP_STATION} ./${PYCLECSAMP_STATION}
    cp ${CURDIR}/${PYPLTPDF} ./${PYPLTPDF}
    cp ${CURDIR}/${PYPLTMEANSTATS} ./${PYPLTMEANSTATS}
    cp ${CURDIR}/${PYPLTMAP} ./${PYPLTMAP}

if [ "HBO" = 'HBO' ]; then
# Step-1: Output and collect AERONET AOD and HFX samples
echo "Step-1: Output and collect AERONET AOD and HFX samples"
CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}
    INDIR=${TOPEXPDIR}/${EXP}/dr-data-longfcst-backup/gdas.${CY}${CM}${CD}/${CH}/diag/aod_obs
    OUTDIR=${SAMPDIR}/${EXP}/${CY}/${CY}${CM}/${CY}${CM}${CD}/
    [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}

    FHR=${FHMIN}
    while [ ${FHR} -le ${FHMAX} ]; do
	FHRPAD=$(printf "%03d" ${FHR})
        FIELD="fhr${FHRPAD}"
        SAMPFILE=${EXP}_${AODTYPE}_${SDATE}_${EDATE}_${FIELD}.out
	OUTFILE=${OUTDIR}/${EXP}_${AODTYPE}_lon_lat_obs_hfx_${CDATE}_${FIELD}.txt
	if [ -f ${OUTFILE} ];then
            echo "${OUTFILE} exists and continue."
	else
	    if ( grep ${CDATE} ${MISS_AERONET} ); then
		echo "AERONET missing at ${CDATE} and touch ${OUTFILE}"
                touch ${OUTFILE}
	    else
		echo "Run ${PYCLECSAMP} at ${CDATE}"
                python ${PYCLECSAMP} -c ${CDATE} -a ${AODTYPE} -f ${FIELD} -i ${INDIR} -o ${OUTFILE}
		ERR=$?
		[[ ${ERR} -ne 0 ]] && exit 1
	    fi
	fi

	if [ ${CDATE} = ${SDATE} ]; then
	    cp ${OUTFILE} ${SAMPFILE}
	else
	    cat ${OUTFILE} >> ${SAMPFILE}
	fi

	FHR=$((${FHR} + ${FHOUT}))
    done
    CDATE=$(${NDATE} ${CINC} ${CDATE})
done

for PDAY in ${PLOT_DAYS}; do
    SAMPFILE_DAY=${EXP}_${AODTYPE}_${SDATE}_${EDATE}_Day${PDAY}.out
    STFHR=$(( ${PDAY} - 1 ))
    STFHR=$(( ${STFHR} * 24 + ${FHOUT} ))
    EDFHR=$(( ${PDAY} * 24 ))
    
    FHR=${STFHR}
    echo "HBO-DAY-${STFHR}-${EDFHR}-${SAMPFILE_DAY}"
    while [ ${FHR} -le ${EDFHR} ]; do
        FHRPAD=$(printf "%03d" ${FHR})
	FIELD="fhr${FHRPAD}"
	SAMPFILE_FHR=${EXP}_${AODTYPE}_${SDATE}_${EDATE}_${FIELD}.out
    	echo "HBO-FHR-${SAMPFILE_FHR}"
    
	if [ ${FHR} = ${STFHR} ]; then
	    cp ${SAMPFILE_FHR} ${SAMPFILE_DAY}
	else
	    cat ${SAMPFILE_FHR} >> ${SAMPFILE_DAY}
	fi
        FHR=$((${FHR} + ${FHOUT}))
    done
done

# Step-2: Output and collect bias, rmse
echo "Step-2: Output and collect bias, rmse"
cd ${PLOTTMPDIR}
#FHR=${FHMIN}
#while [ ${FHR} -le ${FHMAX} ]; do
for PDAY in ${PLOT_DAYS}; do
    FIELD="Day${PDAY}"
    SAMPFILE=${EXP}_${AODTYPE}_${SDATE}_${EDATE}_${FIELD}.out
    OUTFILE=${EXP}_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}_${FIELD}.out
    python ${PYCLECSAMP_STATION} -i ${SAMPFILE} -o ${OUTFILE}
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit 1
    #FHR=$((${FHR} + ${FHOUT}))
done
fi

# Step-3: Plot scattering density plot
echo "Step-3: Plot scattering density plot"
cd ${PLOTTMPDIR}
#FHR=${FHMIN}
#FHRS=""
#while [ ${FHR} -le ${FHMAX} ]; do
for PDAY in ${PLOT_DAYS}; do
    FIELD="Day${PDAY}"
    CYCLE=${SDATE}-${EDATE}-${FIELD}
    SAMPFILE=${EXP}_${AODTYPE}_${SDATE}_${EDATE}_${FIELD}.out

    python ${PYPLTPDF} -c ${CYCLE} -p ${EXP} -i ${SAMPFILE}
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit 1
done
#python ${PYPLTMEANSTATS} -c ${SDATE}-${EDATE} -p ${EXP} -f "${PLOT_DAYS}"
#[[ ${ERR} -ne 0 ]] && exit 1

# Step-4: Plot relative bias and rmse
echo "Step-3: Plot relative bias and rmset"
cd ${PLOTTMPDIR}
#FHR=${FHMIN}
#while [ ${FHR} -le ${FHMAX} ]; do
#    FHRPAD=$(printf "%03d" ${FHR})
for PDAY in ${PLOT_DAYS}; do
    FIELD="Day${PDAY}"
    CYCLE=${SDATE}-${EDATE}-${FIELD}
    OUTFILE=${EXP}_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}_${FIELD}.out

    python ${PYPLTMAP} -c ${CYCLE} -p ${AODTYPE} -i ${OUTFILE}
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit 1
    FHR=$((${FHR} + ${FHOUT}))
done

mkdir -p ${PLOTTMPDIR}/figures
mv *.png ${PLOTTMPDIR}/figures

done # for DAEXPS
exit ${ERR}
