MODULE module_fv3

!interpolate fv3 AOD to observations
!based on fv3pop, Ning Wang, March 2007

  USE netcdf
  USE module_netcdf_io
  USE module_utils
  USE module_constants

  IMPLICIT NONE
  
  INTEGER, PARAMETER :: ntiles=6
  CHARACTER(len=1), DIMENSION(ntiles), PARAMETER :: &
       &ctiles = ["1","2","3","4","5","6"]
  
  PRIVATE
  PUBLIC :: ntiles,filenames,read_fv3_grid,read_fv3_akbk,&
       &read_fv3_var,ctiles
  
CONTAINS
  
  SUBROUTINE filenames(input_grid_dir,fname_grid,gridfiles,&
       &input_fv3_dir,fname_fv3,fv3files)
    
    CHARACTER(len=max_string_length), INTENT(in) :: &
         &input_grid_dir,fname_grid,input_fv3_dir,fname_fv3
    CHARACTER(len=max_string_length), DIMENSION(ntiles), INTENT(inout) ::&
         &gridfiles,fv3files

    INTEGER :: i
 
    DO i=1,ntiles
       gridfiles(i)=TRIM(input_grid_dir)//'/'//&
            &replace_text(fname_grid,'?',ctiles(i))

       fv3files(i)=TRIM(input_fv3_dir)//'/'//&
            &replace_text(fname_fv3,'?',ctiles(i))
    ENDDO
    
  END SUBROUTINE filenames
  
  SUBROUTINE read_fv3_grid(gridfiles,griddata)

    CHARACTER(len = max_string_length), DIMENSION(ntiles), INTENT(in) :: &
         &gridfiles     
    REAL, ALLOCATABLE, DIMENSION(:,:), INTENT(out) :: griddata
    REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardatalon,vardatalat

    INTEGER :: i,j,ij,l,nx,ny,nxy,nxyg

    DO l=1,ntiles
       CALL netcdf_read(gridfiles(l),'grid_lont',vardatalon)
       CALL netcdf_read(gridfiles(l),'grid_latt',vardatalat)

       IF (l == 1) THEN
          nx=SIZE(vardatalat,1)
          ny=SIZE(vardatalat,2)
          nxy=nx*ny
          nxyg=ntiles*nxy
          ALLOCATE(griddata(nxyg,2))
       ENDIF

       ij=1
       DO j=1,ny
          DO i=1,nx
             griddata(ij+(l-1)*nxy,1) = vardatalat(i,j,1,1,1)*d2r
             griddata(ij+(l-1)*nxy,2) = vardatalon(i,j,1,1,1)*d2r
             ij=ij+1
          ENDDO
       END DO
    ENDDO

  END SUBROUTINE read_fv3_grid

  SUBROUTINE read_fv3_var(fv3files,varname,varij)

    CHARACTER(len = max_varname_length), INTENT(in) :: varname
    CHARACTER(len = max_string_length), DIMENSION(ntiles), INTENT(in) :: &
         &fv3files     
    REAL, ALLOCATABLE, DIMENSION(:,:,:,:), INTENT(out) :: varij

    REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardata
    INTEGER :: i,j,ij,l,nx,ny,nxy,nxyg

    DO l=1,ntiles

       CALL netcdf_read(fv3files(l),varname,vardata)

       IF (l == 1) THEN
          nx=SIZE(vardata,1)
          ny=SIZE(vardata,2)
          nxy=nx*ny
          nxyg=ntiles*nxy
          ALLOCATE(varij(nxyg,SIZE(vardata,3),SIZE(vardata,4),&
               &SIZE(vardata,5)))
       ENDIF

       ij=1
       DO j=1,ny
          DO i=1,nx
             varij(ij+(l-1)*nxy,:,:,:) = vardata(i,j,:,:,:)
             ij=ij+1
          ENDDO
       END DO

    ENDDO

  END SUBROUTINE read_fv3_var

  SUBROUTINE read_fv3_akbk(fv3_akbk,ak,bk)
    
    CHARACTER(len = max_string_length), INTENT(in) :: fv3_akbk
    REAL, ALLOCATABLE, DIMENSION(:), INTENT(out) :: ak,bk
    
    REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardata
    CHARACTER(len = max_varname_length) :: varname

    varname="ak"
    
    CALL netcdf_read(fv3_akbk,varname,vardata)

    ALLOCATE(ak(SIZE(vardata,1)),bk(SIZE(vardata,1)))

    ak=vardata(:,1,1,1,1)

    varname="bk"

    CALL netcdf_read(fv3_akbk,varname,vardata)

    bk=vardata(:,1,1,1,1)

  END SUBROUTINE read_fv3_akbk

  
END MODULE module_fv3

