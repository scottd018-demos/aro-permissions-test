#!/usr/bin/env sh

set -e

ACTION="${ACTION:-create}"

export IDENTITY_RESOURCE_GROUP='dscott-v4-eastus'
export VNET_RESOURCE_GROUP='dscott-v4-eastus'

export ARO_VNET='dscott-aro-vnet-eastus'
export ARO_SUBNETS='dscott-aro-machine-subnet-eastus dscott-aro-control-subnet-eastus dscott-aro-control-subnet-nonudr dscott-aro-machine-subnet-nonudr'
export ARO_RT='dscott-rt'
export ARO_NATGW='dscott-natgw'
export ARO_NSG='dscott-nsg'

export ARO_VNET_ROLE='dscott-ideal-aro-vnet'
export ARO_SUBNET_ROLE='dscott-ideal-aro-subnet'
export ARO_RT_ROLE='dscott-ideal-aro-rt'
export ARO_NATGW_ROLE='dscott-ideal-aro-natgw'
export ARO_NSG_ROLE='dscott-ideal-aro-nsg'
export ARO_CREDENTIAL_ROLE='Azure Red Hat OpenShift Federated Credential'

# az role definition list --name "Azure Red Hat OpenShift Service Operator" | jq -r '.[].permissions[].actions'
VNET_IDENTITIES='aro-machine-api aro-cloud-network-config'
SUBNET_IDENTITIES='aro-cloud-controller-manager aro-ingress aro-file-csi-driver aro-machine-api aro-cloud-network-config aro-aro-operator'
NSG_IDENTITIES='aro-cloud-controller-manager aro-file-csi-driver aro-machine-api aro-aro-operator'
RT_IDENTITIES='aro-machine-api aro-aro-operator aro-file-csi-driver'
NATGW_IDENTITIES='aro-aro-operator aro-file-csi-driver'
CREDENTIAL_IDENTITIES='aro-Cluster'

# allow vnet identities permissions over vnet
VNET_ID="$(az network vnet show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_VNET} --query 'id' --output tsv)"
VNET_ROLE_ID="$(az role definition list --name ${ARO_VNET_ROLE} --query '[].id' -o tsv)"
echo "vnet [${VNET_ID}](${ARO_VNET})..."
for IDENTITY in $VNET_IDENTITIES; do
    if [[ "$ACTION" == "create" ]]; then
        IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

        echo "assigning role id [${VNET_ROLE_ID}](${ARO_VNET_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

        az role assignment create \
            --assignee-object-id "${IDENTITY_ID}" \
            --role "${VNET_ROLE_ID}" \
            --scope "${VNET_ID}"
    elif [[ "$ACTION" == "delete" ]]; then
        ASSIGNMENT_IDS=""
        for ASSIGNMENT_ID in "$(az role assignment list --scope "$VNET_ID" --query "[].id" -o tsv)"; do
            if [[ "${ASSIGNMENT_ID}" != "" ]]; then
                echo "removing role definition [${VNET_ROLE_ID}](${ARO_VNET_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
                ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
            fi
        done
        
        if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
            az role assignment delete --ids $ASSIGNMENT_IDS
        fi
    fi
done

# allow subnet identities permissions over subnets
SUBNET_ROLE_ID="$(az role definition list --name ${ARO_SUBNET_ROLE} --query '[].id' -o tsv)"
echo "subnets [${ARO_SUBNETS}](VNET: ${ARO_VNET})..."
for IDENTITY in $SUBNET_IDENTITIES; do
    if [[ "$ACTION" == "create" ]]; then
        IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

        for SUBNET in $ARO_SUBNETS; do
            SUBNET_ID="$(az network vnet subnet list --resource-group ${VNET_RESOURCE_GROUP} --vnet-name ${ARO_VNET} --query "[?name=='$SUBNET'].id" --output tsv)"

            echo "assigning role id [${SUBNET_ROLE_ID}](${ARO_SUBNET_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

            az role assignment create \
                --assignee-object-id "${IDENTITY_ID}" \
                --role "${SUBNET_ROLE_ID}" \
                --scope "${SUBNET_ID}"
        done
    elif [[ "$ACTION" == "delete" ]]; then
        ASSIGNMENT_IDS=""
        for SUBNET in $ARO_SUBNETS; do
            SUBNET_ID="$(az network vnet subnet list --resource-group ${VNET_RESOURCE_GROUP} --vnet-name ${ARO_VNET} --query "[?name=='$SUBNET'].id" --output tsv)"
            ASSIGNMENT_ID="$(az role assignment list --scope "$SUBNET_ID" --query "[].id" -o tsv)"
            if [[ "${ASSIGNMENT_ID}" != "" ]]; then
                echo "removing role definition [${SUBNET_ROLE_ID}](${ARO_SUBNET_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
                ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
            fi
        done

        if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
            az role assignment delete --ids $ASSIGNMENT_IDS
        fi
    fi
done

# allow route table identities permissions over route table
RT_ID="$(az network route-table show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_RT} --query 'id' --output tsv)"
RT_ROLE_ID="$(az role definition list --name ${ARO_RT_ROLE} --query '[].id' -o tsv)"
echo "route table [${RT_ID}](${ARO_RT})..."
for IDENTITY in $RT_IDENTITIES; do
    if [[ "$ACTION" == "create" ]]; then
        IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

        echo "assigning role id [${RT_ROLE_ID}](${ARO_RT_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

        az role assignment create \
            --assignee-object-id "${IDENTITY_ID}" \
            --role "${RT_ROLE_ID}" \
            --scope "${RT_ID}"
    elif [[ "$ACTION" == "delete" ]]; then
        ASSIGNMENT_IDS=""
        for ASSIGNMENT_ID in $(az role assignment list --scope "$RT_ID" --query "[].id" -o tsv); do
            if [[ "${ASSIGNMENT_ID}" != "" ]]; then
                echo "removing role definition [${RT_ROLE_ID}](${ARO_RT_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
                ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
            fi
        done

        if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
            az role assignment delete --ids $ASSIGNMENT_IDS
        fi
    fi
done

# allow nat gateway identities permissions over nat gateway
NATGW_ID="$(az network nat gateway show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_NATGW} --query 'id' --output tsv)"
NATGW_ROLE_ID="$(az role definition list --name ${ARO_NATGW_ROLE} --query '[].id' -o tsv)"
echo "nat gateway [${NATGW_ID}](${ARO_NATGW})..."
for IDENTITY in $NATGW_IDENTITIES; do
    if [[ "$ACTION" == "create" ]]; then
        IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

        echo "assigning role id [${NATGW_ROLE_ID}](${ARO_NATGW_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

        az role assignment create \
            --assignee-object-id "${IDENTITY_ID}" \
            --role "${NATGW_ROLE_ID}" \
            --scope "${NATGW_ID}"
    elif [[ "$ACTION" == "delete" ]]; then
        ASSIGNMENT_IDS=""
        for ASSIGNMENT_ID in $(az role assignment list --scope "$NATGW_ID" --query "[].id" -o tsv); do
            if [[ "${ASSIGNMENT_ID}" != "" ]]; then
                echo "removing role definition [${NATGW_ROLE_ID}](${ARO_NATGW_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
                ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
            fi
        done

        if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
            az role assignment delete --ids $ASSIGNMENT_IDS
        fi
    fi
done

# allow network security group identities permissions over network security group
NSG_ID="$(az network nsg show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_NSG} --query 'id' --output tsv)"
NSG_ROLE_ID="$(az role definition list --name ${ARO_NSG_ROLE} --query '[].id' -o tsv)"
echo "network security group [${NSG_ID}](${ARO_NSG})..."
for IDENTITY in $NSG_IDENTITIES; do
    if [[ "$ACTION" == "create" ]]; then
        IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

        echo "assigning role id [${NSG_ROLE_ID}](${ARO_NSG_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

        az role assignment create \
            --assignee-object-id "${IDENTITY_ID}" \
            --role "${NSG_ROLE_ID}" \
            --scope "${NSG_ID}"
    elif [[ "$ACTION" == "delete" ]]; then
        ASSIGNMENT_IDS=""
        for ASSIGNMENT_ID in $(az role assignment list --scope "$NSG_ID" --query "[].id" -o tsv); do
            if [[ "${ASSIGNMENT_ID}" != "" ]]; then
                echo "removing role definition [${NSG_ROLE_ID}](${ARO_NSG_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
                ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
            fi
        done

        if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
            az role assignment delete --ids $ASSIGNMENT_IDS
        fi
    fi
done

# allow cluster identities permissions over federated credentials
RESOURCE_GROUP_ID="$(az group show --name ${IDENTITY_RESOURCE_GROUP} --query 'id' --output tsv)"
CREDENTIAL_ROLE_ID=`az role definition list --name "${ARO_CREDENTIAL_ROLE}" --query '[].id' -o tsv`
echo "resource group [${RESOURCE_GROUP_ID}](${IDENTITY_RESOURCE_GROUP})..."
for IDENTITY in $CREDENTIAL_IDENTITIES; do
    if [[ "$ACTION" == "create" ]]; then
        IDENTITY_ID="$(az identity show --resource-group ${IDENTITY_RESOURCE_GROUP} --name $IDENTITY --query principalId -o tsv)"

        echo "assigning role id [${CREDENTIAL_ROLE_ID}](${ARO_CREDENTIAL_ROLE}) to identity [${IDENTITY_ID}](${IDENTITY})...]"

        az role assignment create \
            --assignee-object-id "${IDENTITY_ID}" \
            --role "${CREDENTIAL_ROLE_ID}" \
            --scope "${RESOURCE_GROUP_ID}"
    elif [[ "$ACTION" == "delete" ]]; then
        ASSIGNMENT_IDS=""
        for ASSIGNMENT_ID in $(az role assignment list --scope "$RESOURCE_GROUP_ID" --query "[].id" -o tsv); do
            if [[ "${ASSIGNMENT_ID}" != "" ]]; then
                echo "removing role definition [${CREDENTIAL_ROLE_ID}](${ARO_CREDENTIAL_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
                ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
            fi
        done

        if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
            az role assignment delete --ids $ASSIGNMENT_IDS
        fi
    fi
done
