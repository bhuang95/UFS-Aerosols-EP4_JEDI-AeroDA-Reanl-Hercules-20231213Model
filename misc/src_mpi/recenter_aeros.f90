PROGRAM recenter_aeros

!to recenter variables from fnamemem around fnamecntl
!       var(fnamemem)=var(fnamemem)-var(fnameensm)+var(fnamecntl)
!and force recentered vars less than zero to zero.
!Huang Dec 2020 


  USE netcdf
  USE module_netcdf_io, only: handle_err
  USE module_constants


  IMPLICIT NONE

  INTEGER :: i,ivar
  REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: varcntl, varmem
  INTEGER, DIMENSION(4)           :: dimids
  INTEGER, DIMENSION(4)           :: dims
  CHARACTER(len=max_varname_length) :: varname
  CHARACTER(len=max_string_length) :: fnamecntl,fnameensm,fnamemem
  CHARACTER(len=max_varname_length) :: varnames(1:nvarmax)
  INTEGER :: nvars
  LOGICAL :: isfile=.FALSE.

  INTEGER                         ::    idcntl,idensm,idmem, &
                                        varidcntl,varidensm,varidmem, &
                                        &status,ndims

! mpi definitions.
  INCLUDE 'mpif.h'
  INTEGER MPI_Status(MPI_STATUS_SIZE),numproc,nproc,iret
  
  NAMELIST /recenter_aeros_nml/ fnamecntl,fnameensm,fnamemem,varnames
  
  dims=1
  varnames(1:nvarmax)='missing'

  CALL MPI_Init(iret)
! nproc is process number, numproc is total number of processes.
  CALL MPI_Comm_rank(MPI_COMM_WORLD,nproc,iret)
  CALL MPI_Comm_size(MPI_COMM_WORLD,numproc,iret)

  INQUIRE(file='recenter_aeros.nl', exist=isfile)
  
  IF ( .NOT. isfile ) THEN
     PRINT *,'File recenter_aeros.nl missing'
     PRINT *,'Stopping'
     STOP
  ENDIF
  
  OPEN(unit=101, file='recenter_aeros.nl', &
       form='formatted', status='old', action='read')
  READ(101, recenter_aeros_nml)
  CLOSE(101)
  
  nvars = COUNT(varnames .NE. 'missing')

  IF (numproc == 1) THEN

     PRINT *,'fname_cntl = '//TRIM(fnamecntl)
     PRINT *,'fname_ensm = '//TRIM(fnameensm)
     PRINT *,'fname_mem  = '//TRIM(fnamemem)

     ! Open files
     status = nf90_open(fnamecntl, nf90_nowrite, idcntl)
     IF (status /= nf90_noerr) THEN
        PRINT *,'00 ',idcntl,TRIM(fnamecntl)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,1000,iret)
     ENDIF

     status = nf90_open(fnameensm, nf90_nowrite, idensm)
     IF (status /= nf90_noerr) THEN
        PRINT *,'0 ',idensm,TRIM(fnameensm)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,100,iret)
     ENDIF

     status = nf90_open(fnamemem, nf90_write, idmem)
     IF (status /= nf90_noerr) THEN
        PRINT *,'0 ',idmem,TRIM(fnamemem)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,100,iret)
     ENDIF
     
     DO ivar=1,nvars
        
        varname=varnames(ivar)
        
        PRINT *,TRIM(varname)
        
        ! get var dimensions through fnamecntl
        status = nf90_inq_varid(idcntl,TRIM(varname),varidcntl)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'1 ',TRIM(varname)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,101,iret)
        ENDIF
        
        status = nf90_inquire_variable(idcntl, varidcntl, ndims=ndims)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'2 ',varidcntl
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,102,iret)
        ENDIF
        
        status = nf90_inquire_variable(idcntl, varidcntl, dimids=dimids(:ndims))
        IF (status /= nf90_noerr ) THEN
           PRINT *,'3 ',varidcntl
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,103,iret)
        ENDIF
        
        DO i=1,ndims
           status = nf90_inquire_dimension(idcntl,dimids(i),len=dims(i))
           IF (status /= nf90_noerr ) THEN
              PRINT *,'4 ',i,dims(i)
              CALL handle_err(status)
              CALL MPI_Abort(MPI_COMM_WORLD,104,iret)
           ENDIF
        ENDDO
        
        IF (ALLOCATED(varcntl)) DEALLOCATE(varcntl)
        IF (ALLOCATED(varmem)) DEALLOCATE(varmem)
        ALLOCATE(varcntl(dims(1),dims(2),dims(3),dims(4)))
        ALLOCATE(varmem(dims(1),dims(2),dims(3),dims(4)))
        
  
        ! read ensmean and member files and calculate ensemble peturbations
        status = nf90_inq_varid(idensm,TRIM(varname),varidensm)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'6 ',TRIM(varname)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,101,iret)
        ENDIF

        status = nf90_get_var(idensm,varidensm,varcntl)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'5 ',varidensm
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,105,iret)
        ENDIF

        status = nf90_inq_varid(idmem,TRIM(varname),varidmem)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'6 ',TRIM(varname)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,101,iret)
        ENDIF

        status = nf90_get_var(idmem,varidmem,varmem)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'5 ',varidmem
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,105,iret)
        ENDIF

        varmem(:,:,:,:)=varmem(:,:,:,:)-varcntl(:,:,:,:)

        ! Read control files and add the perturbations.
        status = nf90_get_var(idcntl,varidcntl,varcntl)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'5 ',varidcntl
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,105,iret)
        ENDIF

        varmem(:,:,:,:)=varmem(:,:,:,:)+varcntl(:,:,:,:)

        where (varmem < 0.0) varmem=0.0

        status = nf90_put_var(idmem,varidmem,varmem)
        IF (status /= nf90_noerr ) THEN
           PRINT *,'7 ',varidmem,MINVAL(varmem),MAXVAL(varmem)
           CALL handle_err(status)
           CALL MPI_Abort(MPI_COMM_WORLD,106,iret)
        ENDIF
        
     ENDDO

     status = nf90_close(idcntl)
     IF (status /= nf90_noerr) THEN
        PRINT *,'8 ',idcntl,TRIM(fnamecntl)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,107,iret)
     ENDIF

     status = nf90_close(idensm)
     IF (status /= nf90_noerr) THEN
        PRINT *,'9 ',idensm,TRIM(fnameensm)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,107,iret)
     ENDIF

     status = nf90_close(idmem)
     IF (status /= nf90_noerr) THEN
        PRINT *,'9 ',idmem,TRIM(fnamemem)
        CALL handle_err(status)
        CALL MPI_Abort(MPI_COMM_WORLD,107,iret)
     ENDIF

     IF (ALLOCATED(varcntl)) DEALLOCATE(varcntl)
     IF (ALLOCATED(varmem)) DEALLOCATE(varmem)
  
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

END PROGRAM recenter_aeros

