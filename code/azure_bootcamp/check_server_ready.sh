#!/bin/sh
#
# check_server_ready.sh
#
# usege:
#   sh check_server_ready.sh servername

# --- check args ---
if [ $# -ne 1 ]; then
  echo "ERROR: Please specify servername (1 arg)." 1>&2
  exit 1
fi
SERVERNAME=$1

RGNAME="myAGgroup"

# --- get private ip address --
PRIVATEID=$(az vm show --show-details --resource-group $RGNAME --name $SERVERNAME --query privateIps -o tsv)
echo "VM private IP=" $PRIVATEID

# --- check node.js process is running ---
az vm run-command invoke \
  --resource-group myAGgroup \
  --name $SERVERNAME \
  --command-id RunShellScript \
  --scripts "ps -ef | grep nodejs | grep index.js" | grep index.js
RET=$?

# --- check result ---
if [ $RET -ne 0 ]; then
  echo "server NOT READY yet"
  exit $RET
fi

echo "OK. server is READY"
exit $RET

