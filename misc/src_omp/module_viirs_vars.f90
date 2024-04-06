MODULE module_viirs_vars

  USE netcdf
  USE datetime_mod
  USE module_constants, ONLY: MAXVARLEN,date_string_length,&
       &r_earth,pi
  USE module_viirs2aeronet_args, ONLY : radius_pixel_output

  IMPLICIT NONE

  INTEGER, PARAMETER :: qc_retain=0

! lunar:
! retrieval quality:  3: N > 48, 2: 10 < N <= 48 1: N <= 10
! out of (6/0.75)^2=64
  INTEGER, PARAMETER :: qc_retain_lunar=3
  REAL, PARAMETER :: viirs_aod_max=5.

  CHARACTER(len=date_string_length) :: viirstimestr
  CHARACTER(len=MAXVARLEN) :: inst, sat, retrieval_type

  REAL :: viirstdiff

  INTEGER :: nobs_in,nobs_out
  INTEGER, PARAMETER :: nchans=1, channels(nchans)=4
  REAL,  PARAMETER :: viirs_wavelength=550.e-9

  REAL, PARAMETER :: diameter_pixel_viirs=0.75 !in km

  REAL, PARAMETER :: &
       &reg_coeffs_bias(3)=&
       &(/-0.077567529,0.10628428,0.005490243/),&
       &reg_coeffs_uncertainty(3)=&
       &(/0.049280971,0.237700210,-0.001894826/)

  REAL :: diamater_pixel_output,dphi_max

  INTEGER :: num_nn

  TYPE viirs_aod
     REAL :: lat, lon
     REAL :: bias, uncertainty, value550
     INTEGER :: qcall,stype
  END TYPE viirs_aod
  
  TYPE(viirs_aod), ALLOCATABLE, DIMENSION(:) :: viirs_aod_input
  TYPE(viirs_aod), ALLOCATABLE, DIMENSION(:) :: viirs_aod_output

CONTAINS

  SUBROUTINE viirs2aeronet_output_params

    IMPLICIT NONE

    diamater_pixel_output=2.*radius_pixel_output
    dphi_max=radius_pixel_output/(2.*pi*r_earth)

    num_nn=NINT(diamater_pixel_output**2/&
         &diameter_pixel_viirs**2)

  END SUBROUTINE viirs2aeronet_output_params

END MODULE module_viirs_vars
