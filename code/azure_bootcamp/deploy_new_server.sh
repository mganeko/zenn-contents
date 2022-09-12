#!/bin/sh
#
# deploy_new_server.sh
#
# usege:
#   sh deploy_new_server.sh new-servername message

# --- check args ---
if [ $# -ne 2 ]; then
  echo "ERROR: Please specify New-Servername and Message (2 args)." 1>&2
  exit 1
fi
SEREVERNAME=$1
MESSAGE=$2

# -- prepare cloud-init file --
sh prepare_cloudinit.sh $MESSAGE

# -- create new server
#  ex) serveer-name: myVMgreen
sh create_new_server.sh $SEREVERNAME
RET=$?
if [ $RET -ne 0 ]; then
  echo "ERROR: CANNNOT create Server:$SEREVERNAME"
  exit $RET
fi

# -- wait and append new server --
#  ex) serveer-name: myVMgreen
sh switch_server.sh $SEREVERNAME
exit $?


