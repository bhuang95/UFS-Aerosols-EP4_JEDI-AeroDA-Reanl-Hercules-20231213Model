#!/bin/bash
set -x

NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
JEDIDIR=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
DATA=${DATA:-$pwd/analysis.$$}
ROTDIR=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
OBSDIR_NRT=${OBSIDR:-$OBSDIR_NRT}
COMIN_GES=${COMIN_GES:-$COMIN_GES}
COMIN_GES_ENS=${COMIN_GES_ENS:-$COMIN_GES_ENS}
COMP_MOD_ATM_RST=${COMP_MOD_ATM_RST:-"model_data/atmos/restart"}
COMP_CONF=${COMP_CONF:-"conf"}
ANLTIME=${CDATE:-"2001010100"}
GESTIME=$($NDATE -$assim_freq $CDATE)
STARTWIN=$($NDATE -3 $CDATE)
CASE=${CASE:-"C384"} # no lower case
LEVS=${LEVS:-"128"}
CASEC=$(echo ${CASE} |cut -c2-5)
NPX=$((CASEC+1))
NPY=$((CASEC+1))
NPZ=$((LEVS-1))
LAYOUT=${layout_letkf:-"1,1"}
IO_LAYOUT=${io_layout_letkf:-"1,1"}
LETKF_LOC=${LETKF_LOC-"2500e"}
LETKF_INF_MULT=${LETKF_INF_MULT:-"1.2"}
LETKF_INF_RTPP=${LETKF_INF_RTPP:-"0.0"}
LETKF_INF_RTPS=${LETKF_INF_RTPS:-"0.85"}

FIELDMETADIR=${JEDIDIR}/fv3-jedi/test/Data/fieldmetadata/
FV3DIR=${JEDIDIR}/fv3-jedi/test/Data/fv3files/
CRTMFIX=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
JEDIEXE=${JEDIDIR}/bin/fv3jedi_letkf.x

CDUMP=${CDUMP:-"gdas"}
NMEM=${NMEM_ENKF:-"10"}

# Define some aliases
NCP="/bin/cp -r"
NRM="/bin/rm -rf"
NMV="/bin/mv -f"
NLN="/bin/ln -sf"

# set date format
AYY=$(echo ${ANLTIME} | cut -c1-4)
AMM=$(echo ${ANLTIME} | cut -c5-6)
ADD=$(echo ${ANLTIME} | cut -c7-8)
AHH=$(echo ${ANLTIME} | cut -c9-10)
ANLTIMEFMT=${AYY}-${AMM}-${ADD}T${AHH}:00:00Z

GYY=$(echo ${GESTIME} | cut -c1-4)
GMM=$(echo ${GESTIME} | cut -c5-6)
GDD=$(echo ${GESTIME} | cut -c7-8)
GHH=$(echo ${GESTIME} | cut -c9-10)
GESTIMEFMT=${GYY}-${GMM}-${GDD}T${GHH}:00:00Z

SYY=$(echo ${STARTWIN} | cut -c1-4)
SMM=$(echo ${STARTWIN} | cut -c5-6)
SDD=$(echo ${STARTWIN} | cut -c7-8)
SHH=$(echo ${STARTWIN} | cut -c9-10)
STWINFMT=${SYY}-${SMM}-${SDD}T${SHH}:00:00Z


# Link fv3 nemelist files
DATAINPUT=${DATA}/INPUT
mkdir -p ${DATAINPUT}
${NCP} ${FV3DIR}/fmsmpp.nml 		${DATA}/fmsmpp.nml
${NCP} ${FV3DIR}/field_table_gfdl 	${DATA}/field_table_gfdl
${NCP} ${FV3DIR}/akbk${NPZ}.nc4 		${DATAINPUT}/akbk.nc
${NCP} ${FIELDMETADIR}/ufs-aerosol.yaml ${DATA}/ufs-aerosol.yaml

# Link crtm files (only for VIIRS and MODIS)
mkdir -p ${DATA}/CRTM/
LUTS="AerosolCoeff.bin CloudCoeff.bin  
      v.viirs-m_npp.SpcCoeff.bin v.viirs-m_npp.TauCoeff.bin 
      v.modis_terra.SpcCoeff.bin  v.modis_terra.TauCoeff.bin 
      v.modis_aqua.SpcCoeff.bin v.modis_aqua.TauCoeff.bin"

for LUT in ${LUTS}; do
    ${NLN} ${CRTMFIX}/${LUT} ${DATA}/CRTM/${LUT}
done

LUTS=`ls ${CRTMFIX}/NPOESS.* | awk -F "/" '{print $NF}'`
for LUT in ${LUTS}; do
    ${NLN} ${CRTMFIX}/${LUT} ${DATA}/CRTM/${LUT}
done

LUTS=`ls ${CRTMFIX}/USGS.* | awk -F "/" '{print $NF}'`
for LUT in ${LUTS}; do
    ${NLN} ${CRTMFIX}/${LUT} ${DATA}/CRTM/${LUT}
done

LUTS=`ls ${CRTMFIX}/FASTEM6.* | awk -F "/" '{print $NF}'`
for LUT in ${LUTS}; do
    ${NLN} ${CRTMFIX}/${LUT} ${DATA}/CRTM/${LUT}
done

# Link NASA look-up tables
${NLN} ${JEDIDIR}/geos-aero/test/testinput/geosaod.rc ${DATA}/geosaod.rc
${NLN} ${JEDIDIR}/geos-aero/test/testinput/Chem_MieRegistry.rc ${DATA}/Chem_Registry.rc
${NLN} ${JEDIDIR}/geos-aero/test/Data ${DATA}/

# Link observations (only for VIIRS or MODIS)
OBSTIME=${ANLTIME}
if [ ${AODTYPE} = "NOAA_VIIRS" ]; then
    OBSIN=${OBSDIR_NRT}/${OBSTIME}/${AODTYPE}_AOD_npp.${OBSTIME}.iodav3.nc
    #OBSIN1=${OBSDIR_NRT}/${OBSTIME}/${AODTYPE}_AOD_j01.${OBSTIME}.iodav3.nc
    SENSORID=v.viirs-m_npp
    #SENSORID1=v.viirs-m_npp
    OBSOUT=aod_viirs_npp_obs_${OBSTIME}.nc4
    #OBSOUT1=aod_viirs_j01_obs_${OBSTIME}.nc4
    ${NLN} ${OBSIN} ${DATAINPUT}/${OBSOUT}
    #${NLN} ${OBSIN1} ${DATAINPUT}/${OBSOUT1}
elif [ ${AODTYPE} = "MODIS" ]; then
    OBSIN=${OBSDIR_NRT}/${OBSTIME}/nnr_aqua.${OBSTIME}.nc
    #OBSIN1=${OBSDIR_NRT}/${OBSTIME}/nnr_terra.${OBSTIME}.nc
    SENSORID=v.modis_aqua
    #SENSORID1=v.modis_terra
    OBSOUT=aod_nnr_aqua_obs_${OBSTIME}.nc4
    #OBSOUT1=aod_nnr_terra_obs_${OBSTIME}.nc4
    ${NLN} ${OBSIN} ${DATAINPUT}/${OBSOUT}
    #${NLN} ${OBSIN1} ${DATAINPUT}/${OBSOUT1}
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi

# link deterministic background/analysis
ANLPREFIX=${AYY}${AMM}${ADD}.${AHH}0000
GESENSDIR_IN=${COMIN_GES_ENS}/
ANLDIR_OUT=${DATA}/ANALYSIS
mkdir -p ${ANLDIR_OUT}

## Link control bckg/anal files

## Link ensemble bckg and analysis
IMEM=0
while [ ${IMEM} -le ${NMEM} ]; do
    MEMSTR="mem"`printf %03d ${IMEM}`

    MEMDIR_IN=${GESENSDIR_IN}/${MEMSTR}/${COMP_MOD_ATM_RST}
    MEMDIR_OUT=${DATAINPUT}/${MEMSTR}/
    MEMDIR_MEANANL_IN=${GESENSDIR_IN}//ensmean/${COMP_MOD_ATM_RST}
    MEMDIR_ANL_OUT=${ANLDIR_OUT}/${MEMSTR}/
    mkdir -p ${MEMDIR_OUT}
    mkdir -p ${MEMDIR_ANL_OUT}
    mkdir -p ${MEMDIR_MEANANL_IN}/

    if [ ${IMEM} -gt 0 ]; then
        GESCPLR_IN=${MEMDIR_IN}/${ANLPREFIX}.coupler.res
        GESCPLR_OUT=${MEMDIR_OUT}/${ANLPREFIX}.coupler.res
        ${NLN} ${GESCPLR_IN} ${GESCPLR_OUT}
    fi

    ITILE=1
    while [ ${ITILE} -le 6 ]; do
        TILESTR=`printf %1i ${ITILE}`

        if [ ${IMEM} -gt 0 ]; then
            TILEFILE=fv_tracer.res.tile${TILESTR}
            TILEGES_IN=${MEMDIR_IN}/${ANLPREFIX}.${TILEFILE}.nc
            TILEGES_OUT=${MEMDIR_OUT}/${ANLPREFIX}.${TILEFILE}.nc
            ${NLN} ${TILEGES_IN} ${TILEGES_OUT}

            TILEFILE=fv_core.res.tile${TILESTR}
            TILEGES_IN=${MEMDIR_IN}/${ANLPREFIX}.${TILEFILE}.nc
            TILEGES_OUT=${MEMDIR_OUT}/${ANLPREFIX}.${TILEFILE}.nc
            ${NLN} ${TILEGES_IN} ${TILEGES_OUT}

            TILEFILE=fv_tracer_aeroanl_tmp.res.tile${TILESTR}
            TILEANL_IN=${MEMDIR_IN}/${ANLPREFIX}.${TILEFILE}.nc
            TILEANL_OUT=${MEMDIR_ANL_OUT}/${ANLPREFIX}.letkf-gfs_aero.fv_tracer.res.tile${TILESTR}.nc
            if [ -f ${TILEANL_IN} ]; then
                ${NRM} ${TILEANL_IN}
            fi
            ${NLN} ${TILEANL_IN} ${TILEANL_OUT}
        else
            TILEFILE=fv_tracer_aeroanl_tmp.res.tile${TILESTR}
            TILEANL_IN=${MEMDIR_MEANANL_IN}/${ANLPREFIX}.${TILEFILE}.nc
            TILEANL_OUT=${MEMDIR_ANL_OUT}/${ANLPREFIX}.letkf-gfs_aero.fv_tracer.res.tile${TILESTR}.nc
            if [ -f ${TILEANL_IN} ]; then
                ${NRM} ${TILEANL_IN}
            fi
            ${NLN} ${TILEANL_IN} ${TILEANL_OUT}
	fi

       ITILE=$((ITILE+1))
    done

    IMEM=$((IMEM+1))
done

# Link executable
${NLN} ${JEDIEXE} ${DATA}/fv3jedi_enkf.x

# Gnerate control yaml block
BKGBLK="  
background:
  date: ${ANLTIMEFMT}
  members from template:
    template:
      datetime: ${ANLTIMEFMT}
      filetype: fms restart
      state variables: &aerovars [T,delp,sphum,
                                  so4,bc1,bc2,oc1,oc2,
                                  dust1,dust2,dust3,dust4,dust5,
                                  seas1,seas2,seas3,seas4,seas5]
      datapath: INPUT/mem%mem%/
      filename_core: ${ANLPREFIX}.fv_core.res.nc
      filename_trcr: ${ANLPREFIX}.fv_tracer.res.nc
      filename_cplr: ${ANLPREFIX}.coupler.res
    pattern: '%mem%'
    nmembers: ${NMEM}
    zero padding: 3
"

# Generate the yaml block for AOD observations
OBSBLK="  
observations:
  observers:    
  - obs space:
      name: Aod
      distribution:
        name: Halo
        halo size: 2500e3
      obsdatain:
        engine:
          type: H5File
          obsfile: ./INPUT/${OBSOUT}
#       obsdataout:
#         engine:
#           type: H5File
#           obsfile: ./DIAG/diag_${OBSOUT}
      simulated variables: [aerosolOpticalDepth]
      channels: 4
    obs operator:
      name: AodLUTs
      obs options:
        Sensor_ID: ${SENSORID}
        EndianType: little_endian
        CoefficientPath: ./CRTM/
        AerosolOption: aerosols_gocart_1
        RCFile: geosaod.rc
        model units coeff: 1.e-9
    obs error:
      covariance model: diagonal
    obs localizations:
    - localization method: Horizontal Gaspari-Cohn
      lengthscale: ${LETKF_LOC}
#      max nobs: 1000
"

# Create yaml file
cat << EOF > ${DATA}/enkf_gfs_aero_${AODTYPE}.yaml
geometry:
  fms initialization:
    namelist filename: fmsmpp.nml
    field table filename: field_table_gfdl
  akbk: ./INPUT/akbk.nc
  layout: [${LAYOUT}]
  io_layout: [${IO_LAYOUT}]
  npx: ${NPX}
  npy: ${NPY}
  npz: ${NPZ}
  ntiles: 6
  field metadata override: ufs-aerosol.yaml

window begin: &date '${STWINFMT}'
window length: PT6H

${BKGBLK}
${OBSBLK}

driver:
  save posterior mean: true
  save posterior ensemble: true
  save posterior mean increment: false

local ensemble DA:
  solver: LETKF
  inflation:
    mult: ${LETKF_INF_MULT}
    rtpp: ${LETKF_INF_RTPP}
    rtps: ${LETKF_INF_RTPS}

output:
  filetype: fms restart
  datapath: ./ANALYSIS/mem%{member}%
  prefix: ${ANLPREFIX}.letkf-gfs_aero
#  first: PT0H
#  frequency: PT1H
EOF

cat ${DATA}/enkf_gfs_aero_${AODTYPE}.yaml

EMCONF=${GESENSDIR_IN}/ensmean/${COMP_CONF}

[[ ! -d ${EMCONF} ]] && mkdir -p ${EMCONF}

${NCP} ${DATA}/enkf_gfs_aero_${AODTYPE}.yaml ${EMCONF}

ERR=$?

exit ${ERR}
