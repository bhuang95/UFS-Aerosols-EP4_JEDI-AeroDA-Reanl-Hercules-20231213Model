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

source "${HOMEgfs}/ush/preamble.sh"
#. $HOMEgfs/ush/load_fv3gfs_modules.sh
. $HOMEgfs/ush/load_ufswm_modules.sh
ulimit -s unlimited
#UFSMODDIR=/work/noaa/gsd-fv3-dev/bhuang/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/global-workflow/sorc/ufs_model.fd/tests
#source ${UFSMODDIR}/detect_machine.sh
#MACHINE_ID="orion"
#source ${UFSMODDIR}/module-setup.sh
#module use ${UFSMODDIR}/../modulefiles
#module load ufs_orion.intel
#module list
status=$?
[[ $status -ne 0 ]] && exit $status

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-data"}
GBBDIR_NRT=${GBBDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/GBBEPx"}
CEDSDIR_NRT=${CEDSDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/CEDS/v2019/"}
CEDSVER=${CEDSVER:-"2019"}
MEGANDIR_NRT=${MEGANDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/MEGAN_OFFLINE_BVOC/v2019-10/"}
DUSTDIR_NRT=${DUSTDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/Dust/"}
CDATE=${CDATE:-"2023083006"}
CYCINTHR=${CYCINTHR:-"6"}
NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
AEROEMIS_STOCH_CNTL=${AEROEMIS_STOCH_CNTL:-"YES"}
AEROEMIS_STOCH_ENKF=${AEROEMIS_STOCH_ENKF:-"YES"}
NMEM_ENKF=${NMEM_ENKF:-"5"}
ENSRUN=${ENSRUN:-"YES"}
COMP_PERT="model_data/atmos/restart/pertEmis"

if [ ${AEROEMIS_STOCH_CNTL} = "NO" ] && [ ${AEROEMIS_STOCH_ENKF} = "NO" ]; then
    echo "Do not perform SPE for control and ensemble"
    exit 0
fi

export SLURM_EXACT=1
export SLURM_MEM_PER_NODE=0

ENSST=1
ENSED=${NMEM_ENKF}

if [ ${AEROEMIS_STOCH_CNTL} = "YES" ]; then
    ENSST=0
fi

if [ ${ENSRUN} = "NO"  ] || [ ${AEROEMIS_STOCH_ENKF} = "NO" ]; then
    ENSED=0
fi

if [ ${ENSED} -lt ${ENSST} ]; then
    echo "ENSED smaller than ENSST and please check first before continuing."
    exit 1
fi

job="pertemis"
jobid="${job}.$$"
DATA=${DATA:-${DATAROOT}/${jobid}}
[[ ! -d ${DATA} ]] && mkdir -p ${DATA}

export LD_LIBRARY_PATH="/home/mpagowsk/mapp_2018/libs/fortran-datetime/lib:${LD_LIBRARY_PATH}"

EMIS_SRCS=${AEROEMIS_SRCS:-"GBBEPx CEDS MEGAN DUSTPARM"}
OCNSPPT=${AEROEMIS_SPPT:-"1.0"}
OCNSPPT_LSCALE=${AEROEMIS_SPPT_LSCALE:-"500000"}
OCNSPPT_TAU=${AEROEMIS_SPPT_TAU:-"6"}
STOCH_INIT=${AEROEMIS_STOCH_INIT:-".F."}
STOCH_INIT_RST00Z=${AEROEMIS_STOCH_INIT_RST00Z:-".T."}
TSTEP=${TSTEP:-"1"}
FCST_HR=${FHMAX:-"6"}
DELAY_HR=${DELAY_HR:-"6"}
OUTFREQ_HR=${OUTFREQ_HR:-"1"}
NX_GRIDS=180
NY_GRIDS=90
SPPT_INTP=".T."
STOCH_WRITE_ORIG=".T."
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
CYMD=${CY}${CM}${CD}

GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})
GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}
GYMD=${GY}${GM}${GD}

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
    GBBEPx_VAR="'BC','CH4','CO','CO2','MeanFRP','NH3','NOx','OC','PM2.5','SO2'"
elif [ ${GBBEPx_VERSION} = 'gbbepx_v003' ]; then
    GBBEPx_ORG="${GBBDIR_NRT}/GBBEPx_all01GRID.emissions_v003_${CY}${CM}${CD}.nc"
    GBBEPx_PRE="GBBEPx_all01GRID.emissions_v003_"
    GBBEPx_VAR="'BC','CO','CO2','MeanFRP','NH3','NOx','OC','PM2.5','SO2'"
else
    echo "GBBEPx_VERSION missing and exit"
    exit 100
fi
#GBBEPx_VHR=$((12-${CH}))
GBBEPx_CREC_FILLV=".T."
GBBEPx_CV="  cv=1.0"
GBBEPx_BF="  bfactor=1.0"

# CEDS files
CEDS_ORG="${CEDSDIR_NRT}/${CY}/CEDS.${CEDSVER}.emis.${CY}${CM}${CD}.nc"
CEDS_PRE="CEDS.${CEDSVER}.emis."
#CEDS_VHR=$((0-${CH}))
CEDS_VAR="'NH3_oc','NH3_tr','NH3_re','NH3_in','NH3_ag','SO4_ship','SO2_ship','BC_elev','OC_ship','BC_ship','OC_elev','SO2_elev','BC','OC','SO2'"
CEDS_CREC_FILLV=".T."
CEDS_CV="  cv=1.0"
CEDS_BF="  bfactor=1.0"

# MEGAN files
MEGAN_ORG="${MEGANDIR_NRT}/${CY}/MEGAN.OFFLINE.BIOVOC.${CY}.emis.${CY}${CM}${CD}.nc"
MEGAN_PRE="MEGAN.OFFLINE.BIOVOC.${CY}.emis."
#MEGAN_VHR=$((0-${CH}))
MEGAN_VAR="'mtpo','mtpa','limo','isoprene'"
MEGAN_CREC_FILLV=".T."
MEGAN_CV="  cv=1.0"
MEGAN_BF="  bfactor=1.0"

# DUSTPARM files
#DUSTPARM_ORG="${DUSTDIR_NRT}/FENGSHA_p81_10km_inputs.2018${CM}01.nc"
#DUSTPARM_PRE="FENGSHA_p81_10km_inputs."
DUSTPARM_ORG="${DUSTDIR_NRT}/FENGSHA_2022_NESDIS_inputs_10km_v3.2.2018${CM}01.nc"
DUSTPARM_PRE="FENGSHA_2022_NESDIS_inputs_10km_v3.2."
#DUSTPARM_VHR=$((0-${CH}))
#DUSTPARM_VAR="'albedo_drag','clayfrac','sandfrac','uthres'"
#DUSTPARM_VAR="'albedo_drag','clayfrac','sandfrac','uthres','uthres_sg','sep'"
DUSTPARM_VAR="'albedo_drag','clayfrac','sandfrac','uthres','sep'"
DUSTPARM_CREC_FILLV=".T."
DUSTPARM_BF=""
DUSTPARM_CV="  
  cv_ad=1.0
  cv_clay=1.0
  cv_sand=1.0
  cv_ut=1.0
  cv_sep=1.0
  "

# DUSTSRC files
#DUSTSRC_ORG="${DUSTDIR_NRT}/gocart.dust_source.v5a.x1152_y721.nc"
#DUSTSRC_PRE="gocart.dust_source.v5a.x1152_y721."
##DUSTSRC_VHR=$((0-${CH}))
#DUSTSRC_VAR="'du_src'"
#DUSTSRC_CREC_FILLV=".T."
#DUSTSRC_CV="
#  cv_dusrc=0.15
#  "

if [ ${STOCH_INIT} = ".T." ]; then
    if [ ${STOCH_INIT_RST00Z} = ".T." -a ${CH} = "00" ]; then
        STOCH_INIT=".F."
    #else
    #    if [ ! -e ${STOCHPAT_IN} ]; then
    #       STOCH_INIT=".F."
    #       echo "WARNING: STOCH_INIT was changed to False due to missing pattern from previoys cycle. "
    #    fi
    fi
fi

if [ ${STOCH_INIT} = ".T." ]; then
    DELAY_HR=0
fi

STOCH_WRITE=${STOCH_WRITE_ORIG}
for EMIS_SRC in ${EMIS_SRCS}; do
    if [ ${EMIS_SRC} = "GBBEPx" ]; then
        FILE_ORG=${GBBEPx_ORG}
        FILE_TGT_PRE=${GBBEPx_PRE}
        VARLIST=${GBBEPx_VAR}
        CREC_FILLV=${GBBEPx_CREC_FILLV}
        CV_VARS=${GBBEPx_CV}
        BF_VARS=${GBBEPx_BF}
        PERTEXEC=${PERTEXEC_CHEM}
    elif [ ${EMIS_SRC} = "CEDS" ]; then
        FILE_ORG=${CEDS_ORG}
        FILE_TGT_PRE=${CEDS_PRE}
        VARLIST=${CEDS_VAR}
        CREC_FILLV=${CEDS_CREC_FILLV}
        CV_VARS=${CEDS_CV}
        BF_VARS=${CEDS_BF}
        PERTEXEC=${PERTEXEC_CHEM}
    elif [ ${EMIS_SRC} = "MEGAN" ]; then
        FILE_ORG=${MEGAN_ORG}
        FILE_TGT_PRE=${MEGAN_PRE}
        VARLIST=${MEGAN_VAR}
        CREC_FILLV=${MEGAN_CREC_FILLV}
        CV_VARS=${MEGAN_CV}
        BF_VARS=${MEGAN_BF}
        PERTEXEC=${PERTEXEC_CHEM}
    elif [ ${EMIS_SRC} = "DUSTPARM" ]; then
        FILE_ORG=${DUSTPARM_ORG}
        FILE_TGT_PRE=${DUSTPARM_PRE}
        VARLIST=${DUSTPARM_VAR}
        CREC_FILLV=${DUSTPARM_CREC_FILLV}
        CV_VARS=${DUSTPARM_CV}
        BF_VARS=${DUSTPARM_BF}
        PERTEXEC=${PERTEXEC_DUST}
    #elif [ ${EMIS_SRC} = "DUSTSRC" ]; then
    #    FILE_ORG=${DUSTSRC_ORG}
    #    FILE_TGT_PRE=${DUSTSRC_PRE}
    #    VARLIST=${DUSTSRC_VAR}
    #    CREC_FILLV=${DUSTSRC_CREC_FILLV}
    #    CV_VARS=${DUSTSRC_CV}
    #    PERTEXEC=${PERTEXEC_DUST}
    else
        echo "${EMIS_SRC} not inlcuded in ${EMIS_SRCS} and exit"
        exit 100
    fi

    IMEM=${ENSST}
    while [ ${IMEM} -le ${ENSED} ]; do
        ISEED_TMP=$((CDATE*1000 + IMEM*10 + 3))
        #ISEED_EMISPERT=${ISEED_SPPT:-"${ISEED_TMP}"}
        ISEED_EMISPERT=${ISEED_TMP}

        if [ ${IMEM} -eq 0 ]; then
            ENKFOPT="gdas"
            MEMOPT=""
        else
            ENKFOPT="enkfgdas"
            MEMOPT="mem$(printf %03d ${IMEM})"
        fi

	PERTLOG=${ROTDIR}/logs/${CDATE}/pert_${EMIS_SRC}_${ENKFOPT}${MEMOPT}
        PERT_GDATE=${ROTDIR}/${ENKFOPT}.${GYMD}/${GH}/${MEMOPT}/${COMP_PERT}/
        CONF_CDATE=${ROTDIR}/${ENKFOPT}.${CYMD}/${CH}/${MEMOPT}/conf/
        STOCHPAT_IN=${PERT_GDATE}/${CY}${CM}${CD}.${CH}0000.aeroemis_stoch.res.nc
        STOCHPAT_OUT=${EY}${EM}${ED}.${EH}0000.aeroemis_stoch.res.nc

        DIR_TGT="${DATA}/pert_${EMIS_SRC}/${ENKFOPT}${MEMOPT}/"
        PERT_GDATE_TGT=${PERT_GDATE}/pert_${EMIS_SRC}
        [[ ! -d ${DIR_TGT} ]] && mkdir -p ${DIR_TGT}
        [[ ! -d ${PERT_GDATE_TGT} ]] && mkdir -p ${PERT_GDATE_TGT}

        [[ ! -d ${CONF_CDATE} ]] && mkdir -p ${CONF_CDATE}

        cd ${DIR_TGT}

        [[ ! -d ./INPUT ]] && mkdir ./INPUT
        if [ ${STOCH_INIT} = ".T." ]; then
            if [ ! -e ${STOCHPAT_IN} ]; then
                echo "STOCH_INIT=.T. but ${STOCHPAT_IN} is missing. Exit now..."
		exit 100
	    else
                ${NCP} ${STOCHPAT_IN} ./INPUT//ocn_stoch.res.nc
	    fi
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
${BF_VARS}
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
        ${NCP} input.nml ${CONF_CDATE}/ufs.${EMIS_SRC}_emis.input.nml
	[[ -e extcode.${EMIS_SRC} ]] && ${NRM} extcode.${EMIS_SRC}
	{ srun --export=all -n 1  ./standalone_stochy_${EMIS_SRC}.x >& ${PERTLOG}; echo "$?" > extcode.${EMIS_SRC}; } &
        IMEM=$((IMEM+1))
    done
    wait

    IMEM=${ENSST}
    while [ ${IMEM} -le ${ENSED} ]; do
        if [ ${IMEM} -eq 0 ]; then
            ENKFOPT="gdas"
            MEMOPT=""
        else
            ENKFOPT="enkfgdas"
            MEMOPT="mem$(printf %03d ${IMEM})"
        fi

        PERT_GDATE=${ROTDIR}/${ENKFOPT}.${GYMD}/${GH}/${MEMOPT}/${COMP_PERT}/
        PERT_CDATE=${ROTDIR}/${ENKFOPT}.${CYMD}/${CH}/${MEMOPT}/${COMP_PERT}/

        DIR_TGT="${DATA}/pert_${EMIS_SRC}/${ENKFOPT}${MEMOPT}/"
        PERT_GDATE_TGT=${PERT_GDATE}/pert_${EMIS_SRC}
        PERT_CDATE_TGT=${PERT_CDATE}/pert_${EMIS_SRC}
        FILE_CDATE=${FILE_TGT_PRE}${CY}${CM}${CD}t${CH}:00:00z.nc
        FILE_VDATE=${FILE_TGT_PRE}${EY}${EM}${ED}t${EH}:00:00z.nc
        STOCHPAT_OUT=${EY}${EM}${ED}.${EH}0000.aeroemis_stoch.res.nc

        [[ ! -d ${PERT_CDATE_TGT} ]] && mkdir -p ${PERT_CDATE_TGT}
	
	cd ${DIR_TGT}
	ERR=$(cat extcode.${EMIS_SRC})
        if [ ${ERR} -ne 0 ]; then
            echo "Perturbing ${EMIS_SRC} failed and exit"
            exit 100
        else
            echo "Perturbing ${EMIS_SRC} is successful and modify the date if necessary."
            if [ ${STOCH_WRITE}  = ".T." ]; then
                if [ -e ${STOCHPAT_OUT} ]; then
	            ${NCP} ${STOCHPAT_OUT} ${PERT_CDATE}/
    	        else
                    echo "${STOCHPAT_OUT} doesn't exist and exit"
                    exit 100
	        fi
            fi

	    ${NCP} ${FILE_VDATE} ${PERT_CDATE_TGT}/${FILE_VDATE}_forNextCycleWithStochInitTrue

            if [ ${DELAY_HR} -eq 0 ]; then
    	        ${NCP} ${PERT_GDATE_TGT}/${FILE_CDATE}_forNextCycleWithStochInitTrue ./${FILE_CDATE}
            fi

            #${NRM} ${PERT_GDATE_TGT}/${FILE_TGT_PRE}????????t??:??:??z.nc
	    ${NRM} ${PERT_GDATE_TGT}/*.nc

            ${NMV} *.nc ${PERT_GDATE_TGT}/

            if [ ${EMIS_SRC} = "MEGAN" ]; then
	    if [ ${CY} != ${EY} ]; then
	        cd ${PERT_GDATE_TGT}
	        FILES_NYEAR=$(ls MEGAN.OFFLINE.BIOVOC.${CY}.emis.${EY}*.nc)
		for FILE in ${FILES_NYEAR}; do
		    FPRE=$(echo "${FILE}" | cut -d. -f1-3)
		    FSUF=$(echo "${FILE}" | cut -d. -f5-)
		    FILE_NYEAR=${FPRE}.${EY}.${FSUF}
		    echo ${FILE}
		    echo ${FILE_NYEAR}
                    ${NCP} ${FILE} ${FILE_NYEAR}
		done
             fi
            fi
        fi
        IMEM=$((IMEM+1))
    done
    STOCH_WRITE=".F."
done

rm -rf ${DATA}
echo $(date) EXITING $0 with return code ${ERR} >&2
exit ${ERR}
