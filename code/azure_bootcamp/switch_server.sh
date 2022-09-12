#!/bin/sh
#
# swith_server.sh
#
# usage:
#   sh switch_server.sh newservername

#-- variables --
RGNAME="myAGgroup"
APPGATEWAY="myAppGateway"
BACKENDPOOL="myBackendPool"
SERVERNAME=""
FISTIP=""


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
  for COUNT in 1 2 3 4 5 6 7 8 9 10
  do
    echo "- wait 30 sec. count:$COUNT"
    sleep 30
    checkServerReady
    local RET=$?

    if [ $RET -eq 0 ]; then
      echo "-- OK: new server is READY --"
      return 0
    fi
  done

  echo "-- ERROR: new server is NOT READY --"
  return 2
}

# --- get private ip address --
function getPrivateIP() {
  PRIVATEID=$(az vm show --show-details --resource-group $RGNAME --name $SERVERNAME --query privateIps -o tsv)
  echo "VM private IP=" $PRIVATEID
}

# --- add to backend pool ---
function appendToPool() {
  az network application-gateway address-pool update -g $RGNAME \
    --gateway-name $APPGATEWAY -n $BACKENDPOOL \
    --add backendAddresses ipAddress=$PRIVATEID
  echo "-- server" $SERVERNAME $PRIVATEID " added to backend pool --"
}

function getBackendCount() {
  #az network application-gateway address-pool show -g myAGgroup --gateway-name myAppGateway -n myBackendPool --query "backendAddresses"
  #az network application-gateway address-pool show -g myAGgroup --gateway-name myAppGateway -n myBackendPool --query "backendAddresses[].ipAddress" -o tsv
  local COUNT=$(az network application-gateway address-pool show -g myAGgroup --gateway-name myAppGateway -n myBackendPool --query "backendAddresses[].ipAddress" -o tsv | wc -l)
  return $COUNT
}

function checkFirstIsOld() {
  FIRSTIP=$(az network application-gateway address-pool show -g myAGgroup --gateway-name myAppGateway -n myBackendPool --query "backendAddresses[].ipAddress" -o tsv)
}

function removeFirst() {
  az network application-gateway address-pool update -g myAGgroup \
  --gateway-name myAppGateway -n myBackendPool \
  --remove backendAddresses 0
}


# ============= main ==============

# -- args --
ARGNUM=$#
checkArgs $ARGNUM

SERVERNAME=$1
echo "---- wait server:$SERVERNAME ready ---"

# -- wait for new server --
waitLoopServerReady
RET=$?
if [ $RET -ne 0 ]; then
  echo "ERROR: Server $SERVERNAME NOT READY."
  exit $RET
fi

# -- get pivateIP --
getPrivateIP

# -- append to backend pool --
appendToPool
sleep 5

# --- get count of backend --
getBackendCount
BAKCENDCOUNT=$?
if [ $BAKCENDCOUNT -eq 1 ]; then
  echo "only 1 backend. skip removing old server"
  echo "New Server:$SERVERNAME OK"
  exit 0
fi

# --- remove old server --
removeFirst
echo "--- remove old server ---"
echo "New Server:$SERVERNAME OK"

# --- exit ---
exit 0


