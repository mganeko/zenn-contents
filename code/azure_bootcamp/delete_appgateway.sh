#!/bin/sh
#
# delete_appgateway.sh
#
# usege:
#   sh delete_appgateway.sh resorucegoupname appgateway-name

# --- check args ---
if [ $# -ne 2 ]; then
  echo "ERROR: Please specify resouce-group-name and appgateway-name (2 args)." 1>&2
  exit 1
fi


# -- param --
RGNAME=$1
APPGATEWAY=$2
echo "ResourceGroup Name=" $RGNAME
echo "AppGateway Name=" $APPGATEWAY
echo ""

# -- delete AppGateway ---
echo "-- deleting AppGateway name=" $APPGATEWAY " --"
az network application-gateway delete --resource-group $RGNAME --name $APPGATEWAY
echo "delete AppGateway result:" $?
