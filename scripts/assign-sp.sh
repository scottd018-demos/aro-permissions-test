#!/usr/bin/env sh

set -e

export VNET_RESOURCE_GROUP='dscott-v4-eastus'
export SERVICE_PRINCIPAL_NAME='dscott-sp'

export ARO_VNET='dscott-aro-vnet-eastus'
export ARO_RT='dscott-rt'
export ARO_NATGW='dscott-natgw'
export ARO_NSG='dscott-nsg'

export ARO_VNET_ROLE='dscott-aro-vnet'
export ARO_RT_ROLE='dscott-aro-rt'
export ARO_NATGW_ROLE='dscott-aro-natgw'
export ARO_NSG_ROLE='dscott-aro-nsg'

# create the service principal
SP_OUTPUT=$(az ad sp create-for-rbac --name "$SERVICE_PRINCIPAL_NAME" --query "{client_id:appId, client_secret:password}" --output json)

# extract the client ID and client secret
CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r .client_id)
CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r .client_secret)
echo "client id: $CLIENT_ID"
echo "client secret: $CLIENT_SECRET"

# allow cluster sp permissions over vnet
VNET_ID="$(az network vnet show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_VNET} --query 'id' --output tsv)"
echo "vnet [${VNET_ID}](${ARO_VNET})..."
ROLE_ID="$(az role definition list --name ${ARO_VNET_ROLE} --query '[].id' -o tsv)"

echo "assigning role id [${ROLE_ID}](${ARO_VNET_ROLE}) to service principal [${CLIENT_ID}](${SERVICE_PRINCIPAL_NAME})...]"

az role assignment create \
    --assignee "${CLIENT_ID}" \
    --role "${ROLE_ID}" \
    --scope "${VNET_ID}"


# allow cluster sp permissions over route table
RT_ID="$(az network route-table show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_RT} --query 'id' --output tsv)"
echo "route table [${RT_ID}](${ARO_RT})..."
ROLE_ID="$(az role definition list --name ${ARO_RT_ROLE} --query '[].id' -o tsv)"

echo "assigning role id [${ROLE_ID}](${ARO_RT_ROLE}) to service principal [${CLIENT_ID}](${SERVICE_PRINCIPAL_NAME})...]"

az role assignment create \
    --assignee "${CLIENT_ID}" \
    --role "${ROLE_ID}" \
    --scope "${RT_ID}"


# allow cluster sp permissions over nat gateway
NATGW_ID="$(az network nat gateway show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_NATGW} --query 'id' --output tsv)"
echo "nat gateway [${NATGW_ID}](${ARO_NATGW})..."
ROLE_ID="$(az role definition list --name ${ARO_NATGW_ROLE} --query '[].id' -o tsv)"

echo "assigning role id [${ROLE_ID}](${ARO_NATGW_ROLE}) to service principal [${CLIENT_ID}](${SERVICE_PRINCIPAL_NAME})...]"

az role assignment create \
    --assignee "${CLIENT_ID}" \
    --role "${ROLE_ID}" \
    --scope "${NATGW_ID}"


# allow cluster sp permissions over network security group
NSG_ID="$(az network nsg show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_NSG} --query 'id' --output tsv)"
echo "network security group [${NSG_ID}](${ARO_NSG})..."
ROLE_ID="$(az role definition list --name ${ARO_NSG_ROLE} --query '[].id' -o tsv)"

echo "assigning role id [${ROLE_ID}](${ARO_NSG_ROLE}) to service principal [${CLIENT_ID}](${SERVICE_PRINCIPAL_NAME})...]"

az role assignment create \
    --assignee "${CLIENT_ID}" \
    --role "${ROLE_ID}" \
    --scope "${NSG_ID}"
