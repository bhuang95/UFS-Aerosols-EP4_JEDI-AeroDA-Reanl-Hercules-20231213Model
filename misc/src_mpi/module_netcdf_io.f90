MODULE module_netcdf_io

  USE netcdf
  USE module_kinds
  USE module_constants, ONLY: max_varname_length,max_string_length,&
       &date_string_length

  USE module_utils, ONLY: upper2lower,lower2upper

  IMPLICIT NONE

  PRIVATE
  PUBLIC :: ndims_max
  PUBLIC :: netcdf_read,netcdf_read_strings,&
       &netcdf_write_fv3_aod,netcdf_write_fv3_aod_layers,&
       &netcdf_write_fv3_aod4hofx,netcdf_write_ioda_hofx,&
       &netcdf_write_generic_pll,netcdf_write_generic_ll,&
       &netcdf_write_fv3aodll,netcdf_write_fv3_concentration,handle_err

  INTEGER, PARAMETER :: ndims_max=5

CONTAINS
  
  SUBROUTINE netcdf_read_strings(fnamein,varname,vardata)

    IMPLICIT NONE

    CHARACTER(len=*), INTENT(in)    :: varname
    CHARACTER(len=*), INTENT(in)    :: fnamein
    CHARACTER(len=*), ALLOCATABLE, INTENT(out)      :: vardata(:)
    INTEGER                         :: ncid,varid,status,ndims
    INTEGER                         :: dimids(1:ndims_max),dims(1:ndims_max)
    INTEGER :: i,n

    dims=1

    status = nf90_open(fnamein, nf90_nowrite, ncid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'0 ',ncid,TRIM(fnamein)
       CALL handle_err(status)
    ENDIF

    status = nf90_inq_varid(ncid,TRIM(varname),varid)
    IF (status /= nf90_noerr ) THEN 
       PRINT *,'1 ',TRIM(varname)
       CALL handle_err(status)
    ENDIF

    status = nf90_inquire_variable(ncid, varid, ndims=ndims)
    status = nf90_inquire_variable(ncid, varid, dimids=dimids(:ndims))    
    IF (status /= nf90_noerr ) THEN
       PRINT *,'2 ',varid
       CALL handle_err(status)
    ENDIF

    DO i=1,ndims
       status = nf90_inquire_dimension(ncid,dimids(i),len=dims(i))
       IF (status /= nf90_noerr ) THEN
          PRINT *,'3 ',i,dims(i)
          CALL handle_err(status)
       ENDIF
    ENDDO

    ALLOCATE(vardata(dims(2)))

    status = nf90_get_var(ncid,varid,vardata)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'4 ',varid
       CALL handle_err(status)
    ENDIF

    status = nf90_close(ncid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'5 ',ncid,TRIM(fnamein)
       CALL handle_err(status)
    ENDIF

  END SUBROUTINE netcdf_read_strings

  SUBROUTINE netcdf_read(fnamein,varnamein,vardata,dim2reverse)

    IMPLICIT NONE
    
    CHARACTER(len=*), INTENT(in)    :: varnamein
    CHARACTER(len=*), INTENT(in)    :: fnamein
    REAL(SINGLE), ALLOCATABLE, INTENT(out)      :: vardata(:,:,:,:,:)
    INTEGER, INTENT(in), OPTIONAL               :: dim2reverse

    INTEGER                         :: ncid,varid,status,ndims
    INTEGER                         :: dimids(1:ndims_max),dims(1:ndims_max)
    REAL(SINGLE), ALLOCATABLE       :: tmp(:,:,:,:,:)
    
    INTEGER :: i,n,attnum
    REAL(SINGLE) :: scale_factor,add_offset
    CHARACTER(len=max_varname_length) :: varname


    dims=1

    status = nf90_open(fnamein, nf90_nowrite, ncid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'0 ',ncid,TRIM(fnamein)
       CALL handle_err(status)
    ENDIF

    varname=varnamein

    status = nf90_inq_varid(ncid,TRIM(varname),varid)
    IF (status /= nf90_noerr ) THEN
       varname=upper2lower(varname)
       status = nf90_inq_varid(ncid,TRIM(varname),varid)
       IF (status /= nf90_noerr ) THEN
          varname=lower2upper(varname)
          status = nf90_inq_varid(ncid,TRIM(varname),varid)
          IF (status /= nf90_noerr ) THEN
             PRINT *,'1 ',TRIM(varname)
             status = nf90_inq_varid(ncid,TRIM(varname),varid)
             CALL handle_err(status)
          ENDIF
       ENDIF
    ENDIF

    status = nf90_inquire_variable(ncid, varid, ndims=ndims)
    status = nf90_inquire_variable(ncid, varid, dimids=dimids(:ndims))    
    IF (status /= nf90_noerr ) THEN
       PRINT *,'3 ',varid
       CALL handle_err(status)
    ENDIF

    DO i=1,ndims
       status = nf90_inquire_dimension(ncid,dimids(i),len=dims(i))
       IF (status /= nf90_noerr ) THEN
          PRINT *,'4 ',i,dims(i)
          CALL handle_err(status)
       ENDIF
    ENDDO

!always convert all vars to real     

    IF (ALLOCATED(vardata)) DEALLOCATE(vardata)

    ALLOCATE(vardata(dims(1),dims(2),dims(3),dims(4),dims(5)),&
         &tmp(dims(1),dims(2),dims(3),dims(4),dims(5)))

    status = nf90_get_var(ncid,varid,tmp)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'5 ',varid
       CALL handle_err(status)
    ENDIF

    scale_factor=1.
    add_offset=0.

    status =  nf90_inquire_attribute(ncid, varid, 'scale_factor')
    IF (status  == nf90_noerr ) THEN
       status = nf90_get_att(ncid, varid, 'scale_factor', scale_factor)
       IF (status /= nf90_noerr ) THEN
          PRINT *,'5.1',varid,attnum
          CALL handle_err(status)
       ENDIF
    ENDIF

    status =  nf90_inquire_attribute(ncid, varid, 'add_offset')
    IF (status  == nf90_noerr ) THEN
       status = nf90_get_att(ncid, varid, 'add_offset', add_offset)
       IF (status /= nf90_noerr ) THEN
          PRINT *,'5.2',varid,attnum
          CALL handle_err(status)
       ENDIF
    ENDIF

    status = nf90_close(ncid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'6 ',ncid,TRIM(fnamein)
       CALL handle_err(status)
    ENDIF

    IF (PRESENT(dim2reverse)) THEN
       IF (dim2reverse > ndims) THEN
          PRINT *,'Stopping: dimension to reverse larger than max dimension number'
          STOP 1
       ELSE
          DO i=1,ndims
             IF (i == dim2reverse) THEN 
                n=SIZE(vardata,i)
                SELECT CASE (i)
                CASE (1)
                   vardata=tmp(n:1:-1,:,:,:,:)*scale_factor+add_offset
                CASE (2)
                   vardata=tmp(:,n:1:-1,:,:,:)*scale_factor+add_offset
                CASE (3)
                   vardata=tmp(:,:,n:1:-1,:,:)*scale_factor+add_offset
                CASE (4)
                   vardata=tmp(:,:,:,n:1:-1,:)*scale_factor+add_offset
                CASE (5)
                   vardata=tmp(:,:,:,:,n:1:-1)*scale_factor+add_offset
                END SELECT
             ENDIF
          ENDDO
       ENDIF
    ELSE
       vardata=tmp*scale_factor+add_offset
    ENDIF

    DEALLOCATE(tmp)

  END SUBROUTINE netcdf_read

  SUBROUTINE netcdf_write_fv3_aod_layers(fnameout,aodsfc,&
       &aodlayers,channels)

    IMPLICIT NONE
    
    CHARACTER(len=*), INTENT(in)    :: fnameout
    REAL(SINGLE), INTENT(in)      :: aodsfc(:,:,:,:),aodlayers(:,:,:,:,:),channels(:)

    INTEGER                         :: mcid,aodsfcid,aodlayersid,channelsid,status
    INTEGER                         :: dimids(1:ndims_max),dims(1:ndims_max)
    CHARACTER(len=max_varname_length), PARAMETER    :: dimstring(1:ndims_max)=&
         &(/'xaxis_1','yaxis_1','zaxis_1','nchannels','time'/)

    CHARACTER(len=max_varname_length) :: attname,attvalue

    INTEGER :: i

    PRINT *,'in netcdf_write_fv3_aod'

    status = nf90_create(fnameout, nf90_write, mcid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'0 ',mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    DO i=1,ndims_max-1
       status = nf90_def_dim(mcid,dimstring(i),SIZE(aodlayers,i),dimids(i))
       IF (status /= nf90_noerr) THEN
          PRINT *,'1 ',dimids(i),TRIM(dimstring(i))
          CALL handle_err(status)
       ENDIF
    ENDDO

    i=ndims_max
    status = nf90_def_dim(mcid,dimstring(i),NF90_UNLIMITED,dimids(i))
    IF (status /= nf90_noerr) THEN
       PRINT *,'1 ',dimids(i),TRIM(dimstring(i))
       CALL handle_err(status)
    ENDIF
    
    i=ndims_max-1

    status = nf90_def_var(mcid,'channels',NF90_REAL,dimids(i),channelsid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'2 ',dimids(i),TRIM(dimstring(i))
       CALL handle_err(status)
    ENDIF
    
    attname="units"
    attvalue="nm"
    status = nf90_put_att(mcid, channelsid, TRIM(attname),attvalue)
    IF (status /= nf90_noerr) THEN 
       PRINT *,'3 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    status = nf90_def_var(mcid,'aod',NF90_REAL,(/dimids(1:2),dimids(4:5)/),aodsfcid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'4 ','aod',aodsfcid
       CALL handle_err(status)
    ENDIF
    
    attname="units"
    attvalue=""
    status = nf90_put_att(mcid, aodsfcid, TRIM(attname),attvalue)
    IF (status /= nf90_noerr) THEN
       PRINT *,'5 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    status = nf90_def_var(mcid,'aod_layers',NF90_REAL,dimids,aodlayersid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'6 ','aod_layers',aodlayersid
       CALL handle_err(status)
    ENDIF
    
    attname="units"
    attvalue=""
    status = nf90_put_att(mcid, aodlayersid, TRIM(attname),attvalue)
    IF (status /= nf90_noerr) THEN
       PRINT *,'7 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    status = nf90_enddef(mcid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'8 ',mcid
       CALL handle_err(status)
    ENDIF

    status = nf90_put_var(mcid,channelsid,channels)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'9 ',channelsid,channels
       CALL handle_err(status)
    ENDIF

    status = nf90_put_var(mcid,aodsfcid,aodsfc)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'10 ',aodsfcid,MINVAL(aodsfc),MAXVAL(aodsfc)
       CALL handle_err(status)
    ENDIF

    status = nf90_put_var(mcid,aodlayersid,aodlayers)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'11 ',aodlayersid,MINVAL(aodlayers),MAXVAL(aodlayers)
       CALL handle_err(status)
    ENDIF

    status = nf90_close(mcid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'12 ',mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

  END SUBROUTINE    netcdf_write_fv3_aod_layers

  SUBROUTINE netcdf_write_fv3_aod(fnameout,aodsfc,channels)

    IMPLICIT NONE
    
    INTEGER, PARAMETER :: ndims_aod_output=ndims_max-1

    CHARACTER(len=*), INTENT(in)    :: fnameout
    REAL(SINGLE), INTENT(in)      :: aodsfc(:,:,:,:),channels(:)

    INTEGER                         :: mcid,aodsfcid,channelsid,status
    INTEGER                         :: dimids(1:ndims_aod_output),&
         &dims(1:ndims_aod_output)
    CHARACTER(len=max_varname_length), PARAMETER    :: dimstring(1:ndims_aod_output)=&
         &(/'xaxis_1','yaxis_1','nchannels','time'/)

    CHARACTER(len=max_varname_length) :: attname,attvalue

    INTEGER :: i

    PRINT *,'in netcdf_write_fv3_aod'

    status = nf90_create(fnameout, nf90_write, mcid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'0 ',mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    DO i=1,ndims_aod_output-1
       status = nf90_def_dim(mcid,dimstring(i),SIZE(aodsfc,i),dimids(i))
       IF (status /= nf90_noerr) THEN
          PRINT *,'1 ',dimids(i),TRIM(dimstring(i))
          CALL handle_err(status)
       ENDIF
    ENDDO

    i=ndims_aod_output
    status = nf90_def_dim(mcid,dimstring(i),NF90_UNLIMITED,dimids(i))
    IF (status /= nf90_noerr) THEN
       PRINT *,'1 ',dimids(i),TRIM(dimstring(i))
       CALL handle_err(status)
    ENDIF
    
    i=ndims_aod_output-1

    status = nf90_def_var(mcid,'channels',NF90_REAL,dimids(i),channelsid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'2 ',dimids(i),TRIM(dimstring(i))
       CALL handle_err(status)
    ENDIF
    
    attname="units"
    attvalue="nm"
    status = nf90_put_att(mcid, channelsid, TRIM(attname),attvalue)
    IF (status /= nf90_noerr) THEN 
       PRINT *,'3 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    status = nf90_def_var(mcid,'aod',NF90_REAL,(/dimids(1:2),dimids(3:4)/),aodsfcid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'4 ','aod',aodsfcid
       CALL handle_err(status)
    ENDIF
    
    attname="units"
    attvalue=""
    status = nf90_put_att(mcid, aodsfcid, TRIM(attname),attvalue)
    IF (status /= nf90_noerr) THEN
       PRINT *,'5 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    status = nf90_enddef(mcid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'8 ',mcid
       CALL handle_err(status)
    ENDIF

    status = nf90_put_var(mcid,channelsid,channels)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'9 ',channelsid,channels
       CALL handle_err(status)
    ENDIF

    status = nf90_put_var(mcid,aodsfcid,aodsfc)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'10 ',aodsfcid,MINVAL(aodsfc),MAXVAL(aodsfc)
       CALL handle_err(status)
    ENDIF

    status = nf90_close(mcid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'11 ',mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

  END SUBROUTINE    netcdf_write_fv3_aod

  SUBROUTINE netcdf_write_fv3_aod4hofx(fnameout,aodsfc,channel)

    IMPLICIT NONE
    
    INTEGER, PARAMETER :: ndims_aod_output=3

    CHARACTER(len=*), INTENT(in)    :: fnameout
    REAL(SINGLE), INTENT(in)      :: aodsfc(:,:,:,:),channel

    INTEGER                         :: mcid,aodsfcid,timeid,chid,status
    INTEGER                         :: dimids(1:ndims_aod_output),&
         &dims(1:ndims_aod_output)
    
    CHARACTER(len=max_varname_length), PARAMETER    :: &
         &dimstring(1:ndims_aod_output)=(/'xaxis_1','yaxis_1','Time'/)

    INTEGER                         :: dimchid,dimch

    CHARACTER(len=max_varname_length), PARAMETER    :: dimchstring=&
         &'channels'

    CHARACTER(len=max_varname_length) :: attname,attvalue

    INTEGER :: i

    status = nf90_create(fnameout, nf90_write, mcid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'0 ',mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    DO i=1,ndims_aod_output-1
       status = nf90_def_dim(mcid,dimstring(i),SIZE(aodsfc,i),dimids(i))
       IF (status /= nf90_noerr) THEN
          PRINT *,'1 ',dimids(i),TRIM(dimstring(i))
          CALL handle_err(status)
       ENDIF
    ENDDO

    i=ndims_aod_output
    status = nf90_def_dim(mcid,dimstring(i),NF90_UNLIMITED,dimids(i))
    IF (status /= nf90_noerr) THEN
       PRINT *,'1 ',dimids(i),TRIM(dimstring(i))
       CALL handle_err(status)
    ENDIF

    status = nf90_def_dim(mcid,dimchstring,1,dimchid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'1 ',dimchid,TRIM(dimchstring)
       CALL handle_err(status)
    ENDIF

    status = nf90_def_var(mcid,'Time',NF90_REAL,(/dimids(3:3)/),timeid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'2 ','Time',timeid
       CALL handle_err(status)
    ENDIF

    attname="long_name"
    attvalue="Time"
    status = nf90_put_att(mcid, timeid, TRIM(attname),attvalue)
    IF (status /= nf90_noerr) THEN
       PRINT *,'3 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    attname="units"
    attvalue="time level"
    status = nf90_put_att(mcid, timeid, TRIM(attname),attvalue)
    IF (status /= nf90_noerr) THEN
       PRINT *,'4 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    attname="cartesian_axis"
    attvalue="T"
    status = nf90_put_att(mcid, timeid, TRIM(attname),attvalue)
    IF (status /= nf90_noerr) THEN
       PRINT *,'5 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    status = nf90_def_var(mcid,'channels',NF90_REAL,dimchid,chid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'2 ','channels',chid
       CALL handle_err(status)
    ENDIF

    status = nf90_def_var(mcid,'aod',NF90_REAL,(/dimids(1:3)/),aodsfcid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'4 ','aod',aodsfcid
       CALL handle_err(status)
    ENDIF
    
    attname="units"
    attvalue=""
    status = nf90_put_att(mcid, aodsfcid, TRIM(attname),attvalue)
    IF (status /= nf90_noerr) THEN
       PRINT *,'5 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    attname="wavelength_in_nm"
    status = nf90_put_att(mcid,aodsfcid,TRIM(attname),channel)
    IF (status /= nf90_noerr) THEN 
       PRINT *,'3 ',TRIM(attname),attvalue
       CALL handle_err(status)
    ENDIF

    status = nf90_enddef(mcid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'8 ',mcid
       CALL handle_err(status)
    ENDIF

    status = nf90_put_var(mcid,timeid,1.)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'10 ',timeid
       CALL handle_err(status)
    ENDIF

    status = nf90_put_var(mcid,aodsfcid,aodsfc)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'10 ',aodsfcid,MINVAL(aodsfc),MAXVAL(aodsfc)
       CALL handle_err(status)
    ENDIF

    status = nf90_put_var(mcid,chid,channel)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'10 ',chid
       CALL handle_err(status)
    ENDIF

    status = nf90_close(mcid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'11 ',mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

  END SUBROUTINE    netcdf_write_fv3_aod4hofx


!@end

  SUBROUTINE netcdf_write_ioda_hofx(fnameout,hofx)

!writes out only channel 4 for viirs

    IMPLICIT NONE
    
    CHARACTER(len=*), INTENT(in)    :: fnameout
    REAL(SINGLE), DIMENSION(:), INTENT(inout)      :: hofx

    INTEGER                         :: mcid,varid,hofxid,status
    INTEGER                         :: dimids(1:ndims_max),&
         &dims(1:ndims_max)

    CHARACTER(len=max_varname_length) :: varname

    INTEGER :: i,ndims

    PRINT *,'in netcdf_write_ioda_hofx'

    status = nf90_open(fnameout, nf90_write, mcid)
    IF (status /= nf90_noerr) THEN
       PRINT *,'0 ',mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    varname="aerosol_optical_depth_4@ObsValue"

    status = nf90_inq_varid(mcid,TRIM(varname),varid)
    IF (status /= nf90_noerr ) THEN 
       PRINT *,'1 ',TRIM(varname)
       CALL handle_err(status)
    ENDIF

    status = nf90_inquire_variable(mcid, varid, ndims=ndims)

    IF (ndims /= 1) &
         &PRINT *,'dimension mismatch for nobs, ndims = ',ndims

    status = nf90_inquire_variable(mcid, varid, dimids=dimids(:ndims))    
    IF (status /= nf90_noerr ) THEN
       PRINT *,'2 ',varid
       CALL handle_err(status)
    ENDIF

    DO i=1,ndims
       status = nf90_inquire_dimension(mcid,dimids(i),len=dims(i))
       IF (status /= nf90_noerr ) THEN
          PRINT *,'3 ',i,dims(i)
          CALL handle_err(status)
       ENDIF
    ENDDO

    varname="aerosol_optical_depth_4@Hofx"

    status = nf90_inq_varid(mcid,TRIM(varname),hofxid)
    IF (status == nf90_noerr ) THEN 
       PRINT *,TRIM(varname)//' already present - overwriting with new values'
       CONTINUE
    ELSE
       status = nf90_redef(mcid)
       IF (status /= nf90_noerr) THEN
          PRINT *,'4 ',varname,dimids(1),hofxid
          CALL handle_err(status)
       ENDIF
       
       status = nf90_def_var(mcid,varname,NF90_REAL,(/dimids(1)/),hofxid)
       IF (status /= nf90_noerr) THEN
          PRINT *,'5 ',varname,dimids(1),hofxid
          CALL handle_err(status)
       ENDIF
       
       status = nf90_enddef(mcid)
       IF (status /= nf90_noerr ) THEN
          PRINT *,'6 ',mcid
          CALL handle_err(status)
       ENDIF
    ENDIF

    status = nf90_put_var(mcid,hofxid,hofx)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'7 ',varname,hofxid
       CALL handle_err(status)
    ENDIF

    status = nf90_close(mcid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'8 ',mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

  END SUBROUTINE netcdf_write_ioda_hofx
  
  SUBROUTINE netcdf_write_generic_pll(init,fnameout,lon,lat,plev,&
       &datestrings,varname,vardata)

    LOGICAL, INTENT(in)    :: init
    CHARACTER(len=*), INTENT(in)    :: fnameout
    REAL, INTENT(in), OPTIONAL :: lon(:),lat(:),plev(:)
    CHARACTER(len=*), DIMENSION(:), INTENT(in), OPTIONAL :: datestrings
    CHARACTER(len=*), INTENT(in), OPTIONAL :: varname
    REAL, INTENT(in), OPTIONAL :: vardata(:,:,:,:)
    
    INTEGER, PARAMETER :: ndims=4
    INTEGER, SAVE :: nlon, nlat, nplev, nt
    INTEGER, SAVE :: dimids(ndims)
    
    CONTINUE

    IF (PRESENT(lon)) nlon = SIZE(lon)
    IF (PRESENT(lat)) nlat = SIZE(lat)
    IF (PRESENT(plev)) nplev = SIZE(plev)
    IF (PRESENT(vardata)) nt = SIZE(vardata,4)

    IF (init) THEN
       IF (.NOT. PRESENT(datestrings) .OR. .NOT. PRESENT(lon) .OR. &
            &.NOT. PRESENT(lat) .OR. .NOT. PRESENT(plev))  THEN
          PRINT *,'date string and dimensions needs to be present &
               &for init=.TRUE.'
          STOP 1
       ENDIF
       CALL netcdf_init_filepll(fnameout,lon,lat,plev,datestrings)
    ELSE
       CALL netcdf_writevar_filepll(fnameout,varname,vardata)
    ENDIF

  CONTAINS
    
    SUBROUTINE netcdf_init_filepll(fnameout,lon,lat,plev,datestrings)

      CHARACTER(len=*), INTENT(in)    :: fnameout
      REAL, INTENT(in) :: lon(:),lat(:),plev(:)
      CHARACTER(len=*), DIMENSION(:), INTENT(in)    :: datestrings

      INTEGER :: mcid,lonvar_id,lon_id,lat_id,lev_id,tm_id,&
           &timestr_id,&
           &latvar_id,levvar_id,tmvar_id,dtvar_id,status

      CHARACTER(len = max_varname_length) :: attname,attvalue
      CHARACTER(len = 8) :: date
      INTEGER :: i,nt
      REAL, ALLOCATABLE :: minutes(:)

      nt=SIZE(datestrings)
      
      ALLOCATE(minutes(nt))

      IF (nt == 1) THEN
         minutes=0.
      ELSE
         minutes=[(24./nt*60.*(i-1),i=1,nt)]
      ENDIF

      status = nf90_create(fnameout,cmode=nf90_clobber,ncid=mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'0 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'lon',nlon,lon_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'lat',nlat,lat_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'2 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'lev',nplev,lev_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'time',NF90_UNLIMITED,tm_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'4 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'timestr',date_string_length,timestr_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'4.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      dimids=(/lon_id, lat_id, lev_id, tm_id/)

      status = nf90_def_var(mcid,'lat',NF90_REAL,&
           &(/lat_id/),latvar_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'5 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,'lon',NF90_REAL,&
           &(/lon_id/),lonvar_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'6 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      status = nf90_def_var(mcid,'lev',NF90_REAL,&
           &(/lev_id/),levvar_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,'time',NF90_REAL,&
           &(/tm_id/),tmvar_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvalue="minutes since "//datestrings(1)(1:10)//' '//&
           &datestrings(1)(12:19)
      status = nf90_put_att(mcid, tmvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.2 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="long_name"
      attvalue="time"
      status = nf90_put_att(mcid, tmvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,'datetime',NF90_CHAR,&
           &(/timestr_id,tm_id/),dtvar_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="name"
      attvalue="Longitude"
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'8 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      attname="units"
      attvalue="degree_east"
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'9 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      attname="name"
      attvalue="Latitude"
      status = nf90_put_att(mcid, latvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'10 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      attname="units"
      attvalue="degree_north"
      status = nf90_put_att(mcid, latvar_id,TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'11 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      attname="name"
      attvalue="Pressure level"
      status = nf90_put_att(mcid, levvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'14 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvalue="hPa"
      status = nf90_put_att(mcid, levvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'15 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      date=datestrings(1)(1:4)//datestrings(1)(6:7)//&
           &datestrings(1)(9:10)

      status = nf90_put_att(mcid, NF90_GLOBAL, "Conventions", "CF-1")
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_att(mcid, NF90_GLOBAL, "ReferenceDate", date)
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_enddef(mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'17 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      status = nf90_put_var(mcid,lonvar_id,lon)
      IF (status /= nf90_noerr) THEN
         PRINT *,'18 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,latvar_id,lat)
      IF (status /= nf90_noerr) THEN
         PRINT *,'19 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      status = nf90_put_var(mcid,levvar_id,plev)
      IF (status /= nf90_noerr) THEN
         PRINT *,'20 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,dtvar_id,datestrings)
      IF (status /= nf90_noerr) THEN
         PRINT *,'20.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,tmvar_id,minutes)
      IF (status /= nf90_noerr) THEN
         PRINT *,'20.2 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_close(mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'21 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

    END SUBROUTINE netcdf_init_filepll

    SUBROUTINE netcdf_writevar_filepll(fnameout,varname,vardata)

      CHARACTER(len=*), INTENT(in)    :: fnameout
      CHARACTER(len=*), INTENT(in)    :: varname
      REAL, INTENT(in)      :: vardata(:,:,:,:)
      
      REAL, ALLOCATABLE :: tmp(:,:,:,:)
      INTEGER :: i,j,k
      INTEGER :: status,mcid
      INTEGER :: var_id

      CHARACTER(len = max_varname_length) :: attname,attvalue
      
      PRINT *,'min/max ',TRIM(varname),MINVAL(vardata),MAXVAL(vardata)


      ALLOCATE(tmp(nlon,nlat,nplev,nt))

      IF ( SIZE(vardata,1) == nlon*nlat) THEN
         k=0
         DO i=1,nlon
            DO j=1,nlat
               k=k+1
               tmp(i,j,:,:)=vardata(k,:,:,1)
            ENDDO
         ENDDO

!@mzp
!does not work on orion for fv3 why?
!         tmp=RESHAPE(vardata,shape=[nlon,nlat,nplev,nt],order=[2,1,3,4])
      ELSE
         tmp=vardata
      ENDIF

      status = nf90_open(fnameout, nf90_write, mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'0 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF
      
      status = nf90_redef(mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'1 ',varname,dimids,var_id
         CALL handle_err(status)
      ENDIF
      
      status = nf90_def_var(mcid,varname,NF90_REAL,([dimids]),var_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'2 ',varname,dimids,var_id
         CALL handle_err(status)
      ENDIF

      attname="name"
      attvalue=TRIM(varname)
      status = nf90_put_att(mcid, var_id,TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'3 ',varname,dimids,var_id
         CALL handle_err(status)
      ENDIF

      attname="units"
      IF (nplev == 1) THEN
         attvalue="kg"
      ELSE
         attvalue="kg kg-1"
      ENDIF
      status = nf90_put_att(mcid, var_id,TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'4 ',varname,dimids,var_id
         CALL handle_err(status)
      ENDIF

      status = nf90_enddef(mcid)
      IF (status /= nf90_noerr ) THEN
         PRINT *,'5 ',mcid
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,var_id,tmp)
      IF (status /= nf90_noerr ) THEN
         PRINT *,'6 ',varname,var_id
         CALL handle_err(status)
      ENDIF
      
      status = nf90_close(mcid)
      IF (status /= nf90_noerr ) THEN
         PRINT *,'7 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


    END SUBROUTINE netcdf_writevar_filepll

  END SUBROUTINE netcdf_write_generic_pll

  SUBROUTINE netcdf_write_fv3aodll(init,fnameout,lon,lat,channels,&
       &datestrings,varname,vardata)

    LOGICAL, INTENT(in)    :: init
    CHARACTER(len=*), INTENT(in)    :: fnameout
    REAL, INTENT(in), OPTIONAL :: lon(:),lat(:),channels(:)
    CHARACTER(len=*), DIMENSION(:), INTENT(in), OPTIONAL :: datestrings
    CHARACTER(len=*), INTENT(in), OPTIONAL :: varname
    REAL, INTENT(in), OPTIONAL :: vardata(:,:,:,:)
    
    INTEGER, PARAMETER :: ndims=4
    INTEGER, SAVE :: nlon, nlat, nchannels, nt
    INTEGER, SAVE :: dimids(ndims)
    REAL :: attvaluer,attvalueranger(2),fillvalue=1.e+15    
    INTEGER, PARAMETER :: deflate_level=2

    CONTINUE

    IF (PRESENT(lon)) nlon = SIZE(lon)
    IF (PRESENT(lat)) nlat = SIZE(lat)
    IF (PRESENT(channels)) nchannels = SIZE(channels)
    IF (PRESENT(vardata)) nt = SIZE(vardata,4)

    IF (init) THEN
       IF (.NOT. PRESENT(datestrings) .OR. .NOT. PRESENT(lon) .OR. &
            &.NOT. PRESENT(lat) .OR. .NOT. PRESENT(channels)) THEN
          PRINT *,'datestring and dimensions need to be present &
               &for init=.TRUE.'
          STOP 1
       ENDIF
       CALL netcdf_init_fileaodll(fnameout,lon,lat,channels,datestrings)
    ELSE
       CALL netcdf_writevar_fileaodll(fnameout,varname,vardata)
    ENDIF

  CONTAINS
    
    SUBROUTINE netcdf_init_fileaodll(fnameout,lon,lat,channels,&
         &datestrings)

      CHARACTER(len=*), INTENT(in)    :: fnameout
      REAL, INTENT(in) :: lon(:),lat(:),channels(:)
      CHARACTER(len=*), DIMENSION(:), INTENT(in), OPTIONAL :: datestrings
      CHARACTER(len=10) :: date

      INTEGER :: mcid,lonvar_id,lon_id,lat_id,lev_id,tm_id,&
           &latvar_id,levvar_id,tmvar_id,dtvar_id,timestr_id,status

      CHARACTER(len = max_varname_length) :: attname,attvalue

      INTEGER :: i,nt
      REAL, ALLOCATABLE :: minutes(:)

      nt=SIZE(datestrings)

      ALLOCATE(minutes(nt))

      IF (nt == 1) THEN
         minutes=0.
      ELSE
         minutes=[(24./nt*60.*(i-1),i=1,nt)]
      ENDIF

      status = nf90_create(fnameout,cmode=nf90_netcdf4,ncid=mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'0 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'lon',nlon,lon_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'lat',nlat,lat_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'2 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'channel',nchannels,lev_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'time',NF90_UNLIMITED,tm_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'4 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'timestr',date_string_length,timestr_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'4.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      dimids=(/lon_id, lat_id, lev_id, tm_id/)

      status = nf90_def_var(mcid,'lat',NF90_REAL,&
           &(/lat_id/),latvar_id,deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'5 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,'lon',NF90_REAL,&
           &(/lon_id/),lonvar_id,deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'6 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      status = nf90_def_var(mcid,'wavelength',NF90_REAL,&
           &(/lev_id/),levvar_id,deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,'time',NF90_REAL,&
           &(/tm_id/),tmvar_id,deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvalue="minutes since "//datestrings(1)(1:10)//' '//&
           &datestrings(1)(12:19)
      status = nf90_put_att(mcid, tmvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.2 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="long_name"
      attvalue="time"
      status = nf90_put_att(mcid, tmvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, tmvar_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      attvalueranger=[0.,60*24.]
      status = nf90_put_att(mcid, latvar_id, TRIM(attname),attvalueranger)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,'datetime',NF90_CHAR,&
           &(/timestr_id,tm_id/),dtvar_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="name"
      attvalue="longitude"
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'8 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      attname="units"
      attvalue="degree_east"
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'9 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      attvalueranger=[-180.,180.]
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvalueranger)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      attname="name"
      attvalue="latitude"
      status = nf90_put_att(mcid, latvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'10 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvalue="degree_north"
      status = nf90_put_att(mcid, latvar_id,TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'11 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, latvar_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      attvalueranger=[-90.,90.]
      status = nf90_put_att(mcid, latvar_id, TRIM(attname),attvalueranger)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      attname="name"
      attvalue="wavelength"
      status = nf90_put_att(mcid, levvar_id, TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'14 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvalue="nm"
      status = nf90_put_att(mcid, levvar_id,TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'15 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, levvar_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      attvalueranger=[0.,20000.]
      status = nf90_put_att(mcid, levvar_id, TRIM(attname),attvalueranger)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      date=datestrings(1)(1:4)//datestrings(1)(6:7)//&
           &datestrings(1)(9:10)//datestrings(1)(12:13)

      status = nf90_put_att(mcid, NF90_GLOBAL, "Conventions", "CF-1")
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_att(mcid, NF90_GLOBAL, "ReferenceDate", date)
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_att(mcid, NF90_GLOBAL, "Institution", &
           &"NOAA/OAR/GSL")
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_att(mcid, NF90_GLOBAL, "VersionID", &
           &"1.0")
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_enddef(mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'17 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,lonvar_id,lon)
      IF (status /= nf90_noerr) THEN
         PRINT *,'18 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,latvar_id,lat)
      IF (status /= nf90_noerr) THEN
         PRINT *,'19 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,levvar_id,channels)
      IF (status /= nf90_noerr) THEN
         PRINT *,'20 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,dtvar_id,datestrings)
      IF (status /= nf90_noerr) THEN
         PRINT *,'20.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,tmvar_id,minutes)
      IF (status /= nf90_noerr) THEN
         PRINT *,'20.2 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_close(mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'21 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

    END SUBROUTINE netcdf_init_fileaodll

    SUBROUTINE netcdf_writevar_fileaodll(fnameout,varname,vardata)

      CHARACTER(len=*), INTENT(in)    :: fnameout
      CHARACTER(len=*), INTENT(in)    :: varname
      REAL, INTENT(in)      :: vardata(:,:,:,:)
      
      REAL, ALLOCATABLE :: tmp(:,:,:,:)
      INTEGER :: i,j,k
      INTEGER :: status,mcid
      INTEGER :: var_id

      CHARACTER(len = max_varname_length) :: attname,attvalue
      
      PRINT *,'min/max ',TRIM(varname),MINVAL(vardata),MAXVAL(vardata)

      ALLOCATE(tmp(nlat,nlon,nchannels,nt))

      tmp=RESHAPE(vardata,shape=[nlon,nlat,nchannels,nt],order=[2,1,3,4])

      status = nf90_open(fnameout, nf90_write, mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'0 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF
      
      status = nf90_redef(mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'1 ',varname,dimids,var_id
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,varname,NF90_REAL,([dimids]),var_id,&
           &deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'2 ',varname,dimids,var_id
         CALL handle_err(status)
      ENDIF

      attname="name"
      IF (TRIM(varname) == "AOD") THEN
         attvalue="Aerosol Optical Depth"
      ELSE
         attvalue=TRIM(varname)
      ENDIF
      status = nf90_put_att(mcid, var_id,TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'3 ',varname,dimids,var_id
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvalue=""
      status = nf90_put_att(mcid, var_id,TRIM(attname),attvalue)
      IF (status /= nf90_noerr) THEN
         PRINT *,'4 ',varname,dimids,var_id
         CALL handle_err(status)
      ENDIF

      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, var_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      attvalueranger=[0.,10.]
      status = nf90_put_att(mcid, var_id, TRIM(attname),attvalueranger)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_enddef(mcid)
      IF (status /= nf90_noerr ) THEN
         PRINT *,'5 ',mcid
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,var_id,tmp)
      IF (status /= nf90_noerr ) THEN
         PRINT *,'6 ',varname,var_id
         CALL handle_err(status)
      ENDIF
      
      status = nf90_close(mcid)
      IF (status /= nf90_noerr ) THEN
         PRINT *,'7 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


    END SUBROUTINE netcdf_writevar_fileaodll

  END SUBROUTINE netcdf_write_fv3aodll

  SUBROUTINE netcdf_write_generic_ll(init,fnameout,lon,lat,lev,&
       &datestrings,varname,vardata,units,validrange)

    LOGICAL, INTENT(in)    :: init
    CHARACTER(len=*), INTENT(in)    :: fnameout
    REAL, INTENT(in), OPTIONAL :: lon(:),lat(:)
    INTEGER, INTENT(in), OPTIONAL :: lev(:)
    CHARACTER(len=*), DIMENSION(:), INTENT(in), OPTIONAL :: datestrings
    CHARACTER(len=*), INTENT(in), OPTIONAL :: varname
    CHARACTER(len=*), OPTIONAL :: units
    REAL, INTENT(in), OPTIONAL :: vardata(:,:,:,:)
    REAL, OPTIONAL :: validrange(:)

    INTEGER, PARAMETER :: ndims=4
    INTEGER, PARAMETER :: deflate_level=2

    CHARACTER(len = max_varname_length) :: attname,attvaluec
    INTEGER :: attvaluei,attvaluerangei(2)
    REAL :: attvaluer,attvalueranger(2),fillvalue=1.e+15


    INTEGER, SAVE :: nlon, nlat, nlev, nt
    INTEGER, SAVE :: dimids2d(ndims-1),dimids3d(ndims)
    
    CONTINUE

    IF (PRESENT(lon)) nlon = SIZE(lon)
    IF (PRESENT(lat)) nlat = SIZE(lat)
    IF (PRESENT(lev)) nlev = SIZE(lev)
    IF (PRESENT(vardata)) nt = SIZE(vardata,4)

    IF (init) THEN
       IF (.NOT. PRESENT(datestrings) .OR. .NOT. PRESENT(lon) .OR. &
            &.NOT. PRESENT(lat) .OR. .NOT. PRESENT(lev))  THEN
          PRINT *,'date string and dimensions needs to be present &
               &for init=.TRUE.'
          STOP 1
       ENDIF
       CALL netcdf_init_filell(fnameout,lon,lat,lev,datestrings)
    ELSE
       IF (.NOT.PRESENT(units)) units=""
       IF (.NOT.PRESENT(validrange)) validrange=[-fillvalue,fillvalue]
       CALL netcdf_writevar_filell(fnameout,TRIM(varname),vardata,&
            &units,validrange)
    ENDIF

  CONTAINS
    
    SUBROUTINE netcdf_init_filell(fnameout,lon,lat,lev,datestrings)

      CHARACTER(len=*), INTENT(in)    :: fnameout
      REAL, INTENT(in) :: lon(:),lat(:)
      INTEGER, INTENT(in) :: lev(:)
      CHARACTER(len=*), DIMENSION(:), INTENT(in)    :: datestrings

      INTEGER :: mcid,lonvar_id,lon_id,lat_id,lev_id,tm_id,&
           &timestr_id,&
           &latvar_id,levvar_id,tmvar_id,dtvar_id,status

      CHARACTER(len = 10) :: date
      INTEGER :: i,nt
      REAL, ALLOCATABLE :: minutes(:)

      nt=SIZE(datestrings)
      
      ALLOCATE(minutes(nt))

      IF (nt == 1) THEN
         minutes=0.
      ELSE
         minutes=[(24./nt*60.*(i-1),i=1,nt)]
      ENDIF

      status = nf90_create(fnameout,cmode=nf90_netcdf4,ncid=mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'0 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'lon',nlon,lon_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'lat',nlat,lat_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'2 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'lev',nlev,lev_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'time',NF90_UNLIMITED,tm_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'4 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_dim(mcid,'timestr',date_string_length,timestr_id)
      IF (status /= nf90_noerr) THEN
         PRINT *,'4.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      dimids2d=(/lon_id, lat_id, tm_id/)
      dimids3d=(/lon_id, lat_id, lev_id, tm_id/)

      status = nf90_def_var(mcid,'lat',NF90_REAL,(/lat_id/),latvar_id,&
           &deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'5 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="name"
      attvaluec="latitude"
      status = nf90_put_att(mcid, latvar_id, TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'10 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvaluec="degree_north"
      status = nf90_put_att(mcid, latvar_id,TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'11 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, latvar_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      attvalueranger=[-90.,90.]
      status = nf90_put_att(mcid, latvar_id, TRIM(attname),attvalueranger)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,'lon',NF90_REAL,(/lon_id/),lonvar_id,&
           &deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'6 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="name"
      attvaluec="longitude"
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'8 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvaluec="degree_east"
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'9 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      attvalueranger=[-180.,180.]
      status = nf90_put_att(mcid, lonvar_id, TRIM(attname),attvalueranger)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,'lev',NF90_INT,(/lev_id/),levvar_id,&
           &deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="name"
      attvaluec="level"
      status = nf90_put_att(mcid, levvar_id, TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'14 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvaluec=""
      status = nf90_put_att(mcid, levvar_id, TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'15 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, levvar_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      attvaluerangei=[1,SIZE(lev)]
      status = nf90_put_att(mcid, levvar_id, TRIM(attname),attvaluerangei)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      status = nf90_def_var(mcid,'time',NF90_REAL, (/tm_id/),tmvar_id,&
           &deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvaluec="minutes since "//datestrings(1)(1:10)//' '//&
           &datestrings(1)(12:19)
      status = nf90_put_att(mcid, tmvar_id, TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.2 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="long_name"
      attvaluec="time"
      status = nf90_put_att(mcid, tmvar_id, TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, tmvar_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      attvalueranger=[0,60*24]
      status = nf90_put_att(mcid, tmvar_id, TRIM(attname),attvalueranger)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_def_var(mcid,'datetime',NF90_CHAR, &
           &(/timestr_id,tm_id/),dtvar_id,&
           &deflate_level=deflate_level)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      date=datestrings(1)(1:4)//datestrings(1)(6:7)//&
           &datestrings(1)(9:10)//datestrings(1)(12:13)

      status = nf90_put_att(mcid, NF90_GLOBAL, "Conventions", "CF-1")
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_att(mcid, NF90_GLOBAL, "ReferenceDate", date)
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_att(mcid, NF90_GLOBAL, "Institution", &
           &"NOAA/OAR/GSL")
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_att(mcid, NF90_GLOBAL, "VersionID", &
           &"1.0")
      IF (status /= nf90_noerr) THEN
         PRINT *,'16 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_enddef(mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'17 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      status = nf90_put_var(mcid,lonvar_id,lon)
      IF (status /= nf90_noerr) THEN
         PRINT *,'18 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,latvar_id,lat)
      IF (status /= nf90_noerr) THEN
         PRINT *,'19 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


      status = nf90_put_var(mcid,levvar_id,lev)
      IF (status /= nf90_noerr) THEN
         PRINT *,'20 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,dtvar_id,datestrings)
      IF (status /= nf90_noerr) THEN
         PRINT *,'20.1 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,tmvar_id,minutes)
      IF (status /= nf90_noerr) THEN
         PRINT *,'20.2 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_close(mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'21 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

    END SUBROUTINE netcdf_init_filell

    SUBROUTINE netcdf_writevar_filell(fnameout,varname,vardata,&
         &units,validrange)

      CHARACTER(len=*), INTENT(in)    :: fnameout
      CHARACTER(len=*), INTENT(in)    :: varname
      CHARACTER(len=*), INTENT(in)    :: units
      REAL, INTENT(in)                :: validrange(:)


      REAL, INTENT(in)      :: vardata(:,:,:,:)
      
      REAL, ALLOCATABLE :: tmp(:,:,:,:)
      INTEGER :: i,j,k
      INTEGER :: status,mcid
      INTEGER :: var_id

      CHARACTER(len = max_varname_length) :: attname,attvaluec
      
      PRINT *,'min/max ',TRIM(varname),MINVAL(vardata),MAXVAL(vardata)

      IF ( SIZE(vardata,1) == nlon*nlat) THEN
         IF (SIZE(vardata,2)==1) THEN
            ALLOCATE(tmp(nlon,nlat,1,nt))
!mzp does not work on Orion
!            tmp=RESHAPE(vardata,shape=[nlon,nlat,1,nt],order=[2,1,3,4])
         ELSE
            ALLOCATE(tmp(nlon,nlat,nlev,nt))
!mzp does not work on Orion
!            tmp=RESHAPE(vardata,shape=[nlon,nlat,nlev,nt],order=[2,1,3,4])
         ENDIF
         k=0
         DO i=1,nlon
            DO j=1,nlat
               k=k+1
               tmp(i,j,:,:)=vardata(k,:,:,1)
            ENDDO
         ENDDO
      ELSE
         tmp=vardata
      ENDIF

      status = nf90_open(fnameout, nf90_write, mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'0 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF
      
      status = nf90_redef(mcid)
      IF (status /= nf90_noerr) THEN
         PRINT *,'1 ',varname,var_id
         CALL handle_err(status)
      ENDIF
      
      IF (SIZE(vardata,2)==1) THEN
         status = nf90_def_var(mcid,TRIM(varname),NF90_REAL,&
              &([dimids2d]),var_id,deflate_level=deflate_level)
         IF (status /= nf90_noerr) THEN
            PRINT *,'2 ',varname,dimids2d,var_id
            CALL handle_err(status)
         ENDIF
      ELSE
         status = nf90_def_var(mcid,TRIM(varname),NF90_REAL,&
              &([dimids3d]),var_id,deflate_level=deflate_level)
         IF (status /= nf90_noerr) THEN
            PRINT *,'2 ',varname,dimids3d,var_id
            CALL handle_err(status)
         ENDIF
      ENDIF

      attname="name"
      attvaluec=TRIM(varname)
      status = nf90_put_att(mcid, var_id,TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'3 ',varname,var_id
         CALL handle_err(status)
      ENDIF

      attname="units"
      attvaluec=units

      status = nf90_put_att(mcid, var_id,TRIM(attname),attvaluec)
      IF (status /= nf90_noerr) THEN
         PRINT *,'4 ',varname,var_id
         CALL handle_err(status)
      ENDIF

      attname="FillValue"
      attvaluer=fillvalue
      status = nf90_put_att(mcid, var_id, TRIM(attname),attvaluer)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      attname="valid_range"
      status = nf90_put_att(mcid, var_id, TRIM(attname),validrange)
      IF (status /= nf90_noerr) THEN
         PRINT *,'7.3 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF

      status = nf90_enddef(mcid)
      IF (status /= nf90_noerr ) THEN
         PRINT *,'5 ',mcid
         CALL handle_err(status)
      ENDIF

      status = nf90_put_var(mcid,var_id,tmp)

      IF (status /= nf90_noerr ) THEN
         PRINT *,'6 ',TRIM(varname),var_id
         CALL handle_err(status)
      ENDIF
      
      status = nf90_close(mcid)
      IF (status /= nf90_noerr ) THEN
         PRINT *,'7 ',mcid,TRIM(fnameout)
         CALL handle_err(status)
      ENDIF


    END SUBROUTINE netcdf_writevar_filell

  END SUBROUTINE netcdf_write_generic_ll

  SUBROUTINE netcdf_write_fv3_concentration(fnameout,var,varname)

    IMPLICIT NONE
    
    CHARACTER(len=*), INTENT(in)    :: fnameout
    REAL(SINGLE), INTENT(in)      :: var(:,:,:,:)
    CHARACTER(len=max_varname_length) :: varname

    INTEGER, PARAMETER              :: ndims_max=4
    INTEGER                         :: mcid,tid,varid,status
    INTEGER                         :: dimids(1:ndims_max),dims(1:ndims_max)
    CHARACTER(len=max_varname_length), PARAMETER    :: dimstring(1:ndims_max)=&
         &(/'xaxis_1','yaxis_1','zaxis_1','Time'/)

    CHARACTER(len=max_varname_length) :: attname,attvalue

    INTEGER :: i
    LOGICAL :: existin

    INQUIRE(file=fnameout,exist=existin)

    IF (.NOT. existin) THEN

       status = nf90_create(fnameout, nf90_write, mcid)
       IF (status /= nf90_noerr) THEN
          PRINT *,'0 ',mcid,TRIM(fnameout)
          CALL handle_err(status)
       ENDIF
       
       DO i=1,ndims_max-1
          status = nf90_def_dim(mcid,dimstring(i),SIZE(var,i),dimids(i))

          IF (status /= nf90_noerr) THEN
             PRINT *,'1 ',dimids(i),TRIM(dimstring(i))
             CALL handle_err(status)
          ENDIF
       ENDDO
       
       i=ndims_max
       status = nf90_def_dim(mcid,dimstring(i),NF90_UNLIMITED,dimids(i))
       IF (status /= nf90_noerr) THEN
          PRINT *,'1 ',dimids(i),TRIM(dimstring(i))
          CALL handle_err(status)
       ENDIF
       
       status = nf90_def_var(mcid,'Time',NF90_REAL,&
            &(/dimids(ndims_max:ndims_max)/),tid)
       IF (status /= nf90_noerr) THEN
          PRINT *,'2 ','Time',tid
          CALL handle_err(status)
       ENDIF
       
       attname="long_name"
       attvalue="Time"
       status = nf90_put_att(mcid, tid, TRIM(attname),attvalue)
       IF (status /= nf90_noerr) THEN
          PRINT *,'3.1',TRIM(attname),attvalue
          CALL handle_err(status)
       ENDIF
       
       attname="units"
       attvalue="time level"
       status = nf90_put_att(mcid, tid, TRIM(attname),attvalue)
       IF (status /= nf90_noerr) THEN
          PRINT *,'3.2',TRIM(attname),attvalue
          CALL handle_err(status)
       ENDIF
       
       attname="cartesian_axis"
       attvalue="T"
       status = nf90_put_att(mcid, tid, TRIM(attname),attvalue)
       IF (status /= nf90_noerr) THEN
          PRINT *,'3.3',TRIM(attname),attvalue
          CALL handle_err(status)
       ENDIF
       
       status = nf90_def_var(mcid,varname,NF90_DOUBLE,&
            &(/dimids(1:2),dimids(ndims_max:ndims_max)/),varid)
       IF (status /= nf90_noerr) THEN
          PRINT *,'4 ',TRIM(varname),varid
          CALL handle_err(status)
       ENDIF
    
       attname="long_name"
       attvalue=varname
       status = nf90_put_att(mcid, varid, TRIM(attname),attvalue)
       IF (status /= nf90_noerr) THEN
          PRINT *,'4.1 ',TRIM(attname),attvalue
          CALL handle_err(status)
       ENDIF
       
       attname="units"
       attvalue="ug m-3"
       status = nf90_put_att(mcid, varid, TRIM(attname),attvalue)
       IF (status /= nf90_noerr) THEN
          PRINT *,'4.2',TRIM(attname),attvalue
          CALL handle_err(status)
       ENDIF
       
       status = nf90_put_att(mcid,NF90_GLOBAL,"filename","RESTART/fv3_sfc_concentration.res.nc")
       IF (status /= 0) THEN
          PRINT *,'4.3',"filename"
          CALL handle_err(status)
       ENDIF
      
       status = nf90_enddef(mcid)
       IF (status /= nf90_noerr ) THEN
          PRINT *,'5 ',mcid
          CALL handle_err(status)
       ENDIF

       status = nf90_put_var(mcid,tid,1.)
       IF (status /= nf90_noerr ) THEN
          PRINT *,'6 ',tid,MINVAL(var),MAXVAL(var)
          CALL handle_err(status)
       ENDIF
       
       status = nf90_put_var(mcid,varid,var)
       IF (status /= nf90_noerr ) THEN
          PRINT *,'7 ',varid,MINVAL(var),MAXVAL(var)
          CALL handle_err(status)
       ENDIF
       
    ELSE

       status = nf90_open(fnameout, nf90_write, mcid)
       IF (status /= nf90_noerr) THEN
          PRINT *,'0 ',mcid,TRIM(fnameout)
          CALL handle_err(status)
       ENDIF

       DO i=1,ndims_max
          status = nf90_inq_dimid(mcid,dimstring(i),dimids(i))
          IF (status /= nf90_noerr) THEN
             PRINT *,'1 ',dimids(i),TRIM(dimstring(i))
             CALL handle_err(status)
          ENDIF
       ENDDO

       status = nf90_redef(mcid)
       IF (status /= nf90_noerr) THEN
          PRINT *,'2 ',varname
          CALL handle_err(status)
       ENDIF

       status = nf90_def_var(mcid,varname,NF90_DOUBLE,&
            &(/dimids(1:2),dimids(ndims_max:ndims_max)/),varid)
       IF (status /= nf90_noerr) THEN
          PRINT *,'4 ',TRIM(varname),varid
          CALL handle_err(status)
       ENDIF

       attname="long_name"
       attvalue=varname
       status = nf90_put_att(mcid, varid, TRIM(attname),attvalue)
       IF (status /= nf90_noerr) THEN
          PRINT *,'4.1 ',TRIM(attname),attvalue
          CALL handle_err(status)
       ENDIF
       
       attname="units"
       attvalue="ug m-3"
       status = nf90_put_att(mcid, varid, TRIM(attname),attvalue)
       IF (status /= nf90_noerr) THEN
          PRINT *,'4.2',TRIM(attname),attvalue
          CALL handle_err(status)
       ENDIF

       status = nf90_enddef(mcid)
       IF (status /= nf90_noerr ) THEN
          PRINT *,'5 ',mcid
          CALL handle_err(status)
       ENDIF

       status = nf90_put_var(mcid,varid,var)
       IF (status /= nf90_noerr ) THEN
          PRINT *,'7 ',varid,MINVAL(var),MAXVAL(var)
          CALL handle_err(status)
       ENDIF
       
    ENDIF

    status = nf90_close(mcid)
    IF (status /= nf90_noerr ) THEN
       PRINT *,'12 ',mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

  END SUBROUTINE    netcdf_write_fv3_concentration

  SUBROUTINE handle_err(status)
    INTEGER status
    WRITE(6,*) 'Error: ', nf90_strerror(status)
    STOP 1
  END SUBROUTINE handle_err

END MODULE module_netcdf_io
