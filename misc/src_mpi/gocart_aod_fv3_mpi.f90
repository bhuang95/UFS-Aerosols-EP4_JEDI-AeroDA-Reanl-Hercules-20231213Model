PROGRAM gocart_aod_fv3_mpi

!Mariusz Pagowski Jan, 2020

  USE module_kinds
  USE module_constants, ONLY : kap, kap1, ug2kg, &
       &max_varname_length, max_string_length, n_maxabsorbers
  USE netcdf
  USE module_netcdf_io
  USE module_cfnames, ONLY: m2cf, cf2m
  USE ufo_vars_mod
  USE ufo_crtm_bare_utils_mod
  USE ufo_aodcrtm_bare_mod
  USE ufo_luts_bare_utils_mod
  USE ufo_aodluts_bare_mod

  IMPLICIT NONE

  TYPE(crtm_conf) :: conf_crtm
  TYPE(luts_conf) :: conf_luts

  INTEGER, PARAMETER :: nchan_nnr=6

  REAL(r_single), DIMENSION(nchan_nnr), PARAMETER :: nnr_channels=&
       &[440_r_single,470_r_single,500_r_single,550_r_single,&
       &660_r_single,870_r_single]

  INTEGER, DIMENSION(nchan_nnr), PARAMETER :: &
!viirs: 443.,486.,486.,551.,671.,861.
       &nchan_viirs_select=[2,3,11,4,5,7],&
!modis: 442.,466.,530.,553.,666.,867.
       &nchan_modis_select=[9,3,10,4,13,16]

! v.viirs-m_npp       
!           1   410.4901    
!           2   443.4030    
!           3   485.8821    
!           4   550.6119    
!           5   671.2543    
!           6   745.1992    
!           7   861.4292    
!           8   1238.214    
!           9   1375.301    
!          10   1600.850    
!          11   2256.858    

! v.modis_aqua        
!           1   644.8408    
!           2   856.7571    
!           3   466.1064    
!           4   553.2176    
!           5   1242.038    
!           6   1627.984    
!           7   2112.483    
!           8   412.7716    
!           9   442.4463    
!          10   487.9652    
!          11   530.2004    
!          12   546.8652    
!          13   666.4443    
!          14   678.0049    
!          15   747.0498    
!          16   867.3760    
!          17   904.2808    
!          18   935.8021    
!          19   935.7385    
!          20   1382.167    

! v.modis_terra       
!           1   644.1409    
!           2   855.8562    
!           3   465.6163    
!           4   553.3287    
!           5   1242.543    
!           6   1628.997    
!           7   2112.717    
!           8   410.8992    
!           9   441.9383    
!          10   487.2798    
!          11   529.7424    
!          12   546.4805    
!          13   666.2437    
!          14   676.7939    
!          15   746.2441    
!          16   866.4699    
!          17   904.0203    
!          18   935.8414    
!          19   935.3293    
!          20   1381.289    


  INTEGER :: i,j,k,ii,iii

  REAL(r_single), ALLOCATABLE, DIMENSION(:,:,:,:) :: aerosols
  REAL(r_single), ALLOCATABLE, DIMENSION(:,:,:) :: ts,sphum,prsl,prsi

  CHARACTER(len=max_varname_length), ALLOCATABLE, DIMENSION(:) :: &
       &aeronames_gocart_fv3

  INTEGER :: nlon,nlat,nsig,naero_gocart_fv3,nchanl
  
  CHARACTER(len=max_varname_length) :: varname,aerosol_option
  CHARACTER(len=max_string_length) :: input_dir,fname_akbk,fname_core,fname_tracer,output_dir,fname_aod

  REAL(r_single), ALLOCATABLE :: psfc(:,:)
  REAL(r_single), ALLOCATABLE :: ak(:),bk(:)
  REAL(r_single), ALLOCATABLE :: aod(:,:,:,:),aodlayers(:,:,:,:,:)
  REAL(r_single), ALLOCATABLE :: aod_nproc(:,:,:)
  REAL(r_single), ALLOCATABLE :: vardata(:,:,:,:,:)
  INTEGER, ALLOCATABLE :: channels(:)
  REAL(r_single), ALLOCATABLE :: wavelengths(:)

  CHARACTER(len=max_varname_length) :: Absorbers(n_maxabsorbers), model

  NAMELIST /record_input/ input_dir,fname_akbk,fname_core,&
        &fname_tracer,output_dir,fname_aod

  NAMELIST /record_model/ model

  LOGICAL :: isfile

!mpi stuff
  INTEGER, ALLOCATABLE, DIMENSION(:) :: jbegin,jend,displs,sendcounts
  REAL(r_single), ALLOCATABLE, DIMENSION(:) :: sendbuf,recvbuf
  INTEGER :: jextra,num_j_groups,nx

  INTEGER, DIMENSION(2) :: maxlocs

! mpi definitions
  INCLUDE 'mpif.h'
  INTEGER MPI_Status(MPI_STATUS_SIZE),numprocs,nproc,iret,ierr

  CALL MPI_Init(iret)
! nproc is process number, numprocs is total number of processes.
  CALL MPI_Comm_rank(MPI_COMM_WORLD,nproc,iret)
  CALL MPI_Comm_size(MPI_COMM_WORLD,numprocs,iret)

  INQUIRE(file='gocart_aod_fv3_mpi.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='gocart_aod_fv3_mpi.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     READ(98, record_model)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist gocart_aod_fv3_mpi.nl'
     CALL mpi_abort(mpi_comm_world, iret)
  ENDIF

  IF (TRIM(upper2lower(model)) == "aodcrtm") THEN
     CALL crtm_conf_setup(conf_crtm,channels)
     aerosol_option=conf_crtm%aerosol_option
     nchanl=SIZE(channels)
  ELSEIF (TRIM(upper2lower(model)) == "aodluts") THEN
     CALL luts_conf_setup(conf_luts)
     aerosol_option=conf_luts%aerosol_option
     nchanl=SIZE(conf_luts%wavelengths)
  ELSE
     IF (nproc == 0) THEN
        PRINT *,'Unknown model ',TRIM(model)
        CALL mpi_abort(mpi_comm_world, iret)
     ENDIF
  ENDIF

  CALL assign_aerosol_names(aerosol_option,aeronames_gocart_fv3)
  naero_gocart_fv3=SIZE(aeronames_gocart_fv3)

!until here all cores work together
!here node=0 needs to read sphum and fcst to cores
!same next for tsen
!@mzp

!only nproc=0 reads netcdf
  
  IF (nproc == 0) THEN
     
     fname_akbk=TRIM(input_dir)//'/'//TRIM(fname_akbk)
     fname_core=TRIM(input_dir)//'/'//TRIM(fname_core)
     fname_tracer=TRIM(input_dir)//'/'//TRIM(fname_tracer)
     fname_aod=TRIM(output_dir)//'/'//TRIM(fname_aod)
     
     varname='delp'
     IF (ALLOCATED(vardata)) DEALLOCATE(vardata)
     CALL netcdf_read(fname_core,varname,vardata)
     nlon=SIZE(vardata,1)
     nlat=SIZE(vardata,2)
     nsig=SIZE(vardata,3)
     ALLOCATE(psfc(nlon,nlat))

     psfc=SUM(vardata(:,:,:,1,1),3)

     ALLOCATE(ak(nsig+1),bk(nsig+1))

     varname='ak'
     IF (ALLOCATED(vardata)) DEALLOCATE(vardata)
     CALL netcdf_read(fname_akbk,varname,vardata)
     ak=vardata(:,1,1,1,1)

     varname='bk'
     IF (ALLOCATED(vardata)) DEALLOCATE(vardata)
     CALL netcdf_read(fname_akbk,varname,vardata)
     bk=vardata(:,1,1,1,1)

     psfc=psfc+ak(1)

     ALLOCATE(sendbuf(nlon*nlat))

     ii=0
     
     DO j=1,nlon
        DO i=1,nlat
           ii=ii+1
           sendbuf(ii)=psfc(j,i)
        END DO
     END DO

     DEALLOCATE(psfc)

     ierr=0
   
  ENDIF

  CALL mpi_bcast(ierr,1,mpi_integer,0,mpi_comm_world,iret)  

  IF (ierr /= 0) THEN
     CALL MPI_Barrier(MPI_COMM_WORLD,iret)
     CALL MPI_Finalize(iret)
     IF (iret .NE. 0) THEN
        PRINT *, 'MPI_Finalize error status = ',iret
     END IF
     CALL mpi_abort(mpi_comm_world, 1000, iret)
  ENDIF

  CALL mpi_bcast(model,max_varname_length,mpi_character,0,mpi_comm_world,iret)   

  CALL mpi_bcast(nlon,1,mpi_integer,0,mpi_comm_world,iret)
  CALL mpi_bcast(nlat,1,mpi_integer,0,mpi_comm_world,iret)
  CALL mpi_bcast(nsig,1,mpi_integer,0,mpi_comm_world,iret)

  ALLOCATE(jbegin(0:numprocs),jend(0:numprocs-1),displs(0:numprocs-1),sendcounts(0:numprocs-1))

  num_j_groups=nlon/numprocs
  jextra=nlon-num_j_groups*numprocs
  
  jbegin(0)=1
  IF(jextra > 0) THEN
     DO j=1,jextra
        jbegin(j)=jbegin(j-1)+1+num_j_groups
     END DO
  END IF
  DO j=jextra+1,numprocs
     jbegin(j)=jbegin(j-1)+num_j_groups
  END DO

  DO j=0,numprocs-1
     jend(j)=MIN(jbegin(j+1)-1,nlon)
  END DO

  nx=jend(nproc)-jbegin(nproc)+1

  IF (.NOT. ALLOCATED(ak)) ALLOCATE(ak(nsig+1)) 
  IF (.NOT. ALLOCATED(bk)) ALLOCATE(bk(nsig+1)) 

  CALL mpi_bcast(ak,nsig+1,mpi_real,0,mpi_comm_world,iret)
  CALL mpi_bcast(bk,nsig+1,mpi_real,0,mpi_comm_world,iret)

  DO j=0,numprocs-1
     sendcounts(j)=(jend(j)-jbegin(j)+1)*nlat
  ENDDO

  displs(0)=0
  DO j=1,numprocs-1
     displs(j)=displs(j-1)+sendcounts(j-1)
  ENDDO

  ALLOCATE(recvbuf(sendcounts(nproc)))
  
  recvbuf=0.

!scatter psfc
  CALL mpi_scatterv(sendbuf,sendcounts,displs,mpi_real, &
       recvbuf,sendcounts(nproc),mpi_real,0,mpi_comm_world,iret)

  ALLOCATE(psfc(nx,nlat))
  ALLOCATE(ts(nx,nlat,nsig),sphum(nx,nlat,nsig),&
       &prsi(nx,nlat,nsig+1),prsl(nx,nlat,nsig))
  
  ii=0
  
  DO j=1,nx
     DO i=1,nlat
        ii=ii+1
        psfc(j,i)=recvbuf(ii)
     ENDDO
  ENDDO

  DO j=1,nx
     DO i=1,nlat
        DO k=1,nsig+1
           prsi(j,i,k)=ak(k)+bk(k)*psfc(j,i)
        ENDDO
        
        k=1
        IF (ak(1) < 1.E-8 ) THEN
           prsl(j,i,k)=(prsi(j,i,k+1)-prsi(j,i,k))*kap/kap1
        ELSE
           prsl(j,i,k)=(prsi(j,i,k+1)-prsi(j,i,k))/&
                &LOG(prsi(j,i,k+1)/prsi(j,i,k))
        ENDIF
        
        DO k = 2, nsig
           prsl(j,i,k)=(prsi(j,i,k+1)-prsi(j,i,k))/&
                &LOG(prsi(j,i,k+1)/prsi(j,i,k))
        ENDDO

        
        
!phillips
!        DO k=1,nsig
!           prsl(j,i,k)=(&
!                &(prsi(j,i,k)**kap1-prsi(j,i,k+1)**kap1)/&
!                (kap1*(prsi(j,i,k)-prsi(j,i,k+1))))**kapr
!        ENDDO
        
     ENDDO
  ENDDO
  
  IF (nproc == 0) THEN

     DEALLOCATE(sendbuf)
     
     ALLOCATE(sendbuf(nlon*nlat*nsig))

     varname='sphum'
     IF (ALLOCATED(vardata)) DEALLOCATE(vardata)
     CALL netcdf_read(fname_tracer,varname,vardata)
     ii=0

     DO j=1,nlon
        DO k=1,nsig
           DO i=1,nlat
              ii=ii+1
              sendbuf(ii)=vardata(j,i,k,1,1)
           END DO
        END DO
     END DO
  ENDIF
  
  CALL mpi_bcast(ierr,1,mpi_integer,0,mpi_comm_world,iret)

  IF (ierr /= 0) THEN
     CALL MPI_Barrier(MPI_COMM_WORLD,iret)
     CALL MPI_Finalize(iret)
     IF (iret .NE. 0) THEN
        PRINT *, 'MPI_Finalize error status = ',iret
     END IF
     CALL mpi_abort(mpi_comm_world,1001,iret)
  ENDIF


!recalculate displs and sendcounts for 3d array

  DO j=0,numprocs-1
     sendcounts(j)=(jend(j)-jbegin(j)+1)*nlat*nsig
  ENDDO
  
  displs(0)=0
  DO j=1,numprocs-1
     displs(j)=displs(j-1)+sendcounts(j-1)
  ENDDO


  DEALLOCATE(recvbuf)
  ALLOCATE(recvbuf(sendcounts(nproc)))
  
  recvbuf=0.

  CALL mpi_scatterv(sendbuf,sendcounts,displs,mpi_real, &
       recvbuf,sendcounts(nproc),mpi_real,0,mpi_comm_world,iret)

  ii=0
  
  DO j=1,nx
     DO k=1,nsig
        DO i=1,nlat
           ii=ii+1
           sphum(j,i,k)=recvbuf(ii)
        END DO
     END DO
  END DO

  IF (nproc == 0) THEN

     varname='T'
     IF (ALLOCATED(vardata)) DEALLOCATE(vardata)
     CALL netcdf_read(fname_core,varname,vardata)

     ii=0
     
     DO j=1,nlon
        DO k=1,nsig
           DO i=1,nlat
              ii=ii+1
              sendbuf(ii)=vardata(j,i,k,1,1)
           END DO
        END DO
     END DO
     
  ENDIF

  recvbuf=0.

  CALL mpi_scatterv(sendbuf,sendcounts,displs,mpi_real, &
       recvbuf,sendcounts(nproc),mpi_real,0,mpi_comm_world,iret)

  ii=0

  DO j=1,nx
     DO k=1,nsig
        DO i=1,nlat
           ii=ii+1
           ts(j,i,k)=recvbuf(ii)
        END DO
     END DO
  END DO


  ALLOCATE(aerosols(nx,nlat,nsig,naero_gocart_fv3))
  
  DO iii=1,naero_gocart_fv3
     
     varname=TRIM(cf2m(aeronames_gocart_fv3(iii)))

! need to translate names to model names

     IF (nproc == 0) THEN
        
        IF (ALLOCATED(vardata)) DEALLOCATE(vardata)
        CALL netcdf_read(fname_tracer,varname,vardata)

        ii=0
        
        DO j=1,nlon
           DO k=1,nsig
              DO i=1,nlat
                 ii=ii+1
                 sendbuf(ii)=vardata(j,i,k,1,1)
              END DO
           END DO
        END DO

     ENDIF

     recvbuf=0.

     CALL mpi_scatterv(sendbuf,sendcounts,displs,mpi_real, &
          recvbuf,sendcounts(nproc),mpi_real,0,mpi_comm_world,iret)

     ii=0

     DO j=1,nx
        DO k=1,nsig
           DO i=1,nlat
              ii=ii+1
              aerosols(j,i,k,iii)=MAX(ug2kg*recvbuf(ii),&
                   &aerosol_concentration_minvalue)
           ENDDO
        ENDDO
     ENDDO
  ENDDO

!call load atm etc and run crtm

  IF (ALLOCATED(vardata)) DEALLOCATE(vardata)

  ALLOCATE(aod_nproc(nx,nlat,nchanl),wavelengths(nchanl))
  aod_nproc=0_r_single
  wavelengths=0_r_single

  IF (TRIM(upper2lower(model)) == 'aodcrtm') THEN
     CALL ufo_aodcrtm_simobs(nx,nlat,nsig,ts,sphum,prsl,prsi,&
          &aerosols,channels,conf_crtm,aod_nproc,wavelengths)
  ELSEIF (TRIM(upper2lower(model)) == 'aodluts') THEN
     CALL ufo_aodluts_simobs(nx,nlat,nsig,ts,sphum,prsl,prsi,&
          &aerosols,conf_luts,aod_nproc)
     wavelengths=conf_luts%wavelengths
  ELSE
     IF (nproc == 0) THEN 
        PRINT *,TRIM(model)//' model not implemented'
        CALL mpi_abort(mpi_comm_world,1002,iret)
     ENDIF
  ENDIF

!  maxlocs=MAXLOC(aod_nproc)
  
  DEALLOCATE(aerosols,prsl,prsi,ts,sphum,psfc)
  DEALLOCATE(ak,bk)

 
  DO j=0,numprocs-1
     sendcounts(j)=(jend(j)-jbegin(j)+1)*nlat*nchanl
  ENDDO

  displs(0)=0
  DO j=1,numprocs-1
     displs(j)=displs(j-1)+sendcounts(j-1)
  ENDDO

  IF (ALLOCATED(sendbuf)) DEALLOCATE(sendbuf)
  DEALLOCATE(recvbuf)
  
  ALLOCATE(sendbuf(sendcounts(nproc)))

  ii=0

  DO j=1,nx
     DO i=1,nlat
        DO k=1,nchanl
           ii=ii+1
           sendbuf(ii)=aod_nproc(j,i,k)
        ENDDO
     ENDDO
  ENDDO

  DEALLOCATE(aod_nproc)

  ALLOCATE(recvbuf(nlon*nlat*nchanl))
  recvbuf=0.
  
  CALL mpi_gatherv(sendbuf,sendcounts(nproc),mpi_real, &
       recvbuf,sendcounts,displs,mpi_real,0,mpi_comm_world,iret)
  
  IF (nproc == 0) THEN

!only if outputting aodlayers
!     ALLOCATE(aodlayers(nlon,nlat,nsig,nchanl,1))

     ALLOCATE(aod(nlon,nlat,nchanl,1))

     ii=0
     DO j=1,nlon
        DO i=1,nlat
           DO k=1,nchanl
              ii=ii+1
              aod(j,i,k,1)=recvbuf(ii)
           ENDDO
        ENDDO
     ENDDO

     DO k=1,nchanl
        PRINT *,'wavelength = ',wavelengths(k),'minval/maxval=',&
             &MINVAL(aod(:,:,k,1)),MAXVAL(aod(:,:,k,1))
     ENDDO

     CALL netcdf_write_fv3_aod(fname_aod,aod,wavelengths)
     
     DEALLOCATE(aod)

!     aodlayers=1.

!     CALL netcdf_write_fv3_aod_layers(fname_aod,aod,&
!          &aodlayers,wavelengths)

!     DEALLOCATE(aodlayers)

  ENDIF
  
  DEALLOCATE(sendbuf,recvbuf,sendcounts,jbegin,jend)

  CALL MPI_Barrier(MPI_COMM_WORLD,iret)

  CALL MPI_Finalize(iret)
  IF (iret .NE. 0) THEN
     PRINT *, 'MPI_Finalize error status = ',iret
  ELSE
     IF (nproc == 0)  WRITE(6,*) 'All done !!!'
  END IF

END PROGRAM gocart_aod_fv3_mpi
