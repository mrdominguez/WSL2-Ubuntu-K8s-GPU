#!/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU
# https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html#jupyter-notebook

cat <<EOF | kubectl create -f -
---
apiVersion: v1
kind: Service
metadata:
  name: tf-notebook
  labels:
    app: tf-notebook
spec:
  type: NodePort
  ports:
  - port: 80
    name: http
    targetPort: 8888
    nodePort: 30001
  selector:
    app: tf-notebook
---
apiVersion: v1
kind: Pod
metadata:
  name: tf-notebook
  labels:
    app: tf-notebook
spec:
  securityContext:
    fsGroup: 0
  containers:
  - name: tf-notebook
    image: tensorflow/tensorflow:latest-gpu-jupyter
    resources:
      limits:
        nvidia.com/gpu: 1
    ports:
    - containerPort: 8888
      name: notebook
EOF

kubectl wait --for=condition=Ready pod -l app=tf-notebook --timeout=300s
echo
kubectl get pod tf-notebook
echo
kubectl get svc tf-notebook
echo
kubectl logs -f tf-notebook
echo
kubectl port-forward svc/tf-notebook 8888:80