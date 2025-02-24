#!/bin/bash --login
#SBATCH -J LETKF
#SBATCH -A gsd-fv3-dev
##SBATCH --open-mode=truncate
#SBATCH -o log.nemsio2nc
#SBATCH -e log.nemsio2nc
#SBATCH -n 1
##SBATCH --nodes=1
##SBATCH -q debug
#SBATCH -p service
#SBATCH -t 00:30:00


#module load matlab
module load python/3.7.5

SDATE=20230601 # in YYYYMMDDyy
EDATE=20230603 # in YYYYMMDDyy
DATADIR="/work/noaa/gsd-fv3-dev/bhuang/JEDI-FV3/expRuns/MISC/VIIRS-AWS/data"
PYEXE="/work/noaa/gsd-fv3-dev/bhuang/JEDI-FV3/expRuns/MISC/VIIRS-AWS/viirs_aws_download_globalmode_v1_bo.py"

python ${PYEXE} ${SDATE} ${EDATE} ${DATADIR}

exit 0
