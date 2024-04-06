&record_input
 input_dir = "./data"
 fname_akbk = "20200614.000000.fv_core.res.nc"
 fname_core = "20200614.000000.fv_core.res.tile1.nc"
 fname_tracer = "20200614.000000.fv_tracer.res.tile1.nc"
 output_dir = "./"
 fname_aod = "20200614.120000.fv_aod.res.tile1.nc"
/
&record_model
! Model = "AodCRTM"
 Model = "AodLUTs"
/
&record_conf_crtm
!this option is invaleid for hofx
 AerosolOption = "aerosols_gocart_default"
 Absorbers = "H2O","O3"
 Sensor_ID = "v.viirs-m_npp"
 EndianType = "big_endian"
 CoefficientPath = "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/crtm_fix"
 Channels = 4
/
&record_conf_luts
 AerosolOption = "aerosols_gocart_2"
!single wavelength only for hofx
 WavelengthsOutput = 550.
! WavelengthsOutput = 340.,380.,440.,500.,550.,675.,870.,1020.,1640.
 RCFile = "all_wavelengths.rc"
/
