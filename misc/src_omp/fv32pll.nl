&record_input
 date="2018041406"
 input_grid_dir="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/fix_fv3/C96"
 fname_grid="grid_spec.tile?.nc"
 input_fv3_dir="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/from_cory/control"
 fname_fv3_tracer="20180414.060000.fv_tracer.anal.tile?.nc"
 fname_fv3_core="20180414.060000.fv_core.res.tile?.nc"
 fname_akbk="20180414.060000.fv_core.res.nc"
/
&record_interp
!varlist_in is only for illustration since translation is hard-coded
!and will not aggregate correctly if all species not present
 varlist_in= "bc1","bc2","dust1","dust2","dust3","dust4","dust5","oc1","oc2","seas1","seas2","seas3","seas4","seas5","sulf"
!varlist_out is only for illustration since translation is hard-coded
!and will not aggregate correctly if all species not present
 varlist_out= "BCPHOBIC","BCPHILIC","DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL","OCPHOBIC","OCPHILIC","SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL","SO4"
 plist = 100.,250.,400.,500.,600.,700.,850.,925.,1000.
 dlon=0.5
 dlat=0.5
/
&record_output
! output_dir="/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/MODEL/pll"
! fname_pll="20180414.060000.fv_pll.nc"
  output_dir="./"
 fname_pll="fv3_test.nc"
/
