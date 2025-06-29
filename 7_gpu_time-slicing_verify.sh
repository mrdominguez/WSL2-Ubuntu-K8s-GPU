#!/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU
# https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html

# Create deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: time-slicing-verification
  labels:
    app: time-slicing-verification
spec:
  replicas: 4
  selector:
    matchLabels:
      app: time-slicing-verification
  template:
    metadata:
      labels:
        app: time-slicing-verification
    spec:
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
      hostPID: true
      containers:
        - name: cuda-vectoradd
          image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda12.5.0
          command: ["/bin/bash", "-c", "--"]
          args:
            - while true; do /cuda-samples/vectorAdd; done
          resources:
           limits:
             nvidia.com/gpu: 1
EOF

kubectl wait --for=condition=Ready pod -l app=time-slicing-verification --timeout=60s
echo
kubectl get pods -l app=time-slicing-verification
echo
echo "Sleeping for 5 seconds... Open (Windows) Task Manager <taskmgr> and check GPU usage"
sleep 5
echo
kubectl logs deploy/time-slicing-verification
kubectl delete deploy/time-slicing-verification