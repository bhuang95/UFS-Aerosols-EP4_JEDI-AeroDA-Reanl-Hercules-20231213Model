#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 07:59:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hera2hpss.out
#SBATCH -e ./hera2hpss.out

set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle

source config_hera2hpss

NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}

#module load hpss
#export PATH="/apps/hpss/bin:$PATH"
set -x

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDATE=$(${NDATE} -${CYCINTHR} ${CDATE})
RMDATE=${GDATE}
RMDIR=${TMPDIR}/../${RMDATE}
RMREC=${RMDIR}/remove.record

#if ( grep YES ${RMREC} ); then
#    ${NRM} ${RMDIR}
#fi

CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}
CYMD=${CDATE:0:8}
CPREFIX=${CYMD}.${CH}0000

GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}
GYMD=${GDATE:0:8}

#DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data/${GY}/${GY}${GM}/${GYMD}/
DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data/${GDATE}

#hsi "mkdir -p ${DATAHPSSDIR}"
mkdir -p ${DATAHPSSDIR}
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "*hsi mkdir* failed at ${GDATE}" >> ${HPSSRECORD}
    exit ${ERR}
fi


# Back up gdas cntl
# Copy cntl
LOGDIR=${ROTDIR}/logs/${GDATE}/
CNTLDIR=${ROTDIR}/gdas.${GYMD}/${GH}
CNTLDIR_ATMOS=${CNTLDIR}/model_data/atmos/
CNTLDIR_DIAG=${CNTLDIR}/diag/
CNTLDIR_ATMOS_RT=${CNTLDIR_ATMOS}/restart

CNTLBAK=${ROTDIR}/../dr-data-backup/gdas.${GYMD}/${GH}
CNTLBAK_ATMOS_RT=${CNTLBAK}/model_data/atmos/restart/
CNTLBAK_DIAG=${CNTLBAK}/diag/aod_obs

[[ ! -d ${CNTLBAK_ATMOS_RT} ]] && mkdir -p ${CNTLBAK_ATMOS_RT}
[[ ! -d ${CNTLBAK_DIAG} ]] && mkdir -p ${CNTLBAK_DIAG}

if [ -s ${CNTLDIR_ATMOS} ]; then
    ${NCP} ${LOGDIR} ${CNTLDIR}/logs

    #${NRM} ${CNTLDIR_ATMOS}/gdas.t??z.*?.txt
    #${NRM} ${CNTLDIR_ATMOS}/gdas.t??z.master.grb2f???
    if [ ${AERODA} = "YES" ]; then
        ${NRM} ${CNTLDIR_ATMOS_RT}/${CPREFIX}.fv_tracer_aeroanl_tmp.res.tile?.nc
    fi
    
    ${NCP} ${CNTLDIR_DIAG}/* ${CNTLBAK_DIAG}
    ${NCP} ${CNTLDIR_ATMOS_RT}/${CPREFIX}.coupler* ${CNTLBAK_ATMOS_RT}/
    ${NCP} ${CNTLDIR_ATMOS_RT}/${CPREFIX}.fv_core* ${CNTLBAK_ATMOS_RT}/
    ${NCP} ${CNTLDIR_ATMOS_RT}/${CPREFIX}.fv_tracer* ${CNTLBAK_ATMOS_RT}/
    
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "Copy cntl data failed at ${GDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    fi

    cd ${CNTLDIR}
    TARFILE=${DATAHPSSDIR}/gdas.${GDATE}.tar
    #htar -P -cvf ${TARFILE} *
    tar -cvf ${TARFILE} *
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "HTAR cntl data failed at ${CDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    fi
fi # Done with loop through cntl

# Back up gdasenkf cntl
if [ ${ENSRUN} = "YES" ]; then
    NGRPS=$((10#${NMEM_ENKF} / 10#${NMEM_ENSGRP_ARCH}))
    ENKFDIR=${ROTDIR}/enkfgdas.${GYMD}/${GH}
    ENKFDIR_DIAG=${ENKFDIR}/diag/
    ENKFDIR_ATMOS_MEAN_RT=${ENKFDIR}/ensmean/model_data/atmos/restart

    ENKFBAK=${ROTDIR}/../dr-data-backup/enkfgdas.${GYMD}/${GH}
    ENKFBAK_ATMOS=${ENKFBAK}/atmos/
    ENKFBAK_DIAG=${ENKFBAK}/diag/aod_obs
    ENKFBAK_ATMOS_MEAN_RT=${ENKFBAK}/ensmean/model_data/atmos/restart

    [[ ! -d ${ENKFBAK_DIAG} ]] && mkdir -p ${ENKFBAK_DIAG}
    #[[ ! -d ${ENKFBAK_ATMOS_MEAN_RT} ]] && mkdir -p ${ENKFBAK_ATMOS_MEAN_RT}

    #${NRM} ${ENKFDIR_ATMOS}/mem???/*.txt

    if [ ${AERODA} = "YES" ]; then
        ${NRM} ${ENKFDIR}/ensmean/model_data/atmos/restart/${CPREFIX}.fv_tracer_aeroanl_tmp.res.tile?.nc
        ${NRM} ${ENKFDIR}/mem???/model_data/atmos/restart/${CPREFIX}.fv_tracer_aeroanl_tmp.res.tile?.nc
    fi

    ${NCP} ${ENKFDIR_DIAG}/* ${ENKFBAK_DIAG}/
    #${NCP} ${ENKFDIR_ATMOS_MEAN_RT}/${CPREFIX}.coupler* ${ENKFBAK_ATMOS_MEAN_RT}/
    #${NCP} ${ENKFDIR_ATMOS_MEAN_RT}/${CPREFIX}.fv_core* ${ENKFBAK_ATMOS_MEAN_RT}/
    #${NCP} ${ENKFDIR_ATMOS_MEAN_RT}/${CPREFIX}.fv_tracer* ${ENKFBAK_ATMOS_MEAN_RT}/

    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "Copy enkf data failed at ${CDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    fi

    IGRP=0
    LGRP=${TMPDIR}/list.grp${IGRP}
    [[ -f ${LGRP} ]] && rm -rf ${LGRP}
    echo "ensmean" > ${LGRP}
    IGRP=1
    while [ ${IGRP} -le ${NGRPS} ]; do
        ENSED=$((${NMEM_ENSGRP_ARCH} * 10#${IGRP}))
	ENSST=$((${ENSED} - ${NMEM_ENSGRP_ARCH} + 1))
	    
	LGRP=${TMPDIR}/list.grp${IGRP}
	[[ -f ${LGRP} ]] && rm -rf ${LGRP}

	IMEM=${ENSST}
	while [ ${IMEM} -le ${ENSED} ]; do
	    MEMSTR="mem"`printf %03d ${IMEM}`
            echo ${MEMSTR} >> ${LGRP}
	    IMEM=$((IMEM+1))
	done
	IGRP=$((IGRP+1))
    done

    IGRP=0
    TARFILE=${DATAHPSSDIR}/enkfgdas.${GDATE}.ensmean.tar
    LGRP=${TMPDIR}/list.grp${IGRP}
    cd ${ENKFDIR}
    #htar -P -cvf ${TARFILE}  $(cat ${LGRP})
    tar -cvf ${TARFILE}  $(cat ${LGRP})
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "HTAR enkf data failed at ${GDATE} and grp${IGRP}" >> ${HPSSRECORD}
        exit ${ERR}
    fi

    #for field in "atmos" "chem"; do
    #    if [ ${field} = "atmos" ]; then
    #	    ENKFDIR_FIELD=${ENKFDIR_ATMOS}
    #	elif [ ${field} = "chem" ]; then
    #	    ENKFDIR_FIELD=${ENKFDIR_CHEM}
    #	else
    #	    echo "Only atmos and chem defined for field variable"
    #	    exit 100
    #	fi

    IGRP=1
    while [ ${IGRP} -le ${NGRPS} ]; do
        TARFILE=${DATAHPSSDIR}/enkfgdas.${GDATE}.grp${IGRP}.tar
        LGRP=${TMPDIR}/list.grp${IGRP}
        cd ${ENKFDIR}
        #htar -P -cvf ${TARFILE}  $(cat ${LGRP})
        tar -P -cvf ${TARFILE}  $(cat ${LGRP})
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "HTAR enkf data* failed at ${GDATE} and grp${IGRP}" >> ${HPSSRECORD}
            exit ${ERR}
        fi
        IGRP=$((IGRP+1))
    done

    CPCNTLDIAG=${ENKFDIR_DIAG}/cntl
    [[ ! -d ${CPCNTLDIAG} ]] && mkdir -p ${CPCNTLDIAG}
    ${NCP} ${CNTLDIR_DIAG}/* ${CPCNTLDIAG}/
    cd ${ENKFDIR_DIAG}
    TARFILE=${DATAHPSSDIR}/diag.cntlenkf.${GDATE}.tar
    #tar -P -cvf ${TARFILE} *
    tar -P -cvf ${TARFILE} *
    ERR=$?
    if [ ${ERR} -ne 0 ]; then
        echo "HTAR enkf diag data failed at ${GDATE}" >> ${HPSSRECORD}
        exit ${ERR}
    fi

fi #ENSRUN

if [ ${ERR} -eq 0 ]; then
    echo "HTAR is successful at ${GDATE}"
    #${NRM} ${CNTLDIR}
    #if [ ${AERODA} = "YES" -o ${ENSRUN} = "YES" ]; then
    #    ${NRM} ${ENKFDIR}
    #fi
    # echo "YES" > ${TMPDIR}/remove.record
    cd ${TMPDIR}
/opt/slurm/bin/sbatch sbatch_glbus2niag_ret.sh
else
    echo "HTAR failed at ${GDATE}" >> ${HPSSRECORD}
    exit ${ERR}
fi

exit ${ERR}
