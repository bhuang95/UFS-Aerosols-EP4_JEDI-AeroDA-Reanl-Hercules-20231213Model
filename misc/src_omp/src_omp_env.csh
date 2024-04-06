#source /etc/csh.login
# Need to run make ${EXECDIR}/*.x twice
module purge
module use /scratch1/NCEPDEV/jcsda/jedipara/spack-stack/modulefiles
module load miniconda/3.9.12
module load ecflow/5.5.3
module load mysql/8.0.31
module use /scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
module load stack-intel/2021.5.0
module load stack-intel-oneapi-mpi/2021.5.1
module load stack-python/3.10.13

module load jedi-fv3-env


setenv LD_LIBRARY_PATH "${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/libs/fortran-datetime/lib"
#:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/build/ioda-bundle/lib"
set path = ( ./ $path )
