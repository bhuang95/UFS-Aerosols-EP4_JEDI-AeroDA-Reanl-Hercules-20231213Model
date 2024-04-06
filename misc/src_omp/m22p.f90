PROGRAM m22p

!interpolate merra-2 to constant pressure levels
!aggregate dust and sea-salt bins to CAMS
!mzp june, 2020
  
  USE timedelta_mod
  USE datetime_mod
  
  USE module_constants
  USE module_netcdf_io
  USE module_interp
  USE module_gocart_cams
  USE module_m2gocart2cams
  USE module_utils
  USE module_m2


  IMPLICIT NONE

  CHARACTER(len=8) :: date

  CHARACTER(len=max_string_length) :: input_m2_dir,fname_m2,fname_akbk,&
       &output_dir,fname_pll
  CHARACTER(len=max_string_length) :: akbkfile,pllfile

  CHARACTER(len = max_varname_length) :: varlist_in(nvarmax),&
       &varlist_out(nvarmax)
  REAL :: plist(n_maxlevels)
  
  CHARACTER(len = max_varname_length) :: varname
  CHARACTER(len = max_varname_length), ALLOCATABLE :: varnames_in(:),&
       &varnames_out(:)

  CHARACTER(len = date_string_length), ALLOCATABLE :: datestrings(:)

  REAL, ALLOCATABLE :: plevels(:)
  REAL :: ptop
  REAL :: dtinterval

  REAL, ALLOCATABLE :: lon(:),lat(:)
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: vardataij,vardataijp

  REAL, ALLOCATABLE :: ps(:,:,:),pmid(:,:,:,:)
  REAL, ALLOCATABLE :: ak(:),bk(:)
  

  LOGICAL :: isfile

  INTEGER :: nlon,nlat,nlevs,nlevsi,nt,&
       &nplevs,nvars_in,nvars_out
  INTEGER :: i,j,k,iv
  INTEGER :: year,month,day,hour

  TYPE(datetime_type), ALLOCATABLE :: validtimes(:)
  TYPE(timedelta_type) :: dt

  NAMELIST /record_input/ date,input_m2_dir,fname_m2,fname_akbk
  NAMELIST /record_interp/ varlist_in,varlist_out,plist
  NAMELIST /record_output/ output_dir,fname_pll

  varlist_in=""
  varlist_out=""
  plist=0.

  INQUIRE(file='m22p.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='m22p.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     READ(98, record_interp)
     READ(98, record_output)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist m22p.nl'
     STOP(1)
  ENDIF

  nplevs=COUNT(plist > 0.)
  nvars_in=COUNT(varlist_in /= "")
  nvars_out=COUNT(varlist_out /= "")

  akbkfile=fname_akbk
  fname_m2=TRIM(input_m2_dir)//"/"//TRIM(fname_m2)

  CALL read_m2_akbk(akbkfile,ak,bk)

!  PRINT *,MINVAL(ak),MAXVAL(ak)
!  PRINT *,MINVAL(bk),MAXVAL(bk)

  ptop=ak(1)

  nlevsi=SIZE(ak)

  varname='PS'

  CALL read_m2_var(fname_m2,varname,vardataij)

  nlon=SIZE(vardataij,1)
  nlat=SIZE(vardataij,2)
  nt=SIZE(vardataij,3)
  ALLOCATE(datestrings(nt))

  READ(date(1:4),'(i4)')year
  READ(date(5:6),'(i2)')month
  READ(date(7:8),'(i2)')day
  hour=0

  ALLOCATE(validtimes(nt))

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

  ALLOCATE(ps(nlon,nlat,nt))

  ps=vardataij(:,:,:,1)

!  PRINT *,MINVAL(ps),MAXVAL(ps)


!vardataijp is temporarily interface pressure
  ALLOCATE(vardataijp(nlon,nlat,nlevsi,nt))

  DO k=1,nlevsi
     vardataijp(:,:,k,:)=ak(k)+ps(:,:,:)*bk(k)
!     PRINT *,MINVAL(vardataijp(:,:,k,:)),MAXVAL(vardataijp(:,:,k,:))
  ENDDO
 
  nlevs=nlevsi-1

  ALLOCATE(pmid(nlon,nlat,nlevs,nt))

!fv3: fv_eta.F90
!< unit: pascal  

  k=1
  IF (ptop > 1.E-8 ) THEN
     pmid(:,:,k,:) = (vardataijp(:,:,k+1,:) - vardataijp(:,:,k,:)) &
          &/ LOG(vardataijp(:,:,k+1,:)/vardataijp(:,:,k,:)) &
          &* 0.01 ! convert to m
  else
     pmid(:,:,k,:) = (vardataijp(:,:,k+1,:) - vardataijp(:,:,k,:)) &
          &* kap/kap1 * 0.01 ! convert to mb
  endif

!  PRINT *,'@@@1',k,MINVAL(pmid(:,:,k,:)),MAXVAL(pmid(:,:,k,:))


  DO k = 2, nlevsi-1
     pmid(:,:,k,:) = (vardataijp(:,:,k+1,:) - vardataijp(:,:,k,:)) &
          &/ LOG(vardataijp(:,:,k+1,:)/vardataijp(:,:,k,:)) &
          &* 0.01 ! convert to mb
!     PRINT *,'@@@1',k,MINVAL(pmid(:,:,k,:)),MAXVAL(pmid(:,:,k,:))
!     PRINT *,'@@@2',k,MINVAL(vardataijp(:,:,k,:)),&
!          &MAXVAL(vardataijp(:,:,k,:))
  ENDDO
  
!  k=nlevsi
!  PRINT *,'@@@2',k,MINVAL(vardataijp(:,:,k,:)),&
!       &MAXVAL(vardataijp(:,:,k,:))

!!phillips
!  DO k = 1, nlevsi-1
!     pmid(:,k,:,:)=(&
!          &(vardataijp(:,k,:,:)**kap1-vardataijp(:,k+1,:,:)**kap1)/&
!          &(kap1*(vardataijp(:,k,:,:)-vardataijp(:,k+1,:,:)))&
!          &)**kapr*0.01 ! convert to mb
!!     PRINT *,'@@@2',k,MINVAL(pmid(:,k,:,:)),MAXVAL(pmid(:,k,:,:))
!!     WRITE(102,*),k,MINVAL(pmid(:,k,:,:)),MAXVAL(pmid(:,k,:,:))
!  ENDDO

  DEALLOCATE(vardataijp)

  ALLOCATE(plevels(nplevs),varnames_in(nvars_in),varnames_out(nvars_out))
  plevels=plist(:nplevs)
  varnames_in=varlist_in(:nvars_in)
  varnames_out=varlist_out(:nvars_out)

  varname='lon'
  CALL read_m2_var(fname_m2,varname,vardataij)
  ALLOCATE(lon(nlon))
  lon=vardataij(:,1,1,1)

  varname='lat'
  CALL read_m2_var(fname_m2,varname,vardataij)
  ALLOCATE(lat(nlat))
  lat=vardataij(:,1,1,1)

  pllfile=TRIM(output_dir)//'/'//fname_pll

  CALL netcdf_write_generic_pll(.TRUE.,pllfile,lon=lon,lat=lat,&
       &plev=plevels, datestrings=datestrings)

  DO iv=1,nvars_out

     IF ( (INDEX(upper2lower(varnames_out(iv)),"du") > 0) ) THEN
        PRINT *,"Aggregate dust"
        CALL aggregate_m2gocart2cams(fname_m2,"dust",varnames_in,&
             &varnames_out(iv),vardataij)
        CALL p_interp_nx_ny(pmid,plevels,vardataij,vardataijp)
        CALL netcdf_write_generic_pll(.FALSE.,pllfile,&
             &varname=varnames_out(iv),vardata=vardataijp)
        CYCLE
     ELSEIF ( (INDEX(upper2lower(varnames_out(iv)),"seas") > 0) ) THEN
        PRINT *,"Aggregate seas"
        CALL aggregate_m2gocart2cams(fname_m2,"seas",varnames_in,&
             &varnames_out(iv),vardataij)
        CALL p_interp_nx_ny(pmid,plevels,vardataij,vardataijp)
        CALL netcdf_write_generic_pll(.FALSE.,pllfile,&
             &varname=varnames_out(iv),vardata=vardataijp)
        CYCLE
     ENDIF

     CALL translate_cams2m2gocart(varnames_out(iv),varname)

     CALL read_m2_var(fname_m2,varname,vardataij)
     CALL p_interp_nx_ny(pmid,plevels,vardataij,vardataijp)

!     DO k=1,nplevs
!        PRINT *,plevels(k),TRIM(varname),MINVAL(vardataij(:,:,k,:)),&
!             &MAXVAL(vardataij(:,:,k,:))
!     ENDDO
!     
!     DO k=1,nplevs
!        PRINT *,plevels(k),TRIM(varname),&
!             &MINVAL(vardataijp(:,:,k,:)),MAXVAL(vardataijp(:,:,k,:))
!     ENDDO

     CALL netcdf_write_generic_pll(.FALSE.,pllfile,&
          &varname=varnames_out(iv),vardata=vardataijp)

  ENDDO
  
  IF (ALLOCATED(vardataij)) DEALLOCATE(vardataij)
  IF (ALLOCATED(vardataijp)) DEALLOCATE(vardataijp)
  IF (ALLOCATED(plevels)) DEALLOCATE(plevels)
  IF (ALLOCATED(ak)) DEALLOCATE(ak)
  IF (ALLOCATED(bk)) DEALLOCATE(bk)
  IF (ALLOCATED(pmid)) DEALLOCATE(pmid)  
  IF (ALLOCATED(lon)) DEALLOCATE(lon)  
  IF (ALLOCATED(lat)) DEALLOCATE(lat)  

END PROGRAM m22p
  
