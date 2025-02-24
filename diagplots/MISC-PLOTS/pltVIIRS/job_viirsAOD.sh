#!/bin/bash
#SBATCH -J pltEmis
#SBATCH -A wrf-chem
#SBATCH -o /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/viirsaod.out
#SBATCH -e /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/viirsaod.out
#SBATCH -n 1
#SBATCH -p service
#SBATCH -t 05:30:00

set -x
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

curdir=$(pwd)
plotdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/conferencePlots/2024AMS/VIIRSAOD

cp ${curdir}/plt_VIIRS_AOD_IODAV3_6HOUR.py ${plotdir}

cd ${plotdir}
python plt_VIIRS_AOD_IODAV3_6HOUR.py
