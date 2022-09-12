#!/bin/sh
#
# create_appgateway.sh
#
# usege:
#   sh create_appgateway.sh resorucegoupname appgateway

# --- check args ---
if [ $# -ne 2 ]; then
  echo "ERROR: Please specify resouce-group-name and application-gatway-name (2 args)." 1>&2
  exit 1
fi
RESOUCEGROUP=$1
APPGATEWAY=$2

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




# --- app gateway ---
az network application-gateway create \
  --name $APPGATEWAY \
  --location japaneast \
  --resource-group $RESOUCEGROUP \
  --capacity 1 \
  --sku Standard_v2 \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --public-ip-address $PUBLICIPNAME \
  --vnet-name $VNET \
  --subnet $SUBNET1 \
  --priority 100

# listner, bakend pool, rule が自動作成

# appGatewayBackendPool
#   rule1
#     listner ... appGatwayHttpListener
#     backendTarget ... appGatewayBackendPool
#       appGatewayBakcendHttpSettings 
# ....    backendPort 80 --> 8080 にしたい

# fontEnd
#   appGatewayFrontendIP ... myAGPublicIPAdddre
#     appGatewayHttpListener
#       port 80
#       rule .. rule1


