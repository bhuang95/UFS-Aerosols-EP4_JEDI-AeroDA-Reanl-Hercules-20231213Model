PROGRAM calc_gas_col_integrals

!integrate co column vertically from ppmv output
!mzp july, 2020
  
  USE module_constants
  USE module_fv3
  USE module_netcdf_io
  USE module_utils

  IMPLICIT NONE

  REAL, PARAMETER :: ppmv_factor=1.e-6

  CHARACTER(len=10) :: date

  CHARACTER(len=max_string_length) :: &
       &input_fv3_dir,fname_fv3_core,fname_fv3_tracer,&
       &output_dir,fname_column

  CHARACTER(len=max_string_length), DIMENSION(ntiles) :: fv3files

  CHARACTER(len = max_varname_length) :: varlist(nvarmax)
  REAL :: mol_weights(nvarmax)

  CHARACTER(len = max_varname_length) :: varname
  CHARACTER(len = max_varname_length), ALLOCATABLE :: varnames(:)

  REAL, ALLOCATABLE, DIMENSION(:,:,:,:,:) :: vardata

  REAL, ALLOCATABLE :: delp(:,:,:,:,:)

  LOGICAL :: isfile

  INTEGER :: nx,ny,nz,nt,nvars,nzp
  INTEGER :: i,j,k,l,ivar
  INTEGER :: year,month,day,hour

  NAMELIST /record_input/ date,input_fv3_dir,&
       &fname_fv3_tracer,fname_fv3_core,&
       &varlist,mol_weights
  NAMELIST /record_output/ output_dir,fname_column

  varlist=""

  INQUIRE(file='calc_gas_col_integrals.nl', exist=isfile)
  IF ( isfile ) THEN
     OPEN(unit=98, file='calc_gas_col_integrals.nl', &
          form='formatted', status='old', action='read')
     READ(98, record_input)
     READ(98, record_output)
     CLOSE(98)
  ELSE
     PRINT *,'Missing namelist calc_gas_col_integrals.nl'
     STOP(1)
  ENDIF

  nvars=COUNT(varlist /= "")
  varnames=varlist(:nvars)

  DO l=1,ntiles
  
     fv3files(l)=TRIM(input_fv3_dir)//'/'//&
          &replace_text(fname_fv3_core,'?',ctiles(l))


     varname='delp'
     CALL netcdf_read(fv3files(l),varname,vardata)

     nx=SIZE(vardata,1)
     ny=SIZE(vardata,2)
     nz=SIZE(vardata,3)
     nt=SIZE(vardata,4)

     IF (.NOT. ALLOCATED(delp)) ALLOCATE(delp(nx,ny,nz,nt,1))
     delp=vardata

     fv3files(l)=TRIM(input_fv3_dir)//'/'//&
          &replace_text(fname_fv3_tracer,'?',ctiles(l))

     varname='sphum'
     CALL netcdf_read(fv3files(l),varname,vardata)

     delp(i,j,:,nt,1)=delp(i,j,:,nt,1)/(1.+rv_rd*&
          &vardata(i,j,:,nt,1)/(1.-vardata(i,j,:,nt,1)))
     
     DO ivar=1,nvars
        varname=varnames(ivar)
        CALL netcdf_read(fv3files(l),varname,vardata)
        vardata=ppmv_factor*delp/grav*&
        &mol_weights(ivar)/mol_weight_air*vardata
        vardata(:,:,1,:,:)=SUM(vardata(:,:,:,:,:),dim=3)
        PRINT *,MINVAL(vardata(:,:,1,:,:)),MAXVAL(vardata(:,:,1,:,:))
!             CALL netcdf_write(fv3files(l),varname,vardata)
     ENDDO

  ENDDO

  IF (ALLOCATED(delp)) DEALLOCATE(delp)
  IF (ALLOCATED(vardata)) DEALLOCATE(vardata)

END PROGRAM calc_gas_col_integrals
  
