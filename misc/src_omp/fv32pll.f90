PROGRAM fv32pll

!interpolate fv3 to constant pressure levels and latlon grid
!aggregate dust and sea-salt bins to CAMS
!mzp march, 2020

  USE timedelta_mod
  USE datetime_mod

  USE module_constants
  USE module_fv3
  USE module_netcdf_io
  USE module_interp
  USE module_gocart_cams
  USE module_fv3gocart2cams
  USE module_utils
  USE slint


  IMPLICIT NONE

  CHARACTER(len=max_string_length) :: input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3_tracer,fname_fv3_core,fname_akbk,&
       &output_dir,fname_pll
  CHARACTER(len=max_string_length), DIMENSION(ntiles) ::&
       &gridfiles,fv3files_tracer,fv3files_core
  CHARACTER(len=max_string_length) :: akbkfile,pllfile

  CHARACTER(len = max_varname_length) :: varlist_in(nvarmax),&
       &varlist_out(nvarmax)
  REAL :: plist(n_maxlevels),dlon,dlat
  
  CHARACTER(len = max_varname_length) :: varname
  CHARACTER(len = max_varname_length), ALLOCATABLE :: varnames_in(:),&
       &varnames_out(:)

  CHARACTER(len=10) :: date


  REAL, ALLOCATABLE :: plevels(:)
  REAL :: ptop
  REAL :: dtinterval

  REAL, ALLOCATABLE :: ll_src(:,:),ll_tgt(:,:),lon(:),lat(:)
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: vardataij,vardataijp,&
       &vardataijpll

  REAL, ALLOCATABLE :: ak(:),bk(:),ps(:,:,:),pmid(:,:,:,:)

  LOGICAL :: isfile

  INTEGER :: nxy,nlevs,nlevsi,nlon,nlat,nlat1,&
       &nll,nt,nplevs,nvars_in,nvars_out
  INTEGER :: i,j,k,iv
  INTEGER :: year,month,day,hour

  CHARACTER(len = date_string_length), ALLOCATABLE :: datestrings(:)
  TYPE(datetime_type), ALLOCATABLE :: validtimes(:)
  TYPE(timedelta_type) :: dt


  NAMELIST /record_input/ date,input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3_tracer,fname_fv3_core,fname_akbk
  NAMELIST /record_interp/ varlist_in,varlist_out,plist,dlon,dlat
  NAMELIST /record_output/ output_dir,fname_pll

  varlist_in=""
  varlist_out=""
  plist=0.

  INQUIRE(file='fv32pll.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='fv32pll.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     READ(98, record_interp)
     READ(98, record_output)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist fv32pll.nl'
     STOP(1)
  ENDIF

!  PRINT *,TRIM(input_fv3_dir),TRIM(fname_fv3_tracer)
!  PRINT *,TRIM(input_fv3_dir),TRIM(fname_fv3_core)
!  PRINT *,varlist_in
!  PRINT *,varlist_out
!  PRINT *,plist
!  PRINT *,dlon,dlat
!  PRINT *,TRIM(output_dir)
!  PRINT *,TRIM(fname_pll)  

  nplevs=COUNT(plist > 0.)
  nvars_in=COUNT(varlist_in /= "")
  nvars_out=COUNT(varlist_out /= "")

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
       &input_fv3_dir,fname_fv3_tracer,fv3files_tracer)

  CALL read_fv3_grid(gridfiles,ll_src)

!  PRINT *,'ll_src(:,1) ',MINVAL(ll_src(:,1)),MAXVAL(ll_src(:,1))
!  PRINT *,'ll_src(:,2) ',MINVAL(ll_src(:,2)),MAXVAL(ll_src(:,2))
!

  CALL filenames(input_grid_dir,fname_grid,gridfiles,&
       &input_fv3_dir,fname_fv3_core,fv3files_core)

  akbkfile=TRIM(input_fv3_dir)//'/'//fname_akbk

  CALL read_fv3_akbk(akbkfile,ak,bk)

!  PRINT *,MINVAL(ak),MAXVAL(ak)
!  PRINT *,MINVAL(bk),MAXVAL(bk)

  nlevsi=SIZE(ak)

  varname='delp'
  
  CALL read_fv3_var(fv3files_core,varname,vardataij)

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

!vardataijp is temporarily interface pressure
  ALLOCATE(vardataijp(SIZE(vardataij,1),SIZE(vardataij,2)+1,&
       &SIZE(vardataij,3), SIZE(vardataij,4)))

  DO k=1,nlevsi
     vardataijp(:,k,:,:)=ak(k)+ps(:,:,:)*bk(k)
!     PRINT *,MINVAL(vardataijp(:,k,:,:)),MAXVAL(vardataijp(:,k,:,:))
  ENDDO

  DEALLOCATE(ps)

  nlevs=nlevsi-1
  nxy=SIZE(vardataij,1)

  ALLOCATE(pmid(SIZE(vardataij,1),SIZE(vardataij,2),SIZE(vardataij,3),&
       &SIZE(vardataij,4)))


!fv3: fv_eta.F90
!< unit: pascal  

  k=1
  IF (ptop > 1.E-8 ) THEN
     pmid(:,k,:,:) = (vardataijp(:,k+1,:,:) - vardataijp(:,k,:,:)) &
          &/ LOG(vardataijp(:,k+1,:,:)/vardataijp(:,k,:,:)) &
          &* 0.01 ! convert to m
  else
     pmid(:,k,:,:) = (vardataijp(:,k+1,:,:) - vardataijp(:,k,:,:)) &
          &* kap/kap1 * 0.01 ! convert to mb
  endif


!  PRINT *,'@@@1',k,MINVAL(pmid(:,k,:,:)),MAXVAL(pmid(:,k,:,:))
!  WRITE(101,*),k,MINVAL(pmid(:,k,:,:)),MAXVAL(pmid(:,k,:,:))

  DO k = 2, nlevsi-1
     pmid(:,k,:,:) = (vardataijp(:,k+1,:,:) - vardataijp(:,k,:,:)) &
          &/ LOG(vardataijp(:,k+1,:,:)/vardataijp(:,k,:,:)) &
          &* 0.01 ! convert to mb
!     PRINT *,'@@@1',k,MINVAL(pmid(:,k,:,:)),MAXVAL(pmid(:,k,:,:))
!     PRINT *,'@@@2',k,MINVAL(vardataijp(:,k,:,:)),&
!          &MINVAL(vardataijp(:,k,:,:))
!     PRINT *,'@@@3',k,MINVAL(vardataijp(:,k+1,:,:)),&
!          &MINVAL(vardataijp(:,k,:,:))
  ENDDO


!!phillips
!  DO k = 1, nlevsi-1
!     pmid(:,k,:,:)=(&
!          &(vardataijp(:,k,:,:)**kap1-vardataijp(:,k+1,:,:)**kap1)/&
!          &(kap1*(vardataijp(:,k,:,:)-vardataijp(:,k+1,:,:)))&
!          &)**kapr*0.01 ! convert to mb
!!     PRINT *,'@@@2',k,MINVAL(pmid(:,k,:,:)),MAXVAL(pmid(:,k,:,:))
!!     WRITE(102,*),k,MINVAL(pmid(:,k,:,:)),MAXVAL(pmid(:,k,:,:))
!  ENDDO

  DEALLOCATE(vardataijp,vardataij)

  ALLOCATE(plevels(nplevs),varnames_in(nvars_in),varnames_out(nvars_out))
  plevels=plist(:nplevs)
  varnames_in=varlist_in(:nvars_in)
  varnames_out=varlist_out(:nvars_out)

  CALL slint_init(ll_src, nxy, ll_tgt, nll)

  ALLOCATE(vardataijpll(nll,nplevs,SIZE(pmid,3),SIZE(pmid,4)))

  pllfile=TRIM(output_dir)//'/'//fname_pll

  CALL netcdf_write_generic_pll(.TRUE.,pllfile,lon=lon,lat=lat,&
       &plev=plevels, datestrings=datestrings)

  DO iv=1,nvars_out

     IF ( (INDEX(upper2lower(varnames_out(iv)),"dust") > 0) ) THEN
        PRINT *,"Aggregate dust"
        CALL aggregate_fv3gocart2cams(fv3files_tracer,"dust",varnames_in,&
             &varnames_out(iv),vardataij)
        CALL p_interp_nxy(pmid,plevels,vardataij,vardataijp)
        CALL h_interp(vardataijp,vardataijpll)
        vardataijpll=vardataijpll*ug2kg
        CALL netcdf_write_generic_pll(.FALSE.,pllfile,&
             &varname=varnames_out(iv),vardata=vardataijpll)
        CYCLE
     ELSEIF ( (INDEX(upper2lower(varnames_out(iv)),"seas") > 0) ) THEN
        PRINT *,"Aggregate seas"
        CALL aggregate_fv3gocart2cams(fv3files_tracer,"seas",varnames_in,&
             &varnames_out(iv),vardataij)
        CALL p_interp_nxy(pmid,plevels,vardataij,vardataijp)
        CALL h_interp(vardataijp,vardataijpll)
        vardataijpll=vardataijpll*ug2kg
        CALL netcdf_write_generic_pll(.FALSE.,pllfile,&
             &varname=varnames_out(iv),vardata=vardataijpll)
        CYCLE
     ENDIF

     CALL translate_aero_names(varnames_out(iv),varname)
!     CALL translate_cams2fv3gocart(varnames_out(iv),varname)

     CALL read_fv3_var(fv3files_tracer,varname,vardataij)
     CALL p_interp_nxy(pmid,plevels,vardataij,vardataijp)

!     DO k=1,nplevs
!        PRINT *,plevels(k),TRIM(varname),MINVAL(vardataijp(:,k,:,:)),&
!             &MAXVAL(vardataijp(:,k,:,:))
!     ENDDO
     
     CALL h_interp(vardataijp,vardataijpll)
     vardataijpll=vardataijpll*ug2kg


!     DO k=1,nplevs
!        PRINT *,plevels(k),TRIM(varname),&
!             &MINVAL(vardataijpll(:,k,:,:)),MAXVAL(vardataijpll(:,k,:,:))
!     ENDDO

     CALL netcdf_write_generic_pll(.FALSE.,pllfile,&
          &varname=varnames_out(iv),vardata=vardataijpll)

     

  ENDDO
  
  IF (ALLOCATED(vardataij)) DEALLOCATE(vardataij)
  IF (ALLOCATED(vardataijp)) DEALLOCATE(vardataijp)
  IF (ALLOCATED(vardataijpll)) DEALLOCATE(vardataijpll)
  IF (ALLOCATED(plevels)) DEALLOCATE(plevels)
  IF (ALLOCATED(ll_src)) DEALLOCATE(ll_src)
  IF (ALLOCATED(ll_tgt)) DEALLOCATE(ll_tgt)
  IF (ALLOCATED(ak)) DEALLOCATE(ak)
  IF (ALLOCATED(bk)) DEALLOCATE(bk)
  IF (ALLOCATED(pmid)) DEALLOCATE(pmid)  
  IF (ALLOCATED(lon)) DEALLOCATE(lon)  
  IF (ALLOCATED(lat)) DEALLOCATE(lat)  
  IF (ALLOCATED(validtimes)) DEALLOCATE(validtimes)
  IF (ALLOCATED(datestrings)) DEALLOCATE(datestrings)

END PROGRAM fv32pll
  
