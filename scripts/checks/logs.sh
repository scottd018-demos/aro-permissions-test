#!/usr/bin/env sh

for ns in openshift-cloud-controller-manager openshift-cloud-controller-manager-operator openshift-cluster-csi-drivers openshift-machine-api openshift-machine-config-operator openshift-ingress openshift-ingress-operator openshift-ingress-canary openshift-azure-operator openshift-azure-logging openshift-cloud-credential-operator openshift-host-network; do 
  for pod in `oc get pods -n $ns -o jsonpath='{.items[*].metadata.name}'`; do 
    for ctr in `oc get pods -n $ns $pod -o jsonpath='{.spec.containers[*].name}'`; do
        echo "checking relevant log messages for container [$ns/$pod/$ctr]..."
        echo "===================="
        oc -n $ns logs $pod -c $ctr | egrep -i "(subnets|virtualNetworks|routeTables|natGateways|networkSecurityGroups|error|401|403)" | egrep -v "(no upstream connections|please apply your changes to the latest version and try again)"
        echo
    done
  done
done