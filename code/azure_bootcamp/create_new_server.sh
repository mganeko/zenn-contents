#!/bin/sh
#
# create_new_server.sh
#
# usege:
#   sh create_new_server.sh servername

# --- check args ---
if [ $# -ne 1 ]; then
  echo "ERROR: Please specify servername (1 arg)." 1>&2
  exit 1
fi
SERVERNAME=$1

RGNAME="myAGgroup"
VNET="myVNet"
SUBNET="myBackendSubnet"
BACKENDPOOL="myBackendPool"

# -- create new VM ---
az vm create \
  --resource-group $RGNAME \
  --name $SERVERNAME \
  --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest \
  --size Standard_B1ls \
  --public-ip-sku Standard \
  --public-ip-address "" \
  --subnet $SUBNET \
  --vnet-name $VNET \
  --nsg "" \
  --storage-sku StandardSSD_LRS \
  --nic-delete-option Delete \
  --os-disk-delete-option Delete \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data cloud-init-work.txt
echo "-- server" $SERVERNAME "created --"

# --- get private ip address --
PRIVATEID=$(az vm show --show-details --resource-group $RGNAME --name $SERVERNAME --query privateIps -o tsv)
echo "VM private IP=" $PRIVATEID

exit 0
