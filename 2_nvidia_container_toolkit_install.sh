#/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Configure docker --> /etc/docker/daemon.json
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
sudo systemctl restart docker

echo
nvidia-container-cli --version
echo
nvidia-container-cli info