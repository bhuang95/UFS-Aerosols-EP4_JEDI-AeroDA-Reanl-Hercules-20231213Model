#!/bin/bash

hh=$(date +%H)

echo ${hh}
if [ "${hh}" = "00" ] || [ "${hh}" = "06" ] || [ "${hh}" = "12" ] || [ "${hh}" = "18" ]; then
   echo ${hh}
fi
