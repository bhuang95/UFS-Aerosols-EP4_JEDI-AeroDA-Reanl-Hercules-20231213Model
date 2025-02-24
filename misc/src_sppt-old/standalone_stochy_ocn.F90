program  standalone_stochy

use stochastic_physics,  only : init_stochastic_physics_ocn,run_stochastic_physics_ocn
!use mpp_domains
use mpp_mod,             only: mpp_set_current_pelist,mpp_get_current_pelist,mpp_init,mpp_pe,mpp_npes ,mpp_declare_pelist,mpp_root_pe
use mpp_domains_mod,     only: mpp_broadcast_domain,MPP_DOMAIN_TIME,mpp_domains_init ,mpp_domains_set_stack_size
use fms_mod,             only:  fms_init
use xgrid_mod,           only: grid_box_type
use netcdf
use kinddef,             only : kind_dbl_prec,kind_phys
use stochy_namelist_def, only : stochini

implicit none
integer                 :: ntasks,fid
integer                 :: nthreads
integer                 :: ncid,xt_dim_id,yt_dim_id,time_dim_id,xt_var_id,yt_var_id,time_var_id,var_id_lat,var_id_lon
integer                 :: varid1,varid2,varid3,varid4
integer                 :: zt_dim_id,zt_var_id
character*2             :: strid

include 'mpif.h'
include 'netcdf.inc'
real(kind=4) :: ts,undef

integer     :: nb,blksz_1,nblks,ierr,my_id,i,j,k,l,nx,ny,id
integer     :: isc,iec,jsc,jec,isd,ied,jsd,jed
integer :: halo_update_type = 1
real        :: dx,dy
integer  :: nargs,nlunit,pe,npes,stackmax=4000000
integer  :: i1,i2,j1,npts,istart,tpt
character*80 :: fname
integer :: comm

real(kind=4),allocatable,dimension(:,:) :: workg
real(kind=4),allocatable,dimension(:) :: grid_xt,grid_yt
real(kind=kind_phys), dimension(:,:),   allocatable, save :: xlat
real(kind=kind_phys), dimension(:,:),   allocatable, save :: xlon

type(grid_box_type)           :: grid_box
real (kind=kind_phys),allocatable :: sppt_wts (:,:)
real (kind=kind_phys),allocatable :: skeb_wts (:,:)
real (kind=kind_phys),allocatable :: t_rp1 (:,:)
real (kind=kind_phys),allocatable :: t_rp2 (:,:)
integer              :: me              !< MPI rank designator
integer              :: root_pe         !< MPI rank of root atmosphere processor
real(kind=kind_phys) :: dtp             !< physics timestep in seconds
real(kind=kind_phys) :: fhour           !< previous forecast hour
integer              :: iret
logical  :: do_sppt,do_skeb,pert_epbl

      namelist /ocn_stoch_nml/do_sppt,do_skeb,pert_epbl
nlunit=23
nargs=iargc()
open (unit=nlunit, file='input.nml', status='OLD')
do_sppt=.false.
do_skeb=.false.
pert_epbl=.false.
read(nlunit,ocn_stoch_nml)
print*,'do_sppt=',do_sppt
print*,'do_skeb=',do_skeb
close(nlunit)
! define stuff
undef=9.99e+20

call fms_init()
call mpp_init()
call fms_init
my_id=mpp_pe()
ntasks=mpp_npes()

!read grid, emissions, and time interval here

! define a grid here
nx=360
ny=180
allocate(xlon(nx,ny))
allocate(xlat(nx,ny))
do i=1,nx
  do j=1,ny
    xlon(i,j)=(i-0.5)
    xlat(i,j)=(j-90.5)
   enddo
enddo
allocate(workg(nx,ny))
print*,'nx,ny=',nx,ny
print*,'lons=',minval(xlon),maxval(xlon)
print*,'lats=',minval(xlat),maxval(xlat)
nthreads = 1
me=my_id
fhour=0
dtp=600
nlunit=21

allocate(grid_xt(nx),grid_yt(ny))
do i=1,nx
  grid_xt(i)=i-0.5
enddo
do j=1,ny
  grid_yt(j)=j-90.5
enddo
root_pe=mpp_root_pe()
comm=MPI_COMM_WORLD
call init_stochastic_physics_ocn(dtp,xlon,xlat,nx,ny,1,pert_epbl,do_sppt, &
                                       do_skeb, root_pe, comm, iret)
if (iret .ne. 0) then
     print *, 'ERROR init_stochastic_physics call' ! Draper - need proper error trapping here
     call mpi_abort()
endif
call get_outfile(fname)
write(strid,'(I2.2)') my_id+1
fid=30+my_id
ierr=nf90_create(trim(fname)//'.nc',cmode=NF90_CLOBBER,ncid=ncid)
ierr=NF90_DEF_DIM(ncid,"grid_xt",nx,xt_dim_id)
ierr=NF90_DEF_DIM(ncid,"grid_yt",ny,yt_dim_id)
ierr=NF90_DEF_DIM(ncid,"time",NF90_UNLIMITED,time_dim_id)
!> - Define the dimension variables.
ierr=NF90_DEF_VAR(ncid,"grid_xt",NF90_FLOAT,(/ xt_dim_id /), xt_var_id)
ierr=NF90_PUT_ATT(ncid,xt_var_id,"long_name","T-cell longitude")
ierr=NF90_PUT_ATT(ncid,xt_var_id,"cartesian_axis","X")
ierr=NF90_PUT_ATT(ncid,xt_var_id,"units","degrees_E")
ierr=NF90_DEF_VAR(ncid,"grid_yt",NF90_FLOAT,(/ yt_dim_id /), yt_var_id)
ierr=NF90_PUT_ATT(ncid,yt_var_id,"long_name","T-cell latitude")
ierr=NF90_PUT_ATT(ncid,yt_var_id,"cartesian_axis","Y")
ierr=NF90_PUT_ATT(ncid,yt_var_id,"units","degrees_N")
ierr=NF90_DEF_VAR(ncid,"time",NF90_FLOAT,(/ time_dim_id /), time_var_id)
ierr=NF90_DEF_VAR(ncid,"time",NF90_FLOAT,(/ time_dim_id /), time_var_id)
ierr=NF90_PUT_ATT(ncid,time_var_id,"long_name","time")
ierr=NF90_PUT_ATT(ncid,time_var_id,"units","hours since 2014-08-01 00:00:00")
ierr=NF90_PUT_ATT(ncid,time_var_id,"cartesian_axis","T")
ierr=NF90_PUT_ATT(ncid,time_var_id,"calendar_type","JULIAN")
ierr=NF90_PUT_ATT(ncid,time_var_id,"calendar","JULIAN")
if (do_sppt)then
   ierr=NF90_DEF_VAR(ncid,"sppt_wts",NF90_FLOAT,(/xt_dim_id, yt_dim_id ,time_dim_id/), varid1)
   ierr=NF90_PUT_ATT(ncid,varid1,"long_name","sppt pattern")
   ierr=NF90_PUT_ATT(ncid,varid1,"units","None")
   ierr=NF90_PUT_ATT(ncid,varid1,"missing_value",undef)
   ierr=NF90_PUT_ATT(ncid,varid1,"_FillValue",undef)
   ierr=NF90_PUT_ATT(ncid,varid1,"cell_methods","time: point")
endif
if (do_skeb)then
   ierr=NF90_DEF_VAR(ncid,"skeb_wts",NF90_FLOAT,(/xt_dim_id, yt_dim_id ,time_dim_id/), varid2)
   ierr=NF90_PUT_ATT(ncid,varid2,"long_name","skeb u pattern")
   ierr=NF90_PUT_ATT(ncid,varid2,"units","None")
   ierr=NF90_PUT_ATT(ncid,varid2,"missing_value",undef)
   ierr=NF90_PUT_ATT(ncid,varid2,"_FillValue",undef)
   ierr=NF90_PUT_ATT(ncid,varid2,"cell_methods","time: point")
endif
ierr=NF90_ENDDEF(ncid)
ierr=NF90_PUT_VAR(ncid,xt_var_id,grid_xt)
ierr=NF90_PUT_VAR(ncid,yt_var_id,grid_yt)
ierr=NF90_PUT_VAR(ncid,var_id_lon,transpose(xlon(:,:)),(/1,1,1/))
ierr=NF90_PUT_VAR(ncid,var_id_lat,transpose(xlat(:,:)),(/1,1,1/))
if (do_sppt)allocate(sppt_wts(nx,ny))
if (do_skeb)allocate(skeb_wts(nx,ny))
if (pert_epbl > 0)allocate(t_rp1(nx,ny))
if (pert_epbl > 0)allocate(t_rp2(nx,ny))
if (stochini) then
   istart=11
else
   istart=1
endif
tpt=1
do i=istart,21
   ts=i/4.0
   call run_stochastic_physics_ocn(sppt_wts,skeb_wts,t_rp1,t_rp2)
   if (me.EQ.0 .and. do_sppt) print*,'SPPT_WTS=',i,sppt_wts(1,2)
   if (me.EQ.0 .and. do_sppt) print*,'writing sppt_wts=',i,sppt_wts(1,2)
   if (do_sppt)then
      do j=1,ny
         workg(:,j)=sppt_wts(:,j)   
      enddo
      ierr=NF90_PUT_VAR(ncid,varid1,workg,(/1,1,tpt/))
   endif
   if (do_skeb)then
      do j=1,ny
         workg(:,j)=skeb_wts(:,j)
      enddo
      print*,'writing skeb_wts=',me,skeb_wts(1,2)
      ierr=NF90_PUT_VAR(ncid,varid2,workg,(/1,1,tpt/))
      print*,ierr
   endif
   if (pert_epbl)then
      do j=1,ny
         workg(:,j)=t_rp1(:,j)   
      enddo
      ierr=NF90_PUT_VAR(ncid,varid3,workg,(/1,1,tpt/))
      do j=1,ny
         workg(:,j)=t_rp2(:,j)   
      enddo
      ierr=NF90_PUT_VAR(ncid,varid4,workg,(/1,1,tpt/))
   endif
   ierr=NF90_PUT_VAR(ncid,time_var_id,ts,(/tpt/))
   tpt=tpt+1
enddo
ierr=NF90_CLOSE(ncid)
end
subroutine get_outfile(fname)
use stochy_namelist_def
character*80,intent(out) :: fname
character*4   :: s_ntrunc,s_lat,s_lon
   write(s_ntrunc,'(I4)') ntrunc
   write(s_lat,'(I4)') lat_s 
   write(s_lon,'(I4)') lon_s  
   fname=trim('workg_T'//trim(adjustl(s_ntrunc))//'_'//trim(adjustl(s_lon))//'x'//trim(adjustl(s_lat)))
   return
end
