#!/bin/bash

dir0=/home/bohuang/Workflow/UFS-Aerosols_NRTcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl-Hercules/
dir1=/work2/noaa/wrf-chem/bohuang/testHercules/UFSAerosols-workflow/20231116-develop/global-workflow/
dir2=/work2/noaa/wrf-chem/bohuang/testHercules/UFSAerosols-workflow/20231213-develop/global-workflow/
subdir=ush

files="
atparse.bash-same
cplvalidate.sh-not avaiable in 202312
detect_machine.sh-copy directly
forecast_det.sh-the same
forecast_postdet.sh-modify orion version and add corresponding new in 202312
forecast_predet.sh-the same
jjob_header.sh-the same
load_ufswm_modules.sh- directly copy
module-setup.sh-directly copy
nems_configure.sh - replaced by ufs_configure.sh
parsing_model_configure_FV3.sh - directly copy
parsing_namelists_FV3.sh- directly copy
preamble.sh- the same
"

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
