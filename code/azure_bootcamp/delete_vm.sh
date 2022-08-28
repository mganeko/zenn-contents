#!/bin/sh
#
# delete_vm.sh
#
# usege:
#   sh delete_vm.sh resorucegoupname vmname

# -- param --
RGNAME=$1
VMNAME=$2
echo "ResourceGroup Name=" + $RGNAME
echo "VM Name=" + $VMNAME
echo ""

# -- delete VM ---
echo "-- deleting VM name=" $VMNAME " --"
az vm delete --resource-group $RGNAME --name $VMNAME
echo "delete VM result:" $?
echo ""
