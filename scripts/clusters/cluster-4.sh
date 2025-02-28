#!/usr/bin/env sh

CLUSTER_NAME="dscott-miwi-public-api"
CLUSTER_OUTBOUND_TYPE="UserDefinedRouting"
VISIBILITY="Public"

. ./env

# TODO: bicep
# TODO: non byo-nsg

# az aro create \
#     --subscription="${SUBSCRIPTION_ID}" \
#     --resource-group="${CLUSTER_RESOURCE_GROUP}" \
#     --cluster-resource-group="${MANAGED_RESOURCE_GROUP}" \
#     --vnet-resource-group="${NETWORK_RESOURCE_GROUP}" \
#     --name="${CLUSTER_NAME}" \
#     --version="${OPENSHIFT_VERSION}" \
#     --worker-count=3 \
#     --vnet="${VNET}" \
#     --master-subnet="${CONTROL_PLANE_SUBNET}" \
#     --worker-subnet="${MACHINE_SUBNET}" \
#     --pull-secret "${OPENSHIFT_PULL_SECRET}" \
#     --apiserver-visibility "${VISIBILITY}" \
#     --ingress-visibility "${VISIBILITY}" \
#     --outbound-type="${CLUSTER_OUTBOUND_TYPE}" \
#     ${MANAGED_IDENTITY_FLAGS}
