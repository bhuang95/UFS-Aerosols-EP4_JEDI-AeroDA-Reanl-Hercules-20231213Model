MODULE module_viirs2aeronet_args

  USE netcdf
  USE datetime_mod

  IMPLICIT NONE

  CHARACTER(len=NF90_MAX_NAME) :: infile,outfile
  CHARACTER(len=NF90_MAX_NAME) :: infile_aeronet

!namelist
  REAL :: tdiff_aeronet_max,tdiff_v2a_max,radius_pixel_output
  CHARACTER(len=10) :: satellite  
  INTEGER :: viirs_errors,seed

  CHARACTER(len=10) :: validtimestr
  TYPE(datetime_type) :: validtime

CONTAINS

  SUBROUTINE viirs2aeronet_args

    IMPLICIT NONE

    INTEGER :: nargs,iarg

    LOGICAL :: existin
    INTEGER :: yyyy,mm,dd,hh
   
    INTEGER :: iargc

    CONTINUE

    IF (iargc() < 4) THEN
       WRITE(*,*) "Too few arguments"
       WRITE(*,*) "Requires valid cycle time, path to grid to be     &
            &        thinned,"
       WRITE(*,*) "and input and output files"
       STOP
    ENDIF
    
    CALL getarg(1,validtimestr)
    READ( validtimestr(1:4), '(i4)' )  yyyy
    READ( validtimestr(5:6), '(i2)' )  mm
    READ( validtimestr(7:8), '(i2)' )  dd
    READ( validtimestr(9:10), '(i2)' )  hh
    validtime = create_datetime(year=yyyy,month=mm,day=dd,hour=hh)

    CALL getarg(2,infile_aeronet)

    INQUIRE(file=infile_aeronet,exist=existin)
    IF (.NOT. existin) THEN
       WRITE(*,*) TRIM(infile_aeronet)
       WRITE(*,*) "Inputfile does not exist. Abort!"
       STOP
    END IF
    
    CALL getarg(3,infile)

    INQUIRE(file=infile,exist=existin)
    IF (.NOT. existin) THEN
       WRITE(*,*) TRIM(infile)
       WRITE(*,*) "Inputfile does not exist. Abort!"
       STOP
    END IF

    CALL getarg(4,outfile)    
    CALL read_namelist
    
  END SUBROUTINE viirs2aeronet_args

  SUBROUTINE read_namelist

    REAL :: radius

    INTEGER :: unit_namelist=10,stderr=0,open_status,read_status
    CHARACTER(len=10) :: file_namelist="viirs2aeronet_common.nl"

    NAMELIST /common_params/ radius,tdiff_aeronet_max,tdiff_v2a_max,&
         &satellite,viirs_errors,seed

    viirs_errors=1
    seed=1

!viirs_errors=0 - bias=0, error=0
!viirs_errors=1 - bias,error using old bias and errors from 2019
!viirs_errors=2 - bias,error using new bias and errors from 2021

    OPEN(unit=unit_namelist, file = "viirs2aeronet_common.nl", &
         &status="old",action = "READ",iostat=open_status)
    IF (open_status /= 0) THEN
       WRITE(stderr,*) "error: namelist viirs2aeronet_common.nl missing"
       STOP
    END IF

    READ (unit_namelist, nml=common_params, iostat=read_status)
    CLOSE(unit_namelist)

    IF (read_status /= 0) THEN
       WRITE(stderr,*) 'Error reading viirs2aeronet_common.nl record common_params'
       STOP 1
    END IF

    radius_pixel_output=radius

  END SUBROUTINE read_namelist

END MODULE module_viirs2aeronet_args
