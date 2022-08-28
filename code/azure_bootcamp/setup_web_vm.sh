#!/bin/sh
#
# setup_web_vm.sh
#
# usege:
#   sh setup_web_vm.sh resorucegoupname vmname

# -- param --
if [ $# -ne 2 ]; then
  echo "ERROR: Please specify ResourceGroupName and VMName (2 args)."
  exit 1
fi

RGNAME=$1
VMNAME=$2
IPNAME=""
NSG=""

echo "ResourceGroup Name=" $RGNAME
echo "VM Name=" $VMNAME
echo ""

# -- get PubliIP name --
IPNAME=$(az network public-ip list -g $RGNAME --query "[?ipConfiguration == null].{name: name}" --output tsv)

if [ -n "$IPNAME" ]; then
  echo "PublicIP found:" $IPNAME
else
  echo "ERROR: Available PublicIP NOT FOUND."
  exit 2
fi

# -- get NSG name --
NSG=$(az network nsg list --resource-group $RGNAME --query "[].{name: name}" --output tsv)

if [ -n "$NSG" ]; then
  echo "Network Security Group found:" $NSG
else
  echo "ERROR: Available Network Security Group NOT FOUND."
  exit 2
fi

#echo "ResourceGroup Name=" $RGNAME
#echo "VM Name=" $VMNAME
#echo "PublicIP Name=" $IPNAME
#echo "Network Security Group=" $NSG
echo ""

# -- create VM ---
echo "-- creating VM name=" $VMNAME " --"
az vm create \
  --resource-group $RGNAME \
  --name $VMNAME \
  --image Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest \
  --size Standard_B1ls \
  --public-ip-address $IPNAME \
  --public-ip-sku Standard \
  --nsg $NSG \
  --storage-sku StandardSSD_LRS \
  --nic-delete-option Delete \
  --os-disk-delete-option Delete \
  --admin-username azureuser \
  --generate-ssh-keys

echo "create VM result:" $?
echo ""


# -- update VM --
echo "-- update VM name=" $VMNAME " --"
az vm run-command invoke \
  --resource-group $RGNAME \
  --name $VMNAME \
  --command-id RunShellScript \
  --scripts "sudo apt update && sudo apt upgrade -y"
echo "update VM result:" $?
echo ""

# -- install nginx --
echo "-- install Nginx --"
az vm run-command invoke \
  --resource-group $RGNAME \
  --name $VMNAME \
  --command-id RunShellScript \
  --scripts "sudo apt-get install -y nginx"
echo "install nginx result:" $?
echo ""

# -- access check --
IPADDR=$(az network public-ip show --resource-group $RGNAME --name $IPNAME --query  ipAddress -o tsv)
echo "IP address=" $IPADDR
echo "-- access test: curl http://$IPADDR --"
curl http://$IPADDR
echo "curl result:" $?
echo ""


# -- finish --
echo "==== setup VM:" $VMNAME " and Web(nginx) DONE ===="
echo ""

exit 0
