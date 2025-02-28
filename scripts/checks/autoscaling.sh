#!/usr/bin/env sh

# see https://github.com/rhpds/bookbag-aro-mobb/blob/main/workshop/content/200-ops/day2/3-autoscaling.adoc

MACHINESET=$(oc -n openshift-machine-api get machinesets -o name \
   | cut -d / -f2 | head -1)

cat <<EOF | oc apply -f -
---
apiVersion: "autoscaling.openshift.io/v1beta1"
kind: "MachineAutoscaler"
metadata:
  name: "${MACHINESET}"
  namespace: "openshift-machine-api"
spec:
  minReplicas: 1
  maxReplicas: 3
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: "${MACHINESET}"
EOF

cat <<EOF | oc apply -f -
---
apiVersion: "autoscaling.openshift.io/v1"
kind: "ClusterAutoscaler"
metadata:
  name: default
spec:
  podPriorityThreshold: -10
  resourceLimits:
    maxNodesTotal: 10
    cores:
      min: 8
      max: 128
    memory:
      min: 4
      max: 256
  scaleDown:
    enabled: true
    delayAfterAdd: 2m
    delayAfterDelete: 1m
    delayAfterFailure: 15s
    unneededTime: 1m
EOF

oc new-project autoscale-ex

cat << EOF | oc create -f -
---
apiVersion: batch/v1
kind: Job
metadata:
  generateName: maxscale
  namespace: autoscale-ex
spec:
  template:
    spec:
      containers:
      - name: work
        image: busybox
        command: ["sleep",  "300"]
        resources:
          requests:
            memory: 500Mi
            cpu: 500m
      restartPolicy: Never
  backoffLimit: 4
  completions: 50
  parallelism: 50
EOF

watch oc get nodes,pods -n autoscale-ex
