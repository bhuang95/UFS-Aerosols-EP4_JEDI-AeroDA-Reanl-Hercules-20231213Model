#!/bin/bash

set -x

HOMEgfs=${HOMEgfs}
HOMEjedi=${HOMEjedi}
INDATADIR=${RSTDIR}
OUTDATADIR=${FV3AODDIR}
TRCR=${TRCR}
NCORES=${NCORES}
CDATE=${CDATE}
CASE=${CASE}
FV3AODEXEC=${FV3AODEXEC}
LLAODEXEC=${LLAODEXEC}

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}
CDATEPRE="${CYMD}.${CH}0000"

NCP="/bin/cp -r"
NLN="/bin/ln -sf"

${NLN} ${FV3AODEXEC} ./gocart_aod_fv3_mpi_LUTs.x
${NLN} ${LLAODEXEC} ./fv3aod2ll.x
${NLN} ${HOMEjedi}/geos-aero/test/testinput/geosaod.rc ./geosaod.rc
${NLN} ${HOMEjedi}/geos-aero/test/testinput/Chem_MieRegistry.rc ./Chem_MieRegistry.rc
${NLN} ${HOMEjedi}/geos-aero/test/Data ./
${NLN} ${HOMEgfs}/fix_self/nasaluts/all_wavelengths.rc ./

FV3AODDIR=./FV3AOD

[[ ! -d ${OUTDATADIR} ]] && mkdir -p ${OUTDATADIR}
[[ ! -d ${FV3AODDIR} ]] && mkdir -p ${FV3AODDIR}

#source /home/Mariusz.Pagowski/.jedi
#ERR=$?
#[[ ${ERR} -ne 0 ]] && exit 1
#export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/libs/fortran-datetime/lib"
FAKBK=${CDATEPRE}.fv_core.res.nc
for ITILE in $(seq 1 6); do
    FCORE=${CDATEPRE}.fv_core.res.tile${ITILE}.nc
    FTRACER=${CDATEPRE}.${TRCR}.res.tile${ITILE}.nc
    FAOD=${CDATEPRE}.fv_aod_LUTs.${TRCR}.res.tile${ITILE}.nc

[[ -f ./gocart_aod_fv3_mpi.nl ]] && rm -rf  ./gocart_aod_fv3_mpi.nl
cat << EOF > ./gocart_aod_fv3_mpi.nl 	
&record_input
 input_dir = "${INDATADIR}"
 fname_akbk = "${FAKBK}"
 fname_core = "${FCORE}"
 fname_tracer = "${FTRACER}"
 output_dir = "${FV3AODDIR}"
 fname_aod = "${FAOD}"
/
&record_model
 Model = "AodLUTs"
/
&record_conf_crtm
 AerosolOption = "aerosols_gocart_default"
 Absorbers = "H2O","O3"
 Sensor_ID = "v.viirs-m_npp"
 EndianType = "big_endian"
 CoefficientPath = ${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/
 Channels = 4
/
&record_conf_luts
 AerosolOption = "aerosols_gocart_1"
 WavelengthsOutput = 550.
 !WavelengthsOutput = 380.,500.,550.,870
 RCFile = "all_wavelengths.rc"
/
EOF
cat gocart_aod_fv3_mpi.nl  
srun --export=all -n ${NCORES}  ./gocart_aod_fv3_mpi_LUTs.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "gocart_aod_fv3_mpi_LUTs failed an exit!!!"
    exit 1
fi
done
${NCP} gocart_aod_fv3_mpi.nl ${OUTDATADIR}/gocart_aod_fv3_mpi_${TRCR}.nl

FV3AOD=${CDATEPRE}.fv_aod_LUTs.${TRCR}.res.tile?.nc
GRIDAOD=fv3_aod_LUTs_${TRCR}_${CDATE}_ll.nc


#source ${HOMEjedi}/jedi_module_base.hera.sh
#ERR=$?
#[[ ${ERR} -ne 0 ]] && exit 1
#export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/libs/fortran-datetime/lib"
[[ -f fv3aod2ll.nl ]] && rm -rf fv3aod2ll.nl
cat > fv3aod2ll.nl <<EOF
&record_input
 date="${CDATE}"
 input_grid_dir="${HOMEgfs}/fix_self/grid_spec/${CASE}"
 fname_grid="${CASE}_grid_spec.tile?.nc"
 input_fv3_dir="${FV3AODDIR}"
 fname_fv3="${FV3AOD}"
/
&record_interp
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="${OUTDATADIR}"
 fname_aod_ll="${GRIDAOD}"
/
EOF

#srun --export=all -n ${NCORES}  ./fv3aod2ll.x
cat fv3aod2ll.nl
./fv3aod2ll.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "fv3aod2ll.x failed an exit!!!"
    exit 1
fi
${NCP} fv3aod2ll.nl ${OUTDATADIR}/fv3aod2ll_${TRCR}.nl

exit ${ERR}
