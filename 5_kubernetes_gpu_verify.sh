#!/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: nvidia-version-check
spec:
  restartPolicy: OnFailure
  containers:
  - name: nvidia-version-check
    image: "nvidia/cuda:12.5.1-base-ubuntu24.04"
    command: ["nvidia-smi"]
    resources:
      limits:
         nvidia.com/gpu: 1
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/nvidia-version-check --timeout=60s
echo
kubectl describe pod/nvidia-version-check
echo
kubectl logs pod/nvidia-version-check
echo
kubectl delete pod/nvidia-version-check
echo

cat <<EOF | kubectl create -f -
 apiVersion: v1
 kind: Pod
 metadata:
   name: cuda-vectoradd
 spec:
   restartPolicy: OnFailure
   containers:
   - name: cuda-vectoradd
     image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda12.5.0
     resources:
       limits:
          nvidia.com/gpu: 1
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/cuda-vectoradd --timeout=60s
echo
kubectl describe pod/cuda-vectoradd
echo
kubectl logs pod/cuda-vectoradd
echo
kubectl delete pod/cuda-vectoradd