#!/bin/bash

dir0=/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules/parm/ufs/gocart
dir1=/work2/noaa/gsd-fv3-dev/bhuang/expRuns/UFS-Aerosols_RETcyc/AeroReanl/AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007/dr-data/logs/2020100206/chem/
dir2=/work2/noaa/wrf-chem/bohuang/testHercules/UFSAerosols-workflow/20231213-develop/global-workflow/expdir/cycExp_ATMA_warm
subdir=""

cd ${dir0}
files=$(ls *)
for file in ${files}; do
    echo "----HBO1-${file}----"
    echo "----202311 vs wk----"
    diff ${dir1}/${subdir}/${file} ${dir0}/${subdir}/${file}
    #echo "                      "
    #echo "----202311 vs 202312----"
    #diff ${dir1}/${subdir}/${file} ${dir2}/${subdir}/${file}
    echo "                      "
    echo "                      "
    echo "                      "
done
