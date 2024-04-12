#source /etc/csh.login
module purge
module use /work/noaa/epic/role-epic/spack-stack/hercules/modulefiles
module load ecflow/5.8.4
module load mysql/8.0.31
module load git-lfs/3.1.2

module use /work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
module load stack-intel/2021.9.0
module load stack-intel-oneapi-mpi/2021.9.0
module load stack-python/3.10.13
#module available
module load jedi-fv3-env

#ecbuild -DMPIEXEC_EXECUTABLE=`which srun` -DMPIEXEC_NUMPROC_FLAG="-n" ${fve-bundle}
#make -j4
