PROGRAM replace_vars

!to replace variables from one file with same variables from the
!second file
!MZP Dec 2020 

  USE netcdf
  USE module_netcdf_io, only: handle_err
  USE module_constants


  IMPLICIT NONE

  INTEGER :: i,ivar
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: varvalue
  INTEGER, DIMENSION(4)           :: dimids
  INTEGER, DIMENSION(4)           :: dims
  CHARACTER(len=max_varname_length) :: varname
  CHARACTER(len=max_string_length) :: fnamein,fnameout
  CHARACTER(len=max_varname_length) :: varnames(1:nvarmax)
  INTEGER :: nvars
  LOGICAL :: isfile=.FALSE.

  INTEGER                         :: ncid,mcid,varidin,varidout,&
       &status,ndims

! mpi definitions.
  INCLUDE 'mpif.h'
  INTEGER MPI_Status(MPI_STATUS_SIZE),numproc,nproc,iret
  
  NAMELIST /replace_vars_nml/ fnamein,fnameout,varnames
  
  dims=1
  varnames(1:nvarmax)='missing'

  CALL MPI_Init(iret)
! nproc is process number, numproc is total number of processes.
  CALL MPI_Comm_rank(MPI_COMM_WORLD,nproc,iret)
  CALL MPI_Comm_size(MPI_COMM_WORLD,numproc,iret)

  INQUIRE(file='replace_vars.nl', exist=isfile)
  
  IF ( .NOT. isfile ) THEN
     PRINT *,'File replace_vars.nl missing'
     PRINT *,'Stopping'
     STOP
  ENDIF
  
  OPEN(unit=101, file='replace_vars.nl', &
       form='formatted', status='old', action='read')
  READ(101, replace_vars_nml)
  CLOSE(101)
  
  nvars = COUNT(varnames .NE. 'missing')

  IF (numproc == 1) THEN

     PRINT *,'fname_in = '//TRIM(fnamein)
     PRINT *,'fname_out = '//TRIM(fnameout)
     status = nf90_open(fnameout, nf90_write, mcid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'00 ',mcid,TRIM(fnameout)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,1000,iret)
     ENDIF

     status = nf90_open(fnamein, nf90_nowrite, ncid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'0 ',ncid,TRIM(fnamein)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,100,iret)
     ENDIF
     
     DO ivar=1,nvars
        
        varname=varnames(ivar)
        
        PRINT *,TRIM(varname)
        
        
        status = nf90_inq_varid(ncid,TRIM(varname),varidin)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'1 ',TRIM(varname)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,101,iret)
        ENDIF
        
        status = nf90_inquire_variable(ncid, varidin, ndims=ndims)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'2 ',varidin
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,102,iret)
        ENDIF
        
        status = nf90_inquire_variable(ncid, varidin, dimids=dimids(:ndims))
        IF (status /= nf90_noerr ) THEN
           PRINT *,'3 ',varidin
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
        
        IF (ALLOCATED(varvalue)) DEALLOCATE(varvalue)
        ALLOCATE(varvalue(dims(1),dims(2),dims(3),dims(4)))
        
        status = nf90_get_var(ncid,varidin,varvalue)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'5 ',varidin
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,105,iret)
        ENDIF
  
        status = nf90_inq_varid(mcid,TRIM(varname),varidout)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'6 ',TRIM(varname)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,101,iret)
        ENDIF

        status = nf90_put_var(mcid,varidout,varvalue)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'7 ',varidout,MINVAL(varvalue),MAXVAL(varvalue)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,106,iret)
        ENDIF
        
     ENDDO

     status = nf90_close(ncid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'8 ',ncid,TRIM(fnamein)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,107,iret)
     ENDIF

     status = nf90_close(mcid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'9 ',mcid,TRIM(fnameout)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,107,iret)
     ENDIF

     IF (ALLOCATED(varvalue)) DEALLOCATE(varvalue)
  
  ELSE

     IF (nproc == 0) THEN 
        PRINT *, 'Code needs to be parallelized - stopping'
        CALL MPI_Abort(MPI_COMM_WORLD,108,iret)
     ENDIF
     
  ENDIF

  CALL MPI_Barrier(MPI_COMM_WORLD,iret)
  IF (nproc == 0) WRITE(6,*) 'all done!'
  CALL MPI_Finalize(iret)
  IF (iret /= 0) THEN
     PRINT *, 'MPI_Finalize error status = ',iret
  END IF

END PROGRAM replace_vars

