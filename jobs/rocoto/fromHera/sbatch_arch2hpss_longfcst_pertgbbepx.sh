#!/bin/bash --login
#SBATCH -J hera2hpss
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./hera2hpss.out
#SBATCH -e ./hera2hpss.out

set -x
# Back up cycled data to HPSS at ${CDATE}-6 cycle

source config_hera2hpss

NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}

module load hpss
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

if ( grep YES ${RMREC} ); then
    echo  "${RMDIR}"
    ${NRM} ${RMDIR}
fi

CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}
CYMD=${CDATE:0:8}

GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}
GYMD=${GDATE:0:8}

DATAHPSSDIR=${ARCHHPSSDIR}/${PSLOT}/dr-data-longfcst-pertgbbepx/${CY}/${CY}${CM}/${CYMD}/
hsi "mkdir -p ${DATAHPSSDIR}"
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "*hsi mkdir* failed at ${CDATE}" >> ${HPSSRECORD}
    exit ${ERR}
fi



CNTLDIR_GDATE=${ROTDIR}/gdas.${GYMD}/${GH}
CNTLDIR_CDATE=${ROTDIR}/gdas.${CYMD}/${CH}
CNTLDIR_ATMOS_GDATE=${CNTLDIR_GDATE}/model_data/atmos/
CNTLDIR_ATMOS_CDATE=${CNTLDIR_CDATE}/model_data/atmos/
CNTLDIR_ATMOS_RT_GDATE=${CNTLDIR_ATMOS_GDATE}/restart
CNTLDIR_ATMOS_RT_CDATE=${CNTLDIR_ATMOS_CDATE}/restart

CNTLBAK=${ROTDIR}/../dr-data-longfcst-pertgbbepx-backup/gdas.${CYMD}/${CH}
CNTLBAK_ATMOS_RT_CDATE=${CNTLBAK}/model_data/atmos/restart/

[[ ! -d ${CNTLBAK_ATMOS_RT_CDATE} ]] && mkdir -p ${CNTLBAK_ATMOS_RT_CDATE}

if [ -s ${CNTLDIR_ATMOS_RT_CDATE} ]; then

    # Copy filed at 00Z or 00D
    TGTDIR=${CNTLBAK_ATMOS_RT_CDATE}
    TGTTRCR="fv_tracer"
    FHR=0
    while [ ${FHR} -le ${FHMAX} ]; do
    #for FHR in ${RSTS}; do
        IDATE=$(${NDATE} ${FHR} ${CDATE})
	IYMD=${IDATE:0:8}
	IH=${IDATE:8:2}
        CPREFIX=${IYMD}.${IH}0000

	if [ ${IDATE} = ${CDATE} ]; then
            SRCDIR=${CNTLDIR_ATMOS_RT_GDATE}
            if [ ${AERODA} = "YES" ]; then
                SRCTRCR="fv_tracer_aeroanl"
            else
                SRCTRCR="fv_tracer"
            fi
	    #ICBAKDIR=${CNTLDIR_ATMOS_RT_CDATE}/IC
	    #[[ ! -d ${ICBAKDIR} ]] && mkdir -p ${ICBAKDIR}
	    #${NCP} ${SRCDIR}/${CPREFIX}* ${ICBAKDIR}/
            #ERR=$?
            #if [ ${ERR} -ne 0 ]; then
            #    echo "Copy cntl data failed at ${CDATE}" >> ${HPSSRECORD}
            #    exit ${ERR}
            #fi
	else
            SRCDIR=${CNTLDIR_ATMOS_RT_CDATE}
            SRCTRCR="fv_tracer"
	fi

        ${NCP} ${SRCDIR}/${CPREFIX}.coupler.res ${TGTDIR}/
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "Copy cntl data failed at ${CDATE}" >> ${HPSSRECORD}
            exit ${ERR}
        fi

        ${NCP} ${SRCDIR}/${CPREFIX}.fv_core.res.nc ${TGTDIR}/
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "Copy cntl data failed at ${CDATE}" >> ${HPSSRECORD}
            exit ${ERR}
        fi

        ${NCP} ${SRCDIR}/${CPREFIX}.fv_core.res.tile?.nc ${TGTDIR}/
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "Copy cntl data failed at ${CDATE}" >> ${HPSSRECORD}
            exit ${ERR}
        fi
	
	if [ ${SRCTRCR} = "fv_tracer_aeroanl" ]; then
	    i=1
	    while [ ${i} -le 6 ]; do
                ${NCP} ${SRCDIR}/${CPREFIX}.${SRCTRCR}.res.tile${i}.nc ${TGTDIR}/${CPREFIX}.${TGTTRCR}.res.tile${i}.nc
                ERR=$?
                if [ ${ERR} -ne 0 ]; then
                    echo "Copy cntl data failed at ${CDATE}" >> ${HPSSRECORD}
                    exit ${ERR}
                fi

		i=$((i+1))
	    done
	else
            ${NCP} ${SRCDIR}/${CPREFIX}.fv_tracer.res.tile?.nc ${TGTDIR}/
            ERR=$?
            if [ ${ERR} -ne 0 ]; then
                echo "Copy cntl data failed at ${CDATE}" >> ${HPSSRECORD}
                exit ${ERR}
            fi
	fi

	FHR=$((${FHR}+${FHOUT}))
    done
    
    if [ ${TARALLRST} = "YES" ]; then
        if [ -d ${CNTLDIR_ATMOS_RT_GDATE}/pertEmis ]; then
            TARFILE=${DATAHPSSDIR}/gdas.longfcst.${CDATE}.pertEmis.InRstDir${GDATE}.tar
            cd ${CNTLDIR_ATMOS_RT_GDATE}
            htar -P -cvf ${TARFILE} ./pertEmis
            ERR=$?
            if [ ${ERR} -ne 0 ]; then
                echo "HTAR cntl restart data failed at ${CDATE} and ${FHR}" >> ${HPSSRECORD}
                exit ${ERR}
    	    fi
	fi

        cd ${CNTLDIR_CDATE}
        TARFILE=${DATAHPSSDIR}/gdas.longfcst.${CDATE}.tar
        htar -P -cvf ${TARFILE} *
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "HTAR cntl restart data failed at ${CDATE} and ${FHR}" >> ${HPSSRECORD}
            exit ${ERR}
        else
    	    echo "HTAR is complete and remove data"
            echo "${CNTLDIR_CDATE}"
            echo "${CNTLDIR_GDATE}"
            ${NRM} ${CNTLDIR_CDATE}
            ${NRM} ${CNTLDIR_GDATE}
	fi

    else
        cd ${CNTLDIR_ATMOS_RT_CDATE}

        if [ -d ${CNTLDIR_ATMOS_RT_CDATE}/pertEmis ]; then
            TARFILE=${DATAHPSSDIR}/gdas.longfcst.${CDATE}.pertEmis.tar
            htar -P -cvf ${TARFILE} ./pertEmis
            ERR=$?
            if [ ${ERR} -ne 0 ]; then
                echo "HTAR cntl restart data failed at ${CDATE} and ${FHR}" >> ${HPSSRECORD}
                exit ${ERR}
    	    fi

	fi

	FHR=${FHMIN}
	while [ ${FHR} -le ${FHMAX} ]; do
            IDATE=$(${NDATE} ${FHR} ${CDATE})
            IYMD=${IDATE:0:8}
    	    IH=${IDATE:8:2}
            CPREFIX=${IYMD}.${IH}0000
	    echo $(ls ${CPREFIX}*) > list.${FHR}
	    FHR=$((${FHR}+${FHOUT}))
        done

	FHR=${FHMIN}
	while [ ${FHR} -le ${FHMAX} ]; do
	    FHRSTR=$(printf %03d ${FHR})
            TARFILE=${DATAHPSSDIR}/gdas.longfcst.${CDATE}.RESTART.f${FHRSTR}.tar
            htar -P -cvf ${TARFILE} $(cat list.${FHR})
            ERR=$?
            if [ ${ERR} -ne 0 ]; then
                echo "HTAR cntl restart data failed at ${CDATE} and ${FHR}" >> ${HPSSRECORD}
                exit ${ERR}
    	    fi
	    FHR=$((${FHR}+${FHOUT}))
        done

        if [ ${ERR} -eq 0 ]; then
	    FHR=${FHMIN}
	    while [ ${FHR} -le ${FHMAX} ]; do
                cat list.${FHR}
                echo "$(cat list.${FHR})"
                ${NRM} $(cat list.${FHR})
                ERR=$?
                if [ ${ERR} -ne 0 ]; then
                    echo "RM HTAR cntl failed at ${CDATE} and ${FHR}" >> ${HPSSRECORD}
                    exit ${ERR}
	        fi
	        FHR=$((${FHR}+${FHOUT}))
    	    done
        fi

        if [ -d ${CNTLDIR_ATMOS_RT_GDATE}/pertEmis ]; then
            TARFILE=${DATAHPSSDIR}/gdas.longfcst.${CDATE}.pertEmis.InRstDir${GDATE}.tar
            cd ${CNTLDIR_ATMOS_RT_GDATE}
            htar -P -cvf ${TARFILE} ./pertEmis
            ERR=$?
            if [ ${ERR} -ne 0 ]; then
                echo "HTAR cntl restart data failed at ${CDATE} and ${FHR}" >> ${HPSSRECORD}
                exit ${ERR}
    	    fi
	fi

        cd ${CNTLDIR_CDATE}
        TARFILE=${DATAHPSSDIR}/gdas.longfcst.${CDATE}.NO_RESTART.tar
        htar -P -cvf ${TARFILE} *
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "HTAR cntl restart data failed at ${CDATE} and ${FHR}" >> ${HPSSRECORD}
            exit ${ERR}
        else
    	    echo "HTAR is complete and remove data"
            echo "${CNTLDIR_CDATE}"
            echo "${CNTLDIR_GDATE}"
            ${NRM} ${CNTLDIR_CDATE}
            ${NRM} ${CNTLDIR_GDATE}
        fi

    fi    
    echo "YES" > ${TMPDIR}/remove.record
fi # Done with loop through cntl

exit ${ERR}
