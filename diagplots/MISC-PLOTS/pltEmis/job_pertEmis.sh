#!/bin/bash
#SBATCH -J pltEmis
#SBATCH -A wrf-chem
#SBATCH -o /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/pltEmis.out
#SBATCH -e /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/misc/pltEmis.out
#SBATCH -n 1
#SBATCH -p service
#SBATCH -t 05:30:00
#SBATCH --mem=2G

set -x
module use -a /contrib/anaconda/modulefiles
module load anaconda/latest

curdir=$(pwd)
plotdir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/conferencePlots/2024AMS/pertEmis
pyexe=plt_contourf_BC_Emis_GBBEPx.py

cp ${curdir}/${pyexe} ${plotdir}

cd ${plotdir}
python ${pyexe}
