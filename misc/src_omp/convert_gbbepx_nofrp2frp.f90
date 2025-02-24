!reworked from Sam at 
!/scratch2/BMC/wrfruc/Samuel.Trahan/perturb-smoke/no-ncl
!convert gbbepx without frp to gbbepx with frp using regression 
!derived for two sets of data in June-Aug 2016

PROGRAM convert_gbbepx_nofrp2frp
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

!from regression over 3 months for .995 ordered points
  REAL, PARAMETER :: fixfrp=2698.2e8
  REAL, PARAMETER :: &
!       &int_co=5.8e-11, slope_co=0.9,&
!       &int_oc=5.4e-12, slope_oc=0.9,&
!       &int_bc=3.1e-13, slope_bc=0.9,&
!       &int_pm25=7.7e-12, slope_pm25=0.9,&
!       &int_so2=5.5e-13, slope_so2=0.9
       &int_co=0., slope_co=0.9,&
       &int_oc=0., slope_oc=0.9,&
       &int_bc=0., slope_bc=0.9,&
       &int_pm25=0., slope_pm25=0.9,&
       &int_so2=0., slope_so2=0.9
!co: "coeffs = "            "5.80426386246971e-11" "0.869725881789441"
!so2: "coeffs = "            "5.53068520047958e-13" "0.89261217512051"
!oc: "coeffs = "            "5.40294830491767e-12" "0.882019014946997"
!bc: "coeffs = "            "3.08581371980567e-13" "0.930056883658845"
!pm_25: "coeffs = "            "7.74248279506606e-12" "0.894045189339218"


  REAL, PARAMETER :: small=1.e-16



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
       CALL check(toutfile//': define ebu_pm25 variable',nf90_def_var(ncid,'ebu_pm_25',NF90_FLOAT,dims,varid(5)))
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
       WHERE(ebc > small) ebc=int_bc+slope_bc*ebc
       PRINT *,'ebu_bc max,min',MAXVAL(ebc),MINVAL(ebc)
       CALL check(toutfile//': write ebu_bc variable',nf90_put_var(ncid,varid(3),ebc,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(eoc)) THEN
       WHERE(eoc > small) eoc=int_oc+slope_oc*eoc
       PRINT *,'ebu_oc max,min',MAXVAL(eoc),MINVAL(eoc)
       CALL check(toutfile//': write ebu_oc variable',nf90_put_var(ncid,varid(4),eoc,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(epm25)) THEN
       WHERE(epm25 > small) epm25=int_pm25+slope_pm25*epm25
       PRINT *,'ebu_pm25 max,min',MAXVAL(epm25),MINVAL(epm25)
       CALL check(toutfile//': write ebu_pm25 variable',nf90_put_var(ncid,varid(5),epm25,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(eso2)) THEN
       WHERE(eso2 > small) eso2=int_so2+slope_so2*eso2
       PRINT *,'ebu_so2 max,min',MAXVAL(eso2),MINVAL(eso2)
       CALL check(toutfile//': write ebu_so2 variable',nf90_put_var(ncid,varid(6),eso2,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(eco)) THEN
       WHERE(eco > small) eco=int_co+slope_co*eco
       PRINT *,'ebu_co max,min',MAXVAL(eco),MINVAL(eco)
       CALL check(toutfile//': write ebu_co variable',nf90_put_var(ncid,varid(7),eco,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    IF(ASSOCIATED(plume)) THEN
       plume=fixfrp*eco
       PRINT *,'ebu_frp max,min',MAXVAL(plume),MINVAL(plume)
       CALL check(toutfile//': write ebu_frp variable',nf90_put_var(ncid,varid(8),plume,(/1,1/),(/nlat,nlon/),(/1,1/)))
    ENDIF

    CALL check(toutfile//': close',nf90_close(ncid))
  END SUBROUTINE write_netcdf

END PROGRAM convert_gbbepx_nofrp2frp
