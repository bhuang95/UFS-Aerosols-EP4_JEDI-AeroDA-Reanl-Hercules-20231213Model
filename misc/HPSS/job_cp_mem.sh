#! /usr/bin/env bash
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -p service
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out

SRCDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007/dr-data/fromHera/PertOcn
DETDIR=/work/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007/dr-data/enkfgdas.20200723/06
NMEM_ENKF=40
FILE=MEGAN.OFFLINE.BIOVOC.2020.emis.20200723t12:00:00z.nc_forNextCycleWithStochInitTrue

IMEM=1
while [ ${IMEM} -le ${NMEM_ENKF} ]; do
    MEMSTR="mem"$(printf %03d ${IMEM})
    SRCMEM=${SRCDIR}/${MEMSTR}/pert_MEGAN/
    DETMEM=${DETDIR}/${MEMSTR}/model_data/atmos/restart/pertEmis/pert_MEGAN/
    mkdir -p ${DETMEM}
    cp ${SRCMEM}/${FILE} ${DETMEM}/${FILE}
    IMEM=$((IMEM+1))
done

