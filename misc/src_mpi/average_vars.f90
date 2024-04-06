PROGRAM average_vars

!to average two variables from two files and write out the average in the first file
!MZP Dec 2020 

  USE netcdf
  USE module_netcdf_io, only: handle_err
  USE module_constants


  IMPLICIT NONE

  INTEGER :: i,ivar
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: varvalue_first,varvalue_second
  INTEGER, DIMENSION(4)           :: dimids
  INTEGER, DIMENSION(4)           :: dims
  CHARACTER(len=max_varname_length) :: varname
  CHARACTER(len=max_string_length) :: fname_first,fname_second
  CHARACTER(len=max_varname_length) :: varnames(1:nvarmax)
  INTEGER :: nvars
  LOGICAL :: isfile=.FALSE.

  INTEGER                         :: ncid,mcid,varid_first,varid_second,&
       &status,ndims

! mpi definitions.
  INCLUDE 'mpif.h'
  INTEGER MPI_Status(MPI_STATUS_SIZE),numproc,nproc,iret
  
  NAMELIST /average_vars_nml/ fname_first,fname_second,varnames
  
  dims=1
  varnames(1:nvarmax)='missing'

  CALL MPI_Init(iret)
! nproc is process number, numproc is total number of processes.
  CALL MPI_Comm_rank(MPI_COMM_WORLD,nproc,iret)
  CALL MPI_Comm_size(MPI_COMM_WORLD,numproc,iret)

  INQUIRE(file='average_vars.nl', exist=isfile)
  
  IF ( .NOT. isfile ) THEN
     PRINT *,'File average_vars.nl missing'
     PRINT *,'Stopping'
     CALL MPI_Abort(MPI_COMM_WORLD,10,iret)
  ENDIF
  
  OPEN(unit=101, file='average_vars.nl', &
       form='formatted', status='old', action='read')
  READ(101, average_vars_nml)
  CLOSE(101)
  
  nvars = COUNT(varnames .NE. 'missing')

  IF (numproc == 1) THEN

     PRINT *,'fname_first = '//TRIM(fname_first)
     PRINT *,'fname_second = '//TRIM(fname_second)

     status = nf90_open(fname_first, nf90_write, ncid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'-1 ',ncid,TRIM(fname_first)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,100,iret)
     ENDIF

     status = nf90_open(fname_second, nf90_nowrite, mcid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'0 ',mcid,TRIM(fname_second)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,1000,iret)
     ENDIF

     DO ivar=1,nvars
        
        varname=varnames(ivar)
        
        PRINT *,TRIM(varname)

        status = nf90_inq_varid(ncid,TRIM(varname),varid_first)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'1 ',TRIM(varname)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,101,iret)
        ENDIF
        
        status = nf90_inquire_variable(ncid, varid_first, ndims=ndims)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'2 ',varid_first
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,102,iret)
        ENDIF
        
        status = nf90_inquire_variable(ncid, varid_first, dimids=dimids(:ndims))
        IF (status /= nf90_noerr ) THEN
           PRINT *,'3 ',varid_first
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
        
        IF (ALLOCATED(varvalue_first)) DEALLOCATE(varvalue_first)
        ALLOCATE(varvalue_first(dims(1),dims(2),dims(3),dims(4)))

        IF (ALLOCATED(varvalue_second)) DEALLOCATE(varvalue_second)
        ALLOCATE(varvalue_second(dims(1),dims(2),dims(3),dims(4)))
        
        status = nf90_get_var(ncid,varid_first,varvalue_first)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'5 ',varid_first
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,105,iret)
        ENDIF
  
        status = nf90_inq_varid(mcid,TRIM(varname),varid_second)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'6 ',TRIM(varname)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,101,iret)
        ENDIF

        status = nf90_get_var(mcid,varid_second,varvalue_second)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'5 ',varid_second
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,105,iret)
        ENDIF

        varvalue_first=0.5*(varvalue_first+varvalue_second)

        PRINT *,MINVAL(varvalue_first),MAXVAL(varvalue_first)

        status = nf90_put_var(ncid,varid_first,varvalue_first)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'7 ',varid_first,varid_second,MINVAL(varvalue_first),MAXVAL(varvalue_first)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,106,iret)
        ENDIF
        
     ENDDO

     status = nf90_close(ncid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'8 ',ncid,TRIM(fname_first)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,107,iret)
     ENDIF

     status = nf90_close(mcid)
     IF (status /= nf90_noerr) THEN
        PRINT *,'9 ',mcid,TRIM(fname_second)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,107,iret)
     ENDIF

     IF (ALLOCATED(varvalue_first)) DEALLOCATE(varvalue_first)
  
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

END PROGRAM average_vars

