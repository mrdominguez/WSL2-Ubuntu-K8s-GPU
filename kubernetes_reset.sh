#/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU
# https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/

kubeadm reset cleanup-mode
sudo rm -rf /etc/cni/net.d
rm -rf $HOME/.kube