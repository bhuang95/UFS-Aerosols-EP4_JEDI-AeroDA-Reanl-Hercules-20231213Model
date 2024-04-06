!from sam at 
!/scratch2/BMC/wrfruc/Samuel.Trahan/perturb-smoke/no-ncl
module util
  implicit none
contains
  subroutine check(what,err)
    use netcdf
    implicit none
    integer, intent(in) :: err
    character(len=*), intent(in) :: what
    if(err/=0) then
      call abort(what//': '//nf90_strerror(err))
    else
      print '(A,A)',trim(what),': success'
    endif
  end subroutine check

  function read1d(file,n)
    implicit none
    real, dimension(:), pointer :: read1d
    integer :: iunit,n,ios
    character(len=*), intent(in) :: file

    allocate(read1d(n))

    open(newunit=iunit,status='old',form='unformatted',file=trim(file),iostat=ios)
    if(ios/=0) call abort(trim(file)//': cannot open for read')
    read(iunit,iostat=ios) read1d
    if(ios/=0) call abort(trim(file)//': cannot read')
    close(iunit)
  end function read1d

  function read2d(file,n,m)
    implicit none
    real, dimension(:,:), pointer :: read2d
    integer :: iunit,n,m,ios
    character(len=*), intent(in) :: file

    allocate(read2d(n,m))

    open(newunit=iunit,status='old',form='unformatted',file=trim(file),iostat=ios)
    if(ios/=0) call abort(trim(file)//': cannot open for read')
    read(iunit,iostat=ios) read2d
    write(0,*) maxval(read2d),minval(read2d)
    if(ios/=0) call abort(trim(file)//': cannot read')
    close(iunit)
  end function read2d

  subroutine abort(why)
    implicit none
    character(len=*), intent(in) :: why
    write(0,'(A)') why
    stop 1
  end subroutine abort

  subroutine usage(why)
    implicit none
    character(len=*), intent(in), optional :: why
    write(0,'(A)') 'mkncbbepx < /path/to/mkncbbepx.nml'
    write(0,'(A)') ' '
    write(0,'(A)') 'Example of a correct namelist:'
    write(0,'(A)') ' '
    write(0,'(A)') '    &mkncbbepx'
    write(0,'(A)') '      ! These eight are mandatory:'
    write(0,'(A)') '      title="anthropogenic background input (C96, 10, tile1)"'
    write(0,'(A)') '      date="2020-08-31"'
    write(0,'(A)') '      tile=1'
    write(0,'(A)') '      nlat=96'
    write(0,'(A)') '      nlon=96'
    write(0,'(A)') '      outfile="/path/to/FIRE_GBBEPx_data.tile1.nc"'
    write(0,'(A)') '      pathlat="/path/to/lat_tile1.dat"'
    write(0,'(A)') '      pathlon="/path/to/lon_tile1.dat"'
    write(0,'(A)') '      ! These five are optional:'
    write(0,'(A)') '      pathebc="/path/to/GBBEPx.bc.20200831.FV3.C96Grid.tile1.bin"'
    write(0,'(A)') '      pathepm25="/path/to/GBBEPx.pm25.20200831.FV3.C96Grid.tile1.bin"'
    write(0,'(A)') '      patheeso2="/path/to/GBBEPx.so2.20200831.FV3.C96Grid.tile1.bin"'
    write(0,'(A)') '      patheoc="/path/to/GBBEPx.oc.20200831.FV3.C96Grid.tile1.bin"'
    write(0,'(A)') '      patheplume="/path/to/meanFRP.20200831.FV3.C96Grid.tile1.bin"'
    write(0,'(A)') '      ! If one is missing, its variable will not be written.'
    write(0,'(A)') '    /'
    if(present(why)) then
      write(0,'(A,A)') 'ERROR. Program is aborting because: ',trim(why)
      write(0,'(A)') 'See the example namelist above, and compare it to yours.'
    endif
  end subroutine usage
end module util

program prog_mkncgbbepx
  use util
  implicit none
  character(len=500) :: pathlon, pathlat, pathebc, patheoc, pathepm25, &
       patheso2, patheplume, outfile
  character(len=:), allocatable :: toutfile
  character(len=2000) :: title
  character(len=10) :: date
  integer :: nlat, nlon, iunit, tile
  logical :: exists

  real, pointer, dimension(:) :: lat=>null(), lon=>null()
  real, pointer, dimension(:,:) :: ebc=>null(), eoc=>null(), epm25=>null(), &
       eso2=>null(), plume=>null()

  if(command_argument_count()>0) then
    call usage('mkncgbbepx takes no command-line arguments.')
  endif

  title='*'
  date='*'
  tile=-1
  nlat=-1
  nlon=-1
  pathlon='*'
  pathlat='*'
  pathebc='*'
  patheoc='*'
  pathepm25='*'
  patheso2='*'
  patheplume='*'
  outfile='*'

  namelist /mkncgbbepx/ title, tile, date, nlon, nlat, outfile, &
       pathlon, pathlat, pathebc, patheoc, pathepm25, patheso2, &
       patheplume

  read(nml=mkncgbbepx,unit=5)

  if(date=='*') call usage('You must specify the date (date="20200831")')
  if(title=='*') call usage('You must specify the title (title="anthropogenic background input (C96, 10, tile1)")')
  if(tile<1) call usage('You must specify the tile (tile>0)')

  if(outfile=='*') call usage('You must specify the outfile')

  allocate(character(len=len_trim(outfile)) :: toutfile)
  toutfile=trim(outfile)
9 format('"',A,'"')

  if(nlat<1) call usage("nlat must be > 1")
  if(nlon<1) call usage("nlon must be > 1")
  if(pathlon=='*') call usage("You must specify pathlon")
  if(pathlat=='*') call usage("You must specify pathlat")

  lat=>read1d(trim(pathlat),nlat)
  lon=>read1d(trim(pathlon),nlon)

  if(pathebc/='*')   ebc=>read2d(trim(pathebc),nlat,nlon)
  if(patheoc/='*')   eoc=>read2d(trim(patheoc),nlat,nlon)
  if(pathepm25/='*') epm25=>read2d(trim(pathepm25),nlat,nlon)
  if(patheso2/='*')  eso2=>read2d(trim(patheso2),nlat,nlon)
  if(patheplume/='*') plume=>read2d(trim(patheplume),nlat,nlon)

  call write_netcdf(toutfile)

  print '(A)','SUCCESS. Write NetCDF GBBEPx data to "'//toutfile//'"'

contains

  subroutine write_netcdf(outfile)
    use netcdf
    implicit none
    character(len=*), intent(in) :: outfile
    integer :: ncid, latdimid, londimid, attid
    integer :: dims(2), varid(7)

    call check(toutfile//': open for write',nf90_create(toutfile,NF90_CLOBBER,ncid))

    call check(toutfile//': write date attribute',nf90_put_att(ncid,NF90_GLOBAL,'date',trim(date)))
    call check(toutfile//': write tile attribute',nf90_put_att(ncid,NF90_GLOBAL,'tile',tile))
    call check(toutfile//': write title attribute',nf90_put_att(ncid,NF90_GLOBAL,'title',trim(title)))

    call check(toutfile//': define lat dimension',nf90_def_dim(ncid,'lat',nlat,latdimid))
    call check(toutfile//': define lon dimension',nf90_def_dim(ncid,'lon',nlon,londimid))

    call check(toutfile//': define lat variable',nf90_def_var(ncid,'lat',NF90_FLOAT,latdimid,varid(6)))

    call check(toutfile//': define lon variable',nf90_def_var(ncid,'lon',NF90_FLOAT,londimid,varid(7)))

    dims=(/ londimid, latdimid /)

    if(associated(ebc)) then
      call check(toutfile//': define ebu_bc variable',nf90_def_var(ncid,'ebu_bc',NF90_FLOAT,dims,varid(1)))
    endif

    if(associated(eoc)) then
      call check(toutfile//': define ebu_oc variable',nf90_def_var(ncid,'ebu_oc',NF90_FLOAT,dims,varid(2)))
    endif

    if(associated(epm25)) then
      call check(toutfile//': define ebu_pm_25 variable',nf90_def_var(ncid,'ebu_pm_25',NF90_FLOAT,dims,varid(3)))
    endif

    if(associated(eso2)) then
      call check(toutfile//': define ebu_so2 variable',nf90_def_var(ncid,'ebu_so2',NF90_FLOAT,dims,varid(4)))
    endif

    if(associated(plume)) then
      call check(toutfile//': define ebu_frp variable',nf90_def_var(ncid,'ebu_frp',NF90_FLOAT,dims,varid(5)))
    endif

    call check(toutfile//': stop defining file',nf90_enddef(ncid))

    call check(toutfile//': write lat variable',nf90_put_var(ncid,varid(6),lat))
    call check(toutfile//': write lon variable',nf90_put_var(ncid,varid(7),lon))

    if(associated(ebc)) then
      print *,'ebu_bc max,min',maxval(ebc),minval(ebc),ebc
      call check(toutfile//': write ebu_bc variable',nf90_put_var(ncid,varid(1),ebc,(/1,1/),(/nlat,nlon/),(/1,1/)))
    endif

    if(associated(eoc)) then
      print *,'ebu_oc max,min',maxval(eoc),minval(eoc)
      call check(toutfile//': write ebu_oc variable',nf90_put_var(ncid,varid(2),eoc,(/1,1/),(/nlat,nlon/),(/1,1/)))
    endif

    if(associated(epm25)) then
      print *,'ebu_pm_25 max,min',maxval(epm25),minval(epm25)
      call check(toutfile//': write ebu_pm_25 variable',nf90_put_var(ncid,varid(3),epm25,(/1,1/),(/nlat,nlon/),(/1,1/)))
    endif

    if(associated(eso2)) then
      print *,'ebu_so2 max,min',maxval(eso2),minval(eso2)
      call check(toutfile//': write ebu_so2 variable',nf90_put_var(ncid,varid(4),eso2,(/1,1/),(/nlat,nlon/),(/1,1/)))
    endif

    if(associated(plume)) then
      print *,'ebu_frp max,min',maxval(plume),minval(plume)
      call check(toutfile//': write ebu_frp variable',nf90_put_var(ncid,varid(5),plume,(/1,1/),(/nlat,nlon/),(/1,1/)))
    endif

    call check(toutfile//': close',nf90_close(ncid))
  end subroutine write_netcdf

end program prog_mkncgbbepx
