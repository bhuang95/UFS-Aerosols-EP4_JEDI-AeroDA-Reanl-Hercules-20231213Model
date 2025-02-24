module purge
module use /work/noaa/epic/role-epic/spack-stack/orion/modulefiles
module load python/3.9.2
module load ecflow/5.8.4
module load mysql/8.0.31

module use /work/noaa/epic/role-epic/spack-stack/orion/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
module load stack-intel/2022.0.2
module load stack-intel-oneapi-mpi/2021.5.1
module load stack-python/3.10.13

#module load jedi-fv3-env

#ecbuild -DMPIEXEC_EXECUTABLE=`which srun` -DMPIEXEC_NUMPROC_FLAG="-n" ${fve-bundle}
#make -j4
