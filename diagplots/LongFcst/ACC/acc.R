#to calculate anomaly correlation coefficient for AOD forecasts

library("ncdf4")

climtype <- "monthly" 
#climtype <- "daily" # not working yet


viirsdir <- "/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/DATA/OBS/VIIRS/thinned_debiased_C192/"
expdir <- "/scratch2/BMC/gsd-fv3-dev/MAPP_2018/pagowski/expRuns/UFS-Aerosols_RETcyc/"

sim <- "RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006"
climsim <- "RET_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201712"

#sim <- "RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006"
#climsim <- "RET_EP4_AeroDA_NoSPE_YesSfcanl_v14_0dz0dp_41M_C96_201712"

#sim <- "RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006"
#climsim <- "RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201712"

date_start <- "2020060800"
date_end <- "2020063000"
climdate <- "201712"

obsdir <- viirsdir
fcstdir <- paste(expdir,sim,"/viirs_aod_longfcst//",sep="")

climobsdir <- paste(expdir,"clim_obs_",climdate,"/",sep="")
climfcstdir <- paste(expdir,climsim,"/viirs_aod_climfcst/",sep="")

outdir <- "./outdata_acc/"

fcst_interval <- 6
cycle_interval <- 24
fcstlength <- 5*24 # 5 days

year_start <- substr(date_start,1,4)
month_start <- substr(date_start,5,6)
day_start <- substr(date_start,7,8)
hour_start <- substr(date_start,9,10)
minute_start <- "00"
second_start <- "00"

yyyymmdd_start <- paste(year_start,month_start,day_start,sep="-")
time_start <- paste(hour_start,minute_start,second_start,sep=":")
date_start <- as.POSIXlt(paste(yyyymmdd_start,time_start),"UTC")

year_end <- substr(date_end,1,4)
month_end <- substr(date_end,5,6)
day_end <- substr(date_end,7,8)
hour_end <- substr(date_end,9,10)
minute_end <- "00"
second_end <- "00"

yyyymmdd_end <- paste(year_end,month_end,day_end,sep="-")
time_end <- paste(hour_end,minute_end,second_end,sep=":")
date_end <- as.POSIXlt(paste(yyyymmdd_end,time_end),"UTC")

ndays <- as.numeric(difftime(date_end,date_start, units="days"))+1
nhours <- fcstlength/fcst_interval+1

acc <- array(NA,c(ndays,nhours))
locs <- array(NA,c(ndays,nhours))

aod_obs_valid_all <- numeric(0)
aod_hofx_valid_all <- numeric(0)

lats_valid_all <- numeric(0)
lons_valid_all <- numeric(0)

new_date <- date_start

options(warn=-1)

i <- 1
while (new_date <= date_end) {

      ident <- format(new_date,"%Y%m%d%H")

      j <- 1
      for (fcsthour in seq(0,fcstlength,by=fcst_interval)) {
      	  cfcsthour <- sprintf("%03d",fcsthour)
	  fdate <- new_date + fcsthour*3600
	  fident <- format(fdate,"%Y%m%d%H")

	  obsfile <- paste(obsdir,fident,"/VIIRS_AOD_npp.",fident,".nc",
	  	           sep="")
          nc <- nc_open(obsfile,readunlim=FALSE, write=FALSE )
          nlocs <- nc$dim[["Location"]]$len
          obs <- ncvar_get(varid="ObsValue/aerosolOpticalDepth",nc)
          obs[which(obs < 0)] <- 0.
          nc_close(nc)

      	  fcstfile <- paste(fcstdir,ident,"/fhr",cfcsthour,"/",
	    	            "VIIRS_AOD_npp_fcst.",fident,".nc",sep="")
          nc <- nc_open(fcstfile,readunlim=FALSE, write=FALSE )
          nlocs <- nc$dim[["Location"]]$len
          fcst <- ncvar_get(varid="ObsValue/aerosolOpticalDepth",nc)
 	  nc_close(nc)

      	  climobsfile <- paste(climobsdir,ident,"/fhr",cfcsthour,"/",
	    	               "VIIRS_AOD_npp_clim_",climtype,".",
                                fident,".nc",sep="")
          nc <- nc_open(climobsfile,readunlim=FALSE, write=FALSE )
          nlocs <- nc$dim[["Location"]]$len
          climobs <- ncvar_get(varid="ObsValue/aerosolOpticalDepth",nc)
          climobs[which(obs < 0)] <- 0.
          nc_close(nc)

      	  climfcstfile <- paste(climfcstdir,ident,"/fhr",cfcsthour,"/",
	    	            "VIIRS_AOD_npp_fcst_mean.",fident,".nc",
			    sep="")
          nc <- nc_open(climfcstfile,readunlim=FALSE, write=FALSE )
          nlocs <- nc$dim[["Location"]]$len
          climfcst <- ncvar_get(varid="ObsValue/aerosolOpticalDepth",nc)
          nc_close(nc)

	  fcst_anomaly <- fcst - climfcst
	  obs_anomaly <-  obs - climobs
	  stdev_fcst_anomaly <- sd(fcst_anomaly)
	  stdev_obs_anomaly <- sd(obs_anomaly)
	  cov_anomaly <- sum(obs_anomaly*fcst_anomaly)/nlocs
#	  cov_anomaly <- (obs_anomaly%*%fcst_anomaly)/nlocs
	  acc[i,j] <- cov_anomaly/(stdev_fcst_anomaly*stdev_obs_anomaly)
	  locs[i,j] <- nlocs
	  print(paste(ident," fhr",cfcsthour,sep=""))

	  j <- j+1

      }	  

      new_date <- new_date + cycle_interval*3600

      i <- i+1
}

hours <- seq(0,fcstlength,by=fcst_interval)
acc_mean <- apply(acc,2,mean)
locs_mean <- apply(locs,2,mean)

missval <-  1.e+30
ndays_dim <- ncdim_def('ndays','days',1:ndays)
nhours_dim <- ncdim_def('nhours','hours',1:nhours)
acc_out <- ncvar_def('ACC',' ',list(nhours_dim,ndays_dim),missval,
	              longname='Anomaly Correlation Coefficient',
		      prec='float')
locs_out <- ncvar_def('Nobs',' ',list(nhours_dim,ndays_dim),missval,
	              longname='Number of observations',
		      prec='float')
acc_mean_out <- ncvar_def('ACCMean',' ',nhours_dim,
	     	      missval,
	              longname='Mean Anomaly Correlation Coefficient',
		      prec='float')
locs_mean_out <- ncvar_def('NobsMean',' ',nhours_dim,
	     	      missval,
	              longname='Mean Anomaly Correlation Coefficient',
		      prec='float')

hours_out <- ncvar_def('hours','hours',nhours_dim,missval,
	               longname='forecast hours',prec='float')

outfile <- paste(outdir,"acc_",sim,".nc",sep="")

mc <- nc_create(outfile,list(hours_out,acc_out,locs_out,
		acc_mean_out,locs_mean_out))
ncvar_put(mc,hours_out,hours,start=1,count=nhours)
ncvar_put(mc,acc_out,acc,start=c(1,1),count=c(nhours,ndays))
ncvar_put(mc,acc_mean_out,acc_mean,start=1,count=nhours)
ncvar_put(mc,locs_out,locs,start=c(1,1),count=c(nhours,ndays))
ncvar_put(mc,locs_mean_out,locs_mean,start=1,count=nhours)
ncatt_put(mc, 0,"Simulation",sim)
ncatt_put(mc, 0,"Fcst_dates",paste(date_start,"--",date_end,sep=""))
ncatt_put(mc, 0,"Clim_dates",climdate)
nc_close(mc)


