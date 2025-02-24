PROGRAM viirs_lunar2aeronet

  USE module_constants, ONLY: pi, d2r,imissing

  USE module_viirs2aeronet_args, ONLY: viirs2aeronet_args,validtimestr,&
       &outfile
  USE module_viirs2ioda, ONLY: read_aeronet,read_viirsaod,&
       &write_viirs2aeronet
  USE module_generic_thinning, only: thinning_sphere_nn

  USE module_aeronet_vars, ONLY: aeronet_aod_output,viirs2aeronet_out

  USE module_viirs_vars, ONLY: viirs2aeronet_output_params,&
       &viirs_aod_input,num_nn,dphi_max,viirstdiff

  IMPLICIT NONE

  INTEGER :: i,j,k,n,ja(1)

  INTEGER, ALLOCATABLE :: viirs_index(:,:),ind(:)
  REAL, ALLOCATABLE :: grid1(:,:),grid2(:,:)
  REAL :: r,tdiff_v2a

  CONTINUE

  CALL viirs2aeronet_args 
  CALL viirs2aeronet_output_params
  CALL read_viirsaod_lunar
  CALL read_aeronet

  ALLOCATE(&
       &grid1(SIZE(viirs_aod_input(:)%lat),2),&
       &grid2(SIZE(aeronet_aod_output(:)%lat),2))

  grid1(:,1)=viirs_aod_input(:)%lat*d2r
  grid1(:,2)=viirs_aod_input(:)%lon*d2r

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
           viirs2aeronet_out(k)%value550_viirs=&
                &SUM(viirs_aod_input(ind)%value550)/REAL(j)
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

     CALL write_viirs2aeronet

     DEALLOCATE(viirs2aeronet_out)

  ELSE

     PRINT *,'No viirs2aero obs at time ',validtimestr,' for ',&
          &TRIM(outfile)

  ENDIF

END PROGRAM viirs_lunar2aeronet
