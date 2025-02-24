#!/usr/bin/env bash 
##SBATCH -n 1
##SBATCH -t 00:30:00
##SBATCH -p hera
##SBATCH -q debug
##SBATCH -A chem-var
##SBATCH -J fgat
##SBATCH -D ./
##SBATCH -o ./bump_gfs_c96.out
##SBATCH -e ./bump_gfs_c96.out

#set -x

###############################################################
## Abstract:
## Calculate increment of Met. fields for FV3-CHEM
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################
set -x
#source /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/RRFS/ufs-srweather-app-HW-20231024/ufs-srweather-app.oct.24/regional_workflow/ush/source_util_funcs.sh
#source /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/RRFS/ufs-srweather-app-HW-20231024/ufs-srweather-app.oct.24/regional_workflow/ush/bash_utils/save_restore_shell_opts.sh

#export MODULEPATH="/apps/modules/modulefamilies/intel:/apps/lmod/lmod/modulefiles/Core:/apps/modules/modulefiles/Linux:/apps/modules/modulefiles:/contrib/anaconda/modulefiles:/scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles"
set -x 
echo "HBO1"
echo ${MODULEPATH}
echo ${HOME}
echo ${USER}
echo ${PATH}
echo ${NETCDF}
echo "HBO2"
#exit 100
# Source FV3GFS workflow modules
source "${HOMEgfs}/ush/preamble.sh"
echo "HBO2"
echo ${MODULEPATH}
#. $HOMEgfs/ush/load_fv3gfs_modules.sh
. $HOMEgfs/ush/load_ufswm_modules.sh
echo "HBO3"
echo ${MODULEPATH}
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
configs="base"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done
[[ $status -ne 0 ]] && exit $status

ulimit -s unlimited
###############################################################
export CDATE=${CDATE:-"2017110100"}
export HOMEgfs=${HOMEgfs:-"home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work/"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
export DATAROOT=${DATAROOT:-"/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/Bo.Huang/RUNDIRS/cycExp_ATMA_warm/"}
export METDIR_NRT=${METDIR_NRT:-"${ROTDIR}/RetrieveGDAS"}
export assim_freq=${assim_freq:-"6"}
export CDUMP=${CDUMP:-"gdas"}
export CASE_CNTL=${CASE_CNTL:-"C192"}
export CASE_ENKF=${CASE_ENKF:-"C192"}

#export COMPONENT=${COMPONENT:-"atmos"}
COMP_ANL="analysis/atmos"
COMP_BKG="model_data/atmos/history/"
export job="calcinc"
export jobid="${job}.$$"
export DATA=${DATA:-${DATAROOT}/${jobid}}
#export DATA=${jobid}

export MISSGDASRECORD=${MISSGDASRECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15/record.chgres_hpss_htar_allmissing_v15"}

if ( grep ${CDATE} ${MISSGDASRECORD} ); then 
    echo "GDAS Met data not avaibale on HPSS and continue"
    exit 0
fi

mkdir -p $DATA

GDATE=`$NDATE -$assim_freq ${CDATE}`
NTHREADS_CALCINC=${NTHREADS_CALCINC:-1}
ncmd=${ncmd:-1}
imp_physics=${imp_physics:-99}
INCREMENTS_TO_ZERO=${INCREMENTS_TO_ZERO:-"'NONE'"}
DO_CALC_INCREMENT=${DO_CALC_INCREMENT:-"YES"}

CALCINCNCEXEC=${HOMEgfs}/exec/calc_increment_ens_ncio.x

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}
GYMD=${GDATE:0:8}
GH=${GDATE:8:2}

FHR=`printf %03d ${assim_freq}`

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

cd $DATA
${NRM} atmges_mem001 atmanl_mem001 atminc_mem001 calc_increment.nml
${NCP} $CALCINCNCEXEC ./calc_inc.x
export OMP_NUM_THREADS=$NTHREADS_CALCINC

BKGDIR=${ROTDIR}/${CDUMP}.${GYMD}/${GH}/${COMP_BKG}/
ANLDIR=${ROTDIR}/${CDUMP}.${CYMD}/${CH}/${COMP_ANL}/
[[ ! -d ${BKGDIR} ]] && mkdir -p ${BKGDIR}
[[ ! -d ${ANLDIR} ]] && mkdir -p ${ANLDIR}

BKGFILE=${BKGDIR}/${CDUMP}.t${GH}z.atmf${FHR}.nc 
INCFILE=${ANLDIR}/${CDUMP}.t${CH}z.atminc.nc
ANLFILE=${ANLDIR}/${CDUMP}.t${CH}z.atmanl.nc

${NLN} ${BKGFILE} atmges_mem001
${NLN} ${ANLFILE} atmanl_mem001
${NLN} ${INCFILE} atminc_mem001

cat > calc_increment.nml << EOF
&setup
  datapath = './'
  analysis_filename = 'atmanl'
  firstguess_filename = 'atmges'
  increment_filename = 'atminc'
  debug = .false.
  nens = 1
  imp_physics = $imp_physics
/
&zeroinc
  incvars_to_zero = $INCREMENTS_TO_ZERO
/
EOF

cat calc_increment.nml

srun --export=all -n ${ncmd} ./calc_inc.x
ERR=$?
if [[ $ERR != 0 ]]; then
    exit ${ERR}
fi

rm -rf ${DATA}
exit ${ERR}
###############################################################

###############################################################
# Exit cleanly
