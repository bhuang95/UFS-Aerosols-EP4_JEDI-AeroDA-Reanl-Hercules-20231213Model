!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! viirs2ioda
!!  - utility to convert VIIRS AOD netCDF files provided by NOAA
!!    and output them to a format readable by IODA
!!
!! author: Cory Martin - cory.r.martin@noaa.gov
!! history: 2019-02-22 - original
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
PROGRAM viirs2ioda_lunar
  use viirs2ioda_init, only: init
  use viirs2ioda_nc, only: read_viirsaod_lunar_nc, write_iodaaod_nc
  use viirs2ioda_thin, only: thin_fv3, in2out
  use viirs2ioda_vars, only: gridpath
  !! top level driver program, calls all subroutines from other modules
  implicit none
  call init ! read in command line arguments
  call read_viirsaod_lunar_nc ! read the input file
  ! TODO thinning, going from 2D to 1D, etc.
  if (trim(gridpath) /= 'none') then
    call thin_fv3
  else
    call in2out ! just reformat 
  end if

  call write_iodaaod_nc ! write out the obs file

END PROGRAM viirs2ioda_lunar
