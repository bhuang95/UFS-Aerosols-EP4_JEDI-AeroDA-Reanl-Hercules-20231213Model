#! /usr/bin/env bash
#SBATCH -n 1
#SBATCH -t 00:30:00
#SBATCH -p service
#SBATCH -A chem-var
#SBATCH -J fgat
#SBATCH -D ./
#SBATCH -o ./bump_gfs_c96.out
#SBATCH -e ./bump_gfs_c96.out

module load hpss
set -x


export HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/"}
export ROTDIR=${ROTDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data"}
#export EXPDIR=${EXPDIR:-"${HOMEgfs}/dr-work"}
export METRETDIR=${METRETDIR:-"/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/exp_UFS-Aerosols/cycExp_ATMA_warm/dr-data/RetrieveGDAS"}
export CHGRESHPSSDIR=${CHGRESHPSSDIR:-"/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/GDASCHGRES-V14/"}
export CDATE=${CDATE:-"2017100200"}
export CASE_CNTL=${CASE_CNTL:-"C192"}
export CASE_ENKF=${CASE_ENKF:-"C192"}
export NMEMSGRPS=${NMEMSGRPS:-"01-40"}
export assim_freq=${assim_freq:-"6"}
export AERODA=${AERODA:-"YES"}
export NMEM_ENKF=${NMEM_ENKF:-"20"}
export ENSRUN=${ENSRUN:-"YES"}
export MISSGDASRECORD=${MISSGDASRECORD:-"/home/Bo.Huang/JEDI-2020/UFS-Aerosols_NRTcyc/UFS-Aerosols_JEDI-AeroDA-1C192-20C192_NRT/misc/GDAS/CHGRESGDAS/v14/record.chgres_hpss_htar_allmissing_v14"}
COMP_ANL_ATM="analysis/atmos"
COMP_MOD_ATM_RST="model_data/atmos/restart"
NDATE=${NDATE:-"/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Orion/misc/ndate/ndate"}

#source "${HOMEgfs}/ush/preamble.sh"
#. $HOMEgfs/ush/load_ufswm_modules.sh
#status=$?
#[[ $status -ne 0 ]] && exit $status

if ( grep ${CDATE} ${MISSGDASRECORD} ); then 
    echo "GDAS Met data not avaibale on HPSS and continue"
    exit 0
fi
CYMD=${CDATE:0:8}
CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}

GDATE=$($NDATE -$assim_freq ${CDATE})
GYMD=${GDATE:0:8}
GY=${GDATE:0:4}
GM=${GDATE:4:2}
GD=${GDATE:6:2}
GH=${GDATE:8:2}

NCP="/bin/cp -r"
NMV="/bin/mv -f"
NRM="/bin/rm -rf"
NLN="/bin/ln -sf"

GDASDIR=${METRETDIR}/${CASE_CNTL}

GGDASCNTLOUT=${GDASDIR}/gdas.${GYMD}/${GH}
GGDASENKFOUT=${GDASDIR}/enkfgdas.${GYMD}/${GH}
[[ -d ${GGDASCNTLOUT} ]] && ${NRM} ${GGDASCNTLOUT}
[[ -d ${GGDASENKFOUT} ]] && ${NRM} ${GGDASENKFOUT}

GDASCNTLOUT=${GDASDIR}/gdas.${CYMD}/${CH}
GDASENKFOUT=${GDASDIR}/enkfgdas.${CYMD}/${CH}
[[ -d ${GDASCNTLOUT} ]] && ${NRM} ${GDASCNTLOUT}
[[ -d ${GDASENKFOUT} ]] && ${NRM} ${GDASENKFOUT}
mkdir -p ${GDASCNTLOUT}
mkdir -p ${GDASENKFOUT}

GROTCNTLOUT=${ROTDIR}/gdas.${GYMD}/${GH}/
GROTENKFOUT=${ROTDIR}/enkfgdas.${GYMD}/${GH}/
ROTCNTLOUT=${ROTDIR}/gdas.${CYMD}/${CH}/
ROTENKFOUT=${ROTDIR}/enkfgdas.${CYMD}/${CH}/

[[ ! -d ${GROTCNTLOUT} ]] && mkdir -p ${GROTCNTLOUT}
[[ ! -d ${GROTENKFOUT} ]] && mkdir -p ${GROTENKFOUT}
[[ ! -d ${ROTCNTLOUT} ]] && mkdir -p ${ROTCNTLOUT}
[[ ! -d ${ROTENKFOUT} ]] && mkdir -p ${ROTENKFOUT}


cd ${GDASCNTLOUT}
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
TARDIR=${CHGRESHPSSDIR}/GDAS_CHGRES_NC_${CASE_CNTL}/${CY}/${CY}${CM}/${CY}${CM}${CD}
TARFILE=gdas.${CDATE}.${CASE_CNTL}.NC.tar
#htar -xvf ${TARDIR}/${TARFILE} 
tar -xvf ${TARDIR}/${TARFILE} 
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}
TGTDIR=${ROTCNTLOUT}/${COMP_ANL_ATM}
[[ ! -d ${TGTDIR} ]] && mkdir -p ${TGTDIR}
mv ${GDASCNTLOUT}/gdas.t${CH}z.atmanl.${CASE_CNTL}.nc  ${ROTCNTLOUT}/${COMP_ANL_ATM}/gdas.t${CH}z.atmanl.nc
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

GDASCNTLRST=${GDASCNTLOUT}/RESTART
ROTCNTLRST=${ROTCNTLOUT}/${COMP_MOD_ATM_RST}
[[ ! -d ${ROTCNTLRST} ]] && mkdir -p ${ROTCNTLRST}
mv ${GDASCNTLRST}/* ${ROTCNTLRST}/
ERR=$?
[[ ${ERR} -ne 0 ]] && exit ${ERR}

if [ ${AERODA} = 'YES' -o ${ENSRUN} = 'YES' ]; then  
    cd ${GDASENKFOUT}
    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    TARDIR=${CHGRESHPSSDIR}/ENKFGDAS_CHGRES_NC_${CASE_ENKF}/${CY}/${CY}${CM}/${CY}${CM}${CD}
    TARFILE=${TARDIR}/enkfgdas.${CDATE}.${CASE_ENKF}.NC.${NMEMSGRPS}.tar

    rm -rf list1.gdasenkf list2.gdasenkf list3.gdasenkf
    #htar -tvf ${TARFILE} > list1.gdasenkf
    tar -tvf ${TARFILE} > list1.gdasenkf
    IMEM=1
    while [ ${IMEM} -le ${NMEM_ENKF} ]; do
        MEMSTR="mem"$(printf %03d ${IMEM})
	grep ${MEMSTR} list1.gdasenkf >> list2.gdasenkf
	IMEM=$((IMEM+1))
    done

    while read -r line
    do
        echo ${line##*' '} >> ./list3.gdasenkf
    done < "./list2.gdasenkf"

    #htar -xvf ${TARFILE} -L ./list3.gdasenkf
    tar -xvf ${TARFILE} < ./list3.gdasenkf

    ERR=$?
    [[ ${ERR} -ne 0 ]] && exit ${ERR}
    
    IMEM=1
    while [ ${IMEM} -le ${NMEM_ENKF} ]; do
        IMEMSTR=$(printf "%03d" ${IMEM})
	MEM="mem${IMEMSTR}"
	SRCDIR=${GDASENKFOUT}/${MEM}/
	TGTDIR=${ROTENKFOUT}/${MEM}/${COMP_ANL_ATM}
	[[ ! -d ${TGTDIR} ]] && mkdir -p ${TGTDIR}
        SRCFILE=${SRCDIR}/gdas.t${CH}z.ratmanl.${MEM}.${CASE_ENKF}.nc
        TGTFILE=${TGTDIR}/enkfgdas.t${CH}z.ratmanl.nc
	mv ${SRCFILE} ${TGTFILE}
        ERR=$?
        [[ ${ERR} -ne 0 ]] && exit ${ERR}
        
	SRCRST=${GDASENKFOUT}/${MEM}/RESTART
	TGTRST=${ROTENKFOUT}//${MEM}/${COMP_MOD_ATM_RST}
	[[ ! -d ${TGTRST} ]] && mkdir -p ${TGTRST}
	mv ${SRCRST}/* ${TGTRST}/
        ERR=$?
        [[ ${ERR} -ne 0 ]] && exit ${ERR}
	#ITILE=1
	#while [ ${ITILE} -le 6 ]; do
	#    SRCFILE=${SRCRST}/${CYMD}.${CH}0000.sfcanl_data.tile${ITILE}.nc
	#    TGTFILE=${TGTRST}/${CYMD}.${CH}0000.sfcanl_data.tile${ITILE}.nc
	#    mv ${SRCFILE} ${TGTFILE}
	#    ITILE=$((ITILE+1))
	#done

	IMEM=$((IMEM+1))
    done
fi

exit ${ERR}
