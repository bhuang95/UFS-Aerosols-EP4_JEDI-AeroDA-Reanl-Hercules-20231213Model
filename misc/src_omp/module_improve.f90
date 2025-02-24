MODULE module_improve

!to read IMPROVE data
!  MP, May 2023

  USE netcdf
  USE datetime_mod  
  USE timedelta_mod

  USE module_constants
  USE module_netcdf_io, ONLY: handle_err,ndims_max
  USE module_utils, ONLY: indexx, replace_text

  IMPLICIT NONE


  PRIVATE 
  PUBLIC :: improve,get_improve

  TYPE improve
     TYPE(datetime_type) :: datetime
     REAL :: lat
     REAL :: lon
     CHARACTER(len=max_varname_length), ALLOCATABLE :: varnames(:)
     REAL, ALLOCATABLE :: varvalues(:) 
  END TYPE improve

CONTAINS

  SUBROUTINE get_improve(infile,varnames_aeros,improve_record)

    CHARACTER(len=*) :: infile
    CHARACTER(len=*) :: varnames_aeros(:)
    TYPE(improve), ALLOCATABLE, DIMENSION(:) :: improve_record

    INTEGER :: stderr
    INTEGER :: Open_Status,Read_Status


    CHARACTER(len = max_varname_length), PARAMETER :: &
         &latname='latitude',lonname='longitude',&
         &timename='deltaTime',metadata='MetaData',obsvalue='ObsValue'

    INTEGER :: ncid, status, RecordDimID
    CHARACTER(len = max_varname_length) :: RecordDimName

    REAL, DIMENSION(:), ALLOCATABLE :: lat,lon,time,obs

    INTEGER :: latid,lonid,timeid,obsid,grpid

    INTEGER :: i,j,nlocs,naeros
    INTEGER :: centerdate,year_ref,month_ref,day_ref,hour_ref

    TYPE(datetime_type) :: date_ref
    TYPE(timedelta_type) :: dt,dt_ref

    CONTINUE

    naeros=SIZE(varnames_aeros)
    stderr = 0

    status = nf90_open(infile, nf90_nowrite, ncid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inquire(ncid, unlimitedDimId = RecordDimID)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inquire_dimension(ncid,RecordDimID,RecordDimName,nlocs)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_get_att(ncid,NF90_GLOBAL,"centerdate",centerdate)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_grp_ncid(ncid,metadata,grpid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_varid(grpid, latname, latid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_varid(grpid, lonname, lonid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    status = nf90_inq_varid(grpid, timename, timeid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    ALLOCATE(lat(nlocs),lon(nlocs),time(nlocs),obs(nlocs))

    ALLOCATE(improve_record(nlocs))

    DO i=1,nlocs
       ALLOCATE(improve_record(i)%varnames(naeros),&
            &improve_record(i)%varvalues(naeros))
    ENDDO

    status = nf90_get_var(grpid, latid, lat) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)
    improve_record(:)%lat=lat

    status = nf90_get_var(grpid, lonid, lon) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)
    improve_record(:)%lon=lon

    status = nf90_get_var(grpid, timeid, time) 
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    year_ref=centerdate/1000000
    month_ref=(centerdate-year_ref*1000000)/10000
    day_ref=(centerdate-year_ref*1000000-month_ref*10000)/100
    hour_ref=centerdate-year_ref*1000000-month_ref*10000-day_ref*100

    dt_ref=timedelta(hours=12)

    DO i=1,nlocs
       dt=timedelta(seconds=time(i))
       improve_record(i)%datetime=create_datetime(year=year_ref,&
            &month=month_ref,day=day_ref,hour=hour_ref)-dt-dt_ref
    ENDDO

    status = nf90_inq_grp_ncid(ncid,obsvalue,grpid)
    IF (status .NE. nf90_noerr) CALL handle_err(status)

    DO i=1,naeros
       status = nf90_inq_varid(grpid, varnames_aeros(i), obsid)
       IF (status .NE. nf90_noerr) CALL handle_err(status)
       status = nf90_get_var(grpid, obsid, obs) 
       IF (status .NE. nf90_noerr) CALL handle_err(status)
       improve_record(:)%varnames(i)=varnames_aeros(i)
       improve_record(:)%varvalues(i)=obs
    ENDDO

    status = nf90_close(ncid)

    DEALLOCATE(lat,lon,time,obs)

  END SUBROUTINE get_improve

END MODULE module_improve

