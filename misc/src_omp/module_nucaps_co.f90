MODULE module_nucaps_co

!  reads CLASS CO nucaps  and puts in a structure
!  MP, Jul 2020

  USE netcdf
  USE datetime_mod  
  USE timedelta_mod

  USE module_constants
  USE module_netcdf_io, ONLY: handle_err,ndims_max
  USE module_utils, ONLY: indexx, replace_text

  IMPLICIT NONE


  PRIVATE 
  PUBLIC :: get_nucaps_co,nucaps_co,write_ioda_nucaps_co

  REAL, PARAMETER :: co_mw=0.028 !in kg 

  TYPE nucaps_co
     CHARACTER(len=max_varname_length) :: satellite
     TYPE(datetime_type) :: obsdate
     REAL :: lat
     REAL :: lon
     REAL :: co_column
     INTEGER :: qc
  END TYPE nucaps_co

CONTAINS

  SUBROUTINE get_nucaps_co(nucaps_co_record)

    REAL, PARAMETER :: p_offset=5.

    TYPE(nucaps_co), ALLOCATABLE, DIMENSION(:) :: nucaps_co_record

    INTEGER :: stderr
    INTEGER :: Open_Status,Read_Status

    INTEGER :: ncid, status
    CHARACTER(len = max_varname_length), PARAMETER :: &
         &plevdimname='Number_of_P_Levels',&
         &obsdimname='Number_of_CrIS_FORs',&
         &latname='Latitude',lonname='Longitude',timename='Time',&
         &pname='Effective_Pressure',psname='Surface_Pressure',&
         &obsname='CO',qcname='Quality_Flag'

    CHARACTER(len=max_varname_length) :: units
    CHARACTER(len=max_string_length)  :: input_dir_obs,input_file_obs

    INTEGER, DIMENSION(:), ALLOCATABLE :: qc
    REAL, DIMENSION(:), ALLOCATABLE :: time,lat,lon,ps
    REAL, DIMENSION(:,:), ALLOCATABLE :: obs,p

    INTEGER :: plevdimid,obsdimid
    INTEGER :: latid,lonid,timeid,obsid,qcid,pid,psid
    INTEGER :: nplev,nobs,nobs_qc

    INTEGER :: year_ref,month_ref,day_ref,hour_ref
    INTEGER :: i,j,k,npbot
    REAL :: bmult,dobs

    CHARACTER(max_varname_length) :: satellite

    INTEGER :: unit_namelist=101

    TYPE(datetime_type) :: obsdate
    TYPE(timedelta_type) :: dt

    NAMELIST /record_obs/ &
         &input_dir_obs, input_file_obs

    CONTINUE

    stderr = 0

    OPEN (unit=unit_namelist, file = "nucaps_co2ioda.nl", &
         &status="old",action = "read",iostat=open_status)

    IF (open_status /= 0) THEN
       WRITE(stderr,*) "error: there is no namelist file nucaps_co2ioda.nl)"
       STOP
    END IF

    WRITE(stderr,*) 'Reading nucaps_co2ioda.nl record_obs'
    READ (unit_namelist, NML=record_obs, IOSTAT=Read_Status)
    CLOSE(unit_namelist)

    IF (Read_Status /= 0) THEN
       WRITE(stderr,*) 'Error reading nnr2ioda.nl record_obs'
       STOP
    END IF

!ncdf file names

    satellite='snpp'

    input_file_obs=TRIM(input_dir_obs)//'/'//TRIM(input_file_obs)

    status = nf90_open(input_file_obs, nf90_nowrite, ncid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status=nf90_inq_dimid(ncid,obsdimname,obsdimid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inquire_dimension(ncid,obsdimid,len=nobs)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status=nf90_inq_dimid(ncid,plevdimname,plevdimid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)
    status = nf90_inquire_dimension(ncid,plevdimid,len=nplev)
    IF (status .NE. nf90_noerr) CALL handle_err(status)


    ALLOCATE(time(nobs),ps(nobs),qc(nobs),lon(nobs),lat(nobs),&
         &p(nplev,nobs),obs(nplev,nobs))

    status = nf90_inq_varid(ncid, latname, latid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_varid(ncid, lonname, lonid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_varid(ncid, timename, timeid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_varid(ncid, qcname, qcid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_varid(ncid, obsname, obsid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_varid(ncid, psname, psid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_varid(ncid, pname, pid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_get_var(ncid, latid, lat) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_get_var(ncid, lonid, lon) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_get_var(ncid, timeid, time) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_get_att(ncid, timeid, 'units',units)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    READ(units,'(11X,i4,X,i2,X,i2,X,i2)')&
         &year_ref,month_ref,day_ref,hour_ref

    status = nf90_get_var(ncid, qcid, qc) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_get_var(ncid, obsid, obs) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_get_var(ncid, psid, ps) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_get_var(ncid, pid, p) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_close(ncid)

    nobs_qc=COUNT(qc == 0)

    ALLOCATE(nucaps_co_record(nobs_qc))

    j=0

    DO i=1,nobs

       IF (qc(i) == 0) THEN

          j=j+1

          nucaps_co_record(j)%satellite=satellite
          dt=timedelta(seconds=time(i)*1.e-3)
          obsdate=create_datetime(year=year_ref,month=month_ref,&
               & day=day_ref,hour=hour_ref)+dt
          nucaps_co_record(j)%obsdate=obsdate
          nucaps_co_record(j)%lon=lon(i)           
          nucaps_co_record(j)%lat=lat(i)           
          nucaps_co_record(j)%qc=qc(i)
          
          DO k=nplev,1,-1
             IF (ps (i) >= p(k,i) + p_offset) EXIT
          ENDDO
          
          npbot=k+1
          bmult=(ps(i)-p(npbot-1,i))/(p(npbot,i)-p(npbot-1,i))
          dobs=bmult*obs(npbot,i)

          nucaps_co_record(j)%co_column=(SUM(obs(:npbot-1,i))+dobs)/&
               &n_avogadro*&
               &1.e+4*&   !cm^2 to m^2
               &co_mw     !co mw in kg/mol

       ENDIF

    ENDDO

    DEALLOCATE(obs,p,ps,time,lat,lon)

  END SUBROUTINE get_nucaps_co

  SUBROUTINE write_ioda_nucaps_co(nucaps_co_record,nobs,center_date_time)

    IMPLICIT NONE

    INTEGER :: nobs
    TYPE(nucaps_co), DIMENSION(nobs), INTENT(in) :: nucaps_co_record
    CHARACTER(len=10), INTENT(in) :: center_date_time

    INTEGER                         :: status

    CHARACTER(len=max_varname_length) :: satellite,varname

    INTEGER :: i,iout,ivar,j,validtime
    INTEGER :: unit_namelist=101
    INTEGER :: stderr
    INTEGER :: Open_Status,Read_Status
    INTEGER :: mcid,nlocsid,nobsid,nrecsid,nvarsid
    INTEGER, ALLOCATABLE ::  varids(:)
    
    REAL, ALLOCATABLE :: bias(:),uncertainty(:)

    CHARACTER(len = max_string_length) :: output_dir,output_file,fnameout
    INTEGER, PARAMETER :: nvarco=4
    CHARACTER(len=max_varname_length) :: varnames(nvarco)

    TYPE(datetime_type) :: validdate
    TYPE(timedelta_type) :: dt(nobs)
    REAL :: sol_zenith_angle(nobs), sol_azimuth_angle(nobs), qc(nobs),&
         &tdiff(nobs),values(nobs)
    INTEGER :: isfc(nobs), yyyy, mm, dd, hh

    NAMELIST /record_output/ output_dir, output_file

    PRINT *,'In write_ioda_co'

    varnames=[&
         &'co_column@ObsValue',&
         &'co_column@ObsError',&
         &'co_column@PreQc',&
         &'co_column@KnownObsBias']

    OPEN(unit=unit_namelist, file = "nucaps_co2ioda.nl", &
         &status="old",action = "READ",iostat=open_status)
    IF (open_status /= 0) THEN
       WRITE(stderr,*) "error: there is no NAMELIST file (nucaps_co2ioda.nl)"
       STOP
    END IF
    WRITE(stderr,*) 'Reading nucaps_co2ioda.nl record_output'
    READ (unit_namelist, NML=record_output, IOSTAT=Read_Status)
    CLOSE(unit_namelist)

    fnameout=TRIM(output_dir)//'/'//TRIM(output_file)

    ALLOCATE(varids(nvarco+3))
    ALLOCATE(bias(nobs),uncertainty(nobs))

    bias=0.
    uncertainty=0.

    satellite=nucaps_co_record(1)%satellite

    iout=0
    status = nf90_create(fnameout, cmode=nf90_clobber, ncid=mcid)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    status = nf90_put_att(mcid,NF90_GLOBAL,"observation_type","CO_column")
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    READ(center_date_time,"(i10)") validtime

    status = nf90_put_att(mcid,NF90_GLOBAL,"date_time",validtime)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF


    status = nf90_put_att(mcid,NF90_GLOBAL,"satellite",satellite)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    status = nf90_def_dim(mcid,'nlocs',NF90_UNLIMITED,nlocsid)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    status = nf90_def_dim(mcid,'nobs',nobs,nobsid)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    ivar=0

    ivar=ivar+1
    status = nf90_def_var(mcid,'latitude@MetaData',nf90_real,&
         &nlocsid,varids(ivar))
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    ivar=ivar+1
    status = nf90_def_var(mcid,'longitude@MetaData',nf90_real,&
         &nlocsid,varids(ivar))
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    ivar=ivar+1
    status = nf90_def_var(mcid,'time@MetaData',nf90_real,&
         &nlocsid,varids(ivar))
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF


    DO i=1,nvarco
       ivar=ivar+1
       status = nf90_def_var(mcid,TRIM(varnames(i)),nf90_real,&
            &nlocsid,varids(ivar))
       IF (status /= nf90_noerr) THEN
          iout=iout+1
          PRINT *,iout,mcid,TRIM(fnameout)
          CALL handle_err(status)
       ENDIF
    ENDDO
    
    status = nf90_enddef(mcid)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    ivar=0

    ivar=ivar+1
    status = nf90_put_var(mcid,varids(ivar),nucaps_co_record(:)%lat)
    IF (status /= nf90_noerr ) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    ivar=ivar+1
    status = nf90_put_var(mcid,varids(ivar),nucaps_co_record(:)%lon)
    IF (status /= nf90_noerr ) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

    ivar=ivar+1

    READ(center_date_time(1:4), '(i4)' )  yyyy
    READ(center_date_time(5:6), '(i2)' )  mm
    READ(center_date_time(7:8), '(i2)' )  dd
    READ(center_date_time(9:10), '(i2)' )  hh

    validdate=create_datetime(year=yyyy,month=mm,day=dd,hour=hh)
    
    DO i=1,nobs
       dt(i)=nucaps_co_record(i)%obsdate-validdate
       tdiff(i)=dt(i)%total_hours()
    ENDDO

    status = nf90_put_var(mcid,varids(ivar),tdiff)
    IF (status /= nf90_noerr ) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF

!ObsValue
    ivar=ivar+1
    status = nf90_put_var(mcid,varids(ivar),nucaps_co_record(:)%co_column)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF
    
!ObsError
    ivar=ivar+1
    status = nf90_put_var(mcid,varids(ivar),uncertainty)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF
    
!PreQc
    ivar=ivar+1
    status = nf90_put_var(mcid,varids(ivar),nucaps_co_record(:)%qc)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF
    
!KnownObsBias
    ivar=ivar+1
    status = nf90_put_var(mcid,varids(ivar),bias)
    IF (status /= nf90_noerr) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF
    
    status = nf90_close(mcid)
    IF (status /= nf90_noerr ) THEN
       iout=iout+1
       PRINT *,iout,mcid,TRIM(fnameout)
       CALL handle_err(status)
    ENDIF
    
    DEALLOCATE(bias,uncertainty,varids)
    
  END SUBROUTINE write_ioda_nucaps_co
  
END MODULE module_nucaps_co

