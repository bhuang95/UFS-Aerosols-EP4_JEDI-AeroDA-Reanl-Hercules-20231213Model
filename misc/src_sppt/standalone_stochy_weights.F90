PROGRAM  standalone_stochy_weights

  USE stochastic_physics,  ONLY : init_stochastic_physics_ocn,run_stochastic_physics_ocn
  USE get_stochy_pattern_mod,  ONLY : write_stoch_restart_ocn
  USE mpp_mod,             ONLY: mpp_init
  USE fms_mod,             ONLY: fms_init
  USE netcdf
  USE kinddef,             ONLY : kind_dbl_prec,kind_phys
  USE stochy_namelist_def, ONLY : stochini
  USE slint
  USE timedelta_mod
  USE datetime_mod


  IMPLICIT NONE

  INTEGER, PARAMETER :: max_varname_length=100,nvarmax=50,&
       &max_string_length=800

  INTEGER                 :: ncid,xt_dim_id,yt_dim_id,time_dim_id,xt_var_id,yt_var_id,time_var_id,var_id_lat,var_id_lon
  INTEGER                 :: varid

  INCLUDE 'mpif.h'
  INCLUDE 'netcdf.inc'

  INTEGER     :: i,j,k,l,itime
  INTEGER  :: nlunit,pe,npes
  CHARACTER(len=max_string_length) :: fnamein_prefix,fnameout_prefix,&
       &fnamein,fnameout,&
       &fnamein_pattern,fnameout_pattern,&
       &timestring,command,cmsg,time_attstring,isostring
  INTEGER :: comm

  CHARACTER(len=10) :: cdate
  TYPE(datetime_type) :: datatime,datatime_start
  TYPE(timedelta_type) dt,dtime

  REAL(kind=4),ALLOCATABLE,DIMENSION(:,:) :: workg
  REAL(kind=kind_phys), ALLOCATABLE :: xlat(:,:),lat_tgt(:),xlat_tgt(:,:)
  REAL(kind=kind_phys), ALLOCATABLE :: xlon(:,:),lon_tgt(:),xlon_tgt(:,:)
  REAL(kind=kind_phys) :: dtp             !< physics timestep in seconds  
  REAL (kind=kind_phys),ALLOCATABLE :: sppt_wts (:,:)
  REAL (kind=kind_phys),ALLOCATABLE :: skeb_wts (:,:)
  REAL (kind=kind_phys),ALLOCATABLE :: t_rp1 (:,:)
  REAL (kind=kind_phys),ALLOCATABLE :: t_rp2 (:,:)
  INTEGER              :: root_pe         !< MPI rank of root atmosphere processor
  INTEGER              :: iret,cstat
  LOGICAL  :: do_sppt,do_skeb,pert_epbl

  INTEGER :: nvars, nx, ny, nxy, nxx, nyy, nxxyy
  CHARACTER(len = max_varname_length) :: varlist(nvarmax),varname

  REAL(kind=kind_phys), ALLOCATABLE :: vardata(:,:)

  REAL(kind=kind_phys), PARAMETER ::  pi = ACOS(-1.0), d2r = pi / 180.,&
       &small_value=1.e-30
  REAL(kind=kind_phys), ALLOCATABLE :: ll_src(:,:),ll_tgt(:,:),src_data(:),tgt_data(:)

  INTEGER :: ntimes,ntimes_delay,year,month,day,hour
  REAL(kind=kind_phys) :: ts
  REAL(kind=kind_phys) :: tstep,fcst_length,delay_time,&
       &output_interval,dx,dy
  INTEGER :: nx_fixed, ny_fixed
  LOGICAL :: sppt_interpolate,fillvalue_correct,write_stoch_pattern

  NAMELIST /chem_io/cdate,fnamein_prefix,fnameout_prefix,varlist,&
       &tstep,fcst_length,delay_time,output_interval,&
       &nx_fixed,ny_fixed,sppt_interpolate,fillvalue_correct,&
       &write_stoch_pattern,fnameout_pattern

  NAMELIST /chem_stoch/do_sppt,do_skeb,pert_epbl
  nlunit=10
  OPEN (unit=nlunit, file='input.nml', status='OLD')
  cdate='2018010100'
  varlist(:)=""
  tstep=3600.
  fcst_length=86400.
  delay_time=21600.
  output_interval=3600.
  nx_fixed=360
  ny_fixed=180
  sppt_interpolate=.TRUE.
  fillvalue_correct=.FALSE.
  write_stoch_pattern=.false.
  fnameout_pattern="./OUTPUT/ocn_stoch.res.nc"


  READ(nlunit,chem_io)
  nvars=COUNT(varlist /= "")

  dtp=tstep 
  dt=timedelta(seconds=tstep)
  ntimes=NINT((fcst_length+delay_time)/tstep)
  ntimes_delay=NINT(delay_time/tstep)
  time_attstring='hours since '//&
       &cdate(1:4)//'-'//cdate(5:6)//'-'//cdate(7:8)//' '//&
       &cdate(9:10)//':00:00'
  READ(cdate(1:4),'(i4)')year
  READ(cdate(5:6),'(i2)')month
  READ(cdate(7:8),'(i2)')day
  READ(cdate(9:10),'(i2)')hour
  datatime_start=create_datetime(year=year,month=month,day=day,hour=hour)

  do_sppt=.FALSE.
  do_skeb=.FALSE.
  pert_epbl=.FALSE.
  READ(nlunit,chem_stoch)
  PRINT*,'do_sppt=',do_sppt
  PRINT*,'do_skeb=',do_skeb
  CLOSE(nlunit)

  IF (do_skeb .OR. pert_epbl) THEN
     PRINT *,'skeb and pert_pbl not implemented - stopping'
     STOP
  ENDIF

  CALL fms_init()
  CALL mpp_init()

  root_pe=0
  comm=MPI_COMM_WORLD

  fnamein=TRIM(fnamein_prefix)//'.nc'
  CALL read_ncgrid(fnamein,lon_tgt,lat_tgt)

  nxx=SIZE(lon_tgt)
  nyy=SIZE(lat_tgt)

  IF (sppt_interpolate) THEN

     nx=nx_fixed
     ny=ny_fixed
     nxy=nx*ny  
     nxxyy=nxx*nyy
     
     ALLOCATE(xlon(nx,ny),xlat(nx,ny),ll_src(nxy,2),&
          &xlon_tgt(nxx,nyy),xlat_tgt(nxx,nyy),ll_tgt(nxxyy,2))
     ALLOCATE(src_data(nxy),tgt_data(nxxyy))

     l=0
     dx=360./nx_fixed
     dy=180./ny_fixed
     DO i=1,nx
        DO j=1,ny
           xlon(i,j)=i*dx-0.5*dx
           xlat(i,j)=j*dy-0.5*dy-90.
           l=l+1
           ll_src(l,1)=xlat(i,j)*d2r
           ll_src(l,2)=xlon(i,j)*d2r
        ENDDO
     ENDDO

     l=0
     DO i=1,nxx
        DO j=1,nyy
           l=l+1
           ll_tgt(l,1)=lat_tgt(j)*d2r
           ll_tgt(l,2)=lon_tgt(i)*d2r
           xlon_tgt(i,j)=lon_tgt(i)
           xlat_tgt(i,j)=lat_tgt(j)
        ENDDO
     ENDDO
     
     CALL slint_init(ll_src, nxy, ll_tgt, nxxyy)

  ELSE

     nx=nxx
     ny=nyy

     ALLOCATE(xlon(nx,ny),xlat(nx,ny))

     DO i=1,nx
        DO j=1,ny
           xlon(i,j)=lon_tgt(i)
           xlat(i,j)=lat_tgt(j)
        ENDDO
     ENDDO

  ENDIF

  CALL init_stochastic_physics_ocn(dtp,xlon,xlat,nx,ny,1,&
       &pert_epbl,do_sppt,do_skeb, root_pe, comm, iret)

  IF (iret .NE. 0) PRINT *, 'ERROR init_stochastic_physics call'

  ALLOCATE(sppt_wts(nx,ny))

  ALLOCATE(vardata(nxx,nyy),workg(nxx,nyy))

  DO itime=1,ntimes

     CALL run_stochastic_physics_ocn(sppt_wts,skeb_wts,t_rp1,t_rp2)

     PRINT *,'min/max SPPT_WTS=',itime,MINVAL(sppt_wts),MAXVAL(sppt_wts)

     IF (itime < ntimes_delay) CYCLE

     ts=itime-ntimes_delay

     IF (MOD(ts,output_interval/3600.) > 0) CYCLE

     dtime=timedelta(seconds=ts*tstep)
     datatime=datatime_start+dtime
     isostring=datatime%isoformat()
     timestring=isostring(1:4)//isostring(6:7)//&
          &isostring(9:10)//'t'//isostring(12:19)

     fnameout=TRIM(fnameout_prefix)//TRIM(timestring)//'z.nc'

     command="/bin/cp "//TRIM(fnamein)//" "//TRIM(fnameout)
     
     CALL execute_command_line(command, cmdstat=cstat, cmdmsg=cmsg)
     
     IF (cstat > 0) THEN
        PRINT *, "command execution failed with error ", TRIM(cmsg)
        STOP
     ELSE IF (cstat < 0) THEN
        PRINT *, "command execution not supported"
        STOP
     END IF

     CALL check_nc(nf90_open(TRIM(fnameout),mode=nf90_write,&
          &ncid=ncid))
     CALL check_nc(nf90_inq_varid(ncid,'time',time_var_id))
     CALL check_nc(nf90_redef(ncid))
     CALL check_nc(nf90_put_att(ncid,time_var_id,'units',&
          &TRIM(time_attstring)))
     CALL check_nc(nf90_enddef(ncid))
     CALL check_nc(nf90_put_var(ncid,time_var_id,ts,(/1/)))

     IF (sppt_interpolate) THEN
        
        l=0
        DO i=1,nx
           DO j=1,ny
              l=l+1
              src_data(l)=sppt_wts(i,j)
           ENDDO
        ENDDO

        CALL bilinear_interp(src_data,tgt_data)
        
        l=0
        DO i=1,nxx
           DO j=1,nyy
              l=l+1
              workg(i,j)=tgt_data(l)
           ENDDO
        ENDDO
        
     ELSE
        
        workg=sppt_wts
        
     ENDIF

     DO i=1,nvars
        varname=TRIM(varlist(i))
        CALL check_nc(nf90_inq_varid(ncid,varname,varid))
        CALL check_nc(nf90_get_var(ncid,varid,vardata))
        vardata=workg-1.
     ENDDO

     CALL check_nc(nf90_put_var(ncid,varid,vardata,(/1,1,1/)))
     
     CALL check_nc(nf90_close(ncid))

  ENDDO
  
  IF (write_stoch_pattern)  &
       &CALL write_stoch_restart_ocn(TRIM(fnameout_pattern))
  
CONTAINS

  SUBROUTINE read_ncgrid(fnamein,lon,lat)
    
    IMPLICIT NONE
    
    CHARACTER(*), INTENT(in) :: fnamein
    REAL(kind=kind_phys), DIMENSION(:), ALLOCATABLE, INTENT(out) :: &
         &lon,lat

    CHARACTER(len=max_varname_length) :: varname
    INTEGER :: dimids(1),dims(1)
    INTEGER :: varid

    CALL check_nc(nf90_open(fnamein, nf90_nowrite, ncid))
    
    varname='lon'
    CALL check_nc(nf90_inq_varid(ncid,TRIM(varname),varid))
    CALL check_nc(nf90_inquire_variable(ncid,varid,dimids=dimids))
    CALL check_nc(nf90_inquire_dimension(ncid,dimids(1),len=dims(1)))
    ALLOCATE(lon(dims(1)))
    CALL check_nc(nf90_get_var(ncid,varid,lon))

    varname='lat'
    CALL check_nc(nf90_inq_varid(ncid,TRIM(varname),varid))
    CALL check_nc(nf90_inquire_variable(ncid,varid,dimids=dimids))
    CALL check_nc(nf90_inquire_dimension(ncid,dimids(1),len=dims(1)))
    ALLOCATE(lat(dims(1)))
    CALL check_nc(nf90_get_var(ncid,varid,lat))
    CALL check_nc(nf90_close(ncid))

  END SUBROUTINE read_ncgrid

  SUBROUTINE check_nc(status)
    INTEGER, INTENT(in) :: status
    
    IF(status /= nf90_noerr) THEN
       PRINT *, TRIM(nf90_strerror(status))
       STOP 1
    END IF
  END SUBROUTINE check_nc
  
END PROGRAM standalone_stochy_weights

