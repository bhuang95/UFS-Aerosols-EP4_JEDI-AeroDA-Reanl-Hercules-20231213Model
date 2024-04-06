MODULE module_constants

  USE module_kinds

  PUBLIC 
  
  INTEGER, PARAMETER :: MAXVARLEN=100, max_string=800,nvarmax=50
  INTEGER, PARAMETER :: max_varname_length=MAXVARLEN, &
       &max_string_length=max_string, date_string_length=20
  INTEGER, PARAMETER :: n_maxabsorbers=3,n_maxchannels=50,n_maxlevels=50

  INTEGER, PARAMETER :: imissing=-99999

  INTEGER, PARAMETER :: ntiles_fv3=6

  REAL(kind_single), PARAMETER :: pi = ACOS(-1.0),r2d = 180.0 / pi, &
       &d2r = pi / 180.0, small=1e-9_r_single, ug2kg=1e-9_r_single,&
       &aerosol_concentration_minvalue=1.e-16_kind_single,&
       &aerosol_concentration_minvalue_layer=TINY(rd)

  REAL(kind_single), PARAMETER :: rmissing=-99999

!physical constants
  REAL(kind_single), PARAMETER :: &
       &rd = 2.8704e+2_kind_single,&
       &rv = 4.6150e+2_kind_single,&
       &cp = 1004.67_kind_single,&
       &kap = rd/cp,&
       &kapr = cp/rd,&
       &kap1 = kap + 1_kind_single,&
       &rv_rd = rv/rd,&
       &rd_rv = 1_kind_single/rv_rd,&
       &grav = 9.80665_kind_single,&
       &ozone_default_value=1.e-3_kind_single,& ! in ppmv in crtm
       &r_earth = 6378.,& !km
       &speed_of_light = 2.99792458e8,&
       &n_avogadro=6.02214076e23,& !mol^-1
       &mol_weight_air=0.0289645
END MODULE module_constants
