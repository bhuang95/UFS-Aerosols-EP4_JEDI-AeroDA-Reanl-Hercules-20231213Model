#!/bin/bash 
#set -x

#module load  intel/19.0.5.281 netcdf nco
module load nco

TOPSRC="/work/noaa/wrf-chem/bhuang/NRTdata_UFS-Aerosols/gocart_emissions/nexus/CEDS/v2019/monthly"
TOPDET="/work/noaa/wrf-chem/bhuang/NRTdata_UFS-Aerosols/gocart_emissions/nexus/CEDS/v2019"
SDATE=2024030100  #2021042800
EDATE=2024043000  #2022123100
NDATE=/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules-20231213Model//misc/ndate/ndate

NCP='/bin/cp -rL'
INC=24
CDATE=${SDATE}
ICNT=0
while [ ${CDATE} -le ${EDATE} ]; do
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}

    UNITS="hours since ${CY}-${CM}-${CD} 00:00:00 GMT"
    #2022 name
    #FILESRC=${TOPSRC}/${CY}/CEDS.2019.emis.monthly.${CY}${CM}.nc
    #2024 name
    FILESRC=${TOPSRC}/${CY}/CEDS_2019_monthly.${CY}${CM}.nc
    FILEDET=${TOPDET}/${CY}/CEDS.2019.emis.${CY}${CM}${CD}.nc
    echo ${FILESRC}
    echo ${FILEDET}
    echo "*******************"

    ${NCP} ${FILESRC} ${FILEDET}
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
    ncatted -O -a units,time,m,c,"${UNITS}" ${FILEDET}
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))

    if [ ${ICNT} -ne 0 ]; then
       exit ${ICNT}
    fi

    CDATE=$(${NDATE} ${INC} ${CDATE})
done

exit ${ICNT}

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
