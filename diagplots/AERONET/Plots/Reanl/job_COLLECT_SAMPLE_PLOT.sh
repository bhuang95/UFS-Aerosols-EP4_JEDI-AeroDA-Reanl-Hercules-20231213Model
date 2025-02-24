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
SDATE=2018010100 #2017120800 # Starting cycle. Here not using cycels before 2017101000 for spinup purpose
EDATE=2018011718 #2017123118 # Ending cycle
#SDATE=2020060800 # Starting cycle. Here not using cycels before 2017101000 for spinup purpose
#EDATE=2020063118 # Ending cycle
MISS_AERONET=${CURDIR}/Record_AeronetHfxMissing.info
CINC=6
AODTYPE='AERONET_SOLAR_AOD15'
PMONTH=False
TOPEXPDIR=/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl
#TOPEXPDIR=/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/MariuszRun
	# run dir
#NODAEXP="RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006"
NODAEXP="AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801"
#NODAEXP=RET_FreeRun_NoEmisStoch_C96_202006
	# Freerun expname
	# If using mine, link /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/FreeRun-201710/dr-data-backup to your ${TOPEXPDIR}
#DAEXP=ENKF_AEROSEMIS-ON_STOCHINIT-ON-201710 #ENKF_AEROSEMIS-OFF-201710
DAEXPS="
        AeroReanl_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201801
       "
        #RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006
	#RET_EP4_AeroDA_NoSPE_YesSfcanl_v14_0dz0dp_41M_C96_201712
        #RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006
        #RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006
	#RET_AeroDA_NoEmisStoch_C96_202006
#DAEXPS="
#       "
       #ENKF_AEROSEMIS-ON_STOCH_MODIFIED_INIT-ON-201710
       #ENKF_AEROSEMIS-ON_STOCHINIT-ON-201710
       #ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710
       #ENKF_AEROSEMIS-OFF-201710
       # DA expnames
       # If using mine DA exp, link dr-data-backup in /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc// ENKF_AEROSEMIS-OFF-201710 and ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710 to your ${TOPEXPDIR}

for DAEXP in ${DAEXPS}; do
EXPS="${NODAEXP} ${DAEXP}"
TOPDIAGDIR=${TOPEXPDIR}/${DAEXP}/diagplots/AERONET/${AODTYPE}
SAMPDIR=${TOPDIAGDIR}/SAMPLES
PLOTTMPDIR=${TOPDIAGDIR}/PLOTS-${SDATE}-${EDATE}
NODASAMPDIR=${SAMPDIR}/${NODAEXP}/
DASAMPDIR=${SAMPDIR}/${DAEXP}/

PYCLECSAMP=COLLECT_AERONET_AOD500nm_6H.py
PYCLECSAMP_STATION=COLLECT_AERONET_AOD_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm.py
PYPLTPDF=plt_AERONET_AOD_OBS_HFX_MPL_PDF_500nm.py
PYPLTMAP=plt_AERONET_AOD_COUNT_BIAS_RMSE_MAE_BRRMSE_500nm_relativeError.py 

[[ ! -d ${PLOTTMPDIR} ]] && mkdir -p ${PLOTTMPDIR}

cd ${PLOTTMPDIR}
cp ${CURDIR}/${PYCLECSAMP} ./${PYCLECSAMP}
cp ${CURDIR}/${PYCLECSAMP_STATION} ./${PYCLECSAMP_STATION}
cp ${CURDIR}/${PYPLTPDF} ./${PYPLTPDF}
cp ${CURDIR}/${PYPLTMAP} ./${PYPLTMAP}

NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

# Step-1: Output and collect AERONET AOD and HFX samples
echo "Step-1: Output and collect AERONET AOD and HFX samples"
for EXP in ${EXPS}; do
    if [ ${EXP} = ${DAEXP} ]; then
        FIELDS="cntlBkg cntlAnl"
    elif [ ${EXP} = ${NODAEXP} ]; then 
	FIELDS="cntlBkg"
    else
        echo "Please define EXPS and exit now"
	exit 1
    fi
   
    for FIELD in ${FIELDS}; do
        SAMPFILE=${EXP}_${FIELD}_${AODTYPE}_${SDATE}_${EDATE}.out
        CDATE=${SDATE}
        while [ ${CDATE} -le ${EDATE} ]; do
            CY=${CDATE:0:4}
            CM=${CDATE:4:2}
            CD=${CDATE:6:2}
            CH=${CDATE:8:2}
            INDIR=${TOPEXPDIR}/${EXP}/dr-data-backup/gdas.${CY}${CM}${CD}/${CH}/diag/aod_obs
            OUTDIR=${SAMPDIR}/${EXP}/${FIELD}/${CY}/${CY}${CM}/${CY}${CM}${CD}/
	    [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}

	    OUTFILE=${OUTDIR}/${EXP}_${FIELD}_${AODTYPE}_lon_lat_obs_hfx_${CDATE}.txt
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
            CDATE=$(${NDATE} ${CINC} ${CDATE})
	done
    done
done
 
# Step-2: Output and collect bias, rmse
echo "Step-2: Output and collect bias, rmse"
cd ${PLOTTMPDIR}
for EXP in ${EXPS}; do
    if [ ${EXP} = ${DAEXP} ]; then
        FIELDS="cntlBkg cntlAnl"
    elif [ ${EXP} = ${NODAEXP} ]; then 
	FIELDS="cntlBkg"
    else
        echo "Please define EXPS and exit now"
	exit 1
    fi
   
    for FIELD in ${FIELDS}; do
        SAMPFILE=${EXP}_${FIELD}_${AODTYPE}_${SDATE}_${EDATE}.out
        OUTFILE=${EXP}_${FIELD}_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}.out
        python ${PYCLECSAMP_STATION} -i ${SAMPFILE} -o ${OUTFILE}
        ERR=$?
        [[ ${ERR} -ne 0 ]] && exit 1
    done
done

# Step-3: Plot scattering density plot
echo "Step-3: Plot scattering density plot"
cd ${PLOTTMPDIR}
CYCLE=${SDATE}-${EDATE}
FREERUN=${NODAEXP}_cntlBkg_${AODTYPE}_${SDATE}_${EDATE}.out
DABKG=${DAEXP}_cntlBkg_${AODTYPE}_${SDATE}_${EDATE}.out
DAANL=${DAEXP}_cntlAnl_${AODTYPE}_${SDATE}_${EDATE}.out

python ${PYPLTPDF} -c ${CYCLE} -p ${AODTYPE} -m ${PMONTH} -x ${FREERUN} -y ${DABKG} -z ${DAANL}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 1

# Step-4: Plot relative bias and rmse
echo "Step-3: Plot relative bias and rmset"
cd ${PLOTTMPDIR}
CYCLE=${SDATE}-${EDATE}
FREERUN=${NODAEXP}_cntlBkg_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}.out
DABKG=${DAEXP}_cntlBkg_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}.out
DAANL=${DAEXP}_cntlAnl_${AODTYPE}_COUNT_OBS_HFX_BIAS_RMSE_MAE_BRRMSE_500nm_${SDATE}_${EDATE}.out

python ${PYPLTMAP} -c ${CYCLE} -p ${AODTYPE} -x ${FREERUN} -y ${DABKG} -z ${DAANL}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit 1

done # for DAEXPS
exit ${ERR}

