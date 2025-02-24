#!/bin/bash
#SBATCH -n 144
#SBATCH -t 00:30:00
#SBATCH -q debug
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out

#set verbose

set -x
vdir=/work/noaa/wrf-chem/bhuang/expCodes/fv3-bundle/V20240227/build

source ${vdir}/../jedi_module_base.hera.sh

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${vdir}/lib"

ulimit -s unlimited
export MPI_BUFS_PER_PROC=2048
export MPI_BUFS_PER_HOST=2048
export MPI_GROUP_MAX=256
export MPI_MEMMAP_OFF=1
export MP_STDOUTMODE="ORDERED"
export KMP_AFFINITY=scatter
export OMP_STACKSIZE=2048000
export NTHSTACK=1024000000

export OMP_NUM_THREADS=1
JEDIEXEC=${vdir}/bin/fv3jedi_var.x
srun --export=all -n 144 ${JEDIEXEC} hyb-3dvar_gfs_aero_NOAA_VIIRS.yaml #hyb-3dvar_gfs_aero_NOAA_VIIRS.run


#export OMP_NUM_THREADS=1
#srun -n 144 ${vdir}/bin/fv3jedi_error_covariance_training.x "bumpparameters_nicas_gfs_aero_logp_aero.yaml" "logs/bump_gfs_c96_6cores_lopg_aero.run"
#srun -n 144 ${vdir}/bin/fv3jedi_error_covariance_toolbox.x "bumpparameters_nicas_gfs_c96_logp_atmos.yaml" 
#srun -n 384 ${vdir}/bin/fv3jedi_error_covariance_toolbox.x "bumpparameters_nicas_gfs_c96_logp_atmos_layout_8_8.yaml" "logs/bumpparameters_nicas_gfs_c96_logp_atmos_layout_8_8.run"
#srun -n 144 ${vdir}/bin/fv3jedi_error_covariance_toolbox.x "bumpparameters_nicas_gfs_c96_logp_atmos.yaml" 

#"logs/bump_gfs_c96_6cores_lopg_aero.run"
#ulimit -s unlimited

#echo "HBO1---fv3jedi_parameters.x"
#srun -n 6 ${vdir}/bin/fv3jedi_parameters.x "bumpparameters_nicas_gfs_c96_6cores.yaml" "logs/bump_gfs_c96_6cores.run"
#srun -n 6 ${vdir}/bin/fv3jedi_parameters.x "bumpparameters_nicas_gfs_c96_6cores_logp.yaml" "logs/bump_gfs_c96_6cores_lopg.run"
#srun -n 12 ${vdir}/bin/fv3jedi_parameters.x "bumpparameters_nicas_gfs_c96_12cores.yaml" "logs/bump_gfs_c96_12cores.run"
#srun -n 48 ${vdir}/bin/fv3jedi_parameters.x "bumpparameters_nicas_gfs_c96_48cores.yaml" "logs/bump_gfs_c96_48cores.run"
