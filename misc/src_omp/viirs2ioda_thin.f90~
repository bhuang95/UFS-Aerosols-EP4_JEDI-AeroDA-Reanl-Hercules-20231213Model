module viirs2ioda_thin
contains
  subroutine in2out
    use viirs2ioda_vars, only: nobs, nobs_out, viirs_aod_input,&
                               viirs_aod_output,n_channels,tdiffout
    implicit none
    integer :: i
    nobs_out = nobs
    ALLOCATE(viirs_aod_output(nobs_out), tdiffout(nobs_out))
    do i=1,nobs_out
!      viirs_aod_output(i)%obstype=viirs_aod_input(i)%obstype
      viirs_aod_output(i)%values550=viirs_aod_input(i)%values550
      viirs_aod_output(i)%lat=viirs_aod_input(i)%lat
      viirs_aod_output(i)%lon=viirs_aod_input(i)%lon
      viirs_aod_output(i)%qcall=viirs_aod_input(i)%qcall
      viirs_aod_output(i)%bias=viirs_aod_input(i)%bias
      viirs_aod_output(i)%uncertainty=viirs_aod_input(i)%uncertainty
      viirs_aod_output(i)%stype=viirs_aod_input(i)%stype
    end do
  end subroutine in2out
  subroutine thin_fv3
    ! thin VIIRS data based off of provided FV3 grid
    use viirs2ioda_nc, only: read_fv3_grid
    use viirs2ioda_vars, only: fv3_gridfiles,ntiles_fv3,nobs,&
                               viirs_aod_input, pi, r2d, d2r, r_earth,&
                               thinning_grid_ratio_min,thinning_grid_ratio_max,&
                               nobs_out, viirs_aod_output, n_channels, tdiffout
    use kd_tree, only: init_kd_tree, close_kd_tree, knn_search_ts, knn_search
    use m_unirnk, only: unirnk
    implicit none
    real, allocatable, dimension(:,:) :: fv3griddata
    real, allocatable, dimension(:,:) :: grid1, grid2
    integer :: i,j,k,nx,nxy
    real :: dphi_max
    real, dimension(3) :: hp1,hp2
    integer :: num_nn, num_nn_found
    integer, dimension(:), allocatable :: nn,obsgrid,obsgrid_unique
    real, dimension(:), allocatable :: min_d

    ! read FV3 grid information
    call read_fv3_grid(fv3griddata,fv3_gridfiles)

    nxy = size(fv3griddata,2)
    nx=sqrt(real(nxy)/real(ntiles_fv3))

    allocate(grid1(nobs,2),grid2(nxy,2))

    grid1(:,1)=viirs_aod_input(:)%lat*d2r
    grid1(:,2)=viirs_aod_input(:)%lon*d2r
    where ((grid1(:,2) > pi)) grid1(:,2)=grid1(:,2)-2.*pi
    grid2(:,1)=fv3griddata(1,:)*d2r
    grid2(:,2)=fv3griddata(2,:)*d2r
    where ((grid2(:,2) > pi)) grid2(:,2)=grid2(:,2)-2.*pi

    ! note this is only doing spatial thinning, for temporal just don't use this file...
    dphi_max=2.*pi/(4.*REAL(nx))*thinning_grid_ratio_max
    hp1=0.
    hp2=0.
    !number of closest neighbors
    num_nn=1

    call init_kd_tree(grid1, nobs, num_nn)
    allocate(nn(num_nn),min_d(num_nn),obsgrid(nxy))
    obsgrid=0
    j=0
!$OMP PARALLEL DO DEFAULT (NONE) &
!$OMP SHARED (grid2,dphi_max,hp1,hp2,obsgrid,num_nn,nxy,j) &
!$OMP PRIVATE (nn,min_d,num_nn_found,i) 

    DO i=1,nxy
      CALL knn_search_ts(grid2(i,1:2),nn,min_d,hp1,hp2,1.0,num_nn,num_nn_found)
      IF ( num_nn_found > 0 .AND. MINVAL(min_d) < dphi_max ) THEN
!!$OMP ATOMIC UPDATE          
!$OMP CRITICAL
        j=j+1
        obsgrid(j)=nn(1)
!$OMP END CRITICAL

      ENDIF
    ENDDO
    call close_kd_tree()
    allocate(obsgrid_unique(j))
    CALL unirnk(obsgrid(1:j),obsgrid_unique,nobs_out)

    ALLOCATE(viirs_aod_output(nobs_out),tdiffout(nobs_out))

    DO i=1,nobs_out

       j = obsgrid(obsgrid_unique(i))
       viirs_aod_output(i)%values550=viirs_aod_input(j)%values550
       viirs_aod_output(i)%lat=viirs_aod_input(j)%lat
       viirs_aod_output(i)%lon=viirs_aod_input(j)%lon
       viirs_aod_output(i)%qcall=viirs_aod_input(j)%qcall
       viirs_aod_output(i)%bias=viirs_aod_input(j)%bias
       viirs_aod_output(i)%uncertainty=viirs_aod_input(j)%uncertainty
       viirs_aod_output(i)%stype=viirs_aod_input(j)%stype

    END DO

    DEALLOCATE(fv3griddata,grid1,grid2)
    if (allocated(obsgrid)) deallocate(obsgrid)
    if (allocated(obsgrid_unique)) deallocate(obsgrid_unique)
    print *, 'Retained ',nobs_out,' observations out of ',nobs
 
  end subroutine thin_fv3
end module viirs2ioda_thin
