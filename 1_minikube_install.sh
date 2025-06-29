#!/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU

# Enable passwordless sudo
sudo sed -i '/%sudo/s/ ALL$/ NOPASSWD:ALL/' /etc/sudoers

sudo apt update

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

# Install docker, containerd
sudo apt -y install docker.io containerd
sudo usermod -aG docker $USER

# Configure cgroup driver for containerD
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

# Install conntrack
sudo apt -y install conntrack
sudo ln -s /usr/sbin/conntrack /usr/bin/conntrack
conntrack --version

# Install containernetworking-plugins
CNI_PLUGIN_VERSION="v1.3.0"
CNI_PLUGIN_TAR="cni-plugins-linux-amd64-$CNI_PLUGIN_VERSION.tgz" # change arch if not on amd64
CNI_PLUGIN_INSTALL_DIR="/opt/cni/bin"

curl -LO "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/$CNI_PLUGIN_TAR"
sudo mkdir -p "$CNI_PLUGIN_INSTALL_DIR"
sudo tar -xf "$CNI_PLUGIN_TAR" -C "$CNI_PLUGIN_INSTALL_DIR"
rm "$CNI_PLUGIN_TAR"

# Install crictl
CRICTL_VERSION="v1.33.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$CRICTL_VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$CRICTL_VERSION-linux-amd64.tar.gz
sudo crictl version

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb

# Create symbolic link to minikube’s binary named 'kubectl'
sudo ln -s $(which minikube) /usr/local/bin/kubectl

# Create Minikube cluster
# Driver: none (bare-metal)
# Runtime: containerd
# CNI: calico
minikube start -d none -c containerd --cni calico

# Check resources
echo
kubectl get all -A
echo
kubectl get nodes -o wide
echo
minikube profile list
echo

# Check status
minikube status