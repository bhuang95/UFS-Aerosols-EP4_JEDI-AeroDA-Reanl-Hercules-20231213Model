# Command: make EXECDIR/test.x then make EXECDIR/${targetexec}.x
FC =  mpiifort
FCFLAGS =  -FR -O3 -convert big_endian

NETCDF_F = $(netcdf_fortran_ROOT)
NETCDF_C = $(netcdf_c_ROOT)
LIBCDF = -I$(NETCDF_F)/include -L$(NETCDF_F)/lib -I$(NETCDF_C)/include -L$(NETCDF_C)/lib -lnetcdff -lnetcdf

LIBMP = -lmpi -qopenmp
LIBS = /work/noaa/wrf-chem/bhuang/expCodes-Hercules/MariusLibs/libs
#/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/MariusLibs/libs 
#/work/noaa/wrf-chem/bhuang/expCodes/HerculesCodes/MariusLibs/libs
#/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/misc/MariusLibs/libs 
#/home/mpagowsk/mapp_2018/libs
#/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/libs
LIBCRTM = -I$(LIBS)/crtm_big_endian/include -L$(LIBS)/crtm_big_endian/lib -lcrtm
LIBGEOS =  -I$(LIBS)/geos-aero/include -L$(LIBS)/geos-aero/lib -lgeos-aero
LDFLAGS = $(LIBCDF) $(LIBMP) $(LIBCRTM) $(LIBGEOS)

#SOURCEDIR = /work/noaa/wrf-chem/bhuang/NRTdata_UFS-Aerosols/src_mpi/src_mpi
SOURCEDIR = /home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model/misc/src_mpi
#/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/src_mpi
BUILDDIR = /work/noaa/wrf-chem/bhuang/expCodes-Hercules/src_mpi/build/
#/work/noaa/wrf-chem/bhuang/NRTdata_UFS-Aerosols/src_mpi/build
EXECDIR = /work/noaa/wrf-chem/bhuang/expCodes-Hercules/src_mpi/exec
#/work/noaa/wrf-chem/bhuang/NRTdata_UFS-Aerosols/src_mpi/exec

RM = /bin/rm -f

.SUFFIXES:

.SUFFIXES: .F .f90 .f .o

OBJ100 = \
	$(BUILDDIR)/module_kinds.o \
	$(BUILDDIR)/module_constants.o \
	$(BUILDDIR)/module_utils.o \
	$(BUILDDIR)/module_netcdf_io.o \
	$(BUILDDIR)/test.o 

OBJ101 = \
	$(BUILDDIR)/module_kinds.o \
	$(BUILDDIR)/module_constants.o \
	$(BUILDDIR)/module_netcdf_io.o \
	$(BUILDDIR)/module_utils.o \
	$(BUILDDIR)/calc_ensmean_fv3.o

OBJ102 = \
	$(BUILDDIR)/module_kinds.o \
	$(BUILDDIR)/module_constants.o \
	$(BUILDDIR)/module_netcdf_io.o \
	$(BUILDDIR)/module_utils.o \
	$(BUILDDIR)/ufo_variables_mod.o \
	$(BUILDDIR)/module_cfnames.o \
	$(BUILDDIR)/ufo_crtm_bare_utils_mod.o \
	$(BUILDDIR)/ufo_aodcrtm_bare_mod.o \
	$(BUILDDIR)/ufo_luts_bare_utils_mod.o \
	$(BUILDDIR)/ufo_aodluts_bare_mod.o \
	$(BUILDDIR)/module_luts.o \
	$(BUILDDIR)/gocart_aod_fv3_mpi.o

OBJ103 = \
	$(BUILDDIR)/module_kinds.o \
	$(BUILDDIR)/module_constants.o \
	$(BUILDDIR)/module_utils.o \
	$(BUILDDIR)/module_netcdf_io.o \
	$(BUILDDIR)/replace_vars.o

OBJ104 = \
	$(BUILDDIR)/module_kinds.o \
	$(BUILDDIR)/module_constants.o \
	$(BUILDDIR)/module_utils.o \
	$(BUILDDIR)/module_netcdf_io.o \
	$(BUILDDIR)/recenter_aeros.o

OBJ105 = \
	$(BUILDDIR)/module_kinds.o \
	$(BUILDDIR)/module_constants.o \
	$(BUILDDIR)/module_utils.o \
	$(BUILDDIR)/module_netcdf_io.o \
	$(BUILDDIR)/average_vars.o

OBJ106 = \
	$(BUILDDIR)/module_kinds.o \
	$(BUILDDIR)/module_constants.o \
	$(BUILDDIR)/module_netcdf_io.o \
	$(BUILDDIR)/module_utils.o \
	$(BUILDDIR)/ufo_variables_mod.o \
	$(BUILDDIR)/module_cfnames.o \
	$(BUILDDIR)/ufo_crtm_bare_utils_mod.o \
	$(BUILDDIR)/ufo_aodcrtm_bare_mod.o \
	$(BUILDDIR)/ufo_luts_bare_utils_mod.o \
	$(BUILDDIR)/ufo_aodluts_bare_mod.o \
	$(BUILDDIR)/module_luts.o \
	$(BUILDDIR)/gocart_aod_fv3_hofx_mpi.o



$(EXECDIR)/test.x: $(OBJ100)
	$(FC) $(OBJ100) $(FCFLAGS) $(LDFLAGS) -o $@

$(EXECDIR)/calc_ensmean_fv3.x: $(OBJ101)
	$(FC) $(OBJ101) $(FCFLAGS) $(LDFLAGS) -o $@

$(EXECDIR)/gocart_aod_fv3_mpi.x: $(OBJ102)
	$(FC) $(OBJ102) $(FCFLAGS) $(LDFLAGS) -o $@

$(EXECDIR)/replace_vars.x: $(OBJ103)
	$(FC) $(OBJ103) $(FCFLAGS) $(LDFLAGS) -o $@

$(EXECDIR)/recenter_aeros.x: $(OBJ104)
	$(FC) $(OBJ104) $(FCFLAGS) $(LDFLAGS) -o $@

$(EXECDIR)/average_vars.x: $(OBJ105)
	$(FC) $(OBJ105) $(FCFLAGS) $(LDFLAGS) -o $@

$(EXECDIR)/gocart_aod_fv3_hofx_mpi.x: $(OBJ106)
	$(FC) $(OBJ106) $(FCFLAGS) $(LDFLAGS) -o $@


$(BUILDDIR)/test.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_netcdf_io.o 

$(BUILDDIR)/module_netcdf_io.o: $(BUILDDIR)/module_utils.o $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_constants.o

$(BUILDDIR)/calc_ensmean_fv3.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_netcdf_io.o $(BUILDDIR)/module_constants.o

$(BUILDDIR)/gocart_aod_fv3_mpi.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_netcdf_io.o $(BUILDDIR)/module_constants.o $(BUILDDIR)/ufo_variables_mod.o $(BUILDDIR)/ufo_crtm_bare_utils_mod.o $(BUILDDIR)/ufo_aodcrtm_bare_mod.o $(BUILDDIR)/module_utils.o $(BUILDDIR)/module_cfnames.o $(BUILDDIR)/ufo_luts_bare_utils_mod.o $(BUILDDIR)/ufo_aodluts_bare_mod.o $(BUILDDIR)/module_luts.o

$(BUILDDIR)/gocart_aod_fv3_hofx_mpi.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_netcdf_io.o $(BUILDDIR)/module_constants.o $(BUILDDIR)/ufo_variables_mod.o $(BUILDDIR)/ufo_crtm_bare_utils_mod.o $(BUILDDIR)/ufo_aodcrtm_bare_mod.o $(BUILDDIR)/module_utils.o $(BUILDDIR)/module_cfnames.o $(BUILDDIR)/ufo_luts_bare_utils_mod.o $(BUILDDIR)/ufo_aodluts_bare_mod.o $(BUILDDIR)/module_luts.o

$(BUILDDIR)/ufo_aodcrtm_bare_mod.o: $(BUILDDIR)/ufo_crtm_bare_utils_mod.o $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_constants.o $(BUILDDIR)/ufo_variables_mod.o

$(BUILDDIR)/ufo_crtm_bare_utils_mod.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_constants.o $(BUILDDIR)/ufo_variables_mod.o

$(BUILDDIR)/ufo_crtm_bare_utils_mod.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_constants.o $(BUILDDIR)/ufo_variables_mod.o

$(BUILDDIR)/ufo_luts_bare_utils_mod.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_constants.o $(BUILDDIR)/ufo_variables_mod.o $(BUILDDIR)/ufo_crtm_bare_utils_mod.o

$(BUILDDIR)/ufo_aodluts_bare_mod.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_constants.o $(BUILDDIR)/ufo_variables_mod.o $(BUILDDIR)/module_luts.o

$(BUILDDIR)/module_luts.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/ufo_variables_mod.o

$(BUILDDIR)/replace_vars.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_netcdf_io.o $(BUILDDIR)/module_constants.o

$(BUILDDIR)/average_vars.o: $(BUILDDIR)/module_kinds.o $(BUILDDIR)/module_netcdf_io.o $(BUILDDIR)/module_constants.o

$(BUILDDIR)/recenter_aeros.o: $(BUILDDIR)/module_netcdf_io.o $(BUILDDIR)/module_constants.o

#$(BUILDDIR)/%: $(BUILDDIR)/%.o
#	$(FC) $(FCFLAGS) -o $@ $^ $(LDFLAGS) 
$(BUILDDIR)/%.o: $(SOURCEDIR)/%.f90
	$(FC) $(FCFLAGS) -c $< $(LDFLAGS) -o $@ -module $(BUILDDIR) 

clean:
	$(RM) $(BUILDDIR)/*.o $(BUILDDIR)/*.mod

