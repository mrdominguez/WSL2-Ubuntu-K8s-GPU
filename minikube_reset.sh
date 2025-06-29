#/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU
# https://minikube.sigs.k8s.io/docs/commands/delete/

minikube delete --purge
rm -rf .kube