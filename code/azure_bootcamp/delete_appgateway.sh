#!/bin/sh
#
# delete_vm.sh
#
# usege:
#   sh delete_vm.sh resorucegoupname vmname

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
