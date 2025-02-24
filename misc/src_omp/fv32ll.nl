&record_input
 date="2018041500"
 input_grid_dir="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/fix_fv3/C96"
 fname_grid="grid_spec.tile?.nc"
 input_fv3_dir="/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/envar_2018/C96/RESTART/gfs_aero_c96/bkg"
 fname_fv3_tracer="20180415.000000.fv_tracer.res.tile?.nc"
 fname_fv3_core="20180415.000000.fv_core.res.tile?.nc"
 fname_akbk="akbk64.nc4"
/
&record_interp
 varlist_core= "T"
 varlist_tracer= "sphum","bc1","bc2","dust1","dust2","dust3","dust4","dust5","oc1","oc2","seas1","seas2","seas3","seas4","seas5","sulf"
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="./"
 fname_ll="fv3_test.nc"
/
