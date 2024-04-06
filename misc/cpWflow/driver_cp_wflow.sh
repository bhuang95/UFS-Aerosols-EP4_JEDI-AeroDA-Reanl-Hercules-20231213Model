#!/bin/bash


### Mannually copy or link fix, exec, sorc
SCRDIR=$(pwd)
TOPSRCDIR="/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/UFSAerosols-workflow/20231116-develop/global-workflow/"

TOPDETDIR="/home/Bo.Huang/JEDI-2020/UFS-Aerosols_RETcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl"

### config.*
SRCDIR=${TOPSRCDIR}/expdir/cycExp_ATMA_warm
DETDIR=${TOPDETDIR}/dr-work
FILES="
       config.base 
       config.fcst 
       config.efcs 
       config.ufs  
       config.com  
       config.resources  
       config.aero 
       config.nsst
       "
${SCRDIR}/cp_file.sh "${SRCDIR}" "${DETDIR}" "${FILES}"
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

### env
SRCDIR="${TOPSRCDIR}/env"
DETDIR="${TOPDETDIR}/env"
FILES="HERA.env"
${SCRDIR}/cp_file.sh "${SRCDIR}" "${DETDIR}" "${FILES}"
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

### ush
SRCDIR="${TOPSRCDIR}/ush"
DETDIR="${TOPDETDIR}/ush"
FILES="jjob_header.sh 
       cplvalidate.sh 
       forecast_predet.sh 
       forecast_det.sh 
       forecast_postdet.sh 
       nems_configure.sh 
       parsing_namelists_FV3.sh
       parsing_model_configure_FV3.sh
       getncdimlen
       atparse.bash
       load_ufswm_modules.sh
       preamble.sh
       "
${SCRDIR}/cp_file.sh "${SRCDIR}" "${DETDIR}" "${FILES}"
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

### jobs
SRCDIR="${TOPSRCDIR}/jobs"
DETDIR="${TOPDETDIR}/jobs"
FILES="JGLOBAL_FORECAST JGDAS_ENKF_FCST"
${SCRDIR}/cp_file.sh "${SRCDIR}" "${DETDIR}" "${FILES}"
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

### jobs/rocoto
SRCDIR="${TOPSRCDIR}/jobs/rocoto"
DETDIR="${TOPDETDIR}/jobs/rocoto"
FILES="fcst.sh efcs.sh"
${SCRDIR}/cp_file.sh "${SRCDIR}" "${DETDIR}" "${FILES}"
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

### scripts
SRCDIR="${TOPSRCDIR}/scripts"
DETDIR="${TOPDETDIR}/scripts"
FILES="exglobal_forecast.sh exgdas_enkf_fcst.sh"
${SCRDIR}/cp_file.sh "${SRCDIR}" "${DETDIR}" "${FILES}"
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

### parm
SRCDIR="${TOPSRCDIR}/parm"
DETDIR="${TOPDETDIR}/parm"
FILES="post ufs"
${SCRDIR}/cp_file.sh "${SRCDIR}" "${DETDIR}" "${FILES}"
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
