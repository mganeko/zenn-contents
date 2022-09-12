#!/bin/sh
#
# create_network.sh
#
# usage:
#   sh create_network.sh resorucegoupname

# --- check args ---
if [ $# -ne 1 ]; then
  echo "ERROR: Please specify resouce-group-name (1 arg)." 1>&2
  exit 1
fi
RESOUCEGROUP=$1

VNET="myVNet"
VNETRANGE="10.1.0.0/16"
SUBNET1="myAGSubnet"
SUBNET1RANGE="10.1.0.0/24"
SUBNET2="myBackendSubnet"
SUBNET2RANGE="10.1.1.0/24"
PUBLICIPNAME="myAGPublicIPAddress"


# --- create VNet and gateway subnet ---
az network vnet create \
  --name $VNET \
  --resource-group $RESOUCEGROUP \
  --location japaneast \
  --address-prefix $VNETRANGE \
  --subnet-name $SUBNET1 \
  --subnet-prefix $SUBNET1RANGE
echo "-- VNET created --"

# --- create backend subnet ---
az network vnet subnet create \
  --name $SUBNET2 \
  --resource-group $RESOUCEGROUP \
  --vnet-name $VNET   \
  --address-prefix $SUBNET2RANGE
echo "-- backend subnet created --"

# --- create public IP address ---
az network public-ip create \
  --resource-group $RESOUCEGROUP \
  --name $PUBLICIPNAME \
  --allocation-method Static \
  --sku Standard

PUBLICIPADDR=$(az network public-ip list -g myAGgroup --query "[?name == '$PUBLICIPNAME'].{ip: ipAddress}" -o tsv)
echo "-- PublicIP created. address=" $PUBLICIPADDR " --"

exit 0

