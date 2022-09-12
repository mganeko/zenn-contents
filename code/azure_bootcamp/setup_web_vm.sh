#!/bin/sh
#
# setup_web_vm.sh
#
# usage:
#   sh setup_web_vm.sh resorucegoupname vmname

# ============= functions ==============

# -- check args (must be 2) --
function checkArgs() {
  if [ $1 -ne 2 ]; then
    echo "ERROR: Please specify ResourceGroupName and VMName (2 args)."
    exit 1
  fi
}

# -- get PubliIP name --
function getPublicIP() {
  IPNAME=$(az network public-ip list -g $RGNAME --query "[?ipConfiguration == null].{name: name}" --output tsv)

  if [ -n "$IPNAME" ]; then
    echo "PublicIP found:" $IPNAME
  else
    echo "ERROR: Available PublicIP NOT FOUND."
    exit 2
  fi
}

# -- get NSG name --
getNetworkSecurityGroup() {
  NSG=$(az network nsg list --resource-group $RGNAME --query "[].{name: name}" --output tsv)

  if [ -n "$NSG" ]; then
    echo "Network Security Group found:" $NSG
  else
    echo "ERROR: Available Network Security Group NOT FOUND."
    exit 2
  fi
}

# -- create VM ---
function createVM() {
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
  RET=$?

  if [ $RET -ne 0 ]; then
    echo "ERROR: create VM result=" $RET
    exit $RET
  fi

  echo "create VM Success"
  echo ""
  return $RET
}

# -- update VM --
function updateVM() {
  echo "-- update VM name=" $VMNAME " --"
  az vm run-command invoke \
    --resource-group $RGNAME \
    --name $VMNAME \
    --command-id RunShellScript \
    --scripts "sudo apt update && sudo apt upgrade -y"
  echo "update VM result:" $?
  echo ""
}

# -- install nginx --
function installNginx() {
  echo "-- install Nginx --"
  az vm run-command invoke \
    --resource-group $RGNAME \
    --name $VMNAME \
    --command-id RunShellScript \
    --scripts "sudo apt-get install -y nginx"
  RET=$?

  if [ $RET -ne 0 ]; then
    echo "ERROR: install nginx result=" $RET
    exit $RET
  fi

  echo "install nginx Success"
  echo ""
  return $RET
}

# -- web access check --
function webAccessCheck() {
  IPADDR=$(az network public-ip show --resource-group $RGNAME --name $IPNAME --query  ipAddress -o tsv)
  echo "IP address=" $IPADDR
  echo "-- access test: curl http://$IPADDR --"
  curl http://$IPADDR
  RET=$?

  echo "curl result:" $RET
  echo ""

  return $RET
}

# ============= main ==============

# -- args --
ARGNUM=$#
checkArgs $ARGNUM

RGNAME=$1
VMNAME=$2
IPNAME=""
NSG=""

echo "ResourceGroup Name=" $RGNAME
echo "VM Name=" $VMNAME
echo ""

# -- get PubliIP name --
getPublicIP

# -- get NSG name --
getNetworkSecurityGroup
echo ""

# -- create VM ---
createVM

# -- update VM --
updateVM

# -- install nginx --
installNginx

# -- web access check --
webAccessCheck


# -- finish --
echo "==== setup VM:" $VMNAME " and Web(nginx) DONE ===="
echo ""

exit 0


