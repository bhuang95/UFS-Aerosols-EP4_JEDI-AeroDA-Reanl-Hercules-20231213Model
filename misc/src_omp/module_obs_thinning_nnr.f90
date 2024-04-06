MODULE module_obs_thinning_nnr

!to thin data for time window, distance, and negative values

  USE datetime_mod
  USE timedelta_mod

  USE module_constants, ONLY: max_varname_length,max_string_length,pi,d2r
  USE module_fv3, ONLY: read_fv3_grid, ntiles, ctiles
  USE module_generic_thinning, ONLY: thinning_sphere
  USE module_aod_nnr, ONLY: aod_nnr

  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: obs_thinning_nnr

CONTAINS

  SUBROUTINE obs_thinning_nnr(aod_nnr_record,nobs,&
       &aod_nnr_thin_record,nobs_thin,center_date_time)

    TYPE(aod_nnr), DIMENSION(nobs), INTENT(in) :: aod_nnr_record
    INTEGER, INTENT(in) :: nobs

    TYPE(aod_nnr), DIMENSION(:), ALLOCATABLE, INTENT(out) :: aod_nnr_thin_record
    
    CHARACTER(len=10), INTENT(out) :: center_date_time

    INTEGER, INTENT(out) :: nobs_thin

    LOGICAL :: thin_spatial
    CHARACTER(len = max_string_length) :: input_dir_grid_thinning
    REAL :: thinning_grid_ratio_min, thinning_grid_ratio_max
    INTEGER :: time_half_window

    TYPE(timedelta_type) :: dt_window,dt
    INTEGER :: nobs_twindow


    CHARACTER(len = max_string_length) :: input_file
    CHARACTER(len = max_string_length), DIMENSION(ntiles) :: gridfiles
    INTEGER :: stderr
    INTEGER :: Open_Status,Read_Status
    INTEGER :: i,j,k,nx,nxy,nchan_nnr

    INTEGER :: num_nn,num_nn_found
    INTEGER, DIMENSION(:), ALLOCATABLE :: nn
    REAL :: dphi_max
    INTEGER, DIMENSION(:), ALLOCATABLE :: output_thin

    REAL, ALLOCATABLE, DIMENSION(:,:) ::  grid1, grid2
    TYPE(aod_nnr), DIMENSION(:), ALLOCATABLE :: aod_nnr_tmp_record
    TYPE(datetime_type) :: validtime,newcentertime

    INTEGER :: yyyy,mm,dd,hh
    INTEGER :: unit_namelist=101

    INTEGER :: off_center
    LOGICAL :: sort_condition
    CHARACTER(len=max_varname_length) :: date_string

    REAL :: start,finish

    NAMELIST /record_obs_thinning/ thin_spatial,center_date_time, &
         &off_center,&
         &input_dir_grid_thinning, &
         &thinning_grid_ratio_min, thinning_grid_ratio_max,&
         &time_half_window
    
    CONTINUE

    stderr = 0

    OPEN(unit=unit_namelist, file = "nnr2ioda.nl", &
         &status="old",action = "READ",iostat=open_status)
    IF (open_status /= 0) THEN
       WRITE(stderr,*) "error: there is no NAMELIST file (nnr2ioda.nl)"
       STOP
    END IF
    WRITE(stderr,*) 'Reading nnr2ioda.nl record_obs_thinning'
    READ (unit_namelist, NML=record_obs_thinning, IOSTAT=Read_Status)
    CLOSE(unit_namelist)

!screen if within time window
!calculate first nobs_twindow

    READ(center_date_time(1:4), '(i4)' )  yyyy
    READ(center_date_time(5:6), '(i2)' )  mm
    READ(center_date_time(7:8), '(i2)' )  dd
    READ(center_date_time(9:10), '(i2)' )  hh
    validtime = create_datetime(year=yyyy,month=mm,day=dd,hour=hh)

    nchan_nnr=SIZE(aod_nnr_record(1)%channels)
    dt_window=timedelta(minutes=time_half_window)

    ALLOCATE(aod_nnr_tmp_record(nobs))

    j=0

    IF (off_center < 0) THEN
       newcentertime=validtime-timedelta(minutes=2*time_half_window)
    ELSE IF (off_center > 0) THEN
       newcentertime=validtime+timedelta(minutes=2*time_half_window)
    ELSE
       newcentertime=validtime
    ENDIF

    date_string=newcentertime%isoformat()

    center_date_time=date_string(1:4)//&
         &date_string(6:7)//date_string(9:10)//&
         &date_string(12:13)
    
    DO i=1,nobs

       dt=aod_nnr_record(i)%obsdate-validtime

       IF ( ABS(dt%total_minutes()) <= dt_window%total_minutes() ) THEN
          IF (off_center == 0) THEN 
             sort_condition = .TRUE.
          ELSEIF (off_center < 0 .AND. dt%total_minutes() < 0.) THEN
             sort_condition = .TRUE.
          ELSEIF (off_center > 0 .AND. dt%total_minutes() > 0.) THEN
             sort_condition = .TRUE.
          ELSE
             sort_condition = .FALSE.
          ENDIF
       ELSE
          sort_condition = .FALSE.
       ENDIF

       IF (sort_condition) THEN

          j=j+1

          IF (ALLOCATED(aod_nnr_tmp_record(j)%channels)) &
               &DEALLOCATE(aod_nnr_tmp_record(j)%channels)
          
          IF (ALLOCATED(aod_nnr_tmp_record(j)%values)) &
               &DEALLOCATE(aod_nnr_tmp_record(j)%values)

          ALLOCATE(aod_nnr_tmp_record(j)%channels(nchan_nnr),&
               &aod_nnr_tmp_record(j)%values(nchan_nnr))
          
          aod_nnr_tmp_record(j)%satellite=aod_nnr_record(i)%satellite
          aod_nnr_tmp_record(j)%obstype=aod_nnr_record(i)%obstype
          aod_nnr_tmp_record(j)%channels(:)=aod_nnr_record(i)%channels(:)
          aod_nnr_tmp_record(j)%values(:)=aod_nnr_record(i)%values(:)
          aod_nnr_tmp_record(j)%lat=aod_nnr_record(i)%lat
          aod_nnr_tmp_record(j)%lon=aod_nnr_record(i)%lon
          aod_nnr_tmp_record(j)%obsdate=aod_nnr_record(i)%obsdate
       ENDIF

    ENDDO

    nobs_twindow=j

    PRINT *,'There are ',nobs_twindow,' observations within half-time window ',time_half_window,' minutes'

    IF (nobs_twindow == 0) THEN
       PRINT *,'Model not matching observation times - Stopping'
       STOP
    ENDIF

    gridfiles=TRIM(input_dir_grid_thinning)//'/'//"grid_spec.tile"//ctiles//".nc"

    CALL read_fv3_grid(gridfiles,grid2)

    nxy=SIZE(grid2,1)
    nx=SQRT(REAL(nxy)/REAL(ntiles))

    ALLOCATE(grid1(nobs_twindow,2))

    grid1(:,1)=aod_nnr_tmp_record(:nobs_twindow)%lat*d2r
    grid1(:,2)=aod_nnr_tmp_record(:nobs_twindow)%lon*d2r
    WHERE ( (grid1(:,2) > pi) ) grid1(:,2)=grid1(:,2)-2.*pi

    WHERE ( (grid2(:,2) > pi) ) grid2(:,2)=grid2(:,2)-2.*pi

!    PRINT *,MINVAL(grid1(:,1)),MAXVAL(grid1(:,1))
!    PRINT *,MINVAL(grid1(:,2)),MAXVAL(grid1(:,2))
!
!    PRINT *,MINVAL(grid2(:,1)),MAXVAL(grid2(:,1))
!    PRINT *,MINVAL(grid2(:,2)),MAXVAL(grid2(:,2))

!    PRINT *,nobs_twindow 

!    PRINT *,SIZE(grid2,1),SIZE(grid2,2)
!    PRINT *,SIZE(grid1,1),SIZE(grid1,2)

    IF (.NOT. thin_spatial) THEN
       nobs_thin=nobs_twindow    
    ELSE
       dphi_max=2.*pi/(4.*REAL(nx))*thinning_grid_ratio_max
       CALL thinning_sphere(grid1,grid2,nobs_twindow,dphi_max,output_thin)
       nobs_thin=SIZE(output_thin)
    ENDIF

    ALLOCATE(aod_nnr_thin_record(nobs_thin))
 
    DO i=1,nobs_thin

       IF (ALLOCATED(aod_nnr_thin_record(i)%channels)) &
            &DEALLOCATE(aod_nnr_thin_record(i)%channels)

       IF (ALLOCATED(aod_nnr_thin_record(i)%values)) &
            &DEALLOCATE(aod_nnr_thin_record(i)%values)

       ALLOCATE(aod_nnr_thin_record(i)%channels(nchan_nnr),&
            &aod_nnr_thin_record(i)%values(nchan_nnr))
       
       IF (thin_spatial) THEN
          j=output_thin(i)
       ELSE
          j=i
       ENDIF

       aod_nnr_thin_record(i)%satellite=aod_nnr_tmp_record(j)%satellite
       aod_nnr_thin_record(i)%obstype=aod_nnr_tmp_record(j)%obstype
       aod_nnr_thin_record(i)%channels(:)=aod_nnr_tmp_record(j)%channels(:)
       aod_nnr_thin_record(i)%values(:)=aod_nnr_tmp_record(j)%values(:)
       aod_nnr_thin_record(i)%lat=aod_nnr_tmp_record(j)%lat
       aod_nnr_thin_record(i)%lon=aod_nnr_tmp_record(j)%lon
       aod_nnr_thin_record(i)%obsdate=aod_nnr_tmp_record(j)%obsdate

    ENDDO

    DO i=1,nobs_twindow
       DEALLOCATE(aod_nnr_tmp_record(i)%channels,aod_nnr_tmp_record(i)%values)
    ENDDO

    DEALLOCATE(aod_nnr_tmp_record)

    DEALLOCATE(grid1,grid2)
    IF (ALLOCATED(output_thin)) DEALLOCATE(output_thin)

    PRINT *,'Retained ',nobs_thin,' observations out of ',nobs

  END SUBROUTINE obs_thinning_nnr


END MODULE module_obs_thinning_nnr
