!reworked from Sam at 
!/scratch2/BMC/wrfruc/Samuel.Trahan/perturb-smoke/no-ncl

PROGRAM convert_gbbepx
  USE module_util_gbbepx
  IMPLICIT NONE
  CHARACTER(len=500) :: pathlon, pathlat, pathebc, patheoc, pathepm25, &
       patheso2, patheco, patheplume, outfile
  CHARACTER(len=:), ALLOCATABLE :: toutfile
  CHARACTER(len=2000) :: title
  CHARACTER(len=21) :: time
  INTEGER :: nlat, nlon, iunit, tile
  INTEGER :: stderr
  INTEGER :: Open_Status,Read_Status
  INTEGER :: unit_namelist=101

  REAL, POINTER, DIMENSION(:) :: lat=>NULL(), lon=>NULL()
  REAL, POINTER, DIMENSION(:,:) :: ebc=>NULL(), eoc=>NULL(), &
       &epm25=>NULL(), eso2=>NULL(), eco=> NULL(), plume=>NULL()

  NAMELIST /record_input/ title, tile, time, nlon, nlat, outfile, &
       pathlon, pathlat, pathebc, patheoc, pathepm25, patheso2, &
       patheco, patheplume
  

  title='*'
  time='*'
  tile=-1
  nlat=-1
  nlon=-1
  pathlon='*'
  pathlat='*'
  pathebc='*'
  patheoc='*'
  pathepm25='*'
  patheso2='*'
  patheco='*'
  patheplume='*'
  outfile='*'

  stderr = 0

  OPEN(unit=unit_namelist, file = "convert_gbbepx.nl", &
       &status="old",action = "READ",iostat=open_status)
  IF (open_status /= 0) THEN
     WRITE(stderr,*) "error: missing NAMELIST file (convert_gbbepx.nl)"
     STOP
  END IF
  WRITE(stderr,*) 'Reading convert_gbbepx.nl record_input'
  READ (unit_namelist, NML=record_input, IOSTAT=Read_Status)
  CLOSE(unit_namelist)

  ALLOCATE(CHARACTER(len=LEN_TRIM(outfile)) :: toutfile)

  toutfile=TRIM(outfile)

  IF(nlat<1) CALL usage("nlat must be > 1")
  IF(nlon<1) CALL usage("nlon must be > 1")
  IF(pathlon=='*') CALL usage("You must specify pathlon")
  IF(pathlat=='*') CALL usage("You must specify pathlat")

  lat=>read1d(TRIM(pathlat),nlat)
  lon=>read1d(TRIM(pathlon),nlon)

  IF(pathebc/='*')   ebc=>read2d(TRIM(pathebc),nlat,nlon)
  IF(patheoc/='*')   eoc=>read2d(TRIM(patheoc),nlat,nlon)
  IF(pathepm25/='*') epm25=>read2d(TRIM(pathepm25),nlat,nlon)
  IF(patheso2/='*')  eso2=>read2d(TRIM(patheso2),nlat,nlon)
  IF(patheco/='*')  eco=>read2d(TRIM(patheco),nlat,nlon)
  IF(patheplume/='*') plume=>read2d(TRIM(patheplume),nlat,nlon)

  CALL write_netcdf(toutfile)

  PRINT '(A)','SUCCESS. Write NetCDF GBBEPx data to "'//toutfile//'"'

CONTAINS

  SUBROUTINE write_netcdf(outfile)
    USE netcdf
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(in) :: outfile
    INTEGER :: ncid, latdimid, londimid, attid
    INTEGER :: dims(2), varid(8)

    CALL check(toutfile//': open for write',nf90_create(toutfile,NF90_CLOBBER,ncid))

    CALL check(toutfile//': write time attribute',nf90_put_att(ncid,NF90_GLOBAL,'time',TRIM(time)))
    CALL check(toutfile//': write tile attribute',nf90_put_att(ncid,NF90_GLOBAL,'tile',tile))
    CALL check(toutfile//': write title attribute',nf90_put_att(ncid,NF90_GLOBAL,'title',TRIM(title)))

    CALL check(toutfile//': define lat dimension',nf90_def_dim(ncid,'lat',nlat,latdimid))
    CALL check(toutfile//': define lon dimension',nf90_def_dim(ncid,'lon',nlon,londimid))

    CALL check(toutfile//': define lat variable',nf90_def_var(ncid,'lat',NF90_FLOAT,latdimid,varid(1)))

    CALL check(toutfile//': define lon variable',nf90_def_var(ncid,'lon',NF90_FLOAT,londimid,varid(2)))

    dims=(/ londimid, latdimid /)

    IF(ASSOCIATED(ebc)) THEN
       CALL check(toutfile//': define ebu_bc variable',nf90_def_var(ncid,'ebu_bc',NF90_FLOAT,dims,varid(3)))
    ENDIF

    IF(ASSOCIATED(eoc)) THEN
       CALL check(toutfile//': define ebu_oc variable',nf90_def_var(ncid,'ebu_oc',NF90_FLOAT,dims,varid(4)))
    ENDIF

    IF(ASSOCIATED(epm25)) THEN
       CALL check(toutfile//': define ebu_pm_25 variable',nf90_def_var(ncid,'ebu_pm_25',NF90_FLOAT,dims,varid(5)))
    ENDIF

    IF(ASSOCIATED(eso2)) THEN
       CALL check(toutfile//': define ebu_so2 variable',nf90_def_var(ncid,'ebu_so2',NF90_FLOAT,dims,varid(6)))
    ENDIF

    IF(ASSOCIATED(eco)) THEN
       CALL check(toutfile//': define ebu_co variable',nf90_def_var(ncid,'ebu_co',NF90_FLOAT,dims,varid(7)))
    ENDIF


    IF(ASSOCIATED(plume)) THEN
       CALL check(toutfile//': define ebu_frp variable',nf90_def_var(ncid,'ebu_frp',NF90_FLOAT,dims,varid(8)))
    ENDIF

    CALL check(toutfile//': stop defining file',nf90_enddef(ncid))

    CALL check(toutfile//': write lat variable',nf90_put_var(ncid,varid(1),lat))
    CALL check(toutfile//': write lon variable',nf90_put_var(ncid,varid(2),lon))

    IF(ASSOCIATED(ebc)) THEN
       PRINT *,'ebu_bc max,min',MAXVAL(ebc),MINVAL(ebc)
       CALL check(toutfile//': write ebu_bc variable',nf90_put_var(ncid,varid(3),ebc,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(eoc)) THEN
       PRINT *,'ebu_oc max,min',MAXVAL(eoc),MINVAL(eoc)
       CALL check(toutfile//': write ebu_oc variable',nf90_put_var(ncid,varid(4),eoc,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(epm25)) THEN
       PRINT *,'ebu_pm_25 max,min',MAXVAL(epm25),MINVAL(epm25)
       CALL check(toutfile//': write ebu_pm_25 variable',nf90_put_var(ncid,varid(5),epm25,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(eso2)) THEN
       PRINT *,'ebu_so2 max,min',MAXVAL(eso2),MINVAL(eso2)
       CALL check(toutfile//': write ebu_so2 variable',nf90_put_var(ncid,varid(6),eso2,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(eco)) THEN
       PRINT *,'ebu_co max,min',MAXVAL(eco),MINVAL(eco)
       CALL check(toutfile//': write ebu_co variable',nf90_put_var(ncid,varid(7),eco,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(plume)) THEN
       PRINT *,'ebu_frp max,min',MAXVAL(plume),MINVAL(plume)
       CALL check(toutfile//': write ebu_frp variable',nf90_put_var(ncid,varid(8),plume,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    CALL check(toutfile//': close',nf90_close(ncid))
  END SUBROUTINE write_netcdf

END PROGRAM convert_gbbepx
