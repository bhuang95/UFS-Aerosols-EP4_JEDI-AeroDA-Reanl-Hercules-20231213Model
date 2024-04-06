!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! viirs2ioda_nc
!! - module for netCDF i/o routines for viirs2ioda 
!!
!! author: Cory Martin - cory.r.martin@noaa.gov
!! history: 2019-03-04 - original
! some changes MZP
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module viirs2ioda_nc
  use netcdf
  implicit none

contains
  subroutine read_viirsaod_nc
    ! reads input netCDF file, allocates arrays,
    ! and puts observation data into memory
    use viirs2ioda_vars, only: infile, &
                               nobs, viirs_aod_input, n_channels, &
                               sat, inst, retrieval_type, tendstr,validtime,tdiff
    use timedelta_mod
    use datetime_mod

    implicit none
    ! netCDF required variables
    integer :: ncid ! netCDF file ID
    integer :: dimid ! dimension ID for inquiry
    integer :: rowid, colid
    ! dimension sizes
    integer :: nrows, ncols
    ! variable IDs
    integer :: varid
    integer :: qcid

    ! data arrays
    real, allocatable, dimension(:,:) :: in_lats, in_lons
    real, allocatable, dimension(:) :: in_lats1d, in_lons1d, in_aodtmp
    real, allocatable, dimension(:,:) :: in_AOD550
    real, allocatable, dimension(:) :: in_AOD5501d
    integer(SELECTED_INT_KIND(2)), allocatable, dimension(:,:) :: in_qcpath,in_qcall
    integer(SELECTED_INT_KIND(2)), allocatable, dimension(:) :: in_qcpath1,in_qcall1d
    
    integer :: i,j,nobs2,qcval
    real :: ab,bb,au,bu,viirs_aod_max
    integer :: yyyy,mm,dd,hh,ii,qc_retain

    INTEGER :: status,ipos

    type(datetime_type) :: datatime
    type(timedelta_type) dt

!only retain high quality
    qc_retain = 0 ! Retrieval quality:  0: high; 1: medium; 2: low; 3: no retrieval
    viirs_aod_max = 5. ! To remove AOD larger than 5.0

    ! open the file
    call check_nc(nf90_open(infile, nf90_nowrite, ncid))
    ! get the size of the dimensions in the file to allocate arrays
    call check_nc(nf90_inq_dimid(ncid,"Rows",dimid))
    call check_nc(nf90_inquire_dimension(ncid,dimid,len=nrows))
    call check_nc(nf90_inq_dimid(ncid,"Columns",dimid))
    call check_nc(nf90_inquire_dimension(ncid,dimid,len=ncols))

    nobs = nrows*ncols

    ! allocate arrays
    allocate(in_lats(ncols,nrows),in_lons(ncols,nrows))
    allocate(in_lats1d(nobs),in_lons1d(nobs))
    allocate(in_aodtmp(nobs))
    allocate(in_qcpath(ncols,nrows),in_qcall(ncols,nrows))
    allocate(in_qcpath1(nobs),in_qcall1d(nobs))
    allocate(in_AOD550(ncols,nrows),in_AOD5501d(nobs))

    call check_nc(nf90_inq_varid(ncid,"Latitude",varid))
    call check_nc(nf90_get_var(ncid,varid,in_lats))
    call check_nc(nf90_inq_varid(ncid,"Longitude",varid))
    call check_nc(nf90_get_var(ncid,varid,in_lons))
    call check_nc(nf90_inq_varid(ncid,"AOD550",varid))
    call check_nc(nf90_get_var(ncid,varid,in_AOD550))
    call check_nc(nf90_inq_varid(ncid,"QCPath",qcid))
    call check_nc(nf90_get_var(ncid,qcid,in_qcpath))
    call check_nc(nf90_inq_varid(ncid,"QCAll",qcid))
    call check_nc(nf90_get_var(ncid,qcid,in_qcall))
    ! metadata

    status = nf90_get_att(ncid,NF90_GLOBAL,"satellite_name",sat)
    status = nf90_get_att(ncid,NF90_GLOBAL,"instrument_name",inst)
    IF (status /= 0 .OR. TRIM(inst)=="VIIRS") inst="v.viirs-m_npp"
    status = nf90_get_att(ncid,NF90_GLOBAL,"summary",retrieval_type)
    IF (retrieval_type(1:10)=="Enterprise") THEN
       retrieval_type="NESDIS Enterprise AOD"
    ELSE
       retrieval_type="unknown"
    ENDIF

 
    status = nf90_get_att(ncid,NF90_GLOBAL,"time_coverage_end",tendstr)

    IF (status == 0) THEN
       READ( tendstr(1:4), '(i4)' )  yyyy
       READ( tendstr(6:7), '(i2)' )  mm
       READ( tendstr(9:10), '(i2)' )  dd
       READ( tendstr(12:13), '(i2)' )  hh
       READ( tendstr(15:17), '(i2)' )  ii 
    ELSE
       ipos=INDEX(infile,'_e')
       tendstr=infile(ipos+2:ipos+13)
       READ( tendstr(1:4), '(i4)' )  yyyy
       READ( tendstr(5:6), '(i2)' )  mm
       READ( tendstr(7:8), '(i2)' )  dd
       READ( tendstr(9:10), '(i2)' )  hh
       READ( tendstr(11:12), '(i2)' )  ii
    ENDIF
  
    ! place into viirs_aod type array
    WHERE(in_AOD550 < 0.) in_qcall=3
    WHERE(in_AOD550 > viirs_aod_max) in_qcall=3

    in_aodtmp = pack(in_qcall,in_qcall <= qc_retain)
    in_lats1d = reshape(in_lats,shape(in_lats1d))
    in_lons1d = reshape(in_lons,shape(in_lons1d))
    in_AOD5501d = reshape(in_AOD550,shape(in_AOD5501d))
    in_qcall1d = reshape(in_qcall,shape(in_qcall1d))
    in_qcpath1 = reshape(in_qcpath,shape(in_qcpath1))
    nobs = size(in_aodtmp)


    IF (nobs  <= 0) THEN 
       PRINT *,TRIM(infile)
       PRINT *,'No valid obs at '//TRIM(tendstr)
       STOP
    ENDIF

    PRINT *,TRIM(infile)
    PRINT *,'There are valid obs at '//TRIM(tendstr)

    allocate(viirs_aod_input(nobs))
    i=1
    DO j=1,nrows*ncols
      if (in_qcall1d(j) <= qc_retain) then 
        viirs_aod_input(i)%values550=in_AOD5501d(j)
        viirs_aod_input(i)%lat=in_lats1d(j)
        viirs_aod_input(i)%lon=in_lons1d(j)
        viirs_aod_input(i)%qcall=in_qcall1d(j)
        if (btest(in_qcpath1(j),0)) then ! water
          qcval = 0 + in_qcall1d(j) 
          viirs_aod_input(i)%stype = 0
        else
          if (btest(in_qcpath1(j),1)) then ! bright land
            qcval = 10 + in_qcall1d(j)
            viirs_aod_input(i)%stype = 2
          else ! dark land
            qcval = 20 + in_qcall1d(j)
            viirs_aod_input(i)%stype = 1
          end if
        end if


        select case(qcval)
        ! case all land high quality
        !ab = -0.0137694 ; bb = 0.153738 ; au = 0.111351 ; bu = 0.148685
        ! case all land medium quality
        !ab = 0.0177766 ; bb = 0.383993; au = 0.0468670 ; bu = 0.259278 
        case (10) ! case dark land high quality
          ab = -0.0138969; bb = 0.157877; au = 0.111431; bu = 0.128699
        case (11) ! case dark land medium quality
          ab = 0.0193166; bb = 0.376421; au = 0.0374849; bu = 0.266073
        case (20) ! case bright land high quality
          ab = -0.0107621; bb = 0.150480; au = 0.0550472; bu = 0.299558
        case (21) ! case bright land medium quality
          ab = 0.0124126; bb = 0.261174; au = 0.0693246; bu = 0.270070
        case (0) ! case water high quality
          ab = 0.0151799; bb = 0.0767385; au = 0.00784394; bu = 0.219923
        case (1) ! case water medium quality
          ab = 0.0377016; bb = 0.283547; au = 0.0416146; bu = 0.0808841
        case default
          ab = 0; bb = 100.; au = 0; bu = 100.
        end select
        viirs_aod_input(i)%bias = ab + bb*in_AOD5501d(j)
        viirs_aod_input(i)%uncertainty = au + bu*in_AOD5501d(j)

        i = i+1
      else
        cycle
      end if
    END DO

    deallocate(in_lats,in_lats1d,in_lons,in_lons1d,in_AOD550,in_AOD5501d)

    ! get time information, just assume the end time of the swath is the time
    ! for all obs (VIIRS will only be 1-2 mins per file, close enough
    datatime = create_datetime(year=yyyy,month=mm,day=dd,hour=hh,minute=ii)
    dt = datatime-validtime
    tdiff = dt%total_hours()      

    ! close the file
    call check_nc(nf90_close(ncid))

  end subroutine read_viirsaod_nc

  SUBROUTINE read_viirsaod_lunar_nc
    ! reads input netCDF file, allocates arrays,
    ! and puts observation data into memory
    use viirs2ioda_vars, only: infile, &
                               nobs, viirs_aod_input, n_channels, &
                               sat, inst, retrieval_type, tendstr,validtime,tdiff
    use timedelta_mod
    use datetime_mod

    implicit none
    ! netCDF required variables
    integer :: ncid ! netCDF file ID
    integer :: dimid ! dimension ID for inquiry
    integer :: rowid, colid
    ! dimension sizes
    integer :: nrows, ncols
    ! variable IDs
    integer :: varid
    integer :: qcid

    ! data arrays
    real, allocatable, dimension(:,:) :: in_lats, in_lons
    real, allocatable, dimension(:) :: in_lats1d, in_lons1d, in_aodtmp
    real, allocatable, dimension(:,:) :: in_AOD550
    real, allocatable, dimension(:) :: in_AOD5501d
    real, allocatable, dimension(:,:) :: in_qc
    real, allocatable, dimension(:) :: in_qc1d
    
    INTEGER :: i,j,nobs2,qcval,nobsvalid
    REAL,PARAMETER :: ab=0.,bb=0.,au=0.085,bu=0.1
    integer :: yyyy,mm,dd,hh,ii,qc_retain

    INTEGER :: status,ipos

    type(datetime_type) :: datatime
    type(timedelta_type) dt

!only retain high quality
    qc_retain = 3 ! Retrieval quality:  0: high; 1: medium; 2: low; 3: no retrieval

    ! open the file
    call check_nc(nf90_open(infile, nf90_nowrite, ncid))
    ! get the size of the dimensions in the file to allocate arrays
    call check_nc(nf90_inq_dimid(ncid,"lat",dimid))
    call check_nc(nf90_inquire_dimension(ncid,dimid,len=nrows))
    call check_nc(nf90_inq_dimid(ncid,"lon",dimid))
    call check_nc(nf90_inquire_dimension(ncid,dimid,len=ncols))

    nobs = nrows*ncols

    ! allocate arrays
    allocate(in_lats(ncols,nrows),in_lons(ncols,nrows))
    allocate(in_lats1d(nobs),in_lons1d(nobs))
    allocate(in_aodtmp(nobs))
    allocate(in_qc(ncols,nrows))
    allocate(in_qc1d(nobs))
    allocate(in_AOD550(ncols,nrows),in_AOD5501d(nobs))

    call check_nc(nf90_inq_varid(ncid,"latitude",varid))
    call check_nc(nf90_get_var(ncid,varid,in_lats))
    call check_nc(nf90_inq_varid(ncid,"longitude",varid))
    call check_nc(nf90_get_var(ncid,varid,in_lons))
    call check_nc(nf90_inq_varid(ncid,"AOD_550nm",varid))
    call check_nc(nf90_get_var(ncid,varid,in_AOD550))
    call check_nc(nf90_inq_varid(ncid,"AOD_QA",qcid))
    call check_nc(nf90_get_var(ncid,qcid,in_qc))

    sat="suomi_npp"
    inst="v.viirs-m_npp"
    retrieval_type="UofIowa lunar"
 
    ipos=INDEX(infile,'.nc')
    tendstr=infile(ipos-15:ipos-4)

    READ( tendstr(1:4), '(i4)' )  yyyy
    READ( tendstr(5:6), '(i2)' )  mm
    READ( tendstr(7:8), '(i2)' )  dd
    READ( tendstr(9:10), '(i2)' )  hh
    READ( tendstr(11:12), '(i2)' )  ii
  
    in_lats1d = RESHAPE(in_lats,SHAPE(in_lats1d))
    in_lons1d = RESHAPE(in_lons,SHAPE(in_lons1d))
    in_AOD5501d = RESHAPE(in_AOD550,SHAPE(in_AOD5501d))
    in_qc1d = RESHAPE(in_qc,SHAPE(in_qc1d))

    nobsvalid=COUNT(in_qc1d(:) >= qc_retain &
         & .AND. in_AOD5501d(:) >= 0. .AND. in_AOD5501d(:) <= 5.)

    PRINT *,TRIM(infile)
    PRINT *,'There are ',nobsvalid,' valid obs at '//TRIM(tendstr)

    ALLOCATE(viirs_aod_input(nobsvalid))
    i=1
    DO j=1,nobs
       
       IF (in_qc1d(j) >= qc_retain &
            & .AND. in_AOD5501d(j) >= 0. .AND. in_AOD5501d(j) <= 5.) THEN 
          
          in_qc1d(j)=0
          
          viirs_aod_input(i)%values550=in_AOD5501d(j)
          viirs_aod_input(i)%lat=in_lats1d(j)
          viirs_aod_input(i)%lon=in_lons1d(j)
          viirs_aod_input(i)%qcall=in_qc1d(j)
          viirs_aod_input(i)%bias = ab + bb*in_AOD5501d(j)
          viirs_aod_input(i)%uncertainty = au + bu*in_AOD5501d(j)
          viirs_aod_input(i)%stype = 1
          
          i = i+1
          
       ELSE
          CYCLE
    
       END IF
    END DO
    
    nobs=nobsvalid

    DEALLOCATE(in_lats,in_lats1d,in_lons,in_lons1d,&
         &in_AOD550,in_AOD5501d,in_qc,in_qc1d)

    ! get time information, just assume the end time of the swath is the time
    ! for all obs (VIIRS will only be 1-2 mins per file, close enough
    datatime = create_datetime(year=yyyy,month=mm,day=dd,hour=hh,minute=ii)
    dt = datatime-validtime
    tdiff = dt%total_hours()      

    ! close the file
    call check_nc(nf90_close(ncid))

  END SUBROUTINE read_viirsaod_lunar_nc

  SUBROUTINE write_iodaaod_nc
    ! write netCDF file in a format that is readable by IODA
    use viirs2ioda_vars, only: outfile, &
                               n_channels, nvars, ichan, &
                               &nobs_out, viirs_aod_output,&
                               sat,inst,retrieval_type,&
                               &validtimestr,tdiff,tdiffout
    use datetime_mod
    USE module_constants, ONLY: MAXVARLEN

    implicit none
    ! netCDF required variables

    integer :: ncid ! netCDF file ID
    integer :: nlocsid, nobsid, nrecsid, nvarsid ! dimension IDs
    integer, dimension((n_channels*3)+9) :: varids
    integer :: i,j
    character(5) :: chchar
    character(len=MAXVARLEN) :: varname
    integer :: validtimeint

    REAL, DIMENSION(n_channels) :: freqs, wvlens, wvnums
    INTEGER, DIMENSION(n_channels) :: chans

    IF (nobs_out==0) RETURN

    ! create the file, add dimensions, variables, and metadata
    call check_nc(nf90_create(path=outfile,cmode=nf90_netcdf4,ncid=ncid))

    ! global attributes
    !call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"Satellite_Sensor",trim(sensor)))
    call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"observation_type","Aod"))
    
    read(validtimestr,"(i)") validtimeint
    call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"date_time",validtimeint))
    ! below to conform to current JEDI names, use better logic later
    call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"satellite",sat))
    call check_nc(nf90_put_att(ncid,NF90_GLOBAL,"sensor",inst))
    CALL check_nc(nf90_put_att(ncid,NF90_GLOBAL,"retrieval_type",TRIM(retrieval_type)))

    ! dimensions
    CALL check_nc(nf90_def_dim(ncid,'nlocs',NF90_UNLIMITED,nlocsid))
    call check_nc(nf90_def_dim(ncid,'nvars',nvars,nvarsid)) ! force just outputting channel 4

    ! variables
    ! note, some of these variable names need to be changed eventually (see
    ! commented out lines for example)
    call check_nc(nf90_def_var(ncid,'frequency@VarMetaData',nf90_real,nvarsid,varids(1)))
    call check_nc(nf90_def_var(ncid,'wavenumber@VarMetaData',nf90_real,nvarsid,varids(2)))
    call check_nc(nf90_def_var(ncid,'sensor_channel@VarMetaData',nf90_int,nvarsid,varids(3)))
    call check_nc(nf90_def_var(ncid,'latitude@MetaData',nf90_float,nlocsid,varids(4)))
    call check_nc(nf90_def_var(ncid,'longitude@MetaData',nf90_float,nlocsid,varids(5)))
    call check_nc(nf90_def_var(ncid,'sol_zenith_angle@MetaData',nf90_float,nlocsid,varids(6)))
    call check_nc(nf90_def_var(ncid,'sol_azimuth_angle@MetaData',nf90_float,nlocsid,varids(7)))
    call check_nc(nf90_def_var(ncid,'surface_type@MetaData',nf90_int,nlocsid,varids(8)))
    call check_nc(nf90_def_var(ncid,'time@MetaData',nf90_float,nlocsid,varids(9)))

    WRITE(chchar,'(i5)') ichan
    j = 9

    j=j+1
    varname = 'aerosol_optical_depth_'//TRIM(ADJUSTL(chchar))//'@ObsValue'
    CALL check_nc(nf90_def_var(ncid,TRIM(varname),nf90_float,nlocsid,varids(j))) 

    j=j+1
    varname = 'aerosol_optical_depth_'//TRIM(ADJUSTL(chchar))//'@ObsError'
    CALL check_nc(nf90_def_var(ncid,TRIM(varname),nf90_float,nlocsid,varids(j))) 

    j=j+1
    varname = 'aerosol_optical_depth_'//TRIM(ADJUSTL(chchar))//'@PreQc'
    CALL check_nc(nf90_def_var(ncid,TRIM(varname),nf90_float,nlocsid,varids(j))) 

    call check_nc(nf90_enddef(ncid))

    wvlens = (/550./)
    wvnums = 10000000./wvlens
    freqs = 2.99792458e8 / (wvlens*1e-9)
    chans = (/ichan/)

    ! for now assign the same time to all the obs
    tdiffout(:) = tdiff

    ! put the variables into the file
    call check_nc(nf90_put_var(ncid,varids(1),freqs))
    call check_nc(nf90_put_var(ncid,varids(2),wvnums))
    call check_nc(nf90_put_var(ncid,varids(3),chans))
    call check_nc(nf90_put_var(ncid,varids(4),viirs_aod_output(:)%lat))
    call check_nc(nf90_put_var(ncid,varids(5),viirs_aod_output(:)%lon))
    call check_nc(nf90_put_var(ncid,varids(6),0.))! solar zenith all 0 for test
    call check_nc(nf90_put_var(ncid,varids(7),0.))! solar azimuth all 0 for test
    call check_nc(nf90_put_var(ncid,varids(8),viirs_aod_output(:)%stype)) !surface type
    call check_nc(nf90_put_var(ncid,varids(9),tdiffout(:)))

    j=9

    viirs_aod_output(:)%values550=MAX(viirs_aod_output(:)%values550-viirs_aod_output(:)%bias,0.)

    viirs_aod_output(:)%bias=0.

! obs value
    j=j+1
    CALL check_nc(nf90_put_var(ncid,varids(j),viirs_aod_output(:)%values550))

! obs error
    j=j+1
    CALL check_nc(nf90_put_var(ncid,varids(j),viirs_aod_output(:)%uncertainty))

! obs qc
    j=j+1
    CALL check_nc(nf90_put_var(ncid,varids(j),viirs_aod_output(:)%qcall))


    call check_nc(nf90_close(ncid)) ! close and finish writing out
    print *, 'Wrote to outfile: ', trim(outfile)
    
  end subroutine write_iodaaod_nc


  subroutine read_fv3_grid(griddata,grid_files)
    ! read FV3 grid for regridding/thinning purposes
    ! from M. Pagowski
    use viirs2ioda_vars, only: ntiles_fv3
    integer, parameter :: &
       &max_name_length_fv3=NF90_MAX_NAME, max_dims_fv3=4, max_vars_fv3=100
    real, allocatable, dimension(:,:), intent(out) :: griddata
    character(len = max_name_length_fv3), dimension(ntiles_fv3) :: grid_files

    integer, dimension(max_dims_fv3) :: dimids,dims
    character(len = max_name_length_fv3) :: input_file

    real, allocatable, dimension(:,:,:) :: tmpdata
    integer :: ncid,status,varid_lon,varid_lat,numdims,i,j,l,ij
    character(len = max_name_length_fv3) :: aname
    integer :: nx, ny, nxy, nxyg
    character(len = max_name_length_fv3), parameter :: &
       &varname_lon_fv3='grid_lont',varname_lat_fv3='grid_latt'

    input_file=trim(grid_files(1))

    call check_nc(nf90_open(input_file, nf90_nowrite, ncid))
    call check_nc(nf90_inq_varid(ncid, varname_lon_fv3, varid_lon))
    call check_nc(nf90_inquire_variable(ncid, varid_lon, aname, ndims=numdims))
    call check_nc(nf90_inquire_variable(ncid, varid_lon, dimids = dimids(:numdims)))
    call check_nc(nf90_inq_varid(ncid, varname_lat_fv3, varid_lat))

    dims=1

    do i=1,numdims
       call check_nc(nf90_inquire_dimension(ncid,dimids(i),len=dims(i)))
    end do

    nx=dims(1)
    ny=dims(2)
    nxy=nx*ny
    nxyg=ntiles_fv3*nxy
    allocate(tmpdata(nx,ny,2),griddata(2,nxyg))

    call check_nc(nf90_close(ncid))

    do l=1,ntiles_fv3
       input_file=trim(grid_files(l))
       call check_nc(nf90_open(input_file, nf90_nowrite, ncid))
       call check_nc(nf90_get_var(ncid,varid_lat,tmpdata(:,:,1), &
            start = (/ 1, 1 /), &
            count = (/ nx, ny /) ))
       call check_nc(nf90_get_var(ncid,varid_lon,tmpdata(:,:,2), &
            start = (/ 1, 1 /), &
            count = (/ nx, ny /) ))
       call check_nc(nf90_close(ncid))
       ij=1
       do j=1,ny
          do i=1,nx
             griddata(:,ij+(l-1)*nxy) = tmpdata(i,j,:)
             ij=ij+1
          end do
       end do
    end do

    deallocate(tmpdata)

  end subroutine read_fv3_grid


  subroutine check_nc(status)
    integer, intent(in) :: status

    if(status /= nf90_noerr) then
      print *, trim(nf90_strerror(status))
      stop "netCDF error...Stopped."
    end if
  end subroutine check_nc

end module viirs2ioda_nc
