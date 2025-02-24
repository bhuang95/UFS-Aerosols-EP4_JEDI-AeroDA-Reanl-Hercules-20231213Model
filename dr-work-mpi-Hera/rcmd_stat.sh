#!/bin/bash

module load rocoto
#rocotostat -w cycExp_ATMA_warm.xml -d cycExp_ATMA_warm.db | less
#rocotostat -w /home/Bo.Huang/JEDI-2020/UFS-Aerosols_RETcyc/UFS-Aerosols-EP4_JEDI-AeroDA-Reanl/dr-work/RET_EP4_SpinUp_C96_202005.xml -d /scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/UFS-Aerosols_RETcyc/RET_EP4_SpinUp_C96_202005/dr-work/RET_EP4_SpinUp_C96_202005.db | less
rocotostat -w RET_EP4_AeroDA_YesSPE_C96_202006.xml -d RET_EP4_AeroDA_YesSPE_C96_202006.db
