#!/usr/bin/env bash
# Author: jayalmaraz 
# Source: https://github.com/jayalmaraz/easy-sed

usage_message() { echo "Usage: $0 FIND REPLACE [FILE]" 1>&2; exit 1; }

if [ "${#}" -lt 2 ]; then
    usage_message
fi

if [ "${#}" -gt 3 ]; then
    usage_message
fi

FIND=$1
REPLACE=$2
FILE=$3

FIND=$(sed 's|*|\\*|g' <<< ${FIND})
FIND=$(sed 's|_|\\_|g' <<< ${FIND})
FIND=$(sed 's|&|\\&|g' <<< ${FIND})
FIND=$(sed 's|'\''|'\'"\\\'"\''|g' <<< ${FIND})

REPLACE=$(sed 's|*|\\*|g' <<< ${REPLACE})
REPLACE=$(sed 's|_|\\_|g' <<< ${REPLACE})
REPLACE=$(sed 's|&|\\&|g' <<< ${REPLACE})
REPLACE=$(sed 's|'\''|'\'"\\\'"\''|g' <<< ${REPLACE})

if [[ "$OSTYPE" == "darwin"* ]]; then
    # EASY_SED_COMMAND="sed -i ''" # uncomment this line if you want to edit in-place
    EASY_SED_COMMAND="sed ''"
else
    # EASY_SED_COMMAND='sed -i' # uncomment this line if you want to edit in-place
    EASY_SED_COMMAND='sed'
fi

if [ "${#}" == 3 ]; then
    COMMAND="${EASY_SED_COMMAND} 's_${FIND}_${REPLACE}_g' ${FILE}"
else
    COMMAND="sed 's_${FIND}_${REPLACE}_g'"
fi
eval ${COMMAND}