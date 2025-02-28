#!/usr/bin/env sh

set -e

export IDENTITY_RESOURCE_GROUP='dscott-v4-eastus'
export VNET_RESOURCE_GROUP='dscott-v4-eastus'

export ARO_VNET='dscott-aro-vnet-eastus'
export ARO_RT='dscott-rt'
export ARO_NATGW='dscott-natgw'
export ARO_NSG='dscott-nsg'

export ARO_VNET_ROLE='dscott-aro-vnet'
export ARO_RT_ROLE='dscott-aro-rt'
export ARO_NATGW_ROLE='dscott-aro-natgw'
export ARO_NSG_ROLE='dscott-aro-nsg'
export ARO_CREDENTIAL_ROLE='Azure Red Hat OpenShift Federated Credential'

# az role definition list --name "Azure Red Hat OpenShift Service Operator" | jq -r '.[].permissions[].actions'
VNET_IDENTITIES='aro-cloud-controller-manager aro-ingress aro-file-csi-driver aro-machine-api aro-cloud-network-config aro-aro-operator'
NSG_IDENTITIES='aro-cloud-controller-manager aro-file-csi-driver aro-machine-api aro-aro-operator'
RT_IDENTITIES='aro-machine-api aro-aro-operator'
NATGW_IDENTITIES='aro-aro-operator'
CREDENTIAL_IDENTITIES='aro-Cluster'

# allow vnet identities permissions over vnet
VNET_ID="$(az network vnet show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_VNET} --query 'id' --output tsv)"
echo "vnet [${VNET_ID}](${ARO_VNET})..."
for IDENTITY in $VNET_IDENTITIES; do
    ROLE_ID="$(az role definition list --name ${ARO_VNET_ROLE} --query '[].id' -o tsv)"
    IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

    echo "assigning role id [${ROLE_ID}](${ARO_VNET_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

    az role assignment create \
        --assignee-object-id "${IDENTITY_ID}" \
        --role "${ROLE_ID}" \
        --scope "${VNET_ID}"
done

# allow route table identities permissions over route table
RT_ID="$(az network route-table show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_RT} --query 'id' --output tsv)"
echo "route table [${RT_ID}](${ARO_RT})..."
for IDENTITY in $RT_IDENTITIES; do
    ROLE_ID="$(az role definition list --name ${ARO_RT_ROLE} --query '[].id' -o tsv)"
    IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

    echo "assigning role id [${ROLE_ID}](${ARO_RT_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

    az role assignment create \
        --assignee-object-id "${IDENTITY_ID}" \
        --role "${ROLE_ID}" \
        --scope "${RT_ID}"
done

# allow nat gateway identities permissions over nat gateway
NATGW_ID="$(az network nat gateway show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_NATGW} --query 'id' --output tsv)"
echo "nat gateway [${NATGW_ID}](${ARO_NATGW})..."
for IDENTITY in $NATGW_IDENTITIES; do
    ROLE_ID="$(az role definition list --name ${ARO_NATGW_ROLE} --query '[].id' -o tsv)"
    IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

    echo "assigning role id [${ROLE_ID}](${ARO_NATGW_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

    az role assignment create \
        --assignee-object-id "${IDENTITY_ID}" \
        --role "${ROLE_ID}" \
        --scope "${NATGW_ID}"
done

# allow network security group identities permissions over network security group
NSG_ID="$(az network nsg show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_NSG} --query 'id' --output tsv)"
echo "network security group [${NSG_ID}](${ARO_NSG})..."
for IDENTITY in $NSG_IDENTITIES; do
    ROLE_ID="$(az role definition list --name ${ARO_NSG_ROLE} --query '[].id' -o tsv)"
    IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

    echo "assigning role id [${ROLE_ID}](${ARO_NSG_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

    az role assignment create \
        --assignee-object-id "${IDENTITY_ID}" \
        --role "${ROLE_ID}" \
        --scope "${NSG_ID}"
done

# allow cluster identities permissions over federated credentials
RESOURCE_GROUP_ID="$(az group show --name ${IDENTITY_RESOURCE_GROUP} --query 'id' --output tsv)"
echo "resource group [${RESOURCE_GROUP_ID}](${IDENTITY_RESOURCE_GROUP})..."
for IDENTITY in $CREDENTIAL_IDENTITIES; do
    ROLE_ID=`az role definition list --name "${ARO_CREDENTIAL_ROLE}" --query '[].id' -o tsv`
    IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

    echo "assigning role id [${ROLE_ID}](${ARO_CREDENTIAL_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

    az role assignment create \
        --assignee-object-id "${IDENTITY_ID}" \
        --role "${ROLE_ID}" \
        --scope "${RESOURCE_GROUP_ID}"
done
