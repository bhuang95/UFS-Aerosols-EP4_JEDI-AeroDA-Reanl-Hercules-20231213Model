#!/bin/bash --login

#SBATCH --output=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/metplus_merra2.out
#SBATCH --job-name=metplus
#SBATCH --qos=batch
#SBATCH --time=03:29:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
#SBATCH --account=wrf-chem

#/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/metPlusDiag/metPlusOutput//wrk-NRT-NODA-cntlBckg-NASAana-2022010100-2022043018-1.0deg/met_series_anl//viirs-m_npp-viirs-m_npp/met_series_anl-NRT-NODA-cntlBckg.aod-NASAana.AODANA.out

export OMP_NUM_THREADS=1

set -x
# Comparison between 2 models at pressure level as a time series.
# Requirements
# 1. If both models are in NetCDF, ensure they have the same vertical layers for comparison
#    and in same top-down or down-top order.
# 2. List all the pres layers in NetCDF files
# 3. List the name of variables that are desired to compare in the corresponding order.
#  
# main.conf: define input and output base.
# 
# Setup SDATE, EDATE, INCH, GRID_NAME, FCST_NAME, OBS_NAME, FCST_VAR, FCST_VARLEV, OBS_VAR, OBS_VARLEV, 
#       FCSTFILETMP, OBSFILETMP, OUTPUTFILE_NAME
# SDATE: start date of evaluation
# EDATE: end date of evaluation
# INC_H: increment of hours
# GRID_NAME: GXXX from https://www.nco.ncep.noaa.gov/pmb/docs/on388/tableb.html
#            G002 2.5 deg by 2.5 deg
#            G004 0.5 deg by 0.5 deg
# PLEV: All the pressure levels in NetCDF files
# FCST/OBSPATH: The path saved forecast and obs data files.
# FCST/OBSFILETMP: The name that can be searched under FCST/OBSPATH
# 
#

#if [ -d /glade/scratch ]; then
#   export machine=Cheyenne
#elif [ -d /scratch1/NCEPDEV/da ]; then
#   export machine=Hera
#fi
#source $BASE/ush/met_load.sh

machine=${machine:-"Hera"}
BASE=${BASE:-"/home/Bo.Huang/JEDI-2020/miscScripts-home/METPlus/METplus-AerosoDiag/METplus_pkg/"}
source $BASE/ush/met_load.sh
rc=$?
if [ $rc -ne 0 ]; then
   exit $rc
fi

#
# User defined variables
#
#SDATE=${SDATE:-"2020060800"}
#EDATE=${EDATE:-"2020063000"}
SDATE=${SDATE:-"2017120800"}
EDATE=${EDATE:-"2017123100"}
INC_H=${INC_H:-"24"}

OBSBASE=${OBSBASE:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/Reanalysis"}
#OBSTYPES=${OBSTYPES:-"camseac4 merra2"}
OBSTYPES=${OBSTYPES:-"merra2"}
#OBSTYPES=${OBSTYPES:-"merra2"}
MISSING_NASA=${MISSING_NASA:-"NO"}
MISSING_EC=${MISSING_EC:-"NO"}

#INPUTBASE=${INPUTBASE:-"/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/"}
INPUTBASE=${INPUTBASE:-"/scratch2/BMC/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/MariuszRun/"}
EXPRUNS="
    RET_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201712
    RET_EP4_AeroDA_NoSPE_YesSfcanl_v14_0dz0dp_41M_C96_201712
    RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201712
    "
    #RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006,
    #RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006
    #RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006
LFCSTTYPE="longfcst"
FHMIN=0
FHMAX=120
FHOUT=6

NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
CONFIG_DIR=$BASE/conf
INCONFIG=${CONFIG_DIR}/SeriesAnalysis.conf.IN
MAINCONF=$CONFIG_DIR/main.conf.IN
MASTER=$METPLUS_PATH/ush/master_metplus.py

if [[ ${MISSING_NASA} == "YES" ]]; then
    OBSTYPES="camseac4"
fi
if [[ ${MISSING_EC} == "YES" ]]; then
    OBSTYPES="merra2"
fi


GRID_NAME="G003" # 1.o deg

FCST_HEAD="fv3_aods_"
FCST_SUFF="_ll.nc"
FCST_VAR="aod"
FCST_VARDIM="4"
SIGLEV="TRUE"
for EXPRUN in ${EXPRUNS}; do
    FCSTPATH=$INPUTBASE/${EXPRUN}/dr-data-${LFCSTTYPE}-backup/
    FCST_NAME=${EXPRUN}
for OBSTYPE in ${OBSTYPES}; do
    OBSPATH=$OBSBASE/${OBSTYPE}/
    if [[ ${OBSTYPE} == "camseac4" ]]; then
        OBS_NAME=${OBSTYPE}
        OBS_HEAD="cams_aods_"
        OBS_SUFF=".nc"
        OBS_VAR="aod550"
        OBS_VARDIM="3"
    elif [[ ${OBSTYPE} == "merra2" ]]; then
        OBS_NAME=${OBSTYPE}
        OBS_HEAD="m2_aods_"
        OBS_SUFF="_ll.nc"
        OBS_VAR="AODANA"
        OBS_VARDIM="3"
    else
        echo "Not valid observation and exit"
        exit 1
    fi

    FCSTFILETMP="${FCST_HEAD}*${FCST_SUFF}"
    OBSFILETMP="${OBS_HEAD}*${OBS_SUFF}"
    #NDATE="python $BASE/bin/ndate.py"

FHR=${FHMIN}
while [ ${FHR} -le ${FHMAX} ]; do
    FHRPAD=$(printf "%03d" ${FHR})
    FIELD="fhr${FHRPAD}"

    OUTPUTDIR=${INPUTBASE}/${EXPRUN}/diagplots/LongFcst/AODReana/PLOTS-${LFCSTTYPE}-${SDATE}-${EDATE}/${OBSTYPE}/

if [ ! -d ${OUTPUTDIR}/fv3_${OBSTYPE}_AODSTAT_2D_${FIELD}.nc ]; then
    WRKD=${OUTPUTDIR}/tmp_${FIELD}
    OUTPUTBASE=${WRKD}

    [[  -d ${WRKD} ]] && rm -rf  ${WRKD}/*
    mkdir -p ${WRKD}

    cd $WRKD
    mkdir -p $WRKD/fcst $WRKD/obs

    FCSTDIR=$WRKD/fcst
    OBSDIR=$WRKD/obs

    CDATE=$SDATE
    while [ $CDATE -le $EDATE ]; do
	ODATE=$(${NDATE} ${FHR} ${CDATE})
	CYMD=${CDATE:0:8}
	CH=${CDATE:8:2}

        ln -sf $FCSTPATH/gdas.${CYMD}/${CH}/diag/aod_grid/fv3_aod_LUTs_fv_tracer_${CDATE}_${FIELD}_ll.nc ./fcst/${FCST_HEAD}${CDATE}${FCST_SUFF}
        ln -sf $OBSPATH/${OBSTYPE}-550nm-AOD-${ODATE}.nc ./obs/${OBS_HEAD}${CDATE}${OBS_SUFF}
        CDATE=`$NDATE $INC_H $CDATE`
    done

if [ ${SIGLEV} == "TRUE" ]; then
    FPLEVLIST=("sigLev")
    FNCLVIDXLIST=(0)

    OPLEVLIST=("sigLev")
    ONCLVIDXLIST=(0)
else
    FPLEVLIST=(100 250 400 500 600 700 850 925 1000)
    FNCLVIDXLIST=(0 1 2 3 4 5 6 7 8)

    OPLEVLIST=(100 250 400 500 600 700 850 925 1000)
    ONCLVIDXLIST=(0 1 2 3 4 5 6 7 8)
fi

nplv=${#FPLEVLIST[*]}

echo ${nplv}

np=0
while [[ $np -lt $nplv ]];
do
    PLEV=${FPLEVLIST[$np]}
    FCST_VARLEV="\"(0,${FNCLVIDXLIST[$np]},*,*)\""
    OBS_VARLEV="\"(0,${ONCLVIDXLIST[$np]},*,*)\""

    if [ ${FCST_VARDIM} == "3" ]; then
       FCST_VARLEV="\"(0,*,*)\""
    fi

    if [ ${OBS_VARDIM} == "3" ]; then
       OBS_VARLEV="\"(0,*,*)\""
    fi

    OUTPUTTMP="${FCST_VAR}_${PLEV}hPa.nc"

    echo $FCST_VAR $FCST_VARLEV
    echo $OBS_VAR $OBS_VARLEV
    echo $OUTPUTTMP

#if [ "YES" == "NO" ]; then
cat $MAINCONF | sed s:_MET_PATH_:${MET_PATH}:g \
              | sed s:_INPUTBASE_:${INPUTBASE}:g \
              | sed s:_OUTPUTBASE_:${OUTPUTBASE}:g \
              > ./main.conf 

cat $INCONFIG | sed s:_SDATE_:${SDATE}:g \
              | sed s:_EDATE_:${EDATE}:g \
              | sed s:_INC_H_:${INC_H}:g \
              | sed s:_BASE_:${BASE}:g \
              | sed s:_GRID_NAME_:${GRID_NAME}:g \
              | sed s:_FCST_NAME_:${FCST_NAME}:g \
              | sed s:_OBS_NAME_:${OBS_NAME}:g \
              | sed s:_FCST_VAR_:${FCST_VAR}:g \
              | sed s:_FCST_VARLEV_:${FCST_VARLEV}:g \
              | sed s:_OBS_VAR_:${OBS_VAR}:g \
              | sed s:_OBS_VARLEV_:${OBS_VARLEV}:g \
              | sed s:_FCSTDIR_:${FCSTDIR}:g \
              | sed s:_OBSDIR_:${OBSDIR}:g \
              | sed s:_FCSTFILETMP_:"${FCSTFILETMP}":g \
              | sed s:_OBSFILETMP_:"${OBSFILETMP}":g \
              | sed s:_OUTPUTTMP_:${OUTPUTTMP}:g \
              > ./SeriesAnalysis.${OBS_VAR}_${PLEV}hPa.conf
#fi

time $MASTER -c ./main.conf -c ./SeriesAnalysis.${OBS_VAR}_${PLEV}hPa.conf

err=$?
if [ ${err} != '0' ]; then
    echo "METPlus failed at ${SDATE} for ${FCST_NAME}_${OBS_NAME} and exit!"
    exit 1
else
    echo "METPlus succeeded at ${SDATE} for ${FCST_NAME}-${OBS_NAME} and proceed to next step!"
    mv ${WRKD}/met_tool_wrapper/SeriesAnalysis/aod_sigLevhPa.nc ${OUTPUTDIR}/fv3_${OBSTYPE}_AODSTAT_2D_${FIELD}.nc
    #rm -rf $WRKD
fi

let np=np+1
done
fi

FHR=$((${FHR} + ${FHOUT}))
done # FIELD
done # OBSTYPE
done # EXPRUN

exit
