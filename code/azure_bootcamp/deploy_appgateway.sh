RGNAME="myAGgroup"
TEMPLATE="./arm/appgateway-template.json"
PARAMS="./arm/appgateway-paramaters.json"
az deployment group create --resource-group $RGNAME \
    --template-file $TEMPLATE  \
    --parameters $PARAMS

