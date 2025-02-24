MODULE module_m2

  USE netcdf
  USE module_netcdf_io
  USE module_constants

  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: read_m2_var,read_m2_akbk
  
CONTAINS
  
  SUBROUTINE read_m2_var(m2file,varname,varij)

    CHARACTER(len = max_varname_length), INTENT(in) :: varname
    CHARACTER(len = max_string_length), INTENT(in) :: m2file
    REAL, ALLOCATABLE, DIMENSION(:,:,:,:), INTENT(out) :: varij

    REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardata
    INTEGER :: i,j,ij,l,nx,ny,nxy

    CALL netcdf_read(m2file,varname,vardata)

    nx=SIZE(vardata,1)
    ny=SIZE(vardata,2)
    nxy=nx*ny
    

    ALLOCATE(varij(SIZE(vardata,1),SIZE(vardata,2),SIZE(vardata,3),&
         &SIZE(vardata,4)))

    varij=vardata(:,:,:,:,1)

    
  END SUBROUTINE read_m2_var

  SUBROUTINE read_m2_akbk(m2_akbk,ak,bk)
    
    CHARACTER(len = max_string_length), INTENT(in) :: m2_akbk
    REAL, ALLOCATABLE, DIMENSION(:), INTENT(out) :: ak,bk
    
    REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardata
    CHARACTER(len = max_varname_length) :: varname

    varname="AK"
    
    CALL netcdf_read(m2_akbk,varname,vardata)

    ALLOCATE(ak(SIZE(vardata,1)),bk(SIZE(vardata,1)))

    ak=vardata(:,1,1,1,1)

    varname="BK"

    CALL netcdf_read(m2_akbk,varname,vardata)

    bk=vardata(:,1,1,1,1)

  END SUBROUTINE read_m2_akbk

  
END MODULE module_m2

