#!/bin/bash 
set -x
EMISDIR_NRT=${EMISDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/gocart_emissions/nexus"}
GBBDIR_NRT=${GBBDIR_NRT:-"${EMISDIR_NRT}/GBBEPx"}
CEDSDIR_NRT=${CEDSDIR_NRT:-"${EMISDIR_NRT}/CEDS"}
MEGANDIR_NRT=${MEGANDIR_NRT:-"${EMISDIR_NRT}/MEGAN_OFFLINE_BVOC"}
DUSTDIR_NRT=${DUSTDIR_NRT:-"${EMISDIR_NRT}/FENGSHA"}
CEDSVER=${CEDSVER:-"2019"}
GBBVER=${GBBVER:-"gbbepx_v003"}
CDATE=${CDATE:-"2023062400"}
DAYINTHR=24
#NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
#NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
NDATE=${HOMEgfs}/misc/ndate/ndate

CH=$(echo "${CDATE}" | cut -c9-10)

MDATE=$(${NDATE} -${DAYINTHR} ${CDATE})
PDATE=$(${NDATE} +${DAYINTHR} ${CDATE})

for IDATE in ${MDATE} ${CDATE} ${PDATE}; do

    IYY=$(echo ${IDATE} | cut -c1-4)
    IMM=$(echo ${IDATE} | cut -c5-6)
    IDD=$(echo ${IDATE} | cut -c7-8)
    IHH=$(echo ${IDATE} | cut -c9-10)
    IYMD=$(echo ${IDATE} | cut -c1-8)

    if [ ${GBBVER} = "gbbepx_v003" ]; then
        GBBFILE=${GBBDIR_NRT}/GBBEPx_all01GRID.emissions_v003_${IYMD}.nc
    elif [ ${GBBVER} = "gbbepx_v004" ]; then
        GBBFILE=${GBBDIR_NRT}/GBBEPx_all01GRID.emissions_v004_${IYMD}.nc
    else
        echo "GBBVER not properly defined and exit 100"
	exit 100
    fi
    CEDSFILE=${CEDSDIR_NRT}/${IYY}/CEDS.${CEDSVER}.emis.${IYMD}.nc
    MEGANFILE=${MEGANDIR_NRT}/${IYY}/MEGAN.OFFLINE.BIOVOC.${IYY}.emis.${IYMD}.nc
    DUSTFILE=${DUSTDIR_NRT}/FENGSHA_2022_NESDIS_inputs_10km_v3.2.nc
    
    for IFILE in ${GBBFILE} ${CEDSFILE} ${MEGANFILE}; do
        if [ ! -f ${IFILE} ]; then
            echo "Missing ${IFILE}"
	    exit 99
        fi
    done
done

#if [ ${CH} = "18" ]; then
#   DAYINTHR=48
#   PDATE=$(${NDATE} +${DAYINTHR} ${CDATE})
#   PYY=$(echo ${PDATE} | cut -c1-4)
#   PYMD=$(echo ${PDATE} | cut -c1-8)
#
#   GBBFILE=${GBBDIR_NRT}/GBBEPx_all01GRID.emissions_v004_${PYMD}.nc
#   CEDSFILE=${CEDSDIR_NRT}/${PYY}/CEDS.${CEDSVER}.emis.${PYMD}.nc
#   MEGANFILE=${MEGANDIR_NRT}/${PYY}/MEGAN.OFFLINE.BIOVOC.${PYY}.emis.${PYMD}.nc
#   for IFILE in ${GBBFILE}  ${CEDSFILE} ${MEGANFILE}; do
#       if [ ! -f ${IFILE} ]; then
#           echo "Missing ${IFILE}"
#           exit 99
#       fi
#   done
#fi

exit 0
