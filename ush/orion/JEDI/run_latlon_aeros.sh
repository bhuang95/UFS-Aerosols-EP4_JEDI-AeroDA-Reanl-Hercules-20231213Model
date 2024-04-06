#!/bin/bash

set -x

HOMEgfs=${HOMEgfs}
INDATADIR=${RSTDIR}
FV3AEROLLDIR=${FV3AEROLLDIR}
FV3AEROPLLDIR=${FV3AEROPLLDIR}
TRCR=${TRCR}
NCORES=${NCORES}
CDATE=${CDATE}
CASE=${CASE}
AEROLLEXEC=${AEROLLEXEC}
AEROPLLEXEC=${AEROPLLEXEC}

CYMD=${CDATE:0:8}
CH=${CDATE:8:2}
CDATEPRE="${CYMD}.${CH}0000"

NLN="/bin/ln -sf"
NCP="/bin/cp -r"

${NLN} ${AEROLLEXEC} ./fv32ll.x
${NLN} ${AEROPLLEXEC} ./fv32pll.x

FV3AERODIR=${INDATADIR}
FV3CORE=${CDATEPRE}.fv_core.res.tile?.nc
FV3TRCR=${CDATEPRE}.${TRCR}.res.tile?.nc
FV3AKBK=${CDATEPRE}.fv_core.res.nc

#${NLN} ${FV3AERODIR}/${FV3CORE} ./
#${NLN} ${FV3AERODIR}/${FV3TRCR} ./
#${NLN} ${FV3AERODIR}/${FV3AKBK} ./
#${NLN} ${HOMEgfs}/fix_self/grid_spec/${CASE}/${CASE}_grid_spec.tile?.nc ./

AEROLL=fv3_aeros_${TRCR}_${CDATE}_ll.nc
[[ ! -d ${FV3AEROLLDIR} ]] && mkdir -p ${FV3AEROLLDIR}
[[ -f fv32ll.nl ]] && rm -rf fv32ll.nl
cat > fv32ll.nl <<EOF
&record_input
 date="${CDATE}"
 input_grid_dir="${HOMEgfs}/fix_self/grid_spec/${CASE}"
 !input_grid_dir="./"
 fname_grid="${CASE}_grid_spec.tile?.nc"
 input_fv3_dir="${FV3AERODIR}"
 !input_fv3_dir="./"
 fname_fv3_tracer="${FV3TRCR}"
 fname_fv3_core="${FV3CORE}"
 fname_akbk="${FV3AKBK}"
/
&record_interp
 varlist_core= "T"
 varlist_tracer= "sphum","bc1","bc2","dust1","dust2","dust3","dust4","dust5","oc1","oc2","seas1","seas2","seas3","seas4","seas5","so4"
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="${FV3AEROLLDIR}"
 !output_dir="./"
 fname_ll="${AEROLL}"
/
EOF

#srun --export=all -n ${NCORES}  ./fv3aod2ll.x
cat fv32ll.nl
./fv32ll.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "fv3aod2ll.x failed an exit!!!"
#    exit 1
fi
${NCP} fv32ll.nl ${FV3AEROLLDIR}/fv32ll_${TRCR}.nl

AEROPLL=fv3_aeros_${TRCR}_${CDATE}_pll.nc
[[ ! -d ${FV3AEROPLLDIR} ]] && mkdir -p ${FV3AEROPLLDIR}
[[ -f fv32pll.nl ]] && rm -rf fv32pll.nl
cat > fv32pll.nl <<EOF
&record_input
 date="${CDATE}"
 input_grid_dir="${HOMEgfs}/fix_self/grid_spec/${CASE}"
 !input_grid_dir="./"
 fname_grid="${CASE}_grid_spec.tile?.nc"
 !input_fv3_dir="./"
 input_fv3_dir="${FV3AERODIR}"
 fname_fv3_core="${FV3CORE}"
 fname_fv3_tracer="${FV3TRCR}"
 fname_akbk="${FV3AKBK}"
/
&record_interp
 ! varlist_in is only for illustration since translation is hard-coded
 ! and will not aggregate correctly if all species not present
 varlist_in= "bc1","bc2","dust1","dust2","dust3","dust4","dust5","oc1","oc2","seas1","seas2","seas3","seas4","seas5","so4"
 ! varlist_out is only for illustration since translation is hard-coded
 ! and will not aggregate correctly if all species not present
 varlist_out= "BCPHOBIC","BCPHILIC","DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL","OCPHOBIC","OCPHILIC","SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL","SO4"
 plist = 100.,250.,400.,500.,600.,700.,850.,925.,1000.
 dlon=0.5
 dlat=0.5
/
&record_output
 output_dir="${FV3AEROPLLDIR}"
 !output_dir="./"
 fname_pll="${AEROPLL}"
/
EOF

#srun --export=all -n ${NCORES}  ./fv3aod2ll.x
cat fv32pll.nl
./fv32pll.x
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "fv3aod2ll.x failed an exit!!!"
    exit 1
fi
${NCP} fv32pll.nl ${FV3AEROPLLDIR}/fv32pll_${TRCR}.nl

exit ${ERR}
