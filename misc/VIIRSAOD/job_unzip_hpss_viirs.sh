#!/bin/bash --login
#SBATCH -J dr-data-1
#SBATCH -A chem-var
#SBATCH -n 1
#SBATCH --mem=5g
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./dr-data-1-out.txt
#SBATCH -e ./dr-data-1-out.txt

module load hpss

datadir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/data
tiledir=${datadir}/ncfile
#cycS=2016051012
#cycE=2016051418
cycS=2020070100
cycE=2020070100
cycInc=24
incdate=/home/Bo.Huang/JEDI-2020/usefulScripts/incdate.sh

mkdir -p ${tmpDir}

cycN=${cycS}
while [ ${cycN} -le ${cycE} ]; do
    echo ${cycN}

    cycY=`echo ${cycN} | cut -c 1-4`
    cycM=`echo ${cycN} | cut -c 5-6`
    cycD=`echo ${cycN} | cut -c 7-8`
    cycH=`echo ${cycN} | cut -c 9-10`
    cycYMD=`echo ${cycN} | cut -c 1-8`

    cd ${datadir}

    hpssdir=/BMC/fdr/Permanent/${cycY}/${cycM}/${cycD}/data/sat/nesdis/viirs/aod/conus
    heradir=${datadir}/${cycN}00

    mkdir -p ${heradir}
    cd ${heradir}

    hsi get ${hpssdir}/${cycN}00.zip 

    stat=$?
    if [ ${stat} != '0' ]; then
       echo "HTAR failed at ${cycN}  and exit at error code ${stat}"
     	exit ${stat}
    else
       echo "HTAR at cntlHPSS completed !"
    fi

    unzip ${cycN}00.zip

    mv *.nc  ${tiledir}

     #fs=$(ls *-C96GT?_v4r0_blend_s${cycYMD}0000000_e${cycYMD}2359590_*)
     #echo ${fs}
#
#     for f in ${fs}; do
#         sufix=$(echo ${f} | cut -d"_" -f1,2)
#	 newf=${sufix}_${cycYMD}.bin
#         ln -sf ${heradir}/${f} ${tiledir}/${newf}
#	 #sleep 2
#     done

     stat=$?
     if [ ${stat} != '0' ]; then
        echo "Linking failed at ${cycN}" 
      	exit ${stat}
     fi

     cycN=`${incdate} ${cycN} ${cycInc}`
done
    
exit 0

