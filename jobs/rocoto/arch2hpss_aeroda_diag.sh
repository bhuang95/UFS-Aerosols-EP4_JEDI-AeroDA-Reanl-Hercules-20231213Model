#! /usr/bin/env bash

HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/"}
ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_NRTcyc/"}
PSLOT=${PSLOT:-"UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT"}
EXPDIR=${EXPDIR:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/"}
TASKRC=${TASKRC:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/dr-work/TaskRecords/cmplCycle_misc.rc"}

CDATE=${CDATE:-"2023072506"}
CYCINTHR=${CYCINTHR:-"06"}

AERODA=${AERODA:-"YES"}
ENSRUN=${ENSRUN:-"YES"}

ARCHHPSSDIR=${ARCHHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/UFS-Aerosols_NRTcyc/"}
ARCHNIAGDIR=${ARCHNIAGDIR:-"/collab1/data/Bo.Huang/FromOrion/expRuns/AeroReanl/"}

#NDATE="/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"
NDATE="/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"
CDATE=$(${NDATE} -${CYCINTHR} ${CDATE})


TMPDIR=${ROTDIR}/HERA2HPSS/${CDATE}
[[ ! -d ${TMPDIR} ]] && mkdir -p ${TMPDIR}

cd ${TMPDIR}
cp ${HOMEgfs}/jobs/rocoto/sbatch_arch2hpss_diag.sh ./
cp ${HOMEgfs}/jobs/rocoto/sbatch_glbus2niag_diag.sh ./

cat << EOF > config_hera2hpss
HOMEgfs=${HOMEgfs}
ROTDIR=${ROTDIR}
PSLOT=${PSLOT}

CDATE=${CDATE}
CYCINTHR=${CYCINTHR}

ENSRUN=${ENSRUN}
AERODA=${AERODA}

ARCHHPSSDIR=${ARCHHPSSDIR}
ARCHNIAGDIR=${ARCHNIAGDIR}

HPSSRECORD=${TMPDIR}/../record.failed_HERA2HPSS-${CDATE}

TMPDIR=${TMPDIR}

NIAGEP=1bfd8a79-52b2-4589-88b2-0648e0c0b35d
ORIONEP=2cf2c281-cafc-4b20-900b-45abeb042854
GLBUSRECORD=${TMPDIR}/../record.failed_GLBUS2NIAG-${CDATE}

EOF

/opt/slurm/bin/sbatch sbatch_arch2hpss_diag.sh
ERR=$?
echo ${CDATE} > ${TASKRC}
sleep 60

exit ${ERR}
