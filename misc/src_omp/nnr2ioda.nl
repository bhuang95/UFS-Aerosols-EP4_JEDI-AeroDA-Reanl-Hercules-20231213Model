&record_obs
 input_dir_obs = "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/OBS/NNR_003_6Targets/MOD04/Y2016/M06"
 input_file_obs = "nnr_003.MOD04_L2a.deep.20160606_0600z.ods"
 select_domain = .false.
 lat_ll = -90.0
 lat_ur = 90.0
 lon_ll = -180.0
 lon_ur = 180.0
/

&record_obs_thinning
 thin_spatial = .T.
 center_date_time = "2016060606" 
 off_center = 1
 input_dir_grid_thinning = "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/fix_fv3/C192"
 thinning_grid_ratio_min = .75
 thinning_grid_ratio_max = 1.5
 time_half_window = 90 ! minutes from center_date_time all
/

&record_output
 output_multichannel=.T.
 output_dir = "."
 output_file = "nnr_terra_deep.2016060606.nc"
/

