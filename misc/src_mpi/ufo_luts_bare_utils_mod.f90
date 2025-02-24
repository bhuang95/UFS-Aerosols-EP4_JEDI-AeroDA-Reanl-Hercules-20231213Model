MODULE ufo_luts_bare_utils_mod

  USE module_kinds
  USE module_constants, ONLY : maxvarlen,max_string,imissing,&
       &n_maxabsorbers,n_maxchannels
  USE ufo_vars_mod

  USE ufo_crtm_bare_utils_mod, ONLY: qsmith, assign_aerosol_names, upper2lower
  USE ufo_crtm_bare_utils_mod, ONLY: grav,rv_rd,&
       &aerosol_concentration_minvalue,&
       &aerosol_concentration_minvalue_layer

  USE iso_c_binding

  IMPLICIT NONE
  PRIVATE

  PUBLIC luts_conf
  PUBLIC luts_conf_setup
  PUBLIC :: calculate_aero_layers

  INCLUDE 'mpif.h'

  TYPE luts_conf
     CHARACTER(len=maxvarlen) :: aerosol_option
     CHARACTER(len=max_string) :: rcfile
     REAL(kind_real), ALLOCATABLE :: wavelengths(:)
  END TYPE luts_conf

CONTAINS

  SUBROUTINE luts_conf_setup(conf)

    IMPLICIT NONE
    TYPE(luts_conf),            INTENT(inout) :: conf

    CHARACTER(len=maxvarlen) :: aerosoloption
    CHARACTER(len=max_string) :: rcfile
    REAL(kind_single) :: wavelengthsoutput(n_maxchannels)

    CHARACTER(len=maxvarlen), ALLOCATABLE :: var_aerosols(:)
    INTEGER :: nchanl,iret

    logical :: isfile
    
    NAMELIST /record_conf_luts/aerosoloption,wavelengthsoutput,rcfile
    
    aerosoloption=""
    wavelengthsoutput=0.
    rcfile=""

    INQUIRE(file='gocart_aod_fv3_mpi.nl', exist=isfile)
    IF ( isfile ) THEN
       OPEN(unit=98, file='gocart_aod_fv3_mpi.nl', &
            form='formatted', status='old', action='read')
       READ(98, record_conf_luts)
       CLOSE(98)
    ELSE
       PRINT *,'missing namelist gocart_aod_fv3_mpi.nl'
       CALL mpi_abort(mpi_comm_world, iret)
    ENDIF

    conf%aerosol_option = upper2lower(aerosoloption)
    conf%rcfile = rcfile
    CALL assign_aerosol_names(conf%aerosol_option,var_aerosols)

    nchanl=COUNT(wavelengthsoutput > 0.)
    ALLOCATE(conf%wavelengths(nchanl))
    conf%wavelengths=wavelengthsoutput(1:nchanl)

  END SUBROUTINE luts_conf_setup

  SUBROUTINE calculate_aero_layers(nx,nlat,n_layers,ts,sphum,prsl,prsi,&
       &aerosols,aerosol_option,rh,aero_layers)

    IMPLICIT NONE

    INTEGER, INTENT(in) :: nx,nlat,n_layers
    REAL(kind_single), DIMENSION(:,:,:), INTENT(in) :: ts,sphum,prsl,prsi
    REAL(kind_single), DIMENSION(:,:,:,:), INTENT(in) :: aerosols
    CHARACTER(*), INTENT(in) :: aerosol_option
    REAL(kind_real), ALLOCATABLE, INTENT(out) :: rh(:,:,:)
    REAL(kind_real), ALLOCATABLE, INTENT(out) :: aero_layers(:,:,:,:)

! local variables
    INTEGER :: m, ivar, i,j,k, iret, n_aerosols, n_profiles
    CHARACTER(len=maxvarlen) :: varname
    CHARACTER(len=maxvarlen), ALLOCATABLE :: var_aerosols(:)
    REAL(kind_real) :: factor

    IF (TRIM(aerosol_option) /= "aerosols_gocart_1" .AND. &
         &TRIM(aerosol_option) /= "aerosols_gocart_2") THEN
       PRINT *,'This aerosol not implemented ',TRIM(aerosol_option)
       CALL mpi_abort(mpi_comm_world, iret)
    ENDIF

    CALL assign_aerosol_names(aerosol_option,var_aerosols)

    n_aerosols=SIZE(var_aerosols)

    ALLOCATE(aero_layers(nx,nlat,n_layers,n_aerosols),&
         &rh(nx,nlat,n_layers))

    CALL qsmith(REAL(ts,kind_real),REAL(sphum,kind_real),&
         &REAL(prsl,kind_real),rh)
    WHERE (rh > 1_kind_real) rh=1_kind_real

    DO j=1,nx
       DO k=1,n_layers
          DO i=1,nlat
!!for dry mixing ratio
!             factor=(prsi(j,i,k+1)-prsi(j,i,k))/grav/&
!                  &(1_kind_real+rv_rd*sphum(j,i,k)/&
!                  &(1_kind_real-sphum(j,i,k)))
!!for moist mixing ratio
             factor=(prsi(j,i,k+1)-prsi(j,i,k))/grav
             aero_layers(j,i,k,:)=factor*aerosols(j,i,k,:)
          ENDDO
       ENDDO
    ENDDO

  END SUBROUTINE calculate_aero_layers
  
END MODULE ufo_luts_bare_utils_mod

