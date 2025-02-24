PROGRAM fv32ll

!interpolate fv3 to latlon grid on original model levels and add 
!temperature, specific humidity, and ps
!mzp march, 2020

  USE timedelta_mod
  USE datetime_mod

  USE module_constants
  USE module_fv3
  USE module_netcdf_io
  USE module_interp
  USE module_utils
  USE slint


  IMPLICIT NONE

  CHARACTER(len=max_string_length) :: input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3_tracer,fname_fv3_core,fname_akbk,&
       &output_dir,fname_ll
  CHARACTER(len=max_string_length), DIMENSION(ntiles) ::&
       &gridfiles,fv3files_tracer,fv3files_core
  CHARACTER(len=max_string_length) :: akbkfile,llfile

  CHARACTER(len = max_varname_length) :: varlist_core(nvarmax),&
       &varlist_tracer(nvarmax), units
  REAL :: dlon,dlat

  CHARACTER(len = max_varname_length) :: varname
  CHARACTER(len = max_varname_length), ALLOCATABLE :: varnames_core(:),&
       varnames_tracer(:),varnames_in(:)
  CHARACTER(len=10) :: date


  REAL :: ptop
  REAL :: dtinterval

  REAL, ALLOCATABLE :: ll_src(:,:),ll_tgt(:,:),lon(:),lat(:)
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: vardataij,vardataijll
  INTEGER, ALLOCATABLE, DIMENSION(:) :: levels

  REAL, ALLOCATABLE :: ak(:),bk(:),ps(:,:,:)

  REAL :: validrange(2)

  LOGICAL :: isfile

  INTEGER :: nxy,nlevs,nlevsi,nlon,nlat,nlat1,&
       &nll,nc,nt,nvars_core,nvars_tracer,nvars_in
  INTEGER :: i,j,k,iv
  INTEGER :: year,month,day,hour

  CHARACTER(len = date_string_length), ALLOCATABLE :: datestrings(:)
  TYPE(datetime_type), ALLOCATABLE :: validtimes(:)
  TYPE(timedelta_type) :: dt


  NAMELIST /record_input/ date,input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3_tracer,fname_fv3_core,fname_akbk
  NAMELIST /record_interp/ varlist_core,varlist_tracer,dlon,dlat
  NAMELIST /record_output/ output_dir,fname_ll

  varlist_core=""
  varlist_tracer=""

  INQUIRE(file='fv32ll.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='fv32ll.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     READ(98, record_interp)
     READ(98, record_output)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist fv32ll.nl'
     STOP(1)
  ENDIF

  nvars_core=COUNT(varlist_core /= "")
  nvars_tracer=COUNT(varlist_tracer /= "")
  nvars_in=nvars_core+nvars_tracer


  nlon=360./dlon
  IF (ABS(dlon*nlon - 360.) > small) THEN
     PRINT *,'adjust output grid resolution: dlon*nlon = ',dlon*nlon
     STOP(2)
  ENDIF

  nlat1=180./dlat
  IF (ABS(dlat*nlat1 - 180.) > small) THEN
     PRINT *,'adjust output grid resolution: dlat*nlat1 = ',dlat*nlat1
     STOP(3)
  ENDIF

  IF (MOD(nlat1,2) /= 0) THEN
     PRINT *,'adjust output grid: nlat1 is odd = ',nlat1
     STOP(4)
  ENDIF

  nlat=nlat1+1

  nll=nlon*nlat

  ALLOCATE(ll_tgt(nll,2),lon(nlon),lat(nlat))

  lon=[(((j-1)*dlon)-180.,j=1,nlon)]
  lat=[((i*dlat),i=-nlat/2,nlat/2)]

  ll_tgt(:,1)=[((i*dlat,i=-nlat1/2,nlat1/2),j=1,nlon)]*d2r
  ll_tgt(:,2)=[(((j-1)*dlon-180.,i=-nlat1/2,nlat1/2),j=1,nlon)]*d2r


  CALL filenames(input_grid_dir,fname_grid,gridfiles,&
       &input_fv3_dir,fname_fv3_tracer,fv3files_tracer)

  CALL read_fv3_grid(gridfiles,ll_src)

  CALL filenames(input_grid_dir,fname_grid,gridfiles,&
       &input_fv3_dir,fname_fv3_core,fv3files_core)

  akbkfile=TRIM(input_fv3_dir)//'/'//fname_akbk

  CALL read_fv3_akbk(akbkfile,ak,bk)

!  PRINT *,MINVAL(ak),MAXVAL(ak)
!  PRINT *,MINVAL(bk),MAXVAL(bk)

  nlevsi=SIZE(ak)

  varname='delp'
  
  CALL read_fv3_var(fv3files_core,varname,vardataij)

  nc=SIZE(vardataij,3)
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

  ALLOCATE(ps(SIZE(vardataij,1),SIZE(vardataij,3),&
       &SIZE(vardataij,4)))

  ptop=ak(1)

  ps=SUM(vardataij,dim=2)+ptop

!  PRINT *,MINVAL(ps),MAXVAL(ps)

  nlevs=nlevsi-1
  nxy=SIZE(vardataij,1)

  ALLOCATE(levels(nlevs))
  levels=[(i,i=1,nlevs)]

!fv3: fv_eta.F90
!< unit: pascal  

  ALLOCATE(varnames_in(nvars_in))
  varnames_in(:nvars_core)=varlist_core(:nvars_core)
  varnames_in(nvars_core+1:nvars_in)=varlist_tracer(:nvars_tracer)

  CALL slint_init(ll_src, nxy, ll_tgt, nll)

  llfile=TRIM(output_dir)//'/'//fname_ll

  CALL netcdf_write_generic_ll(.TRUE.,llfile,lon=lon,lat=lat,&
       &lev=levels, datestrings=datestrings)

  DEALLOCATE(vardataij)
  ALLOCATE(vardataij(SIZE(ps,1),SIZE(ps,2),nc,nt))
  vardataij(:,1,:,:)=ps

  ALLOCATE(vardataijll(nll,nlevs,nc,nt))

  CALL h_interp(vardataij,vardataijll)

  validrange=[25000.,110000.]

  CALL netcdf_write_generic_ll(.FALSE.,llfile,&
       &varname='ps',vardata=vardataijll(:,1:1,:,:),units="Pa",&
       &validrange=validrange)
  
  DO iv=1,nvars_in

     varname=varnames_in(iv)
     IF (iv <= nvars_core) THEN
        CALL read_fv3_var(fv3files_core,varname,vardataij)
     ELSE
        CALL read_fv3_var(fv3files_tracer,varname,vardataij)
     ENDIF
     CALL h_interp(vardataij,vardataijll)
     
     SELECT CASE(varname)
     CASE('bc1','bc2','oc1','oc2','sulf','so4',&
          &'dust1','dust2','dust3','dust4','dust5',&
          &'seas1','seas2','seas3','seas4','seas5')
        vardataijll=vardataijll*ug2kg
        units="kg kg-1"
        validrange=[0.,.1]
     CASE("T")
        units="K"
        validrange=[100.,400.]
     CASE("sphum")
        units="kg kg-1"
        validrange=[0.,0.1]
     CASE default
        units=""
     END SELECT

!     DO k=1,nlevs
!        PRINT *,MINVAL(vardataij(:,k,:,:)),MAXVAL(vardataij(:,k,:,:))
!        PRINT *,MINVAL(vardataijll(:,k,:,:)),MAXVAL(vardataijll(:,k,:,:))
!     ENDDO


     CALL netcdf_write_generic_ll(.FALSE.,llfile,&
          &varname=varnames_in(iv),vardata=vardataijll,units=units,&
          &validrange=validrange)

  ENDDO
  
  IF (ALLOCATED(vardataij)) DEALLOCATE(vardataij)
  IF (ALLOCATED(vardataijll)) DEALLOCATE(vardataijll)
  IF (ALLOCATED(ll_src)) DEALLOCATE(ll_src)
  IF (ALLOCATED(ll_tgt)) DEALLOCATE(ll_tgt)
  IF (ALLOCATED(ak)) DEALLOCATE(ak)
  IF (ALLOCATED(bk)) DEALLOCATE(bk)
  IF (ALLOCATED(lon)) DEALLOCATE(lon)  
  IF (ALLOCATED(lat)) DEALLOCATE(lat)  
  IF (ALLOCATED(levels)) DEALLOCATE(levels)  
  IF (ALLOCATED(validtimes)) DEALLOCATE(validtimes)
  IF (ALLOCATED(datestrings)) DEALLOCATE(datestrings)

END PROGRAM fv32ll
  
