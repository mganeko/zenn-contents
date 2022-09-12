RGNAME="myAGgroup"
APPGATEWAY="myAppGateway"
POOL="myBackendPool"

# -- remove old app (1st address) --
az network application-gateway address-pool update -g $RGNAME \
  --gateway-name $APPGATEWAY -n $POOL \
  --remove backendAddresses 0
