#!/bin/bash

dir0=/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules/dr-work-mpi
dir1=/work2/noaa/wrf-chem/bohuang/testHercules/UFSAerosols-workflow/20231116-develop/global-workflow/expdir/cycExp_ATMA_warm
dir2=/work2/noaa/wrf-chem/bohuang/testHercules/UFSAerosols-workflow/20231213-develop/global-workflow/expdir/cycExp_ATMA_warm
subdir=""

cd ${dir0}
files=$(ls config.*)
config.aero-directly copy and modify later
config.aeroanl- directly copy
config.aeroanlinit- the same
config.aeroanlrun- copy first and then modify later for my need
config.aerosol_init - the same
config.base- directly copy and add my later
config.com - the same
config.efcs - copy first and modify later
config.fcst- directly copy
config.nsst - the same
config.resources- direclty copy
config.ufs-directly copy first and then modify 

for file in ${files}; do
    echo "----HBO1-${file}----"
    echo "----202311 vs wk----"
    diff ${dir1}/${subdir}/${file} ${dir0}/${subdir}/${file}
    echo "                      "
    echo "----202311 vs 202312----"
    diff ${dir1}/${subdir}/${file} ${dir2}/${subdir}/${file}
    echo "                      "
    echo "                      "
    echo "                      "
done
