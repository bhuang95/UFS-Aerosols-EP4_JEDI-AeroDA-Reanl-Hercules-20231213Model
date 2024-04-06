PROGRAM viirs2aeronet

  USE module_constants, ONLY: pi, d2r,imissing

  USE module_viirs2aeronet_args, ONLY: viirs2aeronet_args,&
       &seed,validtimestr,outfile
  USE module_viirs2ioda, ONLY: read_aeronet,read_viirsaod,&
       &write_viirs2aeronet
  USE module_generic_thinning, only: thinning_sphere_nn

  USE module_aeronet_vars, ONLY: aeronet_aod_output,viirs2aeronet_out,&
       &nmethods

  USE module_viirs_vars, ONLY: viirs2aeronet_output_params,&
       &viirs_aod_output,num_nn,dphi_max,viirstdiff,viirs_aod_max

  IMPLICIT NONE

  REAL, PARAMETER :: log_offset=0.01

  INTEGER :: i,j,k,l,n,ja(1)

  INTEGER, ALLOCATABLE :: viirs_index(:,:),ind(:)
  REAL, ALLOCATABLE :: grid1(:,:),grid2(:,:)
  REAL :: r,tdiff_v2a
  INTEGER, ALLOCATABLE :: seed_array(:)
  INTEGER :: seed_size,isample
  REAL :: random(10)

  CONTINUE

  CALL viirs2aeronet_args 
  CALL viirs2aeronet_output_params
  CALL read_viirsaod
  CALL read_aeronet

  ALLOCATE(&
       &grid1(SIZE(viirs_aod_output(:)%lat),2),&
       &grid2(SIZE(aeronet_aod_output(:)%lat),2))

  grid1(:,1)=viirs_aod_output(:)%lat*d2r
  grid1(:,2)=viirs_aod_output(:)%lon*d2r

  grid2(:,1)=aeronet_aod_output(:)%lat*d2r
  grid2(:,2)=aeronet_aod_output(:)%lon*d2r

  CALL thinning_sphere_nn(grid1,grid2,dphi_max,num_nn,viirs_index)

  DEALLOCATE(grid1,grid2)

  n=COUNT(viirs_index(:,1) /= imissing)

  IF (n > 0) THEN 
     ALLOCATE(viirs2aeronet_out(n))
     k=1

     DO i=1,SIZE(aeronet_aod_output(:)%lat)
        IF (ANY(viirs_index(i,:) == imissing)) THEN
           ja=MINLOC(viirs_index(i,:))-1
           j=ja(1)
        ELSE
           j=SIZE(viirs_index(i,:))
        ENDIF
        
        tdiff_v2a=viirstdiff-aeronet_aod_output(i)%tdiff

        IF (j > 0) THEN
           viirs2aeronet_out(k)%tdiff=aeronet_aod_output(i)%tdiff
           viirs2aeronet_out(k)%lat=aeronet_aod_output(i)%lat
           viirs2aeronet_out(k)%lon=aeronet_aod_output(i)%lon
           viirs2aeronet_out(k)%value550_aero=&
                &aeronet_aod_output(i)%value550
           ALLOCATE(ind(j))
           ind(:)=viirs_index(i,1:j)
           viirs2aeronet_out(k)%value550_viirs(1)=&
                viirs_aod_output(ind(1))%value550
           viirs2aeronet_out(k)%value550_viirs(2)=&
                   &SUM(viirs_aod_output(ind)%value550)/REAL(j)
           viirs2aeronet_out(k)%value550_viirs(3)=&
                   &EXP(SUM&
                   &(LOG(viirs_aod_output(ind)%value550+log_offset))/&
                   &REAL(j))-log_offset
           CALL RANDOM_SEED(size=seed_size)
           IF (ALLOCATED(seed_array)) DEALLOCATE(seed_array)
           ALLOCATE(seed_array(1:seed_size))
           seed_array=seed
           CALL RANDOM_SEED(put=seed_array(1:seed_size))
           CALL RANDOM_NUMBER(random)
           isample=MAX(NINT(random(5)*REAL(j)),1)
           viirs2aeronet_out(k)%value550_viirs(4)=&
                &viirs_aod_output(ind(isample))%value550

           DEALLOCATE(ind)

           r=REAL(j)/REAL(num_nn)

           viirs2aeronet_out(k)%coverage_ratio=r
           viirs2aeronet_out(k)%station_id=&
                &aeronet_aod_output(i)%station_id
           viirs2aeronet_out(k)%stype=aeronet_aod_output(i)%stype
           viirs2aeronet_out(k)%tdiff_v2a=tdiff_v2a

           k=k+1
 
        ENDIF

     ENDDO

     DO i=1,nmethods

        IF (ANY(viirs2aeronet_out(:)%value550_viirs(1) > viirs_aod_max)) &
             &PRINT *,"Out of range value550_viirs(1) on ",validtimestr
        WHERE(viirs2aeronet_out(:)%value550_viirs(1) > viirs_aod_max) &
             &viirs2aeronet_out(:)%value550_viirs(1)=viirs_aod_max+0.1
     
        IF (ANY(viirs2aeronet_out(:)%value550_viirs(2) > viirs_aod_max)) &
             &PRINT *,"Out of range value550_viirs(2) on ",validtimestr
        WHERE(viirs2aeronet_out(:)%value550_viirs(2) > viirs_aod_max) &
             &viirs2aeronet_out(:)%value550_viirs(2)=viirs_aod_max+0.1
        
        IF (ANY(viirs2aeronet_out(:)%value550_viirs(3) > viirs_aod_max)) &
             &PRINT *,"Out of range value550_viirs(3) on ",validtimestr
        WHERE(viirs2aeronet_out(:)%value550_viirs(3) > viirs_aod_max) &
             &viirs2aeronet_out(:)%value550_viirs(3)=viirs_aod_max+0.1
     
        IF (ANY(viirs2aeronet_out(:)%value550_viirs(4) > viirs_aod_max)) &
             &PRINT *,"Out of range value550_viirs(4) on ",validtimestr
        WHERE(viirs2aeronet_out(:)%value550_viirs(4) > viirs_aod_max) &
             &viirs2aeronet_out(:)%value550_viirs(4)=viirs_aod_max+0.1


     ENDDO

     CALL write_viirs2aeronet

     DEALLOCATE(viirs2aeronet_out)

  ELSE

     PRINT *,'No viirs2aero obs at time ',validtimestr,' for ',&
          &TRIM(outfile)

  ENDIF

END PROGRAM viirs2aeronet
