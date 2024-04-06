#!/bin/bash

cy=2017
ey=2018
file1=MEGAN.OFFLINE.BIOVOC.2017.emis.20180101t00:00:00z.nc
fpre=$(echo "${file1}" | cut -d. -f1-3)
fsuf=$(echo "${file1}" | cut -d. -f5-)
file2=${fpre}.${ey}.${fsuf}
echo ${fpre}
echo ${fsuf}
echo ${file1}
echo ${file2}
