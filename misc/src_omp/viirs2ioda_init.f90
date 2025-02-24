!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! viirs2ioda_init
!! - contains initialization subroutines
!!     init      - reads in options from command line
!!
!! author: Cory Martin - cory.r.martin@noaa.gov
!! history: 2019-02-22 - original
! some changes MZP
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module viirs2ioda_init
  implicit none
contains
  subroutine init
    use viirs2ioda_vars, only: thinning, gridpath, infile, outfile,&
                               fv3_gridfiles,ntiles_fv3,validtimestr,&
                               validtime
    use datetime_mod
                
    implicit none
    !! initialize the software
    !! - mainly reads in options from command line
    integer :: nargs,iarg,itile
    character(len=200) :: arg1
    character(len=1) :: tile
    logical :: existin
    integer :: yyyy,mm,dd,hh
   
    INTEGER :: iargc

    IF (iargc() /= 4) THEN
       WRITE(*,*) "Not enough arguments"
       WRITE(*,*) "Requires valid cycle time, path to grid to be thinned,"
       WRITE(*,*) "and input and output files"
       STOP
    END IF
    
    CALL getarg(1,validtimestr)
    READ( validtimestr(1:4), '(i4)' )  yyyy
    READ( validtimestr(5:6), '(i2)' )  mm
    READ( validtimestr(7:8), '(i2)' )  dd
    READ( validtimestr(9:10), '(i2)' )  hh
    validtime = create_datetime(year=yyyy,month=mm,day=dd,hour=hh)

    CALL getarg(2,gridpath)

    DO itile=1,ntiles_fv3
       WRITE(tile,'(i1)') itile
       fv3_gridfiles(itile) = TRIM(gridpath)//"/"//"grid_spec.tile"//tile//".nc"
    END DO

    CALL getarg(3,infile)
    CALL getarg(4,outfile)    
    
    !! finally, let's ensure that infile exists
    inquire(file=infile,exist=existin)
    if (.not. existin) then
      write(*,*) "Input netCDF file does not exist. Abort!"
      stop
    end if

  end subroutine init

end module viirs2ioda_init 
