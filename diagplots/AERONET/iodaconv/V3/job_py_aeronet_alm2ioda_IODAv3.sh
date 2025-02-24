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
# -q: AERONET QOD QC level (ALM15 or ALM20)
# -o: output file name
CDATE=2016093000  #202307010
PYEXE=py_aeronet_alm2ioda_IODAv3.py
WIN=1
ALMQC="ALM20"

${pycmd_jedi} ${PYEXE}  -t ${CDATE} -w ${WIN} -o aeronet_alm.${CDATE}_v3.nc -l ${ALMQC} 
