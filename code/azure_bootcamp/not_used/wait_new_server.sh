#!/bin/sh
#
# check_server_ready.sh
#
# usege:
#   sh wait_new_and_remove_old_server.sh newservername


#-- variables --
RGNAME="myAGgroup"
SERVERNAME=""

# ============= functions ==============

# -- check args (must be 1) --
function checkArgs() {
  if [ $1 -ne 1 ]; then
    echo "ERROR: Please specify new-servername (1 arg)."
    exit 1
  fi
}

# -- check if server ready --
function checkServerReady() {
  # --- check node.js process is running ---
  az vm run-command invoke \
    --resource-group myAGgroup \
    --name $SERVERNAME \
    --command-id RunShellScript \
    --scripts "ps -ef | grep nodejs | grep index.js" | grep index.js
  return $?
}

# --- loop for server ready ---
function waitLoopServerReady() {
  for COUNT in 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
  do
    echo "- wait 30 sec. count:$COUNT --"
    sleep 30
    checkServerReady
    local RET=$?

    if [ $RET -eq 0 ]; then
      echo "-- OK: new server is READY --"
      return 0
    fi
  done

  echo "-- ERROR: new server is NOT READY --"
  return 1
}

# ============= main ==============

# -- args --
ARGNUM=$#
checkArgs $ARGNUM

SERVERNAME=$1

# -- wait for new server --
waitLoopServerReady
RET=$?

exit $RET
