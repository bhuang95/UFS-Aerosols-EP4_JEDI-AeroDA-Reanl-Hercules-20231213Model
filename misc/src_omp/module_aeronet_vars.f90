MODULE module_aeronet_vars

  USE netcdf
  USE datetime_mod
  USE module_constants, ONLY: MAXVARLEN,date_string_length


  IMPLICIT NONE

  INTEGER, PARAMETER :: qc_aeronet_retain=0,nmethods=4
!methods
!1-nn
!2-arithmetic mean
!3-geometric mean
!4-random sample within a circle
!  REAL, PARAMETER :: coverage_threshold(2)=(/0.1,0.6/)


  INTEGER :: nlocs_in,nlocs_out

!only qc=0 used 
!stype always land but may be use for MAN in the future   
  TYPE aeronet_aod
     REAL :: lat, lon, value550, tdiff
     CHARACTER(len=MAXVARLEN) :: station_id
     INTEGER :: qc,stype
  END TYPE aeronet_aod

  TYPE viirs2aeronet_aod
     REAL :: lat, lon, value550_aero
     REAL :: value550_viirs(1:nmethods)
     REAL :: tdiff,tdiff_v2a
     REAL :: coverage_ratio
     CHARACTER(len=MAXVARLEN) :: station_id
     INTEGER :: stype
     
  END TYPE viirs2aeronet_aod

  TYPE(aeronet_aod), ALLOCATABLE, DIMENSION(:) :: aeronet_aod_input
  TYPE(aeronet_aod), ALLOCATABLE, DIMENSION(:) :: aeronet_aod_output
  TYPE(viirs2aeronet_aod), ALLOCATABLE, DIMENSION(:) :: viirs2aeronet_out

END MODULE module_aeronet_vars
