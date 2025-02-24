PROGRAM fv32improve

!interpolate fv3 in space and time and calculate daily average
!for comparion with IMPROVE data
!mzp May 2023

  USE iso_fortran_env

  USE timedelta_mod
  USE datetime_mod

  USE module_constants
  use module_improve
  USE module_fv3
  USE module_netcdf_io
  USE module_interp
  USE module_utils
  USE slint


  IMPLICIT NONE

  CHARACTER(len=max_string_length) :: input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3_aeros,&
       &input_improve_dir,fname_improve,&
       &output_dir,fname_fv32improve,&
       &fname
  CHARACTER(len=max_string_length), DIMENSION(ntiles) ::&
       &gridfiles,fv3files_aeros

  CHARACTER(len = max_varname_length) :: varlist_aeros(nvarmax)

  TYPE(improve), ALLOCATABLE, DIMENSION(:) :: improve_record

  CHARACTER(len = max_varname_length) :: varname
  CHARACTER(len = max_varname_length), ALLOCATABLE :: varnames_aeros(:)
  CHARACTER(len=10) :: date,datemin,datemax
  CHARACTER(len=10), ALLOCATABLE :: cdates(:)
  INTEGER :: idatemin(1),idatemax(1)

  REAL, ALLOCATABLE :: ll_src(:,:),ll_tgt(:,:)
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: vardataij,vardataijll
  REAL, ALLOCATABLE, DIMENSION(:,:) :: aerosll

  LOGICAL :: isfile

  INTEGER :: nxy,nll,nc,nt,nvars_aeros,nweights,ntimes
  INTEGER :: i,j,iv,idt,jdt
  INTEGER :: year,month,day,hour

  REAL, ALLOCATABLE :: weights(:,:)

  TYPE(timedelta_type) :: dt,dtinterval
  TYPE(datetime_type) :: datemin6,datemax6,newdate

  NAMELIST /record_input/ date,varlist_aeros,&
       &input_improve_dir,fname_improve,&
       &input_grid_dir,fname_grid,&
       &input_fv3_dir,fname_fv3_aeros

  NAMELIST /record_output/ output_dir,fname_fv32improve

  varlist_aeros=""

  INQUIRE(file='fv32improve.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='fv32improve.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     READ(98, record_output)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist fv32improve.nl'
     STOP(1)
  ENDIF

  nvars_aeros=COUNT(varlist_aeros /= "")

  ALLOCATE(varnames_aeros(nvars_aeros))
  varnames_aeros(:)=varlist_aeros(:nvars_aeros)

  fname=TRIM(input_improve_dir)//'/'//fname_improve

  CALL get_improve(fname,varnames_aeros,improve_record)

  nll=SIZE(improve_record(:)%lat)

  ALLOCATE(cdates(nll))

  DO i=1,nll
     WRITE(cdates(i)(1:4),'(i4.4)')improve_record(i)%datetime%year
     WRITE(cdates(i)(5:6),'(i2.2)')improve_record(i)%datetime%month
     WRITE(cdates(i)(7:8),'(i2.2)')improve_record(i)%datetime%day
     WRITE(cdates(i)(9:10),'(i2.2)')improve_record(i)%datetime%hour
  ENDDO

  datemin=MINVAL(cdates)
  datemax=MAXVAL(cdates)
  idatemin=MINLOC(cdates)
  idatemax=MAXLOC(cdates)

  j=MOD(improve_record(idatemin(1))%datetime%hour,6)
  datemin6=improve_record(idatemin(1))%datetime-timedelta(hours=j)

  j=6-MOD(improve_record(idatemax(1))%datetime%hour,6)
  datemax6=improve_record(idatemax(1))%datetime+timedelta(hours=j)

  dtinterval=datemax6-datemin6

  idt=dtinterval%days*24+dtinterval%hours
  jdt=idt+24
  nweights=jdt/6+1
  ntimes=(dtinterval%days*24+dtinterval%hours)/6+1

  ALLOCATE(weights(nll,nweights))
  weights=0.

  newdate=datemin6

  DO j=1,ntimes
     
     DO i=1,nll
        dt=improve_record(i)%datetime-newdate
        idt=dt%days*24+dt%hours

        IF (SUM(weights(i,:)) > 0.) CYCLE

        IF (idt == 0) THEN
           weights(i,j)=0.125
           weights(i,j+1:j+4)=0.25
           weights(i,j+4)=0.125
        ELSE IF (idt < 6) THEN
           weights(i,j)=(1.-idt/6.)/5
           weights(i,j+1:j+4)=1./5
           weights(i,j+5)=(idt/6.)/5
        ENDIF

     ENDDO

     newdate=newdate+timedelta(hours=6)

  ENDDO
  
!  DO i=1,nll
!     PRINT *,'@@@1',i,improve_record(i)%datetime%isoformat()
!     PRINT *,'@@@2',weights(i,:)
!     PRINT *,'@@@3',SUM(weights(i,:))
!  ENDDO

  ALLOCATE(ll_tgt(nll,2))
  ll_tgt(:,1)=improve_record(:)%lat
  ll_tgt(:,2)=improve_record(:)%lon

  ALLOCATE(aerosll(nll,nvars_aeros))
  aerosll=0.

  newdate=datemin6
  DO i=1,nweights

     WRITE(date(1:4),'(i4.4)') newdate%year
     WRITE(date(5:6),'(i2.2)') newdate%month
     WRITE(date(7:8),'(i2.2)') newdate%day
     WRITE(date(9:10),'(i2.2)') newdate%hour

     fname_fv3_aeros=date(1:8)//'.'//date(9:10)//&
          &fname_fv3_aeros(12:)

     CALL filenames(input_grid_dir,fname_grid,gridfiles,&
          &input_fv3_dir,fname_fv3_aeros,fv3files_aeros)

     IF (i==1) THEN
        CALL read_fv3_grid(gridfiles,ll_src)
        nxy=SIZE(ll_src,1)
        CALL slint_init(ll_src, nxy, ll_tgt, nll)
     ENDIF

     DO iv=1,nvars_aeros
        varname=varnames_aeros(iv)
        CALL read_fv3_var(fv3files_aeros,varname,vardataij)
!        PRINT *,'@@@1',TRIM(varname),MINVAL(vardataij),MAXVAL(vardataij)
        IF (.NOT. ALLOCATED(vardataijll)) THEN
           nc=SIZE(vardataij,3)
           nt=SIZE(vardataij,4)
           ALLOCATE(vardataijll(nll,1,nc,nt))
        ENDIF
        CALL h_interp(vardataij,vardataijll)
        aerosll(:,iv)=aerosll(:,iv)+weights(:,i)*vardataijll(:,1,nc,nt)
!        PRINT *,'@@@2',MINVAL(vardataijll),MAXVAL(vardataijll)
!        PRINT *,'@@@3',MINVAL(aerosll(:,iv)),MAXVAL(aerosll(:,iv))
     ENDDO
     
     newdate=newdate+timedelta(hours=6)
  
  ENDDO

  fname_fv32improve=TRIM(output_dir)//'/'//fname_fv32improve

  OPEN(unit=10,file=fname_fv32improve)
  DO iv=1,nvars_aeros
     WRITE(10,'(a)')' '
     WRITE(10,'(a)')trim(varnames_aeros(iv))
     DO i=1,nll
        WRITE(10,'(2e15.5)')improve_record(i)%varvalues(iv),aerosll(i,iv)
     ENDDO
  ENDDO
  
  IF (ALLOCATED(vardataij)) DEALLOCATE(vardataij)
  IF (ALLOCATED(vardataijll)) DEALLOCATE(vardataijll)
  IF (ALLOCATED(ll_src)) DEALLOCATE(ll_src)
  IF (ALLOCATED(ll_tgt)) DEALLOCATE(ll_tgt)

END PROGRAM fv32improve
  
