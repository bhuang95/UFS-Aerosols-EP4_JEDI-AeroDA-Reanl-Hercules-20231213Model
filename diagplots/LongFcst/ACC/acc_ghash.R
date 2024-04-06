#to calculate anomaly correlation coefficient for AOD forecasts
#won't work for non-unique observations
#uses JEDI hofx files

library("ncdf4")
library("geohashTools")

climtype <- "monthly" 
#climtype <- "daily" # not working yet

expdir="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/pagowski/expRuns/UFS-Aerosols_RETcyc/"

sim <- "RET_EP4_FreeRun_NoSPE_YesSfcanl_v15_0dz0dp_1M_C96_202006"
climsim <- "RET_EP4_FreeRun_NoSPE_YesSfcanl_v14_0dz0dp_1M_C96_201712"

#sim <- "RET_EP4_AeroDA_NoSPE_YesSfcanl_v15_0dz0dp_41M_C96_202006"
#climsim <- "RET_EP4_AeroDA_NoSPE_YesSfcanl_v14_0dz0dp_41M_C96_201712"

#sim <- "RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202006"
#climsim <- "RET_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v14_0dz0dp_41M_C96_201712"

date_start <- "2020060800"
date_end <- "2020063000"
climdate <- "201712"

hofxdir <- paste(expdir,sim,"/aod_hofx/",sep="")
climhofxdir <- paste(expdir,climsim,"/clim_",climtype,"_aod_hofx/",sep="")
climobsdir <- paste(expdir,"clim_obs_",climdate,"/",sep="")

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
      	  hofxfile <- paste(hofxdir,ident,"/fhr",cfcsthour,"/",
	    	            "VIIRS_AOD_npp_hofx.",fident,".nc",sep="")

          nc <- nc_open(hofxfile,readunlim=FALSE, write=FALSE )
          nlocs <- nc$dim[["Location"]]$len
          nchans <- nc$dim[["Channel"]]$len
          fcst_lats <- ncvar_get(varid="MetaData/latitude",nc)
	  fcst_lons <- ncvar_get(varid="MetaData/longitude",nc)
          fcst_obs <- ncvar_get(varid="ObsValue/aerosolOpticalDepth",nc)
          fcst_obs[which(fcst_obs < 0)] <- 0.
          fcst_hofx <- ncvar_get(varid="hofx/aerosolOpticalDepth",nc)
	  fcst_ghash <- gh_encode(fcst_lats,fcst_lons,precision=8L)
	  fcst_ghash_sorted <- sort(fcst_ghash,index.return=TRUE)
	  fcst_index <- fcst_ghash_sorted$ix
	  nc_close(nc)

      	  climobsfile <- paste(climobsdir,ident,"/fhr",cfcsthour,"/",
	    	               "VIIRS_AOD_npp_clim_",climtype,".",
                                fident,".nc",sep="")
          nc <- nc_open(climobsfile,readunlim=FALSE, write=FALSE )
          nlocs <- nc$dim[["Location"]]$len
          nchans <- nc$dim[["Channel"]]$len
          climobs_lats <- ncvar_get(varid="MetaData/latitude",nc)
          climobs_lons <- ncvar_get(varid="MetaData/longitude",nc)
          climobs <- ncvar_get(varid="ObsValue/aerosolOpticalDepth",nc)
          climobs[which(obs < 0)] <- 0.
	  climobs_ghash <- gh_encode(climobs_lats,climobs_lons,
				     precision=8L)
          climobs_ghash_sorted <- sort(climobs_ghash,index.return=TRUE)
          climobs_index <- climobs_ghash_sorted$ix
          nc_close(nc)

	  if (all(fcst_ghash_sorted$x != climobs_ghash_sorted$x)) {
	        print("climobs cover some obs")
		stop("0")
		}

      	  climhofxfile <- paste(climhofxdir,ident,"/fhr",cfcsthour,"/",
	    	            "VIIRS_AOD_npp_hofx.",fident,".nc",sep="")
          nc <- nc_open(climhofxfile,readunlim=FALSE, write=FALSE )
          nlocs <- nc$dim[["Location"]]$len
          nchans <- nc$dim[["Channel"]]$len
          climhofx_lats <- ncvar_get(varid="MetaData/latitude",nc)
          climhofx_lons <- ncvar_get(varid="MetaData/longitude",nc)
          climhofx <- ncvar_get(varid="hofx/aerosolOpticalDepth",nc)
          climhofx_ghash <- gh_encode(climhofx_lats,climhofx_lons,
                                     precision=8L)
          climhofx_ghash_sorted <- sort(climhofx_ghash,index.return=TRUE)
          climhofx_index <- climhofx_ghash_sorted$ix
          nc_close(nc)

	  fcst_anomaly <- fcst_hofx[fcst_index] - climhofx[climhofx_index]
	  obs_anomaly <-  fcst_obs[fcst_index] - climobs[climobs_index]
	  stdev_fcst_anomaly <- sd(fcst_anomaly)
	  stdev_obs_anomaly <- sd(obs_anomaly)
	  cov_anomaly <- sum(obs_anomaly*fcst_anomaly)/nlocs
	  acc[i,j] <- cov_anomaly/(stdev_fcst_anomaly*stdev_obs_anomaly)

	  print(paste(ident," fhr",cfcsthour,sep=""))

	  j <- j+1

      }	  

      new_date <- new_date + cycle_interval*3600

      i <- i+1
}

hours <- seq(0,fcstlength,by=fcst_interval)
acc_mean <- apply(acc,2,mean)

missval <-  1.e+30
ndays_dim <- ncdim_def('ndays','days',1:ndays)
nhours_dim <- ncdim_def('nhours','hours',1:nhours)
acc_out <- ncvar_def('ACC',' ',list(nhours_dim,ndays_dim),missval,
	              longname='Anomaly Correlation Coefficient',
		      prec='float')
acc_mean_out <- ncvar_def('ACCMean',' ',nhours_dim,
	     	      missval,
	              longname='Mean Anomaly Correlation Coefficient',
		      prec='float')

hours_out <- ncvar_def('hours','hours',nhours_dim,missval,
	               longname='forecasts hours',prec='float')



outfile <- paste(outdir,"acc_",sim,".nc",sep="")

mc <- nc_create(outfile,list(hours_out,acc_out,acc_mean_out))
ncvar_put(mc,hours_out,hours,start=1,count=nhours)
ncvar_put(mc,acc_out,acc,start=c(1,1),count=c(nhours,ndays))
ncvar_put(mc,acc_mean_out,acc_mean,start=1,count=nhours)
ncatt_put(mc, 0,"Simulation",sim)
ncatt_put(mc, 0,"Fcst_dates",paste(date_start,"-",date_end,sep=""))
ncatt_put(mc, 0,"Clim_dates",climdate)
nc_close(mc)


