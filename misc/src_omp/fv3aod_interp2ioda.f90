PROGRAM fv3aod_interp2ioda

!interpolate fv3 aod to thinned viirs aod
!mzp jan 2024

  USE timedelta_mod
  USE datetime_mod

  USE module_constants
  USE module_fv3
  USE module_netcdf_io
  USE module_interp
  USE module_utils
  USE slint

  USE module_viirs2ioda, ONLY: read_viirsaod_clim,&
       &read_viirsaod_obs_thinned,write_iodav3_viirsaod_clim

  USE module_viirs_vars, ONLY: viirs_aod,&
       &inst,sat,retrieval_type,&
       &nchans,channels,viirs_wavelength,viirstimestr,&
       &viirs_aod_output,nobs_out


  IMPLICIT NONE

!optional for log interpolation - not used here for compatibility 
!with clim
  REAL, parameter :: logaod_offset=0.01

  CHARACTER(len=max_string_length) :: input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3,&
       &fname_viirs_aod_in,fname_viirs_aod_out

  CHARACTER(len=max_string_length), DIMENSION(ntiles) ::&
       &gridfiles,fv3files

  CHARACTER(len = max_varname_length) :: varname
  CHARACTER(len=10) :: date

  REAL, ALLOCATABLE :: ll_src(:,:),ll_tgt(:,:),lon(:),lat(:)
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: vardataij_in,vardataij_out
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardata

  REAL :: dtinterval

  INTEGER :: year,month,day,hour
  CHARACTER(len = date_string_length), ALLOCATABLE :: datestrings(:)
  TYPE(datetime_type), ALLOCATABLE :: validtimes(:)
  TYPE(timedelta_type) :: dt

  LOGICAL :: isfile

  INTEGER :: nxy,nlon,nlat,nlat1,nll,nt
  INTEGER :: i,j,k,iv

  NAMELIST /record_fv3_input/ date,input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3
  NAMELIST /record_viirs_inout/ fname_viirs_aod_in,fname_viirs_aod_out

  INQUIRE(file='fv3aod_interp2ioda.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='fv3aod_interp2ioda.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_fv3_input)
     READ(98, record_viirs_inout)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist fv3aod_interp2ioda.nl'
     STOP 1
  ENDIF

  CALL filenames(input_grid_dir,fname_grid,gridfiles,&
       &input_fv3_dir,fname_fv3,fv3files)

  CALL read_fv3_grid(gridfiles,ll_src)
  nxy=SIZE(ll_src,1)

  varname="channels"

  CALL netcdf_read(fv3files(1),varname,vardata)

  varname="aod"
  
  CALL read_fv3_var(fv3files,varname,vardataij_in)

  nt=SIZE(vardataij_in,4)

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

  CALL read_viirsaod_obs_thinned(fname_viirs_aod_in)

  nll=nobs_out

  ALLOCATE(ll_tgt(nll,2))
  ALLOCATE(vardataij_out(nll,SIZE(vardataij_in,2),&
       &SIZE(vardataij_in,3),SIZE(vardataij_in,4)))

  ll_tgt(:,1)=viirs_aod_output(:)%lat*d2r
  ll_tgt(:,2)=viirs_aod_output(:)%lon*d2r

  CALL slint_init(ll_src, nxy, ll_tgt, nll)

!optional log with offset
!  vardataij_in=LOG(vardataij_in+logaod_offset)

  CALL h_interp(vardataij_in,vardataij_out)

!optional log with offset
!  vardataij_out=EXP(vardataij_out)-logaod_offset

  viirs_aod_output(:)%value550=vardataij_out(:,1,1,1)

  CALL write_iodav3_viirsaod_clim(fname_viirs_aod_out)
  
  IF (ALLOCATED(vardataij_in)) DEALLOCATE(vardataij_in)
  IF (ALLOCATED(vardataij_out)) DEALLOCATE(vardataij_out)
  IF (ALLOCATED(ll_src)) DEALLOCATE(ll_src)
  IF (ALLOCATED(ll_tgt)) DEALLOCATE(ll_tgt)
  IF (ALLOCATED(viirs_aod_output)) DEALLOCATE(viirs_aod_output)

END PROGRAM fv3aod_interp2ioda
  
