#!/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU
# https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html

NODE_NAME=$(hostname)

# Create config map
cat <<EOF | kubectl create -n gpu-operator -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: time-slicing-config-all
data:
  any: |-
    version: v1
    flags:
      migStrategy: none
    sharing:
      timeSlicing:
        resources:
        - name: nvidia.com/gpu
          replicas: 4
EOF

# Configure the cluster policy, set the default time-slicing configuration
kubectl patch clusterpolicies.nvidia.com/cluster-policy \
    -n gpu-operator --type merge \
    -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config-all", "default": "any"}}}}'

# Apply labels
kubectl label node ${NODE_NAME} nvidia.com/gpu.count=1
kubectl label node ${NODE_NAME} nvidia.com/gpu.replicas=4

# Confirm that nvidia-device-plugin-daemonset pod gets restarted
#kubectl get pods -n gpu-operator -l app=nvidia-device-plugin-daemonset
# Confirm that GPU capacity gets updated
#kubectl get nodes -o jsonpath='node: {.items[].metadata.name}, nvidia.com/gpu capacity: {.items[].status.capacity.nvidia\.com/gpu}'