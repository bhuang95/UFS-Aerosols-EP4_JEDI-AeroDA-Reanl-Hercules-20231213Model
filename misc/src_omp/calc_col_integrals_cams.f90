PROGRAM calc_col_integrals_cams

!integrate species vertically
!mzp july, 2020

  USE datetime_mod
  USE timedelta_mod
  
  USE module_constants
  USE module_netcdf_io
  USE module_utils
  USE module_interp, ONLY: p_interp_nx_ny

  IMPLICIT NONE

  CHARACTER(len=8) :: date

  CHARACTER(len=max_string_length) :: input_dir,fname_in,&
       &output_dir,fname_out

  CHARACTER(len = max_varname_length) :: varlist(nvarmax)
  
  CHARACTER(len = max_varname_length) :: varname
  CHARACTER(len = max_varname_length), ALLOCATABLE :: varnames(:)

  CHARACTER(len = date_string_length), ALLOCATABLE :: datestrings(:)

  REAL, ALLOCATABLE :: lon(:),lat(:),time(:)
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardataij
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: vardataijp,vardataijint
  REAL, ALLOCATABLE :: p(:,:,:,:),pmid(:),delp(:)
  
  REAL :: dtinterval
  LOGICAL :: isfile

  INTEGER :: nlon,nlat,nplevs,nt,nvars
  INTEGER :: i,j,k,l,iv
  INTEGER :: year,month,day,hour

  TYPE(datetime_type), ALLOCATABLE :: validtimes(:)
  TYPE(timedelta_type) :: dt

  NAMELIST /record_input/ date, input_dir,fname_in,varlist
  NAMELIST /record_output/ output_dir,fname_out

  varlist=""

  INQUIRE(file='calc_col_integrals_cams.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='calc_col_integrals_cams.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     READ(98, record_output)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist calc_col_integrals_cams.nl'
     STOP(1)
  ENDIF

  nvars=COUNT(varlist /= "")
  varnames=varlist(:nvars)

  fname_in=TRIM(input_dir)//"/"//TRIM(fname_in)
  fname_out=TRIM(output_dir)//"/"//TRIM(fname_out)

  varname='longitude'
  CALL netcdf_read(fname_in,varname,vardataij)
  nlon=SIZE(vardataij,1)
  ALLOCATE(lon(nlon))
  lon=vardataij(:,1,1,1,1)

  varname='latitude'
  CALL netcdf_read(fname_in,varname,vardataij)
  nlat=SIZE(vardataij,1)
  ALLOCATE(lat(nlat))
  lat=vardataij(:,1,1,1,1)

  varname='time'
  CALL netcdf_read(fname_in,varname,vardataij)
  nt=SIZE(vardataij,1)
  ALLOCATE(time(nt))
  time=vardataij(:,1,1,1,1)

  dtinterval=time(2)-time(1)

  READ(date(1:4),'(i4)')year
  READ(date(5:6),'(i2)')month
  READ(date(7:8),'(i2)')day
  hour=0

  ALLOCATE(validtimes(nt),datestrings(nt))

  validtimes(1)=create_datetime(year=year,month=month,day=day,hour=hour)
  datestrings(1)=validtimes(1)%isoformat()
  IF (nt > 1) THEN
     dt=timedelta(hours=dtinterval)
     DO i=2,nt
        validtimes(i)=validtimes(i-1)+dt
        datestrings(i)=validtimes(i)%isoformat()
     ENDDO
  ENDIF

  varname='level'
  CALL netcdf_read(fname_in,varname,vardataij)
  nplevs=SIZE(vardataij,1)
  ALLOCATE(p(nlon,nlat,nplevs,nt))
  p(1,1,:,1)=vardataij(:,1,1,1,1)

  ALLOCATE(pmid(nplevs-1),delp(nplevs-1))

!fv3: fv_eta.F90

  DO k = 1, nplevs-1
     delp(k) = p(1,1,k+1,1)-p(1,1,k,1)
     pmid(k) = delp(k) / LOG(p(1,1,k+1,1)/p(1,1,k,1)) 
!     PRINT *,pmid(k),delp(k),p(1,1,k,1),p(1,1,k+1,1)
  ENDDO

  
  DO i=1,nlon
     DO j=1,nlat
        DO k=1,nplevs
           p(i,j,k,:)=p(1,1,k,1)
        ENDDO
     ENDDO
  ENDDO

  ALLOCATE(vardataijint(nlon,nlat,1,nt))

  CALL netcdf_write_generic_pll(.TRUE.,fname_out,lon=lon,lat=lat,&
       &plev=p(1,1,nplevs:nplevs,1),datestrings=datestrings)

  DO iv=1,nvars

     varname=varnames(iv)
     CALL netcdf_read(fname_in,varname,vardataij)
!     PRINT *,TRIM(varname),MINVAL(vardataij),MAXVAL(vardataij)

     CALL p_interp_nx_ny(p,pmid,vardataij(:,:,:,:,1),vardataijp)

     vardataijint(:,:,1,:)=0.

     DO k=1,nplevs-1
        vardataijint(:,:,1,:)=vardataijint(:,:,1,:)+&
             &vardataijp(:,:,k,:)*delp(k)/grav*100. !mb to Pa
     ENDDO

     PRINT *,TRIM(varname),MINVAL(vardataijint),MAXVAL(vardataijint)

     CALL netcdf_write_generic_pll(.FALSE.,fname_out,&
          &varname=TRIM(varnames(iv))//'_INTEGRAL',&
          &vardata=vardataijint)

  ENDDO
  
  IF (ALLOCATED(vardataij)) DEALLOCATE(vardataij)
  IF (ALLOCATED(vardataijp)) DEALLOCATE(vardataijp)
  IF (ALLOCATED(vardataijint)) DEALLOCATE(vardataijint)
  IF (ALLOCATED(p)) DEALLOCATE(p)
  IF (ALLOCATED(delp)) DEALLOCATE(delp)
  IF (ALLOCATED(pmid)) DEALLOCATE(pmid)  
  IF (ALLOCATED(lon)) DEALLOCATE(lon)  
  IF (ALLOCATED(lat)) DEALLOCATE(lat)  

END PROGRAM calc_col_integrals_cams
  
