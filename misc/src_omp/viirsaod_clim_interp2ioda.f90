PROGRAM viirsaod_clim_interp2ioda

!Interpolates climatology (monthly or daily) 
!to thinned gridded VIIRS (in IODA format)
!and writes in IODA format

  USE module_constants, ONLY: pi, d2r, r_earth, imissing

  USE module_viirs2ioda, ONLY: read_viirsaod_clim,&
       &read_viirsaod_obs_thinned,write_iodav3_viirsaod_clim

  USE module_viirs_vars, ONLY: viirs_aod,&
       &inst,sat,retrieval_type,&
       &nchans,channels,viirs_wavelength,viirstimestr,&
       &viirs_aod_input,viirs_aod_output,nobs_in,nobs_out

  USE module_generic_thinning, ONLY: thinning_sphere_nn
  
  IMPLICIT NONE

  TYPE(viirs_aod), ALLOCATABLE, DIMENSION(:) :: clim_aod_output

  REAL, PARAMETER :: max_search_radius=25.,&
       &dphi_max=max_search_radius/(2.*pi*r_earth)
!max_search_radius=25km for 0.25 degree VIIRS clim grid

  INTEGER, PARAMETER :: num_nn=1
!number of nearest neighbors always = 1

  CHARACTER(len=800) :: infile_clim,infile_obs,outfile

  INTEGER :: iargc,nobs_valid
  INTEGER :: i,j

  REAL, ALLOCATABLE :: grid1(:,:),grid2(:,:)
  INTEGER, ALLOCATABLE :: viirs_index(:,:)

  CONTINUE

  IF (iargc() < 3) THEN
     WRITE(*,*) "Too few arguments"
     WRITE(*,*) "Requires and input for gridded VIIRS climatology"
     WRITE(*,*) "input for thinned VIIRS obs and output filename"
     STOP 1
  ENDIF
  
  CALL getarg(1,infile_clim)
  CALL getarg(2,infile_obs)
  CALL getarg(3,outfile)
  
  CALL read_viirsaod_clim(infile_clim)

  nobs_in=nobs_out

  ALLOCATE(viirs_aod_input(nobs_in),grid1(nobs_in,2))
  viirs_aod_input=viirs_aod_output
  grid1(:,1)=viirs_aod_input(:)%lat*d2r
  grid1(:,2)=viirs_aod_input(:)%lon*d2r
  DEALLOCATE(viirs_aod_output)

  CALL read_viirsaod_obs_thinned(infile_obs)

  ALLOCATE(grid2(nobs_out,2))

  grid2(:,1)=viirs_aod_output(:)%lat*d2r
  grid2(:,2)=viirs_aod_output(:)%lon*d2r

  CALL thinning_sphere_nn(grid1,grid2,dphi_max,num_nn,viirs_index)

  nobs_valid=COUNT(viirs_index(:,1) /= imissing)

  IF (nobs_valid > 0) THEN

     ALLOCATE(clim_aod_output(nobs_valid))

     j=0

     DO i=1,nobs_out
        IF (viirs_index(i,1) == imissing) CYCLE
        j=j+1
        clim_aod_output(j)%lat=viirs_aod_output(i)%lat
        clim_aod_output(j)%lon=viirs_aod_output(i)%lon
        clim_aod_output(j)%value550=&
             &viirs_aod_input(viirs_index(i,1))%value550
        clim_aod_output(j)%stype=viirs_aod_output(i)%stype
     ENDDO

  ENDIF

  DEALLOCATE(viirs_aod_input,viirs_aod_output)

  nobs_out=nobs_valid

  PRINT *,'Interpolated climatology for ',nobs_out,' observations'

  ALLOCATE(viirs_aod_output(nobs_out))

  viirs_aod_output=clim_aod_output
  
  DEALLOCATE(clim_aod_output)

  CALL write_iodav3_viirsaod_clim(outfile)

  DEALLOCATE(viirs_aod_output)

END PROGRAM viirsaod_clim_interp2ioda
