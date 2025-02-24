#!/bin/bash 
set -x

ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/ENKF_AEROSEMIS-ON_STOCHINIT-OFF-201710/dr-data-longfcst"}
CDATE=${CDATE:-"2020060100"}
FHMIN=${FHMIN:-"0"}
FHOUT=${FHOUT:-"6"}
FHMAX=${FHMAX:-"120"}
NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}
AODTYPE=${AODTYPE:-""}
OBSDIR_NRT=${OBSDIR_NRT:-""}

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}
FHR=${FHMIN}
while [ ${FHR} -le ${FHMAX} ]; do
    IDATE=$(${NDATE} ${FHR} ${CDATE})
    IYMD=${IDATE:0:8}
    IH=${IDATE:8:2}
    CPLFILE=${ROTDIR}/gdas.${CYMD}/${CH}/model_data/atmos/restart/${IYMD}.${IH}0000.coupler.res
    if [ ! -e ${CPLFILE} ]; then
       echo "${CPLFILE} does not exist and exit now"
       exit 100
    fi
    if [ ! -z ${AODTYPE} ]; then
        AODFILE=${OBSDIR_NRT}/${IDATE}/${AODTYPE}_AOD.${IDATE}.iodav3.nc
        if [ ! -e ${CPLFILE} ]; then
           echo "${AODFILE} does not exist and exit now"
           exit 100
        fi
    fi
    FHR=$((${FHR}+${FHOUT}))
done

exit 0
