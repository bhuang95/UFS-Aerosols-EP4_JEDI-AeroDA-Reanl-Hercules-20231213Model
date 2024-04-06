&record_input
 input_dir = "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/data/fv3-jedi/inputs/gfs_aero_c48/ensmean"
 fname_akbk = "20180415.000000.fv_core.res.nc"
 fname_core = "20180415.000000.fv_core.res.tile1.nc"
 fname_tracer = "20180415.000000.fv_tracer.res.tile1.nc"
 output_dir = "./"
 fname_aod = "20180415.000000.fv_aod.res.tile1.nc"
/
&record_model
! Model = "AodCRTM"
 Model = "AodLUTs"
/
&record_conf_crtm
 AerosolOption = "aerosols_gocart_default"
 Absorbers = "H2O","O3"
 Sensor_ID = "v.viirs-m_npp"
 EndianType = "big_endian"
 CoefficientPath = "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/crtm_fix"
 Channels = 4
/
&record_conf_luts
 AerosolOption = "aerosols_gocart_merra_2"
 Wavelengths = 550.
 RCFile = "geosaod.rc"
/
