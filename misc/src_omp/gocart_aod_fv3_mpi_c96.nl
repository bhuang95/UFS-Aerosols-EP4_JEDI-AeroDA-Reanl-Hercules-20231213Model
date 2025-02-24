&record_input
 input_dir = "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/expruns/aero_c96_jedi3densvar/enkfgdas.20180414/00/mem001/RESTART"
 fname_akbk = "20180414.060000.fv_core.res.nc"
 fname_core = "20180414.060000.fv_core.res.tile1.nc"
 fname_tracer = "20180414.060000.fv_tracer.res.tile1.nc"
 output_dir = "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/expruns/aero_c96_jedi3densvar/enkfgdas.20180414/00/mem001/RESTART"
 fname_aod = "20180414.060000.fv_aod.res.tile1.nc"
/
&record_conf
 Model = "CRTM"
 Absorbers = "H2O","O3"
 Sensor_ID = "v.viirs-m_npp"
 EndianType = "big_endian"
 CoefficientPath = "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/data/crtm"
 AerosolOption = "aerosols_gocart_default"
 Channels = 4
/