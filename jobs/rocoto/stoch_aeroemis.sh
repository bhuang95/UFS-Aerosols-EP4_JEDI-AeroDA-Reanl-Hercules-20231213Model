#!/bin/bash
##SBATCH -q debug
##SBATCH -p hera
##SBATCH -A wrf-chem
##SBATCH -t 00:30:00
##SBATCH -n 1
##SBATCH -J pertemis
##SBATCH -o pertemis.out
##SBATCH -e pertemis.out

set -x

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-data"}
GBBDIR_NRT=${GBBDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/GBBEPx"}
CEDSDIR_NRT=${CEDSDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/CEDS/v2019/"}
CEDSVER=${CEDSVER:-"2019"}
MEGANDIR_NRT=${MEGANDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/MEGAN_OFFLINE_BVOC/v2019-10/"}
DUSTDIR_NRT=${DUSTDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/Dust/"}
CDATE=${CDATE:-"2023083006"}
CYCINTHR=${CYCINTHR:-"6"}
#NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
NDATE=${HOMEgfs}/misc/ndate/ndate
MEMBER=${MEMBER:-"-1"}
DATA=${DATA:-"/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/RUNDIRS/$CDATE/gdas/fcst/"}


#ROTDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/stochEmis/readPattern/dr-data
#DATA=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/UFS-Aerosols/stochEmis/readPattern/data
#FHMAX=12

#module purge
#source "${HOMEgfs}/ush/preamble.sh"
#. ${HOMEgfs}/ush/load_fv3gfs_modules.sh
#status=$?
#[[ $status -ne 0 ]] && exit $status
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/home/mpagowsk/mapp_2018/libs/fortran-datetime/lib"

EMIS_SRCS=${AEROEMIS_SRCS:-"GBBEPx CEDS MEGAN DUSTPARM DUSTSRC"}
OCNSPPT=${AEROEMIS_SPPT:-"1.0"}
OCNSPPT_LSCALE=${AEROEMIS_SPPT_LSCALE:-"500000"}
OCNSPPT_TAU=${AEROEMIS_SPPT_TAU:-"6"}
STOCH_INIT=${AEROEMIS_STOCH_INIT:-".F."}
STOCH_INIT_RST00Z=${AEROEMIS_STOCH_INIT_RST00Z:-".T."}
TSTEP=${TSTEP:-"1"}
FCST_HR=${FHMAX:-"6"}
DELAY_HR=${DELAY_HR:-"6"}
OUTFREQ_HR=${OUTFREQ_HR:-"1"}
NX_GRIDS=360
NY_GRIDS=180
SPPT_INTP=".T."
ISEED_TMP=$((CDATE*1000 + MEMBER*10 + 3))
ISEED_EMISPERT=${ISEED_SPPT:-"${ISEED_TMP}"}
STOCH_WRITE=".T."
GBBEPx_VERSION=${AERO_EMIS_FIRE:-"gbbepx_v004"}

PERTEXEC_CHEM=${HOMEgfs}/exec/standalone_stochy_chem.x
PERTEXEC_DUST=${HOMEgfs}/exec/standalone_stochy_dust.x

NLN='/bin/ln -sf'
NMV='/bin/mv'
NRM='/bin/rm -rf'
NCP='/bin/cp -rL'

CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})
GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}

EDATE=$(${NDATE} ${FCST_HR} ${CDATE})
EY=${EDATE:0:4}
EM=${EDATE:4:2}
ED=${EDATE:6:2}
EH=${EDATE:8:2}

#PERT_FHMAX=$(${NDATE} ${FCST_HR} ${CDATE})

# GBBEPx files
if [ ${GBBEPx_VERSION} = 'gbbepx_v004' ]; then
    GBBEPx_ORG="${GBBDIR_NRT}/GBBEPx_all01GRID.emissions_v004_${CY}${CM}${CD}.nc"
    GBBEPx_PRE="GBBEPx_all01GRID.emissions_v004_"
elif [ ${GBBEPx_VERSION} = 'gbbepx_v003' ]; then
    GBBEPx_ORG="${GBBDIR_NRT}/GBBEPx_all01GRID.emissions_v003_${CY}${CM}${CD}.nc"
    GBBEPx_PRE="GBBEPx_all01GRID.emissions_v003_"
else
    echo "GBBEPx_VERSION missing and exit"
    exit 100
fi
#GBBEPx_VHR=$((12-${CH}))
GBBEPx_VAR="'BC','CO','CO2','MeanFRP','NH3','NOx','OC','PM2.5','SO2'"
GBBEPx_CREC_FILLV=".F."
GBBEPx_CV=""

# CEDS files
CEDS_ORG="${CEDSDIR_NRT}/${CY}/CEDS.${CEDSVER}.emis.${CY}${CM}${CD}.nc"
CEDS_PRE="CEDS.${CEDSVER}.emis."
#CEDS_VHR=$((0-${CH}))
CEDS_VAR="'NH3_oc','NH3_tr','NH3_re','NH3_in','NH3_ag','SO4_ship','SO2_ship','BC_elev','OC_ship','BC_ship','OC_elev','SO2_elev','BC','OC','SO2'"
CEDS_CREC_FILLV=".F."
CEDS_CV=""

# MEGAN files
MEGAN_ORG="${MEGANDIR_NRT}/${CY}/MEGAN.OFFLINE.BIOVOC.${CY}.emis.${CY}${CM}${CD}.nc"
MEGAN_PRE="MEGAN.OFFLINE.BIOVOC.${CY}.emis."
#MEGAN_VHR=$((0-${CH}))
MEGAN_VAR="'mtpo','mtpa','limo','isoprene'"
MEGAN_CREC_FILLV=".F."
MEGAN_CV=""

# DUSTPARM files
#DUSTPARM_ORG="${DUSTDIR_NRT}/FENGSHA_p81_10km_inputs.2018${CM}01.nc"
#DUSTPARM_PRE="FENGSHA_p81_10km_inputs."
DUSTPARM_ORG="${DUSTDIR_NRT}/FENGSHA_2022_NESDIS_inputs_10km_v3.2_2018${CM}.nc"
DUSTPARM_PRE="FENGSHA_2022_NESDIS_inputs_10km_v3.2_"
#DUSTPARM_VHR=$((0-${CH}))
#DUSTPARM_VAR="'albedo_drag','clayfrac','sandfrac','uthres'"
#DUSTPARM_VAR="'albedo_drag','clayfrac','sandfrac','uthres','uthres_sg','sep'"
DUSTPARM_VAR="'albedo_drag','clayfrac','sandfrac','uthres'"
DUSTPARM_CREC_FILLV=".T."
DUSTPARM_CV="  
  cv_ad=0.25
  cv_clay=0.25
  cv_sand=0.25
  cv_ut=0.25
  "

# DUSTSRC files
DUSTSRC_ORG="${DUSTDIR_NRT}/gocart.dust_source.v5a.x1152_y721.nc"
DUSTSRC_PRE="gocart.dust_source.v5a.x1152_y721."
#DUSTSRC_VHR=$((0-${CH}))
DUSTSRC_VAR="'du_src'"
DUSTSRC_CREC_FILLV=".T."
DUSTSRC_CV="
  cv_dusrc=0.15
  "

if [ ${MEMBER} -lt 0 ]; then
    ENKFOPT=""
    MEMOPT=""
elif [ ${MEMBER} -eq 0 ]; then
    ENKFOPT="enkf"
    MEMOPT="ensmean"
else
    ENKFOPT="enkf"
    MEMOPT="mem$(printf %03d ${MEMBER})"

fi

[[ ! -d ${DATA} ]] && mkdir -p ${DATA}
#[[ ! -d ${DATA}/INPUT ]] && mkdir -p ${DATA}/INPUT

RSTDIR_GDATE=${COM_ATMOS_RESTART_PREV}
RSTDIR_CDATE=${COM_ATMOS_RESTART}
CONF_CDATE=${COM_CONF}
STOCHPAT_IN=${COM_ATMOS_RESTART_PREV}/${CY}${CM}${CD}.${CH}0000.aeroemis_stoch.res.nc
STOCHPAT_OUT=${EY}${EM}${ED}.${EH}0000.aeroemis_stoch.res.nc

if [ ${STOCH_INIT} = ".T." ]; then
    if [ ${STOCH_INIT_RST00Z} = ".T." -a ${CH} = "00" ]; then
        STOCH_INIT=".F."
    else
        if [ ! -e ${STOCHPAT_IN} ]; then
           STOCH_INIT=".F."
           echo "WARNING: STOCH_INIT was changed to False due to missing pattern from previoys cycle. "
        fi
    fi
fi

if [ ${STOCH_INIT} = ".T." ]; then
    DELAY_HR=0
fi

for EMIS_SRC in ${EMIS_SRCS}; do
    DIR_TGT="${DATA}/pert_${EMIS_SRC}"
    PERTEXEC=${PERTEXEC_CHEM}
    if [ ${EMIS_SRC} = "GBBEPx" ]; then
        FILE_ORG=${GBBEPx_ORG}
	FILE_TGT_PRE=${GBBEPx_PRE}
	VARLIST=${GBBEPx_VAR}
	CREC_FILLV=${GBBEPx_CREC_FILLV}
	CV_VARS=${GBBEPx_CV}
    elif [ ${EMIS_SRC} = "CEDS" ]; then
        FILE_ORG=${CEDS_ORG}
	FILE_TGT_PRE=${CEDS_PRE}
	VARLIST=${CEDS_VAR}
	CREC_FILLV=${CEDS_CREC_FILLV}
	CV_VARS=${CEDS_CV}
    elif [ ${EMIS_SRC} = "MEGAN" ]; then
        FILE_ORG=${MEGAN_ORG}
	FILE_TGT_PRE=${MEGAN_PRE}
	VARLIST=${MEGAN_VAR}
	CREC_FILLV=${MEGAN_CREC_FILLV}
	CV_VARS=${MEGAN_CV}
    elif [ ${EMIS_SRC} = "DUSTPARM" ]; then
        FILE_ORG=${DUSTPARM_ORG}
	FILE_TGT_PRE=${DUSTPARM_PRE}
	VARLIST=${DUSTPARM_VAR}
	CREC_FILLV=${DUSTPARM_CREC_FILLV}
	CV_VARS=${DUSTPARM_CV}
        DIR_TGT="${DATA}/pert_DUST"
	PERTEXEC=${PERTEXEC_DUST}
    elif [ ${EMIS_SRC} = "DUSTSRC" ]; then
        FILE_ORG=${DUSTSRC_ORG}
	FILE_TGT_PRE=${DUSTSRC_PRE}
	VARLIST=${DUSTSRC_VAR}
	CREC_FILLV=${DUSTSRC_CREC_FILLV}
	CV_VARS=${DUSTSRC_CV}
        DIR_TGT="${DATA}/pert_DUST"
	PERTEXEC=${PERTEXEC_DUST}
    else
        echo "${EMIS_SRC} not inlcuded in ${EMIS_SRCS} and exit"
	exit 100
    fi

    [[ ! -d ${DIR_TGT} ]] && mkdir -p ${DIR_TGT}
    cd ${DIR_TGT}


    [[ ! -d ./INPUT ]] && mkdir ./INPUT
    if [ ${STOCH_INIT} = ".T." ]; then
        ${NCP} ${STOCHPAT_IN} ./INPUT//ocn_stoch.res.nc
    fi
    ${NCP} ${FILE_ORG} ./INPUT/${EMIS_SRC}.nc
    ${NCP} ${PERTEXEC} ./standalone_stochy_${EMIS_SRC}.x

    ${NRM} input.nml
    ${NRM} ${FILE_TGT_PRE}????????t??:??:??z.nc
cat > input.nml << EOF
&chem_io
  cdate='${CDATE}'
  fnamein_prefix='./INPUT/${EMIS_SRC}'
  fnameout_prefix='${FILE_TGT_PRE}'
  varlist=${VARLIST}
  tstep=$((TSTEP*3600))
  fcst_length=$((FCST_HR*3600))
  delay_time=$((DELAY_HR*3600))
  output_interval=$((OUTFREQ_HR*3600))
  nx_fixed=${NX_GRIDS}
  ny_fixed=${NY_GRIDS}
  sppt_interpolate=${SPPT_INTP}
  fillvalue_correct=${CREC_FILLV}
  write_stoch_pattern=${STOCH_WRITE}
  fnameout_pattern='./${STOCHPAT_OUT}'
${CV_VARS}
/
&nam_stochy
  stochini=${STOCH_INIT}
  ocnsppt=${OCNSPPT}
  ocnsppt_lscale=${OCNSPPT_LSCALE}
  ocnsppt_tau=$((OCNSPPT_TAU*3600))
  iseed_ocnsppt=${ISEED_EMISPERT}
/
&nam_sfcperts
/
&nam_sppperts
/
&chem_stoch
  do_sppt=.true.
/
EOF

echo "Perturbing ${EMIS_SRC}"
[[ ! -d ${RSTDIR_CDATE} ]] && mkdir -p ${RSTDIR_CDATE}
${NCP} input.nml ${COM_CONF}/ufs.${EMIS_SRC}_emis.input.nml
srun --export=all -n 1 ./standalone_stochy_${EMIS_SRC}.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "Perturbing ${EMIS_SRC} failed and exit"
    exit 100
else
    echo "Perturbing ${EMIS_SRC} is successful and modify the date if necessary."
    if [ ${STOCH_WRITE}  = ".T." ]; then
        if [ -e ${STOCHPAT_OUT} ]; then
	    ${NMV} ${STOCHPAT_OUT} ${RSTDIR_CDATE}/
	    STOCH_WRITE=".F."
	else
            echo "${STOCHPAT_OUT} doesn't exist and exit"
            exit 100
	fi
    fi

    if [ ${DELAY_HR} -eq 0 ]; then
        FILE_CDATE=${RSTDIR_GDATE}/${FILE_TGT_PRE}${CY}${CM}${CD}t${CH}:00:00z.nc
	${NCP} ${FILE_CDATE} ./
    fi
    FILE_VDATE=${FILE_TGT_PRE}${EY}${EM}${ED}t${EH}:00:00z.nc
    ${NCP} ${FILE_VDATE} ${RSTDIR_CDATE}/
#    IHR=0
#    while [ ${IHR} -le ${FCST_HR} ]; do
#	IHR0=$(printf "%02d" ${IHR})
#        VDATE=$(${NDATE} ${IHR} ${CDATE})
#        VYMD=${VDATE:0:8}
#        VH=${VDATE:8:2}
#	FILE_CDATE=${FILE_TGT_PRE}${CY}${CM}${CD}${CH}t${IHR0}:00:00z.nc
#	FILE_VDATE=${FILE_TGT_PRE}${VYMD}t${VH}:00:00z.nc
#	if [ ! -e ${FILE_CDATE} ]; then
#	    echo "${FILE_CDATE} does not exist and exit"
#	    exit 100
#	else
#	    /bin/mv ${FILE_CDATE} ${FILE_VDATE}
#	fi
#
#	IHR=$((IHR+OUTFREQ_HR))
#    done

fi
done

#rm -rf ${DATA}
echo $(date) EXITING $0 with return code ${ERR} >&2
exit ${ERR}
