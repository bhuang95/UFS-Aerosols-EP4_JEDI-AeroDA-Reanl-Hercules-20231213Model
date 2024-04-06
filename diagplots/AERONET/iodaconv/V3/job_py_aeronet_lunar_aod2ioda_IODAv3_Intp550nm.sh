#!/bin/bash
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -q debug
#SBATCH -p service
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./log.job_py
#SBATCH -e ./log.job_py


set -x

CDATE=2023080512  #2023070100

jedimod=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/ioda-bundle/jedi_module_base.hera.sh
pycmd_jedi=/scratch1/NCEPDEV/global/spack-stack/apps/miniconda/py39_4.12.0/bin/python3.9
source ${jedimod}

IODABULT=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/ioda-bundle/ioda-bundle-20230809/build
export PYTHONPATH=${PYTHONPATH}:${IODABULT}/lib/
export PYTHONPATH=${PYTHONPATH}:${IODABULT}/lib/python3.9/
export PYTHONPATH=${PYTHONPATH}:${IODABULT}/iodaconv/src
export PYTHONPATH=${PYTHONPATH}:/home/Bo.Huang/JEDI-2020/miscScripts-home/JEDI-Support/aeronetScript/readAeronet/lib-python/

module list
echo ${PYTHONPATH}

# -t: center time of AERONET AOD
# -w: Time wihdonws in odd or enven hour around center time [-0.5*window, 0.5*window]
# -l: lunar (=1) or solar (=0) AOD only
# -q: AERONET QOD QC leven (AOD15 or AOD20)
# -p: Interpolate to 550 nm AOD (=1) or not (=0). This will significantly slow down the whole process
# -o: output file name

# This command below downloads AERONET solar Lev 1.5 AOD only centered at ${CDATE} with [-0.5, 0.5] hours and interpolate to 550 nm AOD 
${pycmd_jedi} py_aeronet_lunar_aod2ioda_IODAv3_Intp550nm.py  -t ${CDATE} -w 1 -o aeronet_iodav3_${CDATE}_test.nc -l 0 -q AOD15 -p 1
