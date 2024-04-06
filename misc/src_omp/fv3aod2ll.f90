PROGRAM fv3aod2ll

!interpolate fv3 aod to latlon grid
!mzp april, 2020

  USE timedelta_mod
  USE datetime_mod

  USE module_constants
  USE module_fv3
  USE module_netcdf_io
  USE module_interp
  USE module_utils
  USE slint


  IMPLICIT NONE

  REAL, parameter :: logaod_offset=0.01

  CHARACTER(len=max_string_length) :: input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3,output_dir,fname_aod_ll
  CHARACTER(len=max_string_length), DIMENSION(ntiles) ::&
       &gridfiles,fv3files
  CHARACTER(len=max_string_length) :: aodllfile

  REAL :: dlon,dlat

  CHARACTER(len = max_varname_length) :: varname
  CHARACTER(len=10) :: date

  REAL, ALLOCATABLE :: ll_src(:,:),ll_tgt(:,:),lon(:),lat(:)
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: vardataij,vardataijll
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardata

  REAL :: dtinterval

  INTEGER :: year,month,day,hour
  CHARACTER(len = date_string_length), ALLOCATABLE :: datestrings(:)
  TYPE(datetime_type), ALLOCATABLE :: validtimes(:)
  TYPE(timedelta_type) :: dt

  LOGICAL :: isfile

  INTEGER :: nxy,nlon,nlat,nlat1,nll,nt
  INTEGER :: i,j,k,iv

  NAMELIST /record_input/ date,input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3
  NAMELIST /record_interp/ dlon,dlat
  NAMELIST /record_output/ output_dir,fname_aod_ll

  INQUIRE(file='fv3aod2ll.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='fv3aod2ll.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     READ(98, record_interp)
     READ(98, record_output)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist fv3aod2ll.nl'
     STOP 1
  ENDIF


!  PRINT *,TRIM(input_fv3_dir),TRIM(fname_fv3)
!  PRINT *,dlon,dlat
!  PRINT *,TRIM(output_dir)
!  PRINT *,TRIM(fname_aod_ll)  

  nlon=360./dlon
  IF (ABS(dlon*nlon - 360.) > small) THEN
     PRINT *,'adjust output grid resolution: dlon*nlon = ',dlon*nlon
     STOP 1
  ENDIF

  nlat1=180./dlat
  IF (ABS(dlat*nlat1 - 180.) > small) THEN
     PRINT *,'adjust output grid resolution: dlat*nlat1 = ',dlat*nlat1
     STOP 1
  ENDIF

  IF (MOD(nlat1,2) /= 0) THEN
     PRINT *,'adjust output grid: nlat1 is odd = ',nlat1
     STOP 1
  ENDIF

  nlat=nlat1+1

  nll=nlon*nlat

  ALLOCATE(ll_tgt(nll,2),lon(nlon),lat(nlat))

  lon=[(((j-1)*dlon)-180.,j=1,nlon)]
  lat=[((i*dlat),i=-nlat/2,nlat/2)]

  ll_tgt(:,1)=[((i*dlat,i=-nlat1/2,nlat1/2),j=1,nlon)]*d2r
  ll_tgt(:,2)=[(((j-1)*dlon-180.,i=-nlat1/2,nlat1/2),j=1,nlon)]*d2r


!  tmp=RESHAPE(source=[(((j-1)*dlon,i=-nlat1/2,nlat1/2),j=1,nlon)],&
!       &SHAPE=[nlat,nlon])
!  tmp=RESHAPE(source=[((i*dlat,i=-nlat1/2,nlat1/2),j=1,nlon)],&
!       &SHAPE=[nlat,nlon])


!  k=0
!  DO j=1,nlon
!     k=(j-1)*nlat
!     DO i=1,nlat
!        PRINT *,ll_tgt(k+i,1),ll_tgt(k+i,2),i,j
!     ENDDO
!  ENDDO

  CALL filenames(input_grid_dir,fname_grid,gridfiles,&
       &input_fv3_dir,fname_fv3,fv3files)

  CALL read_fv3_grid(gridfiles,ll_src)

!  PRINT *,'ll_src(:,1) ',MINVAL(ll_src(:,1)),MAXVAL(ll_src(:,1))
!  PRINT *,'ll_src(:,2) ',MINVAL(ll_src(:,2)),MAXVAL(ll_src(:,2))
!

  varname="channels"

  CALL netcdf_read(fv3files(1),varname,vardata)

  varname="aod"
  
  CALL read_fv3_var(fv3files,varname,vardataij)

  nt=SIZE(vardataij,4)

  READ(date(1:4),'(i4)')year
  READ(date(5:6),'(i2)')month
  READ(date(7:8),'(i2)')day
  READ(date(9:10),'(i2)')hour

  ALLOCATE(validtimes(nt),datestrings(nt))

  validtimes(1)=create_datetime(year=year,month=month,day=day,hour=hour)

  datestrings(1)=validtimes(1)%isoformat()


  IF (nt > 1) THEN
     dtinterval=24./nt
     dt=timedelta(hours=dtinterval)
     DO i=2,nt
        validtimes(i)=validtimes(i-1)+dt
        datestrings(i)=validtimes(i)%isoformat()
     ENDDO
  ENDIF

  aodllfile=TRIM(output_dir)//'/'//fname_aod_ll

  CALL netcdf_write_fv3aodll(.TRUE.,aodllfile,lon=lon,lat=lat,&
       &channels=vardata(:,1,1,1,1),datestrings=datestrings)


  ALLOCATE(vardataijll(nll,SIZE(vardataij,2),&
       &SIZE(vardataij,3),SIZE(vardataij,4)))

  nxy=SIZE(vardataij,1)

  CALL slint_init(ll_src, nxy, ll_tgt, nll)

  vardataij=LOG(vardataij+logaod_offset)

  CALL h_interp(vardataij,vardataijll)

  vardataijll=EXP(vardataijll)-logaod_offset

!  PRINT *,'@@@1',nll,SIZE(vardataij,2),SIZE(vardataij,3),SIZE(vardataij,4)
!  PRINT *,'@@@2',MINVAL(vardataij),MAXVAL(vardataij)
  
  CALL netcdf_write_fv3aodll(.FALSE.,aodllfile,&
       &varname=varname,vardata=vardataijll)
  
  IF (ALLOCATED(vardataij)) DEALLOCATE(vardataij)
  IF (ALLOCATED(vardataijll)) DEALLOCATE(vardataijll)
  IF (ALLOCATED(ll_src)) DEALLOCATE(ll_src)
  IF (ALLOCATED(ll_tgt)) DEALLOCATE(ll_tgt)
  IF (ALLOCATED(lon)) DEALLOCATE(lon)  
  IF (ALLOCATED(lat)) DEALLOCATE(lat)  

END PROGRAM fv3aod2ll
  
