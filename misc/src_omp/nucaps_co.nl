&record_obs
 input_dir_obs = "/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/NUCAPS/20190801"
 input_file_obs = "NUCAPS-EDR_v2r0_j01_s201908010009110_e201908010009410_c201908010101180.nc"
/

&record_obs_thinning
 thin_spatial = .F.
 center_date_time = "2019080100" 
 input_dir_grid_thinning = "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/fix_fv3/C192"
 thinning_grid_ratio_min = .75
 thinning_grid_ratio_max = 1.5
 time_half_window = 180 ! minutes from center_date_time all
/

&record_output
 output_dir = "."
 output_file = "nucaps_co_test.nc"
/

