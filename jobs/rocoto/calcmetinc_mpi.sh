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

set -x

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

#export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
#export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work/"}

# Source FV3GFS workflow modules
source "${HOMEgfs}/ush/preamble.sh"
#. $HOMEgfs/ush/load_fv3gfs_modules.sh
. $HOMEgfs/ush/load_ufswm_modules.sh
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

#export ROTDIR=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data/
#export CDATE=2017110106

ulimit -s unlimited
###############################################################
export CDATE=${CDATE:-"2017110100"}
export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work/"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
export DATAROOT=${DATAROOT:-"/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/Bo.Huang/RUNDIRS/cycExp_ATMA_warm/"}
export METDIR_NRT=${METDIR_NRT:-"${ROTDIR}/RetrieveGDAS"}
export assim_freq=${assim_freq:-"6"}
export CASE_CNTL=${CASE_CNTL:-"C192"}
export CASE_ENKF=${CASE_ENKF:-"C192"}
export NMEM_ENKF=${NMEM_ENKF:-"5"}
export ENSRUN=${ENSRUN:-"YES"}

#export COMPONENT=${COMPONENT:-"atmos"}
COMP_ANL="analysis/atmos"
COMP_BKG="model_data/atmos/history/"
export job="calcensinc"
export jobid="${job}.$$"
export DATA=${DATA:-${DATAROOT}/${jobid}}
#export DATA=${jobid}

export MISSGDASRECORD=${MISSGDASRECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v15/record.chgres_hpss_htar_allmissing_v15"}

if ( grep ${CDATE} ${MISSGDASRECORD} ); then 
    echo "GDAS Met data not avaibale on HPSS and continue"
    exit 0
fi

export SLURM_EXACT=1
export SLURM_MEM_PER_NODE=0
unset SLURM_MEM_PER_CPU 
unset SLURM_MEM_PER_GPU

mkdir -p $DATA

ENSST=0
ENSED=${NMEM_ENKF}

if [ ${ENSRUN} = "NO" ]; then
    ENSED=0
fi

if [ ${ENSED} -lt ${ENSST} ]; then
    echo "ENSED smaller than ENSST and please check first before continuing."
    exit 1
fi

GDATE=`$NDATE -$assim_freq ${CDATE}`

NTHREADS_CALCINC=${NTHREADS_CALCINC:-"1"}
ncmd=${ncmd:-"1"}
imp_physics=${imp_physics:-"99"}
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

export OMP_NUM_THREADS=$NTHREADS_CALCINC

IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    if [ ${IMEM} -eq 0 ]; then
        ENKFOPT="gdas"
        MEMOPT=""
	RCEOPT=""
    else
        ENKFOPT="enkfgdas"
        MEMOPT="mem$(printf %03d ${IMEM})"
	RCEOPT="r"
    fi

    TGTDIR=${DATA}/${ENKFOPT}${MEMOPT}
    [[ ! -d ${TGTDIR} ]] && mkdir -p ${TGTDIR}
    cd ${TGTDIR}
    ${NRM} atmges_mem001 atmanl_mem001 atminc_mem001 calc_increment.nml
    ${NCP} $CALCINCNCEXEC ./calc_inc.x

    INCLOG=${ROTDIR}/logs/${CDATE}/calcmetinc_${ENKFOPT}${MEMOPT}
    BKGDIR=${ROTDIR}/${ENKFOPT}.${GYMD}/${GH}/${MEMOPT}/${COMP_BKG}/
    ANLDIR=${ROTDIR}/${ENKFOPT}.${CYMD}/${CH}/${MEMOPT}/${COMP_ANL}/
    [[ ! -d ${BKGDIR} ]] && mkdir -p ${BKGDIR}
    [[ ! -d ${ANLDIR} ]] && mkdir -p ${ANLDIR}
    BKGFILE=${BKGDIR}/${ENKFOPT}.t${GH}z.atmf${FHR}.nc 
    INCFILE=${ANLDIR}/${ENKFOPT}.t${CH}z.${RCEOPT}atminc.nc
    ANLFILE=${ANLDIR}/${ENKFOPT}.t${CH}z.${RCEOPT}atmanl.nc

    [[ -f ${INCFILE} ]] && ${NRM} ${INCFILE}

    ${NLN} ${BKGFILE} ./atmges_mem001
    ${NLN} ${ANLFILE} ./atmanl_mem001
    ${NLN} ${INCFILE} ./atminc_mem001

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

    { srun --export=all -n ${ncmd} ./calc_inc.x >& ${INCLOG}; echo "$?" > extcode.out; } &
    IMEM=$((IMEM+1))
done
wait

IMEM=${ENSST}
while [ ${IMEM} -le ${ENSED} ]; do
    if [ ${IMEM} -eq 0 ]; then
        ENKFOPT="gdas"
        MEMOPT=""
    else
        ENKFOPT="enkfgdas"
        MEMOPT="mem$(printf %03d ${IMEM})"
    fi

    TGTDIR=${DATA}/${ENKFOPT}${MEMOPT}
    [[ ! -d ${TGTDIR} ]] && mkdir -p ${TGTDIR}
    cd ${TGTDIR}
    ERR=$(cat extcode.out)
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    IMEM=$((IMEM+1))
done

rm -rf ${DATA}
exit ${ERR}
###############################################################

###############################################################
# Exit cleanly
