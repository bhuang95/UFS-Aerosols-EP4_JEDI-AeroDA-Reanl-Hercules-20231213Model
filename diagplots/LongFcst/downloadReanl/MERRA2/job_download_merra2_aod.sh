#!/bin/bash --login 
#SBATCH -J NASA-AOD
#SBATCH -A chem-var
#SBATCH -p service
#SBATCH -n 1
#SBATCH -t 05:29:00
#SBATCH -o /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/NASA_AOD.out
#SBATCH -e /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/miscLog/NASA_AOD.out

module use -a /contrib/anaconda/modulefiles
module load anaconda/latest
module load nco


set -x

#SDATE=2020060100
#EDATE=2020071300
SDATE=2017120100
EDATE=2018011000
INC_HR=24
SRCDIR=$(pwd)
DATADIR="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/Reanalysis/merra2"
NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"
NASAHTTP="https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2I3NXGAS.5.12.4"
FPRE="MERRA2_400.inst3_2d_gas_Nx"
FSUF="nc4"
[[ ! -d ${DATADIR} ]] && mkdir -p ${DATADIR}

cd ${DATADIR}

IDATE=${SDATE}
while [ ${IDATE} -le ${EDATE} ]; do
   echo ${IDATE}
   IYEAR=${IDATE:0:4}
   IMON=${IDATE:4:2}
   IDAY=${IDATE:6:2}
   IHOUR=${IDATE:8:2}
   IYMD=${IDATE:0:8}
   FILE=${FPRE}.${IYMD}.${FSUF}

   echo ${FILE}
   #wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --content-disposition -i ${FILE}
   wget ${NASAHTTP}/${IYEAR}/${IMON}/${FILE}
   [[ ${ERR} -ne 0 ]] && exit 100
   FILE00=merra2-550nm-AOD-${IYMD}00.nc
   FILE06=merra2-550nm-AOD-${IYMD}06.nc
   FILE12=merra2-550nm-AOD-${IYMD}12.nc
   FILE18=merra2-550nm-AOD-${IYMD}18.nc
   ncks -d time,0,0 ${FILE} ${FILE00}
   ncks -d time,2,2 ${FILE} ${FILE06}
   ncks -d time,4,4 ${FILE} ${FILE12}
   ncks -d time,6,6 ${FILE} ${FILE18}
   [[ ${ERR} -ne 0 ]] && exit 100

   rm -rf ${FILE}

   IDATE=$(${NDATE} ${INC_HR} ${IDATE})
done
exit 0

exit 0
