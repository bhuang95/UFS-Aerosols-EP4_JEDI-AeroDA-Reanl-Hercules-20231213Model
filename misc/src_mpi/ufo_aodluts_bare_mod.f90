MODULE ufo_aodluts_bare_mod

  USE iso_c_binding
  USE module_kinds
  USE module_constants
  USE ufo_vars_mod

  USE ufo_crtm_bare_utils_mod, ONLY: assign_aerosol_names, max_string
  USE ufo_luts_bare_utils_mod, ONLY: luts_conf, luts_conf_setup,&
       &calculate_aero_layers

  USE m_chars
  USE module_luts, ONLY: get_cf_aod, get_miechannels

  IMPLICIT NONE
  PRIVATE

  INCLUDE 'mpif.h'

  PUBLIC ufo_aodluts_simobs

  TYPE(luts_conf) :: conf

  CHARACTER(maxvarlen), PARAMETER :: varname_tmplate="aerosol_optical_depth"

CONTAINS

  SUBROUTINE ufo_aodluts_simobs(nx,nlat,n_layers,ts,sphum,prsl,prsi,&
       &aerosols,conf,aod)

    IMPLICIT NONE
    INTEGER,                  INTENT(in) :: nx,nlat,n_layers
    REAL(kind_single), DIMENSION(:,:,:), INTENT(in) :: ts,sphum,prsl,prsi
    REAL(kind_single), DIMENSION(:,:,:,:), INTENT(in) :: aerosols
    TYPE(luts_conf) :: conf
    REAL(kind_single),           INTENT(inout) :: aod(:,:,:)

!later put as optional output
!    REAL(kind_single), ALLOCATABLE :: aod_layers(:,:,:,:)

! local variables
    CHARACTER(*), PARAMETER :: program_name = 'ufo_aodluts_mod.f90'
    CHARACTER(255) :: message, version
    INTEGER        :: err_stat, alloc_stat
    INTEGER        :: l, m, n, i, j

    REAL(kind_real), ALLOCATABLE :: aero_layers(:,:,:,:),rh(:,:,:)
    
    CHARACTER(len=maxvarlen), ALLOCATABLE :: var_aerosols(:)

    INTEGER :: iret

    CALL assign_aerosol_names(conf%aerosol_option,var_aerosols)

    CALL calculate_aero_layers(nx,nlat,n_layers,ts,sphum,prsl,prsi,&
         &aerosols,conf%aerosol_option,rh,aero_layers)

    CALL get_cf_aod(nx, nlat, n_layers,&
         &var_aerosols, conf%wavelengths, conf%rcfile,&
         &rh, aero_layers, &
         &aod) !, aod_layers=aod_layers)  

    IF (ALLOCATED(rh)) DEALLOCATE(rh)
    
  END SUBROUTINE ufo_aodluts_simobs

END MODULE ufo_aodluts_bare_mod
