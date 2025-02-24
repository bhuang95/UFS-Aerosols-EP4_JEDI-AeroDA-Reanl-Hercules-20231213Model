MODULE ufo_aodcrtm_bare_mod

  USE iso_c_binding
  USE module_kinds
  USE module_constants
  USE ufo_vars_mod
  USE ufo_crtm_bare_utils_mod
  USE crtm_module
  USE crtm_spccoeff, ONLY: sc

  IMPLICIT NONE
  PRIVATE

  PUBLIC ufo_aodcrtm_simobs

  CHARACTER(max_string_length), PARAMETER :: varname_tmplate="aerosol_optical_depth"

CONTAINS

  SUBROUTINE ufo_aodcrtm_simobs(nx,nlat,n_layers,ts,sphum,prsl,prsi,&
       &aerosols,channels,conf,hofx,wavelengths)

    IMPLICIT NONE
    INTEGER, INTENT(in) :: nx,nlat,n_layers
    REAL(kind_single), DIMENSION(:,:,:), INTENT(in) :: ts,sphum,prsl,prsi
    REAL(kind_single), DIMENSION(:,:,:,:), INTENT(in) :: aerosols
    REAL(kind_single),        INTENT(inout) :: hofx(:,:,:)
    REAL(kind_single),        INTENT(inout) :: wavelengths(:)

    INTEGER,           INTENT(in) :: channels(:)  !list of channels to use
    TYPE(crtm_conf) :: conf

! local variables
    CHARACTER(*), PARAMETER :: program_name = 'ufo_aodcrtm_mod.f90'
    CHARACTER(255) :: message, version
    INTEGER        :: err_stat, alloc_stat
    INTEGER        :: l, m, n, i, j

    INTEGER :: n_profiles
    INTEGER :: n_channels

! define the "non-demoninational" arguments
    TYPE(crtm_channelinfo_type)             :: chinfo(conf%n_sensors)
    TYPE(crtm_geometry_type),   ALLOCATABLE :: geo(:)

! define the forward variables
    TYPE(crtm_atmosphere_type), ALLOCATABLE :: atm(:)
    TYPE(crtm_surface_type),    ALLOCATABLE :: sfc(:)
    TYPE(crtm_rtsolution_type), ALLOCATABLE :: rts(:,:)

! define the k-matrix variables - necessary for aod call
! ---------------------------------
    TYPE(crtm_atmosphere_type), ALLOCATABLE :: atm_k(:,:)
    TYPE(crtm_rtsolution_type), ALLOCATABLE :: rts_k(:,:)

    REAL(kind_single), ALLOCATABLE :: wavelengths_all(:)

    n_profiles = nx*nlat

! program header
! --------------
! call crtm_version( version )
! call program_message( program_name, &
!                       'check/example program for the crtm forward and k-matrix functions using '//&
!                       trim(conf%endian_type)//' coefficient datafiles', &
!                       'crtm version: '//trim(version) )


! initialise all the sensors at once
! ----------------------------------
!** note: crtm_init points to the various binary files needed for crtm.  see the
!**       crtm_lifecycle.f90 for more details.

! write( *,'(/5x,"initializing the crtm...")' )
    err_stat = crtm_init( conf%sensor_id, &
         chinfo, &
         file_path=TRIM(conf%coefficient_path), &
         quiet=.TRUE.)
    IF ( err_stat /= success ) THEN
       message = 'error initializing crtm'
       CALL display_message( program_name, message, failure )
       STOP
    END IF


! loop over all sensors. not necessary if we're calling crtm for each sensor
! ----------------------------------------------------------------------------
    sensor_loop:DO n = 1, conf%n_sensors


! determine the number of channels for the current sensor
! -------------------------------------------------------
       n_channels = crtm_channelinfo_n_channels(chinfo(n))

       IF (ALLOCATED(wavelengths_all)) DEALLOCATE(wavelengths_all)

       ALLOCATE(wavelengths_all(n_channels))

       wavelengths_all=1.e7/sc(chinfo(n)%sensor_index)%wavenumber(:)

! allocate the arrays
! -------------------
       ALLOCATE( geo( n_profiles ),               &
            atm( n_profiles ),               &
            sfc( n_profiles ),               &
            rts( n_channels, n_profiles ),   &
            stat = alloc_stat )
       IF ( alloc_stat /= 0 ) THEN
          message = 'error allocating structure arrays'
          CALL display_message( program_name, message, failure )
          STOP
       END IF


! create the input forward structure (atm)
! ----------------------------------------
       CALL crtm_atmosphere_create( atm, n_layers, conf%n_absorbers, conf%n_clouds, conf%n_aerosols )
       IF ( ANY(.NOT. crtm_atmosphere_associated(atm)) ) THEN
          message = 'error allocating crtm forward atmosphere structure'
          CALL display_message( program_name, message, failure )
          STOP
       END IF

       ALLOCATE( atm_k( n_channels, n_profiles ), &
            rts_k( n_channels, n_profiles ), &
            stat = alloc_stat )
       IF ( alloc_stat /= 0 ) THEN
          message = 'error allocating structure arrays'
          CALL display_message( program_name, message, failure )
          STOP
       END IF

! the output k-matrix structure
       CALL crtm_atmosphere_create( atm_k, n_layers, conf%n_absorbers, conf%n_clouds, conf%n_aerosols)
       IF ( ANY(.NOT. crtm_atmosphere_associated(atm_k)) ) THEN
          message = 'error allocating crtm k-matrix atmosphere structure'
          CALL display_message( program_name, message, failure )
          STOP
       END IF

       CALL crtm_rtsolution_create(rts, n_layers )
       CALL crtm_rtsolution_create(rts_k, n_layers )

       CALL load_atm_data(nx,nlat,n_layers,conf,ts,sphum,prsl,prsi,atm)

       IF (TRIM(conf%aerosol_option) /= "") &
            &CALL load_aerosol_data(nx,nlat,n_layers,&
            &conf%aerosol_option,aerosols,atm)

! 8b.1 the k-matrix model for aod
! ----------------------
       err_stat = crtm_aod_k( atm,    &  ! forward  input
            rts_k                   , &  ! k-matrix input
            chinfo(n:n)             , &  ! input
            rts                     , &  ! forward  output
            atm_k        )               ! k-matrix output

       IF ( err_stat /= success ) THEN
          message = 'error calling crtm forward model for '//TRIM(conf%sensor_id(n))
          CALL display_message( program_name, message, failure )
          STOP
       END IF


       m=0
       DO j=1,nx
          DO i=1,nlat
             m=m+1
             DO l = 1, SIZE(channels)
                hofx(j,i,l) = SUM(rts(channels(l),m)%layer_optical_depth)
             END DO
          END DO
       ENDDO

       DO l = 1, SIZE(channels)
          wavelengths(l)=wavelengths_all(channels(l))
       ENDDO

       CALL crtm_atmosphere_destroy(atm)
       CALL crtm_rtsolution_destroy(rts)

       CALL crtm_atmosphere_destroy(atm_k)
       CALL crtm_rtsolution_destroy(rts_k)

! deallocate all arrays
! ---------------------
       DEALLOCATE(geo, atm, sfc, rts, atm_k, rts_k, stat = alloc_stat)
       IF ( alloc_stat /= 0 ) THEN
          message = 'error deallocating structure arrays'
          CALL display_message( program_name, message, failure )
          STOP
       END IF

    END DO sensor_loop

! destroy crtm instance
! ---------------------
! write( *, '( /5x, "destroying the crtm..." )' )
    err_stat = crtm_destroy( chinfo )
    IF ( err_stat /= success ) THEN
       message = 'error destroying crtm'
       CALL display_message( program_name, message, failure )
       STOP
    END IF

  END SUBROUTINE ufo_aodcrtm_simobs

! ------------------------------------------------------------------------------

END MODULE ufo_aodcrtm_bare_mod
