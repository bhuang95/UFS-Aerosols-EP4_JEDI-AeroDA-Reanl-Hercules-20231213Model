#!/bin/bash -x

module load  intel/19.0.5.281 netcdf nco

DUSTDIR="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus/FENGSHA/"
DUSTFILE=FENGSHA_2022_NESDIS_inputs_10km_v3.2

cd ${DUSTDIR}
MONS=12

IMON=0
while [ ${IMON} -lt ${MONS} ]; do
    MON0=$(printf "%02d" $((IMON+1)))
    FILEOUT=${DUSTFILE}_2018${MON0}
    ncks -d time,${IMON},${IMON} ${DUSTFILE}.nc ${FILEOUT}.nc

    IMON=$((IMON+1))
done

#"""
#ncks -d time,1,1 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20180201.nc
#ncks -d time,2,2 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20180301.nc
#ncks -d time,3,3 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20180401.nc
#ncks -d time,4,4 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20180501.nc
#ncks -d time,5,5 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20180601.nc
#ncks -d time,6,6 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20180701.nc
#ncks -d time,7,7 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20180801.nc
#ncks -d time,8,8 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20180901.nc
##ncks -d time,9,9 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20181001.nc
#ncks -d time,10,10 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20181101.nc
#ncks -d time,11,11 FENGSHA_p81_10km_inputs.nc FENGSHA_p81_10km_inputs.20181201.nc
#"""
