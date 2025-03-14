#!/usr/bin/env sh

CLUSTER_NAME="dscott-miwi-public-api"
CLUSTER_OUTBOUND_TYPE="UserDefinedRouting"
VISIBILITY="Public"

. ./env

ACCESS_TOKEN=$(az account get-access-token --query "accessToken" -o tsv)

curl -X PUT "https://localhost:8443/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.RedHatOpenShift/openShiftClusters/${CLUSTER_NAME}?api-version=${ARO_API_VERSION}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -k \
    --data @- <<EOF
{
  "location": "${LOCATION}",
  "properties": {
    "clusterProfile": {
      "domain": "${DOMAIN}",
      "resourceGroupId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${MANAGED_RESOURCE_GROUP}",
      "version": "${OPENSHIFT_VERSION}",
      "fipsValidatedModules": "Disabled"
    },
    "networkProfile": {
      "podCidr": "10.128.0.0/14",
      "serviceCidr": "172.30.0.0/16",
      "outboundType": "${CLUSTER_OUTBOUND_TYPE}",
      "preconfiguredNSG": "Disabled"
    },
    "masterProfile": {
      "vmSize": "Standard_D8s_v3",
      "subnetId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${NETWORK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${VNET}/subnets/${CONTROL_PLANE_SUBNET}",
      "encryptionAtHost": "Disabled"
    },
    "workerProfiles": [{
      "name": "worker",
      "count": 3,
      "diskSizeGB": 128,
      "vmSize": "Standard_D2s_v3",
      "subnetId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${NETWORK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${VNET}/subnets/${MACHINE_SUBNET}",
      "encryptionAtHost": "Disabled"
    }],
    "apiserverProfile": {
      "visibility": "${VISIBILITY}"
    },
    "ingressProfiles": [{
      "name": "default",
      "visibility": "${VISIBILITY}"
    }],
    "platformWorkloadIdentityProfile": {
      "platformWorkloadIdentities": {
        "cloud-controller-manager": { "resourceId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${CLOUD_CONTROLLER_MANAGER_IDENTITY}" },
        "ingress": { "resourceId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${INGRESS_IDENTITY}" },
        "machine-api": { "resourceId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${MACHINE_API_IDENTITY}" },
        "disk-csi-driver": { "resourceId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${DISK_CSI_DRIVER_IDENTITY}" },
        "cloud-network-config": { "resourceId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${CLOUD_NETWORK_CONFIG_IDENTITY}" },
        "image-registry": { "resourceId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${IMAGE_REGISTRY_IDENTITY}" },
        "file-csi-driver": { "resourceId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${FILE_CSI_DRIVER_IDENTITY}" },
        "aro-operator": { "resourceId": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${ARO_OPERATOR_IDENTITY}" }
      }
    }
  },
  "identity": {
    "type": "UserAssigned",
    "userAssignedIdentities": {
      "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CLUSTER_RESOURCE_GROUP}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${CLUSTER_IDENTITY}": {}
    }
  }
}
EOF
