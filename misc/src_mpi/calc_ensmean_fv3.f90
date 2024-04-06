PROGRAM calc_ensmean_fv3

!to calculate an ensemble  mean of variables in a fv3 netcdf file
!MZP Dec 2019 

  USE netcdf
  USE module_netcdf_io, only: handle_err
  USE module_constants


  IMPLICIT NONE

  INTEGER :: i,ivar
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: varmember,varmean
  INTEGER, DIMENSION(4)           :: dimids
  INTEGER,           DIMENSION(4)                   :: dims
  CHARACTER(len=max_varname_length)                                 :: varname
  CHARACTER(len=max_string_length) :: fnamein,fnameout,prefix
  CHARACTER(len=max_varname_length) :: varnames(1:nvarmax)
  INTEGER :: nvars
  LOGICAL :: isfile=.FALSE.
  INTEGER :: nens,iens
  CHARACTER(len=3) :: cnens,ciens


  INTEGER                         :: ncid,mcid,varid,status,ndims

  INTEGER :: iargc
  
! mpi definitions.
  INCLUDE 'mpif.h'
  INTEGER MPI_Status(MPI_STATUS_SIZE),numproc,nproc,iret
  
  NAMELIST /ensmean_nml/ varnames
  
  dims=1
  varnames(1:nvarmax)='missing'

  CALL MPI_Init(iret)
! nproc is process number, numproc is total number of processes.
  CALL MPI_Comm_rank(MPI_COMM_WORLD,nproc,iret)
  CALL MPI_Comm_size(MPI_COMM_WORLD,numproc,iret)

  IF (iargc() < 2) THEN
     PRINT *,'Requires number of members, prefix with member location'
     PRINT *,'Stopping'
     CALL MPI_Abort(MPI_COMM_WORLD,101,iret)
  ENDIF

  CALL getarg(1,cnens)
  READ(cnens,'(i3)') nens
  CALL getarg(2,prefix)

 IF (nens /= numproc) THEN
     PRINT *,'Number of members = ',nens
     PRINT *,'Number of processors = ',numproc
     PRINT *,'nens needs to equal numproc'
     PRINT *,'Stopping'
     CALL MPI_Abort(MPI_COMM_WORLD,102,iret)
  ENDIF

  INQUIRE(file='ensmean.nl', exist=isfile)
  
  IF ( .NOT. isfile ) THEN
     PRINT *,'Namelist ensmean.nl missing'
     PRINT *,'Stopping'
     STOP
  ENDIF
  
  OPEN(unit=101, file='ensmean.nl', &
       form='formatted', status='old', action='read')
  READ(101, ensmean_nml)
  CLOSE(101)
  
  nvars = COUNT(varnames .NE. 'missing')

  fnameout=TRIM(prefix)//'.ensmean'

  IF (nproc == 0) THEN
     PRINT *,TRIM(fnameout)
     status = nf90_open(fnameout, nf90_write, mcid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'00 ',mcid,TRIM(fnameout)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,1000,iret)
     ENDIF
  ENDIF

  DO ivar=1,nvars
     
     varname=varnames(ivar)
     
     IF (nproc == 0) PRINT *,TRIM(varname)

     iens=nproc + 1
     WRITE(ciens,'(i3.3)')iens
     fnamein=TRIM(prefix)//'.mem'//TRIM(ciens)

     status = nf90_open(fnamein, nf90_nowrite, ncid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'0 ',ncid,TRIM(fnamein)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,100,iret)
     ENDIF

     status = nf90_inq_varid(ncid,TRIM(varname),varid)
     IF (status /= nf90_noerr ) THEN
        PRINT *,'1 ',TRIM(varname)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,101,iret)
     ENDIF

     status = nf90_inquire_variable(ncid, varid, ndims=ndims)
     IF (status /= nf90_noerr ) THEN
        PRINT *,'2 ',varid
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,102,iret)
     ENDIF

     status = nf90_inquire_variable(ncid, varid, dimids=dimids(:ndims))
     IF (status /= nf90_noerr ) THEN
        PRINT *,'3 ',varid
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,103,iret)
     ENDIF

     DO i=1,ndims
        status = nf90_inquire_dimension(ncid,dimids(i),len=dims(i))
        IF (status /= nf90_noerr ) THEN
           PRINT *,'4 ',i,dims(i)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,104,iret)
        ENDIF
     ENDDO

     IF (ALLOCATED(varmean))  DEALLOCATE(varmean)
     ALLOCATE(varmean(dims(1),dims(2),dims(3),dims(4)))

     IF (ALLOCATED(varmember)) DEALLOCATE(varmember)
     ALLOCATE(varmember(dims(1),dims(2),dims(3),dims(4)))

     status = nf90_get_var(ncid,varid,varmember)
     IF (status /= nf90_noerr ) THEN
        PRINT *,'5 ',varid
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,105,iret)
     ENDIF
     
     CALL mpi_allreduce(varmember,varmean,SIZE(varmean),mpi_real,mpi_sum,mpi_comm_world,iret)

     IF (nproc == 0) THEN 
        IF (iret /= 0) THEN
           PRINT *,'iret = ',iret           
           CALL MPI_Abort(MPI_COMM_WORLD,1061,iret)
        ENDIF
        varmean=varmean/REAL(nens)

        status = nf90_put_var(mcid,varid,varmean)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'6 ',varid,MINVAL(varmean),MAXVAL(varmean)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,106,iret)
        ENDIF

     ENDIF

     CALL MPI_Barrier(MPI_COMM_WORLD,iret)

  ENDDO

  IF (nproc == 0) THEN
     status = nf90_close(mcid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'01 ',mcid,TRIM(fnameout)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,1001,iret)
     ENDIF
  ENDIF

  IF (ALLOCATED(varmean)) DEALLOCATE(varmean)
  IF (ALLOCATED(varmember)) DEALLOCATE(varmember)

  CALL MPI_Barrier(MPI_COMM_WORLD,iret)
  IF (nproc == 0) WRITE(6,*) 'all done!'
  CALL MPI_Finalize(iret)
  IF (iret /= 0) THEN
     PRINT *, 'MPI_Finalize error status = ',iret
  END IF

END PROGRAM calc_ensmean_fv3

