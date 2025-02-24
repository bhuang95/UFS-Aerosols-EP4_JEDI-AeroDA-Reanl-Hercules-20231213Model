PROGRAM fv3pm25

!calculate pm2.5 concentration from gocart species
!mzp march, 2023

  USE timedelta_mod
  USE datetime_mod

  USE module_constants
  USE module_fv3
  USE module_netcdf_io
  USE module_utils

  IMPLICIT NONE

  CHARACTER(len=max_string_length) :: &
       &input_fv3_dir,fname_fv3_tracer,fname_fv3_core,&
       &fname_fv3_sfc,fname_akbk,&
       &output_dir,fname_pm25

  CHARACTER(len = max_varname_length) :: varlist_in(nvarmax),&
       &varlist_out(nvarmax)
  INTEGER :: coeffs(nvarmax)
  
  CHARACTER(len = max_varname_length) :: varname
  CHARACTER(len = max_varname_length), ALLOCATABLE :: varnames_in(:),&
       &varnames_out(:)

  CHARACTER(len=10) :: date

  REAL :: ptop
  REAL :: dtinterval

  REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardata
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: pm25

  REAL, ALLOCATABLE :: ak(:),bk(:),ps(:,:,:),t2m(:,:,:),q2m(:,:,:)

  LOGICAL :: isfile

  INTEGER :: nlevs,nlevsi,nvars_in,nvars_out,nt
  INTEGER :: i,j,k,iv
  INTEGER :: year,month,day,hour

  CHARACTER(len = date_string_length), ALLOCATABLE :: datestrings(:)
  TYPE(datetime_type), ALLOCATABLE :: validtimes(:)
  TYPE(timedelta_type) :: dt

  NAMELIST /record_input/ date,input_fv3_dir,&
       &fname_fv3_tracer,fname_fv3_core,fname_fv3_sfc,fname_akbk
  NAMELIST /record_vars/ varlist_in,coeffs,varlist_out
  NAMELIST /record_output/ output_dir,fname_pm25

  varlist_in=""
  varlist_out=""

  INQUIRE(file='fv3pm25.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='fv3pm25.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     READ(98, record_vars)
     READ(98, record_output)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist fv3pm25.nl'
     STOP(1)
  ENDIF

!  PRINT *,TRIM(input_fv3_dir),TRIM(fname_fv3_tracer)
!  PRINT *,TRIM(input_fv3_dir),TRIM(fname_fv3_core)
!  PRINT *,TRIM(input_fv3_dir),TRIM(fname_fv3_sfc)
!  PRINT *,varlist_in
!  PRINT *,coeffs
!  PRINT *,varlist_out
!  PRINT *,TRIM(output_dir)
!  PRINT *,TRIM(fname_pm25)  

  nvars_in=COUNT(varlist_in /= "")
  nvars_out=COUNT(varlist_out /= "")

  varnames_in=varlist_in(:nvars_in)
  varnames_out=varlist_out(:nvars_out)

  fname_akbk=TRIM(input_fv3_dir)//'/'//fname_akbk

  CALL read_fv3_akbk(fname_akbk,ak,bk)

  nlevsi=SIZE(ak)

  varname='delp'

  fname_fv3_core=TRIM(input_fv3_dir)//'/'//fname_fv3_core

  CALL netcdf_read(fname_fv3_core,varname,vardata)

  nt=SIZE(vardata,4)

  READ(date(1:4),'(i4)')year
  READ(date(5:6),'(i2)')month
  READ(date(7:8),'(i2)')day
  READ(date(9:10),'(i2)')hour

  ALLOCATE(validtimes(nt),datestrings(nt))

  validtimes(1)=create_datetime(year=year,month=month,day=day,hour=hour)

  datestrings(1)=validtimes(1)%isoformat()

  IF (nt > 1) THEN
     dtinterval=24./nt
     dt=timedelta(hours=dtinterval)
     DO i=2,nt
        validtimes(i)=validtimes(i-1)+dt
        datestrings(i)=validtimes(i)%isoformat()
     ENDDO
  ENDIF

  ALLOCATE(ps(SIZE(vardata,1),SIZE(vardata,3),&
       &SIZE(vardata,4)))

  ptop=ak(1)

  ps=SUM(vardata(:,:,:,:,1),dim=3)+ptop

  nlevs=nlevsi-1

  fname_fv3_sfc=TRIM(input_fv3_dir)//'/'//fname_fv3_sfc

  ALLOCATE(t2m(SIZE(vardata,1),SIZE(vardata,2),&
       &SIZE(vardata,4)))
  ALLOCATE(q2m(SIZE(vardata,1),SIZE(vardata,2),&
       &SIZE(vardata,4)))
  
  varname='t2m'
  CALL netcdf_read(fname_fv3_sfc,varname,vardata)
  t2m=vardata(:,:,1,:,1)

  varname='q2m'
  CALL netcdf_read(fname_fv3_sfc,varname,vardata)
  q2m=vardata(:,:,1,:,1)

  ALLOCATE(pm25(SIZE(vardata,1),SIZE(vardata,2),1,SIZE(vardata,4)))

  fname_fv3_tracer=TRIM(input_fv3_dir)//'/'//fname_fv3_tracer

  pm25=0.
  DO iv=1,nvars_in
     CALL netcdf_read(fname_fv3_tracer,varnames_in(iv),vardata)
     pm25=vardata(:,:,nlevs:nlevs,:,1)*coeffs(iv)+pm25
  ENDDO

  pm25(:,:,1,:)=pm25(:,:,1,:)*ps/(rd*t2m*(1.+rd_rv*q2m))

  fname_pm25=TRIM(output_dir)//'/'//fname_pm25

  varname=varnames_out(1)
  CALL netcdf_write_fv3_concentration(fname_pm25,pm25,varname)

  IF (ALLOCATED(vardata)) DEALLOCATE(vardata)
  IF (ALLOCATED(pm25)) DEALLOCATE(pm25)
  IF (ALLOCATED(ak)) DEALLOCATE(ak)
  IF (ALLOCATED(bk)) DEALLOCATE(bk)
  IF (ALLOCATED(validtimes)) DEALLOCATE(validtimes)
  IF (ALLOCATED(datestrings)) DEALLOCATE(datestrings)

END PROGRAM fv3pm25
  
