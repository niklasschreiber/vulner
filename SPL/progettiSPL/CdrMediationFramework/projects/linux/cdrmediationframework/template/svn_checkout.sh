#!/bin/bash

###########################################################
#
# Copyright (c) 2013 GFM Integration. All rights reserved.
# GFM Integration Development Unit.
#
# Company confidential.
#
# This software is proprietary to and embodies the confidential
# technology of GFM Integration. Possession, use, or copying of
# this software and media is authorized only pursuant to a valid
# written license from GFM Integration or an authorized sublicensor.
#
# Version         : 1.0.0
# Date created    : 01-11-2013
# Date last modify: 
#
# Description     : SVN Checkout script file
#
#
# Optional parameters are pointed out in the comment,
# all the others are mandatory.
#
# Hints provided below are indications only.
# For reference data, please consult User's manual.
#
# Everything after a '#' is treated as comment.
#
# Comments can also be put after parameter values.
#
###########################################################

###########################################################
#
# Template file: "SVN Checkout Script"
#
###########################################################


#################################################
# USER'S EDITABLE SECTION
#################################################

# Exit codes definition
SUCCESS_CODE=0
INVOKER_ID_MISMATCH_CODE=1
LIST_FILE_READ_ISSUE_CODE=2
OPERATION_COMPLETED_WITH_ERRORS=3

RETVAL=${SUCCESS_CODE}

# APP_NAME is the name of the service provided by the script
APP_NAME="SVN Checkout Service"

# USER is the application username
USER=streamsadmin

# ALLOW_ROOT_ONLY allow the root user only to execute this script
ALLOW_ROOT_ONLY=0

# LIST_FILE is the file containing the list of SVN links to checkout
LIST_FILE=svn_checkout.list

# DEBUG flag (use either DEBUG or null values ) -- in production comment line!
#DEBUG=DEBUG


###############################################################################
# common functions

trim() { echo $1; }


###############################################################################
# main

# Check invoker is root, if not exit
MY_USER="`id -un`"

if [ "${ALLOW_ROOT_ONLY}" != "0" ] ; then
  if [ "${MY_USER}" != "root" ] ; then
    echo "`date`: Cannot continue. Invoker must be 'root', not \"${MY_USER}\""

    exit ${INVOKER_ID_MISMATCH_CODE}
  else
    RUN_CMD="svn checkout"
  fi
elif [ "${MY_USER}" = "root" ] ; then
  RUN_CMD="su -l ${USER} -c svn checkout"
elif [ "${MY_USER}" = "${USER}" ] ; then
  RUN_CMD="svn checkout"
else
  echo "`date`: Cannot continue. Invoker must be 'root' or '${USER}', not \"${MY_USER}\""

  exit ${INVOKER_ID_MISMATCH_CODE}
fi

if test ! -f ${LIST_FILE} ; then
  echo "`date`: Cannot continue. Missing list file ${LIST_FILE} !"

  RETVAL=${LIST_FILE_READ_ISSUE_CODE}
elif test ! -r ${LIST_FILE} ; then
  echo "`date`: Cannot continue. Not a readable file ${LIST_FILE} !"

  RETVAL=${LIST_FILE_READ_ISSUE_CODE}
elif test ! -s ${LIST_FILE} ; then
  echo "`date`: Cannot continue. Empty list file ${LIST_FILE} !"

  RETVAL=${LIST_FILE_READ_ISSUE_CODE}
else
  echo "Starting ${APP_NAME}..."
  echo ""

  # Parse LIST_FILE

  COUNT=0
  while read -r line; do
    if [[ ${line} != \#* ]] && [[ ${line} == *=* ]] ; then
      name=${line%%=*}
      value=${line##*=}

      [ ${DEBUG} ] && echo "DEBUG - raw parsed name >${name}<, value >${value}<"

      name=$(trim ${name})
      value=$(trim ${value})

      [ ${DEBUG} ] && echo "DEBUG - trimmed name >${name}<, value >${value}<"

      if [ ! "${name}" ] ; then
        echo "`date`: Missing SVN link, skipped line: >${line}<"

        continue
      fi

      if [ ! "${value}" ] ; then
        echo "`date`: Missing mount path, skipped line: >${line}<"

        continue
      fi

      NAME_LIST[ ${COUNT} ]=${name}
      VALUE_LIST[ ${COUNT} ]=${value}

      COUNT=$(( ${COUNT} + 1 ))
    fi
  done < ${LIST_FILE}

  I=0
  while [ ${I} -lt ${COUNT} ]; do
    echo "Checking out SVN link \"${NAME_LIST[ ${I} ]}\" to path \"${VALUE_LIST[ ${I} ]}\"..."
    echo ""

    rm -rf ${VALUE_LIST[ ${I} ]}

    ${RUN_CMD} ${NAME_LIST[ ${I} ]} ${VALUE_LIST[ ${I} ]} 1>/dev/null

    RET=$?
    if [ ! ${RET} -eq 0 ]; then
      echo ""
      echo "Error loading SVN link \"${NAME_LIST[ ${I} ]}\", return value=\"${RET}\""
      echo ""

      RETVAL=${OPERATION_COMPLETED_WITH_ERRORS}

      break
    else
      [ ${DEBUG} ] && echo "DEBUG - Loaded SVN link \"${NAME_LIST[ ${I} ]}\""
    fi

    I=$(( ${I} + 1 ))
  done
fi

exit ${RETVAL}
