#!/usr/bin/env sh

CLUSTER_NAME="dscott-miwi-private-cli"
CLUSTER_OUTBOUND_TYPE="UserDefinedRouting"
VISIBILITY="Private"

. ./env

az aro create \
    --subscription="${SUBSCRIPTION_ID}" \
    --resource-group="${CLUSTER_RESOURCE_GROUP}" \
    --cluster-resource-group="${MANAGED_RESOURCE_GROUP}" \
    --vnet-resource-group="${NETWORK_RESOURCE_GROUP}" \
    --name="${CLUSTER_NAME}" \
    --version="${OPENSHIFT_VERSION}" \
    --worker-count=3 \
    --vnet="${VNET}" \
    --master-subnet="${CONTROL_PLANE_SUBNET}" \
    --worker-subnet="${MACHINE_SUBNET}" \
    --pull-secret "${OPENSHIFT_PULL_SECRET}" \
    --apiserver-visibility "${VISIBILITY}" \
    --ingress-visibility "${VISIBILITY}" \
    --enable-preconfigured-nsg \
    --outbound-type="${CLUSTER_OUTBOUND_TYPE}" \
    ${MANAGED_IDENTITY_FLAGS}
