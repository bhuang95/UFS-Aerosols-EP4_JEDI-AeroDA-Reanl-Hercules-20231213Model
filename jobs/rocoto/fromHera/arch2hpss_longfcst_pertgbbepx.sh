#! /usr/bin/env bash

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
EXPDIR=${EXPDIR:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/"}
TASKRC=${TASKRC:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/TaskRecords/cmplCycle_misc.rc"}

CDATE=${CDATE:-"2023072506"}
CYCINTHR=${CYCINTHR:-"06"}
restart_interval=${restart_interval:-"24 48 72 96 120"}
FHMIN=${FHMIN:-"6"}
FHOUT=${FHOUT:-"6"}
FHMAX=${FHMAX:-"120"}
TARALLRST=${TARALLRST:-"YES"}

METDIR_NRT=${METDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/GDASAnl/"}
CASE_CNTL=${CASE_CNTL:-"C192"}
AERODA=${AERODA:-"YES"}

ARCHHPSSDIR=${ARCHHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/UFS-Aerosols_NRTcyc/"}

TMPDIR=${ROTDIR}/HERA2HPSS/${CDATE}
[[ ! -d ${TMPDIR} ]] && mkdir -p ${TMPDIR}

cd ${TMPDIR}
cp ${HOMEgfs}/jobs/rocoto/sbatch_arch2hpss_longfcst_pertgbbepx.sh ./

cat << EOF > config_hera2hpss
HOMEgfs=${HOMEgfs}
ROTDIR=${ROTDIR}
PSLOT=${PSLOT}

CDATE=${CDATE}
CYCINTHR=${CYCINTHR}
FHMIN=${FHMIN}
FHOUT=${FHOUT}
FHMAX=${FHMAX}

CASE_CNTL=${CASE_CNTL}
AERODA=${AERODA}

ARCHHPSSDIR=${ARCHHPSSDIR}
HPSSRECORD=${TMPDIR}/../record.failed_HERA2HPSS-${CDATE}

TARALLRST=${TARALLRST}

TMPDIR=${TMPDIR}
TASKRC=${TASKRC}
EOF

/apps/slurm/default/bin/sbatch sbatch_arch2hpss_longfcst_pertgbbepx.sh
ERR=$?
echo ${CDATE} > ${TASKRC}
sleep 60

exit ${ERR}
