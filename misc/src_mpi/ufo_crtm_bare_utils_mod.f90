MODULE ufo_crtm_bare_utils_mod

  USE module_kinds
  USE module_constants, ONLY : maxvarlen,max_string,imissing,&
       &n_maxabsorbers,n_maxchannels
  USE ufo_vars_mod
  USE crtm_module

  USE iso_c_binding

  IMPLICIT NONE
  PRIVATE

  INCLUDE 'mpif.h'

  PUBLIC crtm_conf
  PUBLIC crtm_conf_setup
  PUBLIC load_atm_data

  PUBLIC load_aerosol_data
  PUBLIC calculate_aero_layer_factor
  PUBLIC assign_aerosol_names
  PUBLIC upper2lower

  PUBLIC :: qsmith
  PUBLIC :: grav,rv_rd,&
     &aerosol_concentration_minvalue,aerosol_concentration_minvalue_layer
  
  REAL(kind_real), PARAMETER :: &
       &rdgas = 2.8704e+2_kind_real,&
       &rvgas = 4.6150e+2_kind_real,&
       &rv_rd = rvgas/rdgas,&
       &esl = 0.621971831,&
       &zvir =  rv_rd - 1_kind_real,&
       &tice = 273.16_kind_real,&
       &grav = 9.81_kind_real,&
       &aerosol_concentration_minvalue=1.e-16_kind_single,&
       &aerosol_concentration_minvalue_layer=TINY(rdgas),&
       &ozone_default_value=1.e-3_kind_real ! in ppmv in crtm

!type for general config
  TYPE crtm_conf
     INTEGER :: n_sensors
     INTEGER :: n_absorbers
     INTEGER :: n_clouds
     INTEGER :: n_aerosols
     CHARACTER(len=maxvarlen), ALLOCATABLE :: absorbers(:)
     INTEGER, ALLOCATABLE :: absorber_id(:)
     INTEGER, ALLOCATABLE :: absorber_units(:)
     CHARACTER(len=255), ALLOCATABLE :: sensor_id(:)
     CHARACTER(len=255) :: endian_type
     CHARACTER(len=255) :: coefficient_path
     CHARACTER(len=maxvarlen) :: aerosol_option
  END TYPE crtm_conf

  INTERFACE calculate_aero_layer_factor

     MODULE PROCEDURE calculate_aero_layer_factor_atm_profile,&
          &calculate_aero_layer_factor_atm

  END INTERFACE calculate_aero_layer_factor

  INTERFACE qsmith

     MODULE PROCEDURE qsmith_atm,qsmith_profiles,qsmith_nxnlat

  END INTERFACE qsmith


! add more ufo_absorbers as needed
! note: must have same ordering as crtm_absorbers, 
!       crtm_absorber_id, and crtm_absorber_units
  CHARACTER(len=maxvarlen), PARAMETER :: &
       ufo_absorbers(3) = &
       [ var_mixr, var_co2, var_oz ]

! copy of absorber_id_name defined in crtm_atmosphere_define
  CHARACTER(len=*), PARAMETER :: &
       crtm_absorbers(n_valid_absorber_ids) = &
       absorber_id_name(1:n_valid_absorber_ids)
  INTEGER, PARAMETER :: &
       crtm_absorber_id(n_valid_absorber_ids) = &
       [ h2o_id,  co2_id,   o3_id,  n2o_id, &
       co_id,  ch4_id,   o2_id,   no_id, &
       so2_id,  no2_id,  nh3_id, hno3_id, &
       oh_id,   hf_id,  hcl_id,  hbr_id, &
       hi_id,  clo_id,  ocs_id, h2co_id, &
       hocl_id,   n2_id,  hcn_id, ch3l_id, &
       h2o2_id, c2h2_id, c2h6_id,  ph3_id, &
       cof2_id,  sf6_id,  h2s_id,hcooh_id ]
  INTEGER, PARAMETER :: &
       crtm_absorber_units(3) = [ &
       mass_mixing_ratio_units   & !h2o
       , volume_mixing_ratio_units & !co2
       , volume_mixing_ratio_units & !o3
       ]

CONTAINS

  SUBROUTINE crtm_conf_setup(conf,channels_selected)

    IMPLICIT NONE
    TYPE(crtm_conf),            INTENT(inout) :: conf
    INTEGER, ALLOCATABLE, INTENT(out) :: channels_selected(:)

    CHARACTER(*), PARAMETER :: routine_name = 'crtm_conf_setup'

    CHARACTER(len=255) :: sensor_id,endiantype,coefficientpath

    CHARACTER(len=maxvarlen) :: absorbers(n_maxabsorbers),aerosoloption
    INTEGER :: channels(n_maxchannels),nchanl

    LOGICAL :: isfile

    INTEGER :: jspec, ivar, iret
    CHARACTER(len=max_string) :: message
    CHARACTER(len=maxvarlen), ALLOCATABLE :: var_aerosols(:)

    NAMELIST /record_conf_crtm/aerosoloption,absorbers,sensor_id,&
         &endiantype,coefficientpath,channels

    absorbers=""
    sensor_id=""
    endiantype=""
    coefficientpath=""
    aerosoloption=""
    channels=imissing

    INQUIRE(file='gocart_aod_fv3_mpi.nl', exist=isfile)
    IF ( isfile ) THEN
       OPEN(unit=98, file='gocart_aod_fv3_mpi.nl', &
            form='formatted', status='old', action='read')
       READ(98, record_conf_crtm)
       CLOSE(98)
    ELSE
       PRINT *,'missing namelist gocart_aod_fv3_mpi.nl'
       CALL mpi_abort(mpi_comm_world, iret)
    ENDIF

    nchanl=COUNT(channels /= imissing)
    ALLOCATE(channels_selected(nchanl))
    channels_selected=channels(1:nchanl)

    conf%n_clouds = 0
    conf%n_absorbers = COUNT(absorbers /= '')

    ALLOCATE( conf%absorbers     ( conf%n_absorbers ), &
         conf%absorber_id   ( conf%n_absorbers ), &
         conf%absorber_units( conf%n_absorbers ) )

    conf%absorbers(1:conf%n_absorbers) = absorbers(1:conf%n_absorbers)

    conf%n_sensors = 1

! convert from crtm names to ufo cf names and define id and units
    DO jspec = 1, conf%n_absorbers
       ivar = ufo_vars_getindex(crtm_absorbers, conf%absorbers(jspec))
       IF (ivar < 1 .OR. ivar > SIZE(ufo_absorbers)) THEN
          WRITE(message,*) TRIM(routine_name),' error: ',TRIM(conf%absorbers(jspec)),' not supported by ufo_absorbers'
          CALL mpi_abort(mpi_comm_world, iret)
       END IF
       conf%absorbers(jspec) = ufo_absorbers(ivar)
       conf%absorber_id(jspec) = crtm_absorber_id(ivar)
       conf%absorber_units(jspec) = crtm_absorber_units(ivar)
    END DO

    ALLOCATE(conf%sensor_id(conf%n_sensors))

    conf%sensor_id(conf%n_sensors) = sensor_id
    conf%endian_type = endiantype
    conf%coefficient_path = TRIM(coefficientpath)//"/"&
         &//TRIM(conf%endian_type)//"/"

    conf%aerosol_option = upper2lower(aerosoloption)

    CALL assign_aerosol_names(conf%aerosol_option,var_aerosols)
    conf%n_aerosols=SIZE(var_aerosols)

  END SUBROUTINE crtm_conf_setup


  SUBROUTINE load_atm_data(nx,nlat,n_layers,conf,ts,sphum,prsl,prsi,atm)

    IMPLICIT NONE

    INTEGER, INTENT(in) :: nx,nlat,n_layers
    REAL(kind_single), DIMENSION(:,:,:), INTENT(in) :: ts,sphum,prsl,prsi
    TYPE(crtm_atmosphere_type), INTENT(inout) :: atm(:)
    TYPE(crtm_conf) :: conf

! local variables
    INTEGER :: k1, jspec,i,j,n_profiles,iret
    CHARACTER(max_string) :: err_msg


! populate the atmosphere structures for crtm
! -------------------------------------------

    n_profiles=nx*nlat

    k1=0
    
    DO j=1,nx
       DO i=1,nlat
          k1=k1+1
          
          IF (k1 == 1) THEN
             IF (SIZE(ts(1,1,:) /= n_layers)) THEN
                WRITE(err_msg,*) 'load_atm_data error: &
                     &layers inconsistent'
                CALL mpi_abort(mpi_comm_world, iret)
             ENDIF
          ENDIF
          
          atm(k1)%temperature(1:n_layers) = ts(j,i,:)
          
          atm(k1)%pressure(1:n_layers) = prsl(j,i,:) * 0.01_fp  ! to hpa
          atm(k1)%level_pressure(:) = prsi(j,i,:) * 0.01_fp     ! to hpa
          atm(k1)%climatology         = us_standard_atmosphere
          
          DO jspec = 1, conf%n_absorbers
             IF ( TRIM(conf%absorbers(jspec)) == TRIM(var_mixr)) THEN
                atm(k1)%absorber(1:n_layers,jspec) = sphum(j,i,:)/(1_kind_real-sphum(j,i,:))
             ELSEIF ( TRIM(conf%absorbers(jspec)) == TRIM(var_oz)) THEN
                atm(k1)%absorber(1:n_layers,jspec) = ozone_default_value
             ENDIF
             atm(k1)%absorber_id(jspec) = conf%absorber_id(jspec)
             atm(k1)%absorber_units(jspec) = conf%absorber_units(jspec)
          END DO
       END DO
    ENDDO
  
  END SUBROUTINE load_atm_data

  SUBROUTINE load_aerosol_data(nx,nlat,n_layers,&
       &aerosol_option,aerosols,atm)
    
    USE crtm_aerosolcoeff, ONLY: aeroc
    
    INTEGER, INTENT(in) :: nx,nlat,n_layers
    REAL(kind_single), DIMENSION(:,:,:,:), INTENT(in) :: aerosols
    TYPE(crtm_atmosphere_type), INTENT(inout) :: atm(:)

    CHARACTER(*) :: aerosol_option
    CHARACTER(max_string) :: message
    CHARACTER(len=maxvarlen) :: varname

    CHARACTER(*), PARAMETER :: routine_name = 'load_aerosol_data'

    REAL(kind_real), DIMENSION(n_layers,nx*nlat) :: rh
    INTEGER :: ivar

    IF (TRIM(aerosol_option) == "aerosols_gocart_default") THEN
       CALL qsmith(atm,rh)
       WHERE (rh > 1_kind_real) rh=1_kind_real
       CALL assign_gocart_default
    ELSEIF (TRIM(aerosol_option) == "aerosols_gocart_1") THEN
       CALL qsmith(atm,rh)
       WHERE (rh > 1_kind_real) rh=1_kind_real
       CALL assign_gocart_1
    ELSEIF (TRIM(aerosol_option) == "aerosols_gocart_2") THEN
       CALL qsmith(atm,rh)
       WHERE (rh > 1_kind_real) rh=1_kind_real
       CALL assign_gocart_2
    ELSEIF (TRIM(aerosol_option) == "aerosols_other") THEN
       CALL assign_other
    ELSE
       message = 'this aerosol not implemented - check later'
       CALL display_message( aerosol_option, message, failure )
       STOP
    ENDIF

  CONTAINS 

    SUBROUTINE assign_gocart_default

      INTEGER, PARAMETER :: ndust_bins=5, nseas_bins=4
      REAL(kind_real), DIMENSION(ndust_bins), PARAMETER  :: dust_radii=[&
           &0.55_kind_real,1.4_kind_real,2.4_kind_real,4.5_kind_real,8.0_kind_real]
      
      INTEGER, DIMENSION(nseas_bins), PARAMETER  :: seas_types=[&
           seasalt_ssam_aerosol,seasalt_sscm1_aerosol,seasalt_sscm2_aerosol,seasalt_sscm3_aerosol]

      REAL(kind_real), DIMENSION(n_layers) :: layer_factors
      
      INTEGER :: i,j,k,m,ia

      CHARACTER(len=maxvarlen) :: varname

      m=0

      DO j=1,nx
         DO i=1,nlat
            m=m+1
            
            CALL calculate_aero_layer_factor(atm(m),layer_factors)
            
            DO ia=1,n_aerosols_gocart_default

               varname=var_aerosols_gocart_default(ia)
               atm(m)%aerosol(ia)%concentration(1:n_layers)=&
                    &MAX(aerosols(j,i,:,ia)*layer_factors,aerosol_concentration_minvalue_layer)

               
               SELECT CASE (TRIM(varname))
               CASE (var_sulfate)
                  atm(m)%aerosol(ia)%TYPE  = sulfate_aerosol
                  DO k=1,n_layers
                     atm(m)%aerosol(ia)%effective_radius(k)=&
                          &gocart_aerosol_size(atm(m)%aerosol(ia)%TYPE, &
                          &rh(k,m))
                  ENDDO
                  
               CASE (var_bcphobic)
                  atm(m)%aerosol(ia)%TYPE  = black_carbon_aerosol
                  atm(m)%aerosol(ia)%effective_radius(:)=&
                       &aeroc%reff(1,atm(m)%aerosol(ia)%TYPE)
               CASE (var_bcphilic)
                  atm(m)%aerosol(ia)%TYPE  = black_carbon_aerosol
                  DO k=1,n_layers
                     atm(m)%aerosol(ia)%effective_radius(k)=&
                          &gocart_aerosol_size(atm(m)%aerosol(ia)%TYPE, &
                          &rh(k,m))
                  ENDDO
                  
               CASE (var_ocphobic)
                  atm(m)%aerosol(ia)%TYPE  = organic_carbon_aerosol
                  atm(m)%aerosol(ia)%effective_radius(:)=&
                       &aeroc%reff(1,atm(m)%aerosol(ia)%TYPE)
               CASE (var_ocphilic)
                  atm(m)%aerosol(ia)%TYPE  = organic_carbon_aerosol
                  DO k=1,n_layers
                     atm(m)%aerosol(ia)%effective_radius(k)=&
                          &gocart_aerosol_size(atm(m)%aerosol(ia)%TYPE, &
                          &rh(k,m))
                  ENDDO
                  
               CASE (var_du001)
                  atm(m)%aerosol(ia)%TYPE  = dust_aerosol
                  atm(m)%aerosol(ia)%effective_radius(:)=dust_radii(1)
               CASE (var_du002)
                  atm(m)%aerosol(ia)%TYPE  = dust_aerosol
                  atm(m)%aerosol(ia)%effective_radius(:)=dust_radii(2)
               CASE (var_du003)
                  atm(m)%aerosol(ia)%TYPE  = dust_aerosol
                  atm(m)%aerosol(ia)%effective_radius(:)=dust_radii(3)
               CASE (var_du004)
                  atm(m)%aerosol(ia)%TYPE  = dust_aerosol
                  atm(m)%aerosol(ia)%effective_radius(:)=dust_radii(4)
               CASE (var_du005)
                  atm(m)%aerosol(ia)%TYPE  = dust_aerosol
                  atm(m)%aerosol(ia)%effective_radius(:)=dust_radii(5)
                  
               CASE (var_ss001)
                  atm(m)%aerosol(ia)%TYPE  = seas_types(1)
                  DO k=1,n_layers
                     atm(m)%aerosol(ia)%effective_radius(k)=&
                          &gocart_aerosol_size(atm(m)%aerosol(ia)%TYPE, &
                          &rh(k,m))
                  ENDDO
               CASE (var_ss002)
                  atm(m)%aerosol(ia)%TYPE  = seas_types(2)
                  DO k=1,n_layers
                     atm(m)%aerosol(ia)%effective_radius(k)=&
                          &gocart_aerosol_size(atm(m)%aerosol(ia)%TYPE, &
                          &rh(k,m))
                  ENDDO
               CASE (var_ss003)
                  atm(m)%aerosol(ia)%TYPE  = seas_types(3)
                  DO k=1,n_layers
                     atm(m)%aerosol(ia)%effective_radius(k)=&
                          &gocart_aerosol_size(atm(m)%aerosol(ia)%TYPE, &
                          &rh(k,m))
                  ENDDO
               CASE (var_ss004)
                  atm(m)%aerosol(ia)%TYPE  = seas_types(4)
                  DO k=1,n_layers
                     atm(m)%aerosol(ia)%effective_radius(k)=&
                       &gocart_aerosol_size(atm(m)%aerosol(ia)%TYPE, &
                       &rh(k,m))
                  ENDDO
               
               END SELECT
               
            ENDDO

         ENDDO
      ENDDO

    END SUBROUTINE assign_gocart_default

    SUBROUTINE assign_gocart_1

      INTEGER :: iret

      message = 'this aerosol not implemented in the crtm - check later'
      CALL display_message( aerosol_option, message, failure )
      CALL mpi_abort(mpi_comm_world, iret)

    END SUBROUTINE assign_gocart_1

    SUBROUTINE assign_gocart_2

      INTEGER :: iret

      message = 'this aerosol not implemented in the crtm - check later'
      CALL display_message( aerosol_option, message, failure )
      CALL mpi_abort(mpi_comm_world, iret)

    END SUBROUTINE assign_gocart_2

    SUBROUTINE assign_other

      INTEGER :: iret

      message = 'this aerosol not implemented - check later'
      CALL display_message( aerosol_option, message, failure )
      CALL mpi_abort(mpi_comm_world, iret)

    END SUBROUTINE assign_other

  END SUBROUTINE load_aerosol_data

  SUBROUTINE assign_aerosol_names(aerosol_option,var_aerosols)

    CHARACTER(*), INTENT(in) :: aerosol_option
    CHARACTER(len=maxvarlen), ALLOCATABLE, INTENT(out) :: var_aerosols(:)

    CHARACTER(max_string) :: err_msg,iret

    IF (aerosol_option == "aerosols_gocart_default") THEN
       ALLOCATE(var_aerosols(SIZE(var_aerosols_gocart_default)))
       var_aerosols=var_aerosols_gocart_default
    ELSEIF (aerosol_option == "aerosols_gocart_1") THEN
       ALLOCATE(var_aerosols(SIZE(var_aerosols_gocart_1)))
       var_aerosols=var_aerosols_gocart_1
    ELSEIF (aerosol_option == "aerosols_gocart_2") THEN
       ALLOCATE(var_aerosols(SIZE(var_aerosols_gocart_2)))
       var_aerosols=var_aerosols_gocart_2
    ELSEIF (aerosol_option == "aerosols_other") THEN
       ALLOCATE(var_aerosols(SIZE(var_aerosols_other)))
       var_aerosols=var_aerosols_other
    ELSE
       WRITE(err_msg,*) 'assign_aerosol_names: aerosol_option not implemented '//TRIM(aerosol_option)
       CALL mpi_abort(mpi_comm_world, iret)
    END IF

  END SUBROUTINE assign_aerosol_names

  SUBROUTINE calculate_aero_layer_factor_atm_profile(atm,layer_factors)

    TYPE(crtm_atmosphere_type), INTENT(in) :: atm
    REAL(kind_real), INTENT(out) :: layer_factors(:)

    INTEGER :: k

    DO k=1,SIZE(layer_factors)
!correct for mixing ratio factor layer_factors 
!being calculated from dry pressure, cotton eq. (2.4)
!p_dry=p_total/(1+1.61*mixing_ratio)
       layer_factors(k)=(atm%level_pressure(k)-&
            &atm%level_pressure(k-1))*100_kind_real/grav/&
            &(1_kind_real+rv_rd*atm%absorber(k,1)*1e-3_kind_real)
    ENDDO

  END SUBROUTINE calculate_aero_layer_factor_atm_profile

  SUBROUTINE calculate_aero_layer_factor_atm(atm,layer_factors)

    TYPE(crtm_atmosphere_type), INTENT(in) :: atm(:)
    REAL(kind_real), INTENT(out) :: layer_factors(:,:)

    INTEGER :: k,m

    DO k=1,SIZE(layer_factors,1)
       DO m=1,SIZE(layer_factors,2)
!correct for mixing ratio factor layer_factors 
!being calculated from dry pressure, cotton eq. (2.4)
!p_dry=p_total/(1+1.61*mixing_ratio)
          layer_factors(k,m)=(atm(m)%level_pressure(k)-&
               &atm(m)%level_pressure(k-1))*100_kind_real/grav/&
               &(1_kind_real+rv_rd*atm(m)%absorber(k,1)*1.e-3_kind_real)
       ENDDO
    ENDDO

  END SUBROUTINE calculate_aero_layer_factor_atm

  FUNCTION gocart_aerosol_size( itype, rh ) & ! rh input in 0-1
       &RESULT(r_eff)   ! in micrometer

    USE crtm_aerosolcoeff, ONLY: aeroc
    IMPLICIT NONE

!
!   modified from a function provided by quanhua liu
!
    INTEGER ,INTENT(in) :: itype
    REAL(kind_real)    ,INTENT(in) :: rh

    INTEGER :: j1,j2,m
    REAL(kind_real)    :: h1
    REAL(kind_real)    :: r_eff

    j2 = 0
    j1 = 1
    IF ( rh <= aeroc%rh(1) ) THEN
       j1 = 1
    ELSE IF ( rh >= aeroc%rh(aeroc%n_rh) ) THEN
       j1 = aeroc%n_rh
    ELSE
       DO m = 1, aeroc%n_rh-1
          IF ( rh < aeroc%rh(m+1) .AND. rh > aeroc%rh(m) ) THEN
             j1 = m
             j2 = m+1
             h1 = (rh-aeroc%rh(m))/(aeroc%rh(m+1)-aeroc%rh(m))
             EXIT
          ENDIF
       ENDDO
    ENDIF

    IF ( j2 == 0 ) THEN
       r_eff = aeroc%reff(j1,itype )
    ELSE
       r_eff = (1_kind_real-h1)*aeroc%reff(j1,itype ) + h1*aeroc%reff(j2,itype )
    ENDIF

  END FUNCTION gocart_aerosol_size


  FUNCTION upper2lower(str) RESULT(string)

    IMPLICIT NONE

    CHARACTER(*), INTENT(in) :: str
    CHARACTER(LEN(str))      :: string

    INTEGER :: ic, i

    CHARACTER(26), PARAMETER :: upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    CHARACTER(26), PARAMETER :: lower = 'abcdefghijklmnopqrstuvwxyz'

!   lowcase each letter if it is lowecase
    string = str
    DO i = 1, LEN_TRIM(str)
       ic = INDEX(upper, str(i:i))
       IF (ic > 0) string(i:i) = lower(ic:ic)
    END DO

  END FUNCTION upper2lower

  INTEGER FUNCTION getindex(names,usrname)
    IMPLICIT NONE
    CHARACTER(len=*),INTENT(in) :: names(:)
    CHARACTER(len=*),INTENT(in) :: usrname
    INTEGER i
    getindex=-1
    DO i=1,SIZE(names)
       IF(TRIM(usrname)==TRIM(names(i))) THEN
          getindex=i
          EXIT
       ENDIF
    ENDDO
  END FUNCTION getindex

!from fv3

  SUBROUTINE qsmith_atm(atm,rh)

    TYPE(crtm_atmosphere_type), INTENT(in) :: atm(:)
    REAL(kind_real), INTENT(out),DIMENSION(:,:):: rh

    REAL, ALLOCATABLE :: table(:),des(:)

    REAL es, qs, q
    REAL ap1, eps10
    REAL tmin
    INTEGER i, k, it, n_layers, n_profiles

    n_layers=SIZE(rh,1)
    n_profiles=SIZE(rh,2)

    tmin = tice-160.
    eps10  = 10.*esl

    IF( .NOT. ALLOCATED(table) ) CALL qsmith_init(table,des)

    DO k=1,n_layers
       DO i=1,n_profiles
          ap1 = 10.*DIM(atm(i)%temperature(k), tmin) + 1.
          ap1 = MIN(2621., ap1)
          it = ap1
          es = table(it) + (ap1-it)*des(it)
          q=atm(i)%absorber(k,1)*1.e-3/(1.+atm(i)%absorber(k,1)*1.e-3)
          qs = esl*es*(1.+zvir*q)/(atm(i)%pressure(k)*100.)
          rh(k,i) = q/qs
       ENDDO
    ENDDO

  END SUBROUTINE qsmith_atm

  SUBROUTINE qsmith_profiles(t,sphum,p,rh)

    REAL(kind_real), DIMENSION(:,:), INTENT(in) :: t,sphum,p
    REAL(kind_real), DIMENSION(:,:), INTENT(out) :: rh

    REAL, ALLOCATABLE :: table(:),des(:)

    REAL es, qs, q
    REAL ap1, eps10
    REAL tmin
    INTEGER i, k, it, n_layers, n_profiles

    n_layers=SIZE(t,1)
    n_profiles=SIZE(t,2)

    tmin = tice-160.
    eps10  = 10.*esl

    IF ( .NOT. ALLOCATED(table) ) CALL qsmith_init(table,des)

    DO k=1,n_layers
       DO i=1,n_profiles
          ap1 = 10.*DIM(t(k,i), tmin) + 1.
          ap1 = MIN(2621., ap1)
          it = ap1
          es = table(it) + (ap1-it)*des(it)
          q=sphum(k,i)
          qs = esl*es*(1.+zvir*q)/p(k,i)
          rh(k,i) = q/qs
       ENDDO
    ENDDO

  END SUBROUTINE qsmith_profiles

  SUBROUTINE qsmith_nxnlat(t,sphum,p,rh)

    REAL(kind_real), DIMENSION(:,:,:), INTENT(in) :: t,sphum,p
    REAL(kind_real), DIMENSION(:,:,:), INTENT(out) :: rh

    REAL, ALLOCATABLE :: table(:),des(:)

    REAL es, qs, q
    REAL ap1, eps10
    REAL tmin
    INTEGER i, j, k, it, n_layers, nx, nlat

    nx=SIZE(t,1)
    nlat=SIZE(t,2)
    n_layers=SIZE(t,3)

    tmin = tice-160.
    eps10  = 10.*esl

    IF ( .NOT. ALLOCATED(table) ) CALL qsmith_init(table,des)

    DO j=1,nx
       DO k=1,n_layers
          DO i=1,nlat
             ap1 = 10.*DIM(t(j,i,k), tmin) + 1.
             ap1 = MIN(2621., ap1)
             it = ap1
             es = table(it) + (ap1-it)*des(it)
             q=sphum(j,i,k)
             qs = esl*es*(1.+zvir*q)/p(j,i,k)
             rh(j,i,k) = q/qs
          ENDDO
       ENDDO
    ENDDO

  END SUBROUTINE qsmith_nxnlat

  SUBROUTINE qsmith_init(table,des)

    REAL, ALLOCATABLE, INTENT(out) :: table(:),des(:)
    INTEGER, PARAMETER:: length=2621 
    INTEGER i

    IF( .NOT. ALLOCATED(table) ) THEN
!                            generate es table (dt = 0.1 deg. c)

       ALLOCATE ( table(length) )
       ALLOCATE (  des (length) )

       CALL qs_table(length, table)

       DO i=1,length-1
          des(i) = table(i+1) - table(i)
       ENDDO
       des(length) = des(length-1)
    ENDIF

  END SUBROUTINE qsmith_init

  SUBROUTINE qs_table(n,table)
    INTEGER, INTENT(in):: n
    REAL table (n)
    REAL :: dt=0.1
    REAL esbasw, tbasw, tbasi, tmin, tem, aa, b, c, d, e
    INTEGER i
! constants
    esbasw = 1013246.0
    tbasw =   373.16
    tbasi =   273.16
    tmin = tbasi - 160.
!  compute es over water
!  see smithsonian meteorological tables page 350.
    DO  i=1,n
       tem = tmin+dt*REAL(i-1)
       aa  = -7.90298*(tbasw/tem-1)
       b   =  5.02808*alog10(tbasw/tem)
       c   = -1.3816e-07*(10**((1-tem/tbasw)*11.344)-1)
       d   =  8.1328e-03*(10**((tbasw/tem-1)*(-3.49149))-1)
       e   =  alog10(esbasw)
       table(i)  = 0.1*10**(aa+b+c+d+e)
    ENDDO

  END SUBROUTINE qs_table

END MODULE ufo_crtm_bare_utils_mod

