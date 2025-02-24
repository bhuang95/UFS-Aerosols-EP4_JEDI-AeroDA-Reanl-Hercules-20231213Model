PROGRAM viirsaod_clim2ioda

!writes gridded VIIRS climatology in IODA format

  USE module_constants, ONLY: pi, d2r,imissing

  USE module_viirs2ioda, ONLY: read_viirsaod_clim,&
       &write_iodav3_viirsaod_clim

  USE module_viirs_vars, ONLY: inst,sat,retrieval_type,&
       &nchans,channels,viirs_wavelength,viirstdiff,viirstimestr,&
       &viirs_aod_input,nobs_in
  
  IMPLICIT NONE

  CHARACTER(len=800) :: infile,outfile

  INTEGER :: iargc

  CONTINUE

  IF (iargc() < 2) THEN
     WRITE(*,*) "Too few arguments"
     WRITE(*,*) "Requires and input and output filenames"
     STOP 1
  ENDIF
  
  CALL getarg(1,infile)
  CALL getarg(2,outfile)
  
  CALL read_viirsaod_clim(infile)

  CALL write_iodav3_viirsaod_clim(outfile)

END PROGRAM viirsaod_clim2ioda
