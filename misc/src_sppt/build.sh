#!/bin/bash
HOMEgfs="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/"
source "${HOMEgfs}/ush/preamble.sh"
source "$HOMEgfs/ush/load_ufswm_modules.sh"

set -x
compile_all=1
#compile_all=0
DEBUG=YES
#DEBUG=NO
#UFSMODDIR=/work/noaa/gsd-fv3-dev/bhuang/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/global-workflow/sorc/ufs_model.fd/tests

SRCDIR=/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/misc/src_sppt
BUILDDIR=/work/noaa/wrf-chem/bhuang/expCodes-Hercules/src_sppt/build
EXECDIR=/work/noaa/wrf-chem/bhuang/expCodes-Hercules/src_sppt/exec

SLINT=/work/noaa/wrf-chem/bhuang/expCodes-Hercules/MariusLibs/libs/slint4stoch
DATETIME=/work/noaa/wrf-chem/bhuang/expCodes-Hercules/MariusLibs/libs/fortran-datetime
#/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/misc/MariusLibs/libs/fortran-datetime

set -x

/bin/rm -f ${EXECDIR}/standalone_stochy_chem.x ${EXECDIR}/standalone_stochy_dust.x ${EXECDIR}/correct_fillvalue.x ${EXECDIR}/correct_fillvalue_dust.x ${EXECDIR}/standalone_stochy_weights.x

NETCDF=${netcdf_fortran_ROOT}
NETCDFC=${netcdf_c_ROOT}
ESMF_LIB=${esmf_ROOT}/lib
HDF5_LIBRARIES=${HDF5_DIR}/lib

#NETCDF=/work/noaa/epic/role-epic/spack-stack/spack-stack-1.4.1/envs/unified-env/install/intel/2022.0.2/netcdf-fortran-4.6.0-5aiyu36
#NETCDFC=/work/noaa/epic/role-epic/spack-stack/spack-stack-1.4.1/envs/unified-env/install/intel/2022.0.2/netcdf-c-4.9.2-5ymrd45
#HDF5_LIBRARIES=/work/noaa/epic/role-epic/spack-stack/spack-stack-1.4.1/envs/unified-env/install/intel/2022.0.2/hdf5-1.14.0-dcgt6o5/lib
ZLIB_LIBRARIES=${zlib_ROOT}/lib
#FC=mpif90
FC=mpiifort
FMS_INC=${fms_ROOT}/include_r8
FMS_LIB=${fms_ROOT}/lib
INCS="-I. -I${FMS_INC} -I${NETCDF}/include"
if [ $DEBUG == 'YES' ]; then
   FLAGS=" -O0 -g -check all -link_mpi=dbg_mt -traceback -real-size 64 -qopenmp -c "$INCS
   #FLAGS=" -FR -O3 -convert big_endian "$INCS
else
   FLAGS=" -traceback -real-size 64 -qopenmp -c "$INCS
fi

cd $BUILDDIR

if [ $compile_all -eq 1 ];then
   rm -f *.i90 *.i *.o *.mod lib*a
   $FC ${FLAGS} ${SRCDIR}/kinddef.F90
   $FC ${FLAGS} ${SRCDIR}/mpi_wrapper.F90
   $FC ${FLAGS} ${SRCDIR}/mersenne_twister.F90
   $FC ${FLAGS} ${SRCDIR}/stochy_internal_state_mod.F90
   $FC ${FLAGS} ${SRCDIR}/stochy_namelist_def.F90
   $FC ${FLAGS} ${SRCDIR}/spectral_transforms.F90
   $FC ${FLAGS} ${SRCDIR}/compns_stochy.F90
   $FC ${FLAGS} ${SRCDIR}/stochy_patterngenerator.F90
   $FC ${FLAGS} ${SRCDIR}/stochy_data_mod.F90
   $FC ${FLAGS} ${SRCDIR}/get_stochy_pattern.F90
   $FC ${FLAGS} ${SRCDIR}/lndp_apply_perts.F90
   $FC ${FLAGS} ${SRCDIR}/stochastic_physics.F90
   ar rv libstochastic_physics.a *.o
fi

if [ $DEBUG == 'YES' ]; then
   $FC -traceback -g -C -real-size 64 -qopenmp -o ${EXECDIR}/standalone_stochy_chem.x ${SRCDIR}/standalone_stochy_chem.F90 ${INCS} -I${NETCDF}/include -L. -lstochastic_physics -L${FMS_LIB} -lfms_r8 -L${ESMF_LIB} -Wl,-rpath,${ESMF_LIB} -lesmf -L${NETCDF}/lib -lnetcdff -L${NETCDFC}/lib -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${SLINT} -L${SLINT} -lslint -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime

   $FC -traceback -g -C -real-size 64 -qopenmp -o ${EXECDIR}/standalone_stochy_dust.x ${SRCDIR}/standalone_stochy_dust.F90 ${INCS} -I${NETCDF}/include -L. -lstochastic_physics -L${FMS_LIB} -lfms_r8 -L${ESMF_LIB} -Wl,-rpath,${ESMF_LIB} -lesmf -L${NETCDF}/lib -lnetcdff -L${NETCDFC}/lib -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${SLINT} -L${SLINT} -lslint -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
  $FC -traceback -g -C -real-size 64 -qopenmp -o ${EXECDIR}/standalone_stochy_dust.x ${SRCDIR}/standalone_stochy_dust.F90 ${INCS} -I${NETCDF}/include -L. -lstochastic_physics -L${FMS_LIB} -lfms_r8 -L${ESMF_LIB} -Wl,-rpath,${ESMF_LIB} -lesmf -L${NETCDF}/lib -lnetcdff -L${NETCDFC}/lib -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${SLINT} -L${SLINT} -lslint -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
  $FC -traceback -g -C -real-size 64 -qopenmp -o ${EXECDIR}/correct_fillvalue.x ${SRCDIR}/correct_fillvalue.F90 ${INCS} -I${NETCDF}/include -L${FMS_LIB} -lfms_r8 -L${NETCDF}/lib -lnetcdff -L${NETCDFC}/lib -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${SLINT} -L${SLINT} -lslint -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
  $FC -traceback -g -C -real-size 64 -qopenmp -o ${EXECDIR}/correct_fillvalue_dust.x ${SRCDIR}/correct_fillvalue_dust.F90 ${INCS} -I${NETCDF}/include -L${FMS_LIB} -lfms_r8 -L${NETCDF}/lib -lnetcdff -L${NETCDFC}/lib -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${SLINT} -L${SLINT} -lslint -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
  $FC -traceback -g -C -real-size 64 -qopenmp -o ${EXECDIR}/standalone_stochy_weights.x ${SRCDIR}/standalone_stochy_weights.F90 ${INCS} -I${NETCDF}/include -L. -lstochastic_physics -L${FMS_LIB} -lfms_r8 -L${ESMF_LIB} -Wl,-rpath,${ESMF_LIB} -lesmf -L${NETCDF}/lib -lnetcdff -L${NETCDFC}/lib -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${SLINT} -L${SLINT} -lslint -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
else
   $FC -traceback -real-size 64 -qopenmp -o ${EXECDIR}/standalone_stochy_chem.x ${SRCDIR}/standalone_stochy_chem.F90 ${INCS} -I${NETCDF}/include -L. -lstochastic_physics -L${FMS_LIB} -lfms_r8 -L${ESMF_LIB} -Wl,-rpath,${ESMF_LIB} -lesmf -L${NETCDF}/lib -lnetcdff -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${SLINT} -L${SLINT} -lslint -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
   $FC -traceback -real-size 64 -qopenmp -o ${EXECDIR}/standalone_stochy_dust.x ${SRCDIR}/standalone_stochy_dust.F90 ${INCS} -I${NETCDF}/include -L. -lstochastic_physics -L${FMS_LIB} -lfms_r8 -L${ESMF_LIB} -Wl,-rpath,${ESMF_LIB} -lesmf -L${NETCDF}/lib -lnetcdff -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${SLINT} -L${SLINT} -lslint -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
   $FC -traceback -real-size 64 -qopenmp -o ${EXECDIR}/correct_fillvalue.x ${SRCDIR}/correct_fillvalue.F90 ${INCS} -I${NETCDF}/include -L. -lstochastic_physics -L${FMS_LIB} -lfms_r8 -L${NETCDF}/lib -lnetcdff -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
   $FC -traceback -real-size 64 -qopenmp -o ${EXECDIR}/correct_fillvalue_dust.x ${SRCDIR}/correct_fillvalue_dust.F90 ${INCS} -I${NETCDF}/include -L. -lstochastic_physics -L${FMS_LIB} -lfms_r8 -L${NETCDF}/lib -lnetcdff -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
   $FC -traceback -real-size 64 -qopenmp -o ${EXECDIR}/standalone_stochy_weights.x ${SRCDIR}/standalone_stochy_weights.F90 ${INCS} -I${NETCDF}/include -L. -lstochastic_physics -L${FMS_LIB} -lfms_r8 -L${ESMF_LIB} -Wl,-rpath,${ESMF_LIB} -lesmf -L${NETCDF}/lib -lnetcdff -lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz -I${SLINT} -L${SLINT} -lslint -I${DATETIME}/include -L${DATETIME}/lib -lfortran_datetime
fi
