#!/bin/bash

FTASK=grp01
FGRP=${FTASK:(-2)}
FGRP1=$((10#${FTASK:(-2)}))

echo ${FGRP}
echo ${FGRP1}
