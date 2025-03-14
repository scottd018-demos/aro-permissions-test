#!/usr/bin/env sh

set -e

ACTION="${ACTION:-create}"

export VNET_RESOURCE_GROUP='dscott-v4-eastus'
export SERVICE_PRINCIPAL_NAME='dscott-sp'

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

# create the service principal
SP_OUTPUT="{}"
if [[ "$ACTION" == "create" ]]; then
    SP_OUTPUT=$(az ad sp create-for-rbac --name "$SERVICE_PRINCIPAL_NAME" --query "{client_id:appId, client_secret:password}" --output json)
else
    SP_OUTPUT="$(az ad sp list --display-name "$SERVICE_PRINCIPAL_NAME" --query "{client_id:[0].appId, client_secret:[0].password}" --output json)"
fi

# extract the client ID and client secret
CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r .client_id)
CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r .client_secret)
echo "client id: $CLIENT_ID"
echo "client secret: $CLIENT_SECRET"

# allow cluster sp permissions over vnet
VNET_ID="$(az network vnet show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_VNET} --query 'id' --output tsv)"
echo "vnet [${VNET_ID}](${ARO_VNET})..."
VNET_ROLE_ID="$(az role definition list --name ${ARO_VNET_ROLE} --query '[].id' -o tsv)"
if [[ "$ACTION" == "create" ]]; then
    echo "assigning role id [${VNET_ROLE_ID}](${ARO_VNET_ROLE}) to identity [${CLIENT_ID}](${SERVICE_PRINCIPAL_NAME})...]"

    az role assignment create \
        --assignee "${CLIENT_ID}" \
        --role "${VNET_ROLE_ID}" \
        --scope "${VNET_ID}"
elif [[ "$ACTION" == "delete" ]]; then
    ASSIGNMENT_IDS=""
    for ASSIGNMENT_ID in "$(az role assignment list --scope "$VNET_ID" --assignee ${CLIENT_ID} --query "[].id" -o tsv)"; do
        if [[ "${ASSIGNMENT_ID}" != "" ]]; then
            echo "removing role definition [${VNET_ROLE_ID}](${ARO_VNET_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
            ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
        fi
    done
    
    if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
        az role assignment delete --ids $ASSIGNMENT_IDS
    fi
fi

# allow subnet identities permissions over subnets
SUBNET_ROLE_ID="$(az role definition list --name ${ARO_SUBNET_ROLE} --query '[].id' -o tsv)"
echo "subnets [${ARO_SUBNETS}](VNET: ${ARO_VNET})..."
if [[ "$ACTION" == "create" ]]; then
    for SUBNET in $ARO_SUBNETS; do
        SUBNET_ID="$(az network vnet subnet list --resource-group ${VNET_RESOURCE_GROUP} --vnet-name ${ARO_VNET} --query "[?name=='$SUBNET'].id" --output tsv)"

        echo "assigning role id [${SUBNET_ROLE_ID}](${ARO_SUBNET_ROLE}) to identity [${CLIENT_ID}](${SERVICE_PRINCIPAL_NAME})...]"

        az role assignment create \
            --assignee "${CLIENT_ID}" \
            --role "${SUBNET_ROLE_ID}" \
            --scope "${SUBNET_ID}"
    done
elif [[ "$ACTION" == "delete" ]]; then
    ASSIGNMENT_IDS=""
    for SUBNET in $ARO_SUBNETS; do
        SUBNET_ID="$(az network vnet subnet list --resource-group ${VNET_RESOURCE_GROUP} --vnet-name ${ARO_VNET} --query "[?name=='$SUBNET'].id" --output tsv)"
        ASSIGNMENT_ID="$(az role assignment list --scope "$SUBNET_ID" --assignee ${CLIENT_ID} --query "[].id" -o tsv)"
        if [[ "${ASSIGNMENT_ID}" != "" ]]; then
            echo "removing role definition [${SUBNET_ROLE_ID}](${ARO_SUBNET_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
            ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
        fi
    done

    if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
        az role assignment delete --ids $ASSIGNMENT_IDS
    fi
fi

# allow cluster sp permissions over route table
RT_ID="$(az network route-table show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_RT} --query 'id' --output tsv)"
echo "route table [${RT_ID}](${ARO_RT})..."
RT_ROLE_ID="$(az role definition list --name ${ARO_RT_ROLE} --query '[].id' -o tsv)"
if [[ "$ACTION" == "create" ]]; then
    echo "assigning role id [${RT_ROLE_ID}](${ARO_RT_ROLE}) to identity [${CLIENT_ID}](${SERVICE_PRINCIPAL_NAME})...]"

    az role assignment create \
        --assignee "${CLIENT_ID}" \
        --role "${RT_ROLE_ID}" \
        --scope "${RT_ID}"
elif [[ "$ACTION" == "delete" ]]; then
    ASSIGNMENT_IDS=""
    for ASSIGNMENT_ID in $(az role assignment list --scope "$RT_ID" --assignee ${CLIENT_ID} --query "[].id" -o tsv); do
        if [[ "${ASSIGNMENT_ID}" != "" ]]; then
            echo "removing role definition [${RT_ROLE_ID}](${ARO_RT_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
            ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
        fi
    done

    if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
        az role assignment delete --ids $ASSIGNMENT_IDS
    fi
fi

# allow cluster sp permissions over nat gateway
NATGW_ID="$(az network nat gateway show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_NATGW} --query 'id' --output tsv)"
echo "nat gateway [${NATGW_ID}](${ARO_NATGW})..."
NATGW_ROLE_ID="$(az role definition list --name ${ARO_NATGW_ROLE} --query '[].id' -o tsv)"
if [[ "$ACTION" == "create" ]]; then
    echo "assigning role id [${NATGW_ROLE_ID}](${ARO_NATGW_ROLE}) to identity [${CLIENT_ID}](${SERVICE_PRINCIPAL_NAME})...]"

    az role assignment create \
        --assignee "${CLIENT_ID}" \
        --role "${NATGW_ROLE_ID}" \
        --scope "${NATGW_ID}"
elif [[ "$ACTION" == "delete" ]]; then
    ASSIGNMENT_IDS=""
    for ASSIGNMENT_ID in $(az role assignment list --scope "$NATGW_ID" --assignee ${CLIENT_ID} --query "[].id" -o tsv); do
        if [[ "${ASSIGNMENT_ID}" != "" ]]; then
            echo "removing role definition [${NATGW_ROLE_ID}](${ARO_NATGW_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
            ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
        fi
    done

    if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
        az role assignment delete --ids $ASSIGNMENT_IDS
    fi
fi

# allow cluster sp permissions over network security group
NSG_ID="$(az network nsg show --resource-group ${VNET_RESOURCE_GROUP} --name ${ARO_NSG} --query 'id' --output tsv)"
echo "network security group [${NSG_ID}](${ARO_NSG})..."
NSG_ROLE_ID="$(az role definition list --name ${ARO_NSG_ROLE} --query '[].id' -o tsv)"
if [[ "$ACTION" == "create" ]]; then
    echo "assigning role id [${NSG_ROLE_ID}](${ARO_NSG_ROLE}) to identity [${CLIENT_ID}](${SERVICE_PRINCIPAL_NAME})...]"

    az role assignment create \
        --assignee "${CLIENT_ID}" \
        --role "${NSG_ROLE_ID}" \
        --scope "${NSG_ID}"
elif [[ "$ACTION" == "delete" ]]; then
    ASSIGNMENT_IDS=""
    for ASSIGNMENT_ID in $(az role assignment list --scope "$NSG_ID" --assignee ${CLIENT_ID} --query "[].id" -o tsv); do
        if [[ "${ASSIGNMENT_ID}" != "" ]]; then
            echo "removing role definition [${NSG_ROLE_ID}](${ARO_NSG_ROLE}) with assignment id [$ASSIGNMENT_ID]...]"
            ASSIGNMENT_IDS+="${ASSIGNMENT_ID} "
        fi
    done

    if [[ "${ASSIGNMENT_IDS}" != "" ]]; then
        az role assignment delete --ids $ASSIGNMENT_IDS
    fi
fi
