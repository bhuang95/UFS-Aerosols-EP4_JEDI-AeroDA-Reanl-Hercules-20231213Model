!reworked from 
!from sam at 
!/scratch2/BMC/wrfruc/Samuel.Trahan/perturb-smoke/no-ncl
MODULE module_util_gbbepx
  IMPLICIT NONE
CONTAINS
  SUBROUTINE check(what,err)
    USE netcdf
    IMPLICIT NONE
    INTEGER, INTENT(in) :: err
    CHARACTER(len=*), INTENT(in) :: what
    IF(err/=0) THEN
       CALL abort(what//': '//nf90_strerror(err))
    ELSE
       PRINT '(A,A)',TRIM(what),': success'
    ENDIF
  END SUBROUTINE check

  FUNCTION read1d(file,n)
    IMPLICIT NONE
    REAL, DIMENSION(:), POINTER :: read1d
    INTEGER :: iunit,n,ios
    CHARACTER(len=*), INTENT(in) :: file

    ALLOCATE(read1d(n))

    OPEN(newunit=iunit,status='old',form='unformatted',file=TRIM(file),iostat=ios)
    IF(ios/=0) CALL abort(TRIM(file)//': cannot open for read')
    READ(iunit,iostat=ios) read1d
    IF(ios/=0) CALL abort(TRIM(file)//': cannot read')
    CLOSE(iunit)
  END FUNCTION read1d

  FUNCTION read2d(file,n,m)
    IMPLICIT NONE
    REAL, DIMENSION(:,:), POINTER :: read2d
    INTEGER :: iunit,n,m,ios
    CHARACTER(len=*), INTENT(in) :: file

    ALLOCATE(read2d(n,m))

    OPEN(newunit=iunit,status='old',form='unformatted',file=TRIM(file),iostat=ios)
    IF(ios/=0) CALL abort(TRIM(file)//': cannot open for read')
    READ(iunit,iostat=ios) read2d
    WRITE(0,*) MAXVAL(read2d),MINVAL(read2d)
    IF(ios/=0) CALL abort(TRIM(file)//': cannot read')
    CLOSE(iunit)
  END FUNCTION read2d

  SUBROUTINE abort(why)
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(in) :: why
    WRITE(0,'(A)') why
    STOP 1
  END SUBROUTINE abort

  SUBROUTINE usage(why)
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(in), OPTIONAL :: why
    WRITE(0,'(A)') 'Example of a correct namelist:'
    WRITE(0,'(A)') ' '
    WRITE(0,'(A)') '    &record_input'
    WRITE(0,'(A)') '      ! These eight are mandatory:'
    WRITE(0,'(A)') '      title="gbbepx emissions"'
    WRITE(0,'(A)') '      date="2020-08-31"'
    WRITE(0,'(A)') '      tile=1'
    WRITE(0,'(A)') '      nlat=96'
    WRITE(0,'(A)') '      nlon=96'
    WRITE(0,'(A)') '      outfile="/path/to/FIRE_GBBEPx_data.tile1.nc"'
    WRITE(0,'(A)') '      pathlat="/path/to/lat_tile1.dat"'
    WRITE(0,'(A)') '      pathlon="/path/to/lon_tile1.dat"'
    WRITE(0,'(A)') '      ! These five are optional:'
    WRITE(0,'(A)') '      pathebc="/path/to/GBBEPx.bc.20200831.FV3.C96Grid.tile1.bin"'
    WRITE(0,'(A)') '      pathepm25="/path/to/GBBEPx.pm25.20200831.FV3.C96Grid.tile1.bin"'
    WRITE(0,'(A)') '      patheso2="/path/to/GBBEPx.so2.20200831.FV3.C96Grid.tile1.bin"'
    WRITE(0,'(A)') '      patheco="/path/to/GBBEPx.co.20200831.FV3.C96Grid.tile1.bin"'
    WRITE(0,'(A)') '      patheoc="/path/to/GBBEPx.oc.20200831.FV3.C96Grid.tile1.bin"'
    WRITE(0,'(A)') '      patheplume="/path/to/meanFRP.20200831.FV3.C96Grid.tile1.bin"'
    WRITE(0,'(A)') '      ! If one is missing, its variable will not be written.'
    WRITE(0,'(A)') '    /'
    IF(PRESENT(why)) THEN
       WRITE(0,'(A,A)') 'ERROR. Program is aborting because: ',TRIM(why)
       WRITE(0,'(A)') 'See the example namelist above, and compare it to yours.'
    ENDIF
  END SUBROUTINE usage
END MODULE module_util_gbbepx

