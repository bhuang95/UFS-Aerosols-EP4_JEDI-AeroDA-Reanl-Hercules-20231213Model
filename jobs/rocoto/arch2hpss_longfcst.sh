#! /usr/bin/env bash

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
EXPDIR=${EXPDIR:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/"}
TASKRC=${TASKRC:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/TaskRecords/cmplCycle_misc.rc"}

CDATE=${CDATE:-"2023072506"}
CYCINTHR=${CYCINTHR:-"06"}
restart_interval=${restart_interval:-"24 48 72 96 120 144 168 192 216 240"}
FHMIN=${FHMIN:-"6"}
FHOUT=${FHOUT:-"6"}
FHMAX=${FHMAX:-"120"}
TARALLRST=${TARALLRST:-"YES"}

METDIR_NRT=${METDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata_UFS-Aerosols/GDASAnl/"}
CASE_CNTL=${CASE_CNTL:-"C192"}
AERODA=${AERODA:-"YES"}

ARCHHPSSDIR=${ARCHHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/UFS-Aerosols_NRTcyc/"}
ARCHNIAGDIR=${ARCHNIAGDIR:-"/collab1/data/Bo.Huang/FromOrion/expRuns/AeroReanl/"}

TMPDIR=${ROTDIR}/HERA2HPSS/${CDATE}
[[ ! -d ${TMPDIR} ]] && mkdir -p ${TMPDIR}

cd ${TMPDIR}
cp ${HOMEgfs}/jobs/rocoto/sbatch_arch2hpss_longfcst.sh ./
cp ${HOMEgfs}/jobs/rocoto/sbatch_glbus2niag_longfcst.sh ./

cat << EOF > config_hera2hpss
HOMEgfs=${HOMEgfs}
ROTDIR=${ROTDIR}
PSLOT=${PSLOT}

CDATE=${CDATE}
CYCINTHR=${CYCINTHR}
FHMIN=${FHMIN}
FHOUT=${FHOUT}
FHMAX=${FHMAX}
restart_interval="${restart_interval}"

CASE_CNTL=${CASE_CNTL}
AERODA=${AERODA}

ARCHHPSSDIR=${ARCHHPSSDIR}
ARCHNIAGDIR=${ARCHNIAGDIR}
HPSSRECORD=${TMPDIR}/../record.failed_HERA2HPSS-${CDATE}

TARALLRST=${TARALLRST}

TMPDIR=${TMPDIR}
TASKRC=${TASKRC}
NIAGEP=1bfd8a79-52b2-4589-88b2-0648e0c0b35d
ORIONEP=8a10dd4f-24ee-4794-a39d-9c313ab6a34b
GLBUSRECORD=${TMPDIR}/../record.failed_GLBUS2NIAG-${CDATE}
EOF

/opt/slurm/bin/sbatch sbatch_arch2hpss_longfcst.sh
ERR=$?
echo ${CDATE} > ${TASKRC}
sleep 60

exit ${ERR}
