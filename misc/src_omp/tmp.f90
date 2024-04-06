
  SUBROUTINE read_fv3_grid(griddata,grid_files)

    USE module_constants, ONLY: ntiles_fv3

    IMPLICIT NONE

    INTEGER, PARAMETER :: &
         &max_name_length_fv3=NF90_MAX_NAME, max_dims_fv3=4, max_vars_fv3=100
    REAL, ALLOCATABLE, DIMENSION(:,:), INTENT(out) :: griddata
    CHARACTER(len = max_name_length_fv3), DIMENSION(ntiles_fv3) :: grid_files

    INTEGER, DIMENSION(max_dims_fv3) :: dimids,dims
    CHARACTER(len = max_name_length_fv3) :: input_file

    REAL, ALLOCATABLE, DIMENSION(:,:,:) :: tmpdata
    INTEGER :: ncid,status,varid_lon,varid_lat,numdims,i,j,l,ij
    CHARACTER(len = max_name_length_fv3) :: aname
    INTEGER :: nx, ny, nxy, nxyg
    CHARACTER(len = max_name_length_fv3), PARAMETER :: &
         &varname_lon_fv3='grid_lont',varname_lat_fv3='grid_latt'

    input_file=TRIM(grid_files(1))

    CALL check_nc(nf90_open(input_file, nf90_nowrite, ncid))
    CALL check_nc(nf90_inq_varid(ncid, varname_lon_fv3, varid_lon))
    CALL check_nc(nf90_inquire_variable(ncid, varid_lon, aname, ndims=numdims))
    CALL check_nc(nf90_inquire_variable(ncid, varid_lon, dimids = dimids(:numdims)))
    CALL check_nc(nf90_inq_varid(ncid, varname_lat_fv3, varid_lat))

    dims=1

    DO i=1,numdims
       CALL check_nc(nf90_inquire_dimension(ncid,dimids(i),len=dims(i)))
    END DO

    nx=dims(1)
    ny=dims(2)
    nxy=nx*ny
    nxyg=ntiles_fv3*nxy
    ALLOCATE(tmpdata(nx,ny,2),griddata(2,nxyg))

    CALL check_nc(nf90_close(ncid))

    DO l=1,ntiles_fv3
       input_file=TRIM(grid_files(l))
       CALL check_nc(nf90_open(input_file, nf90_nowrite, ncid))
       CALL check_nc(nf90_get_var(ncid,varid_lat,tmpdata(:,:,1), &
            start = (/ 1, 1 /), &
            count = (/ nx, ny /) ))
       CALL check_nc(nf90_get_var(ncid,varid_lon,tmpdata(:,:,2), &
            start = (/ 1, 1 /), &
            count = (/ nx, ny /) ))
       CALL check_nc(nf90_close(ncid))
       ij=1
       DO j=1,ny
          DO i=1,nx
             griddata(:,ij+(l-1)*nxy) = tmpdata(i,j,:)
             ij=ij+1
          END DO
       END DO
    END DO

    DEALLOCATE(tmpdata)

  END SUBROUTINE read_fv3_grid

