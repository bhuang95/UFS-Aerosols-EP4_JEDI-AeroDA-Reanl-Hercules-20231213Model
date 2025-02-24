PROGRAM fv3aod2obs

!interpolate aod to obs in ioda file
!mzp Jan 8, 2020

  USE module_constants
  USE module_fv3
  USE module_netcdf_io
  USE slint

  IMPLICIT NONE

  CHARACTER(len=max_string_length) :: input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3,input_obs_dir,fnamein_obs,&
       &output_obs_dir,fnameout_obs,fnameout
  CHARACTER(len=max_string_length), DIMENSION(ntiles) ::&
       &gridfiles,fv3files

  CHARACTER(len = max_varname_length) :: varname='aod'
  CHARACTER(len=max_string_length) :: obsfile

  REAL, ALLOCATABLE, DIMENSION(:,:) :: ll_src,ll_tgt
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: vardataij
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardata
  REAL, ALLOCATABLE, DIMENSION(:) :: aod,hofx

  LOGICAL :: isfile

  INTEGER :: nxy,nobs

  NAMELIST /record_input/input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3,input_obs_dir,fnamein_obs,&
       &output_obs_dir,fnameout_obs
  
  INQUIRE(file='fv3aod2obs.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='fv3aod2obs.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist gocart_aod_fv3_mpi.nl'
     STOP
  ENDIF

  CALL filenames(input_grid_dir,fname_grid,gridfiles,&
       &input_fv3_dir,fname_fv3,fv3files)

  CALL read_fv3_grid(gridfiles,ll_src)

  PRINT *,'ll_src(:,1) ',MINVAL(ll_src(:,1)),MAXVAL(ll_src(:,1))
  PRINT *,'ll_src(:,2) ',MINVAL(ll_src(:,2)),MAXVAL(ll_src(:,2))

  CALL read_fv3_var(fv3files,varname,vardataij)

  ALLOCATE(aod(SIZE(vardataij,1)))
  aod=vardataij(:,1,1,1)
  nxy=SIZE(aod)

  PRINT *,'aod ',MINVAL(aod),MAXVAL(aod)

  obsfile=TRIM(input_obs_dir)//'/'//TRIM(fnamein_obs)

  varname="latitude@MetaData"
  CALL netcdf_read(obsfile,varname,vardata)
  ALLOCATE(ll_tgt(SIZE(vardata,1),2))
  ll_tgt(:,1)=vardata(:,1,1,1,1)*d2r
  nobs=SIZE(vardata,1)

  varname="longitude@MetaData"
  CALL netcdf_read(obsfile,varname,vardata)
  ll_tgt(:,2)=vardata(:,1,1,1,1)*d2r

  PRINT *,'ll_tgt(:,1) ',MINVAL(ll_tgt(:,1)),MAXVAL(ll_tgt(:,1))
  PRINT *,'ll_tgt(:,2) ',MINVAL(ll_tgt(:,2)),MAXVAL(ll_tgt(:,2))

  CALL slint_init(ll_src, nxy, ll_tgt, nobs)

  ALLOCATE(hofx(nobs))

  CALL bilinear_interp(aod,hofx)

  PRINT *,'hofx ',MINVAL(hofx),MAXVAL(hofx)

  fnameout=TRIM(output_obs_dir)//'/'//trim(fnameout_obs)

  CALL netcdf_write_ioda_hofx(fnameout,hofx)

END PROGRAM fv3aod2obs
  
