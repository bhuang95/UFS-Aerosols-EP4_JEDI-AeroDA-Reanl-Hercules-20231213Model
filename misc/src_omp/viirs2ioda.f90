PROGRAM viir2ioda

!Thins viirs AOD from NESDIS 
!and writes in IODA v3 format

  USE module_constants, ONLY: pi, d2r, r_earth, imissing,&
       &max_string_length

  USE module_viirs2aeronet_args, ONLY: infile,&
         &validtimestr,validtime,viirs_errors

  USE module_viirs2ioda, ONLY: read_viirsaod,write_iodav3_viirsaod

  USE module_viirs_vars, ONLY: viirs_aod,&
       &inst,sat,retrieval_type,&
       &nchans,channels,viirs_wavelength,viirstimestr,&
       &viirs_aod_input,viirs_aod_output,nobs_in,nobs_out

  USE module_fv3, ONLY: ntiles,filenames,read_fv3_grid

  USE module_generic_thinning, ONLY: thinning_sphere_nn,thinning_sphere

  IMPLICIT NONE

  CHARACTER(len=max_string_length) :: infile_obs,outfile

  CHARACTER(len=max_string_length) :: input_grid_dir,&
       &input_fv3_dir,fname_fv3

  CHARACTER(len=max_string_length) :: fname_grid="grid_spec.tile?.nc"

  CHARACTER(len=max_string_length), DIMENSION(ntiles) ::&
       &gridfiles,fv3files

  INTEGER :: iargc
  INTEGER :: i,j,k,nx,nxy
!numbers of nearest neighbors - can vary like in code viirs2aeronet.f90
!for averaging but here set to 1 only
  INTEGER :: num_nn=1 
  REAL, PARAMETER :: thinning_grid_ratio_max=1.5

  REAL :: dphi_max

  REAL, ALLOCATABLE :: grid1(:,:),grid2(:,:)
  INTEGER, ALLOCATABLE :: viirs_index_nn(:,:),viirs_index(:)

  CONTINUE

  IF (iargc() /= 4) THEN
     WRITE(*,*) "Too few arguments"
     WRITE(*,*) "Requires valid cycle time, obs file, "
     WRITE(*,*) "path to grid to be thinned,"
     WRITE(*,*) "and output file"
     STOP 1
  END IF

  CALL getarg(1,validtimestr)
  CALL getarg(2,input_grid_dir)
  CALL getarg(3,infile_obs)
  CALL getarg(4,outfile)
  
  infile=infile_obs

!assume errors like from 2019 - see module_viirs2ioda/read_viirsaod
  viirs_errors=1 

  CALL read_viirsaod

  ALLOCATE(viirs_aod_input(nobs_in),grid1(nobs_in,2))
  viirs_aod_input=viirs_aod_output
  grid1(:,1)=viirs_aod_input(:)%lat*d2r
  grid1(:,2)=viirs_aod_input(:)%lon*d2r
  DEALLOCATE(viirs_aod_output)

  CALL filenames(input_grid_dir,fname_grid,gridfiles,&
       &input_fv3_dir,fname_fv3,fv3files)

  CALL read_fv3_grid(gridfiles,grid2)

  nxy = SIZE(grid2,1)
  nx=SQRT(REAL(nxy)/REAL(ntiles))

  num_nn=1
  
  dphi_max=2.*pi/(4.*REAL(nx))*thinning_grid_ratio_max

  CALL thinning_sphere(grid1,grid2,nobs_in,dphi_max,viirs_index)
!  CALL thinning_sphere_nn(grid1,grid2,dphi_max,num_nn,viirs_index_nn)

  nobs_out=SIZE(viirs_index)

  IF (nobs_out > 0) THEN

     ALLOCATE(viirs_aod_output(nobs_out))

     k=0
     DO i=1,nobs_out
        k=k+1
        j=viirs_index(i)
        viirs_aod_output(k)%lat=viirs_aod_input(j)%lat
        viirs_aod_output(k)%lon=viirs_aod_input(j)%lon
        viirs_aod_output(k)%value550=&
             &viirs_aod_input(j)%value550
        viirs_aod_output(k)%stype=viirs_aod_input(j)%stype
        viirs_aod_output(k)%bias=viirs_aod_input(j)%bias
        viirs_aod_output(k)%uncertainty=viirs_aod_input(j)%uncertainty
        PRINT *,viirs_aod_output(k)%uncertainty
        viirs_aod_output(k)%qcall=viirs_aod_input(j)%qcall
     ENDDO

  ENDIF

  PRINT *,'There are',nobs_out,' valid observations'

  CALL write_iodav3_viirsaod(outfile)

  DEALLOCATE(viirs_aod_output)

END PROGRAM viir2ioda
