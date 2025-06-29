#!/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU

# Configure containerd --> /etc/containerd/config.toml
sudo nvidia-ctk runtime configure --runtime=containerd --set-as-default
sudo systemctl restart containerd

helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
    && helm repo update

NODE_NAME=$(hostname)

kubectl label node ${NODE_NAME} feature.node.kubernetes.io/pci-10de.present=true
kubectl label node ${NODE_NAME} nvidia.com/gpu.deploy.gpu-feature-discovery=false
kubectl label node ${NODE_NAME} nvidia.com/gpu.deploy.container-toolkit=false
kubectl label node ${NODE_NAME} nvidia.com/gpu.deploy.driver=false

# Self-hosted Kubernetes
helm install --wait \
     -n gpu-operator --create-namespace \
     gpu-operator nvidia/gpu-operator \
     --version=v25.3.1 \
     --set driver.enabled=false \
     --set toolkit.enabled=false \
     --set toolkit.env[0].name=CONTAINERD_CONFIG \
     --set toolkit.env[0].value=/etc/containerd/config.toml \
     --set toolkit.env[1].name=CONTAINERD_SOCKET \
     --set toolkit.env[1].value=/run/containerd/containerd.sock \
     --set toolkit.env[2].name=CONTAINERD_RUNTIME_CLASS \
     --set toolkit.env[2].value=nvidia \
     --set toolkit.env[3].name=CONTAINERD_SET_AS_DEFAULT \
     --set-string toolkit.env[3].value=true