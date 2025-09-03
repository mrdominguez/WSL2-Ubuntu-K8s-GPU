#!/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU

K8S_VER=1.33
CNI_VER=3.28.5

sudo apt update

# Enable passwordless sudo
sudo sed -i '/%sudo/s/ ALL$/ NOPASSWD:ALL/' /etc/sudoers

# Disable swap
# Make root filesystem a shared mount
swapon --show
sudo swapoff -a
sudo mount --make-rshared /

sudo tee /etc/rc.local <<EOF
#!/bin/bash

swapoff -a
mount --make-rshared /
EOF
sudo chmod u+x /etc/rc.local

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl --system

# Load required kernel modules
lsmod | grep -E "overlay|br_netfilter"
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee -a /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

# Install docker, containerd
sudo apt -y install docker.io containerd
sudo usermod -aG docker $USER

# Configure cgroup driver for containerd
[ -d /etc/containerd ] || sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml
grep sandbox_image /etc/containerd/config.toml
sudo sed -i '/sandbox_image/s/=.*$/= "registry.k8s.io\/pause:3.10"/' /etc/containerd/config.toml
grep sandbox_image /etc/containerd/config.toml
sudo systemctl restart containerd

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install helm

# Install Kubernetes
sudo apt install gnupg2 -y
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VER}/deb/Release.key | \
sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg

echo "deb https://pkgs.k8s.io/core:/stable:/v${K8S_VER}/deb/ /" | sudo tee /etc/apt/sources.list.d/kurbenetes.list
sudo apt update
sudo apt install kubelet kubeadm kubectl -y
sudo apt-mark hold kubeadm kubelet kubectl
sudo apt-mark showhold

# Initialize Kubernetes cluster
IP=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
sudo kubeadm init --control-plane-endpoint=${IP} --apiserver-advertise-address=${IP} --pod-network-cidr=10.100.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install pod network addon
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v${CNI_VER}/manifests/tigera-operator.yaml
wget https://raw.githubusercontent.com/projectcalico/calico/v${CNI_VER}/manifests/custom-resources.yaml
sed -i 's/192.168/10.100/' custom-resources.yaml
kubectl create -f custom-resources.yaml

# Enable scheduling on control plane node
kubectl taint nodes $(hostname) node-role.kubernetes.io/control-plane-

# Check Kubernetes resources
echo
kubectl get all --all-namespaces
echo
kubectl get nodes -o wide
echo

# Check version
kubectl version