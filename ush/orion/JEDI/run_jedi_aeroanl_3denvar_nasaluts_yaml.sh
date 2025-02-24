#!/bin/bash
set -x

NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
JEDIDIR=${HOMEjedi:-"$HOMEgfs/sorc/jedi.fd/"}
DATA=${DATA:-"$pwd/analysis.$$"}
ROTDIR=${ROTDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/"}
OBSDIR_NRT=${OBSDIR_NRT:-$OBSDIR_NRT}
COMIN_GES=${COMIN_GES:-$COMIN_GES}
COMIN_GES_ENS=${COMIN_GES_ENS:-$COMIN_GES_ENS}
COMP_MOD_ATM_RST=${COMP_MOD_ATM_RST:-"model_data/atmos/restart"}
COMP_CONF=${COMP_CONF:-"conf"}
ANLTIME=${CDATE:-"2001010100"}
BUMPTIME=${BUMPTIME}
GESTIME=$($NDATE -$assim_freq $CDATE)
STARTWIN=$($NDATE -3 $CDATE)
CASE=${CASE:-"C384"} # no lower case
LEVS=${LEVS:-"128"}
CASEC=$(echo ${CASE} |cut -c2-5)
NPX=$((CASEC+1))
NPY=$((CASEC+1))
NPZ=$((LEVS-1))
LAYOUT=${layout_envar:-"1,1"}
IO_LAYOUT=${io_layout_envar:-"1,1"}
VAR_BUMP_LOC=${VAR_BUMP_LOC:-"fixed_2500km_1.5"}
BUMPLAYOUT=`echo ${LAYOUT} | sed 's/,/_/g'`
BUMPDIR=${BUMPDIR:-${JEDIDIR}/fv3-jedi/test/Data/bump/${CASE}/layout-${BUMPLAYOUT}-${CASE}-logp-atmos-${VAR_BUMP_LOC}/}
FIELDMETADIR=${JEDIDIR}/fv3-jedi/test/Data/fieldmetadata/
FV3DIR=${JEDIDIR}/fv3-jedi/test/Data/fv3files/
### Hard coded this directory
#CRTMFIX=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
CRTMFIX=${JEDIDIR}/fv3-jedi/test/Data/crtm
JEDIEXE=${JEDIDIR}/bin/fv3jedi_var.x
STATICB_WEG=${STATICB_WEG:-"0.0"}
ENSB_WEG=${ENSB_WEG:-"1.0"}

CDUMP=${CDUMP:-"gdas"}
NMEM=${NMEM_ENKF:-"10"}

# Define some aliases
NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

# set date format
BYY=$(echo ${BUMPTIME} | cut -c1-4)
BMM=$(echo ${BUMPTIME} | cut -c5-6)
BDD=$(echo ${BUMPTIME} | cut -c7-8)
BHH=$(echo ${BUMPTIME} | cut -c9-10)
BUMPTIMEFMT=${BYY}-${BMM}-${BDD}T${BHH}:00:00Z

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


# Link bump directory
mkdir -p ${DATA}/BUMP
${NLN} ${BUMPDIR}/fv3jedi_bumpparameters_nicas_3D_gfs*  ${DATA}/BUMP/ 

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
GESDIR_IN=${COMIN_GES}/${COMP_MOD_ATM_RST}
GESDIR_CONF=${COMIN_GES}/${COMP_CONF}
GESENSDIR_IN=${COMIN_GES_ENS}
ANLDIR_OUT=${DATA}/ANALYSIS
DIAGDIR_OUT=${DATA}/DIAG
mkdir -p ${ANLDIR_OUT}
mkdir -p ${DIAGDIR_OUT}

## Link control bckg/anal files
mkdir -p ${DATAINPUT}/CONTROL
#GESCPLR_IN=${GESDIR_IN}/RESTART/${ANLPREFIX}.coupler.res.ges
GESCPLR_IN=${GESDIR_IN}/${ANLPREFIX}.coupler.res
GESCPLR_OUT=${DATAINPUT}/CONTROL/${ANLPREFIX}.coupler.res
${NLN} ${GESCPLR_IN} ${GESCPLR_OUT}
#rm -rf ${GESDIR}/RESTART/*.nc
#rm -rf ${GESDIR}/RESTART/*.nc.anl_jedi

ITILE=1
while [ ${ITILE} -le 6 ]; do
   TILESTR=`printf %1i ${ITILE}`

   TILEFILE=fv_tracer.res.tile${TILESTR}
   TILEGES_IN=${GESDIR_IN}/${ANLPREFIX}.${TILEFILE}.nc
   TILEGES_OUT=${DATAINPUT}/CONTROL/${ANLPREFIX}.${TILEFILE}.nc
   ${NLN} ${TILEGES_IN} ${TILEGES_OUT}

   TILEFILE=fv_core.res.tile${TILESTR}
   TILEGES_IN=${GESDIR_IN}/${ANLPREFIX}.${TILEFILE}.nc
   TILEGES_OUT=${DATAINPUT}/CONTROL/${ANLPREFIX}.${TILEFILE}.nc
   ${NLN} ${TILEGES_IN} ${TILEGES_OUT}

   TILEFILE=fv_tracer_aeroanl_tmp.res.tile${TILESTR}
   TILEANL_IN=${GESDIR_IN}/${ANLPREFIX}.${TILEFILE}.nc
   TILEANL_OUT=${ANLDIR_OUT}/${ANLPREFIX}.hyb-3dvar-gfs_aero.fv_tracer.res.tile${TILESTR}.nc
   if [ -f ${TILEANL_IN} ]; then
       ${NRM} ${TILEANL_IN}
   fi
   ${NLN} ${TILEANL_IN} ${TILEANL_OUT}

   ITILE=$((ITILE+1))
done


## Link ensemble bckg
IMEM=1
while [ ${IMEM} -le ${NMEM} ]; do
    MEMSTR="mem"`printf %03d ${IMEM}`
    MEMDIR_IN=${GESENSDIR_IN}/${MEMSTR}/${COMP_MOD_ATM_RST}
    MEMDIR_OUT=${DATAINPUT}/${MEMSTR}/
    mkdir -p ${MEMDIR_OUT}
    GESCPLR_IN=${MEMDIR_IN}/${ANLPREFIX}.coupler.res
    GESCPLR_OUT=${MEMDIR_OUT}/${ANLPREFIX}.coupler.res
    ${NLN} ${GESCPLR_IN} ${GESCPLR_OUT}

    ITILE=1
    while [ ${ITILE} -le 6 ]; do
       TILESTR=`printf %1i ${ITILE}`

       TILEFILE=fv_tracer.res.tile${TILESTR}
       TILEGES_IN=${MEMDIR_IN}/${ANLPREFIX}.${TILEFILE}.nc
       TILEGES_OUT=${MEMDIR_OUT}/${ANLPREFIX}.${TILEFILE}.nc
       ${NLN} ${TILEGES_IN} ${TILEGES_OUT}

       ITILE=$((ITILE+1))
    done

    IMEM=$((IMEM+1))
done

# Link executable
${NLN} ${JEDIEXE} ${DATA}/fv3jedi_var.x

# Gnerate control yaml block
BKGBLK="  
  background:
    datetime: ${ANLTIMEFMT}
    filetype: fms restart
    datapath: ./INPUT/CONTROL/
    filename_core: ${ANLPREFIX}.fv_core.res.nc
    filename_trcr: ${ANLPREFIX}.fv_tracer.res.nc
    filename_cplr: ${ANLPREFIX}.coupler.res
    state variables: [T,delp,sphum,
                      so4,bc1,bc2,oc1,oc2,
                      dust1,dust2,dust3,dust4,dust5,
                      seas1,seas2,seas3,seas4,seas5]
"
#no3an1,no3an2,no3an3]

# Generate background erro yaml block
BKGERRBLK="  
  background error:
    covariance model: hybrid
    components:
    - covariance:
        covariance model: SABER
        saber central block:
          saber block name: ID
      weight: 
        value: ${STATICB_WEG}
    - covariance:
        covariance model: ensemble
        members from template:
          template:
            datetime: ${ANLTIMEFMT}
            filetype: fms restart
            #state variables: &aerovars [so4,bc1,bc2,oc1,oc2,
            #                            dust1,dust2,dust3,dust4,dust5,
            #                            seas1,seas2,seas3,seas4,seas5]
            state variables: &aerovars [mass_fraction_of_sulfate_in_air,
                               mass_fraction_of_hydrophobic_black_carbon_in_air,
                               mass_fraction_of_hydrophilic_black_carbon_in_air,
                               mass_fraction_of_hydrophobic_organic_carbon_in_air,
                               mass_fraction_of_hydrophilic_organic_carbon_in_air,
                               mass_fraction_of_dust001_in_air,
                               mass_fraction_of_dust002_in_air,
                               mass_fraction_of_dust003_in_air,
                               mass_fraction_of_dust004_in_air,
                               mass_fraction_of_dust005_in_air,
                               mass_fraction_of_sea_salt001_in_air,
                               mass_fraction_of_sea_salt002_in_air,
                               mass_fraction_of_sea_salt003_in_air,
                               mass_fraction_of_sea_salt004_in_air,
                               mass_fraction_of_sea_salt005_in_air]
            datapath: INPUT/mem%mem%/
            filename_trcr: ${ANLPREFIX}.fv_tracer.res.nc
            filename_cplr: ${ANLPREFIX}.coupler.res
          pattern: '%mem%'
          nmembers: ${NMEM}
          zero padding: 3
        localization:
          localization method: SABER
          saber central block:
            saber block name: BUMP_NICAS
            active variables: [mass_fraction_of_sulfate_in_air,
                               mass_fraction_of_hydrophobic_black_carbon_in_air,
                               mass_fraction_of_hydrophilic_black_carbon_in_air,
                               mass_fraction_of_hydrophobic_organic_carbon_in_air,
                               mass_fraction_of_hydrophilic_organic_carbon_in_air,
                               mass_fraction_of_dust001_in_air,
                               mass_fraction_of_dust002_in_air,
                               mass_fraction_of_dust003_in_air,
                               mass_fraction_of_dust004_in_air,
                               mass_fraction_of_dust005_in_air,
                               mass_fraction_of_sea_salt001_in_air,
                               mass_fraction_of_sea_salt002_in_air,
                               mass_fraction_of_sea_salt003_in_air,
                               mass_fraction_of_sea_salt004_in_air,
                               mass_fraction_of_sea_salt005_in_air]
            read:
              io:
                files prefix: BUMP/fv3jedi_bumpparameters_nicas_3D_gfs
                alias:
                - in code: common
                  in file: ${VAR_BUMP_LOC}
              drivers:
                multivariate strategy: duplicated
                read local nicas: true
      weight:
        value: ${ENSB_WEG}
"

# Generate the yaml block for AOD observations
OBSBLK="  
  observations:
    observers:    
    - obs space:
        name: Aod
        obsdatain:
          engine:
            type: H5File
            obsfile: ./INPUT/${OBSOUT}
#        obsdataout:
#          engine:
#            type: H5File
#            obsfile: ./DIAG/diag_${OBSOUT}
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
"

# Create yaml file
cat << EOF > ${DATA}/hyb-3dvar_gfs_aero_${AODTYPE}.yaml
cost function:
${BKGBLK}
${BKGERRBLK}
${OBSBLK}
  cost type: 3D-Var
  analysis variables: *aerovars 
  time window:
    begin: '${STWINFMT}'
    length: PT6H
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
final:
  diagnostics:
    departures: oman
output:
  filetype: fms restart
  datapath: ./ANALYSIS/
  prefix: ${ANLPREFIX}.hyb-3dvar-gfs_aero
  frequency: PT1H
variational:
  minimizer:
    algorithm: DRIPCG
  iterations:
  - ninner: 50
    gradient norm reduction: 1e-10
    test: on
    geometry:
      akbk: ./INPUT/akbk.nc
      layout: [${LAYOUT}]
      io_layout: [${IO_LAYOUT}]
      npx: ${NPX}
      npy: ${NPY}
      npz: ${NPZ}
      field metadata override: ufs-aerosol.yaml
#    diagnostics:
#      departures: ombg
  - ninner: 80
    gradient norm reduction: 1e-10
    test: on
    geometry:
      akbk: ./INPUT/akbk.nc
      layout: [${LAYOUT}]
      io_layout: [${IO_LAYOUT}]
      npx: ${NPX}
      npy: ${NPY}
      npz: ${NPZ}
      field metadata override: ufs-aerosol.yaml
#    diagnostics:
#      departures: ombg
EOF

cat ${DATA}/hyb-3dvar_gfs_aero_${AODTYPE}.yaml

[[ ! -d ${GESDIR_CONF} ]] && mkdir -p ${GESDIR_CONF}
${NCP} ${DATA}/hyb-3dvar_gfs_aero_${AODTYPE}.yaml ${GESDIR_CONF}

ERR=$?

exit ${ERR}
