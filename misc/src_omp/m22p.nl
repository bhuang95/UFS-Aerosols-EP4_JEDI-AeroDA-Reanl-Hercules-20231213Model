&record_input
 date="20160601"
 input_m2_dir="/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/MODEL/m2/akbkll"
 fname_m2="MERRA2_400.inst3_3d_aer_Nv.20160601.nc4"
 fname_akbk="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/fix_m2/akbk72.nc4"
/
&record_interp
!varlist_in is only for illustration since translation is hard-coded
!and will not aggregate correctly if all species not present
 varlist_in= "BCPHOBIC","BCPHILIC","DU001","DU002","DU003","DU004","DU005","OCPHOBIC","OCPHILIC","SS001","SS002","SS003","SS004","SS005","SO4"
!varlist_out is only for illustration since translation is hard-coded
!and will not aggregate correctly if all species not present
 varlist_out= "BCPHOBIC","BCPHILIC","DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL","OCPHOBIC","OCPHILIC","SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL","SO4"
 plist = 100.,250.,400.,500.,600.,700.,850.,925.,1000.
/
&record_output
 output_dir="./"
 fname_pll="m2_test.nc"
/
