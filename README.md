# WSL2-Ubuntu-K8s-GPU
Deploy the NVIDIA GPU Operator to Kubernetes on a Windows Subsystem for Linux (WSL2) backend running Ubuntu.

![Alt text](WSL2-Ubuntu-K8s-GPU.png?raw=true)

WSL2 documentation: https://learn.microsoft.com/en-us/windows/wsl/

While WSL2 is supported on both Windows 10 and Windows 11, generally speaking, the latter is recommended as it provides a better experience.

Details about my environment:
- OS: Windows 11, version 24H2 (OS build 26100.3323)
- CPU: Intel Core i9-10920X
- Memory: 96GB
- GPU: NVIDIA GeForce GTX 1070
- NVIDIA Studio Driver version 576.02
- Working installation of WSL2

NOTE: 16GB of RAM will suffice to get Kubernetes with GPU support up and running.
When running the *OPTIONAL* TensorFlow test on Jupyter (step 9), memory usage goes above 16GB.

```
C:\Users\maria>wsl --version
WSL version: 2.5.7.0
Kernel version: 6.6.87.1-1
WSLg version: 1.0.66
MSRDC version: 1.2.6074
Direct3D version: 1.611.1-81528511
DXCore version: 10.0.26100.1-240331-1435.ge-release
Windows version: 10.0.26100.3323

C:\Users\maria>nvidia-smi -L
GPU 0: NVIDIA GeForce GTX 1070 (UUID: GPU-a420e545-6c05-9323-2027-53d6edab213c)

C:\Users\maria>nvidia-smi
Thu Jun 26 14:20:48 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 576.02                 Driver Version: 576.02         CUDA Version: 12.9     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                  Driver-Model | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce GTX 1070      WDDM  |   00000000:65:00.0  On |                  N/A |
|  0%   38C    P8              8W /  151W |     752MiB /   8192MiB |      1%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
...
```

## Install Ubuntu-24.04
Open the Command Prompt: `Start + R`, type in `cmd` and press `Enter/OK`.

Then, execute the following command: `wsl --install Ubuntu-24.04 --name ubuntu-k8s-gpu`

```
C:\Users\maria>wsl --install Ubuntu-24.04 --name ubuntu-k8s-gpu
Downloading: Ubuntu 24.04 LTS
Installing: Ubuntu 24.04 LTS
Distribution successfully installed. It can be launched via 'wsl.exe -d ubuntu-k8s-gpu'
Launching ubuntu-k8s-gpu...
Provisioning the new WSL instance ubuntu-k8s-gpu
This might take a while...
Create a default Unix user account: core
New password:
Retype new password:
passwd: password updated successfully
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

core@core-10920x:/mnt/c/Users/maria$ cd
core@core-10920x:~$ pwd
/home/core
core@core-10920x:~$ uname -a
Linux core-10920x 6.6.87.1-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Mon Apr 21 17:08:54 UTC 2025 x86_64 x86_64 x86_64 GNU/Linux
```

## Install Kubernetes
I have tested vanilla Kubernetes as well as mutiple Kubernetes distributions, including `Canonical Kubernetes`, `MicroK8s`, `kind` and `minikube`.

Vanilla Kubernetes along with a specific installation of `minikube` were the most reliable and hassle-free with regards to making the NVIDIA GPU Operator work properly. Use either one as you see fit.

### Vanila Kubernetes
### `1_kubernetes_install.sh`
Install the latest stable 1.33 Kubernetes release along with Calico 3.28.5 as CNI addon.

```
core@core-10920x:~$ kubectl get all --all-namespaces
NAMESPACE          NAME                                           READY   STATUS    RESTARTS   AGE
calico-apiserver   pod/calico-apiserver-69d87bbf74-lscsn          1/1     Running   0          3m26s
calico-apiserver   pod/calico-apiserver-69d87bbf74-sxxr5          1/1     Running   0          3m26s
calico-system      pod/calico-kube-controllers-7868479fcd-brfmh   1/1     Running   0          3m26s
calico-system      pod/calico-node-b4npx                          1/1     Running   0          3m26s
calico-system      pod/calico-typha-6c66d57765-cxcvt              1/1     Running   0          3m26s
calico-system      pod/csi-node-driver-9k8np                      2/2     Running   0          3m26s
kube-system        pod/coredns-674b8bbfcf-qlkxx                   1/1     Running   0          3m33s
kube-system        pod/coredns-674b8bbfcf-w224b                   1/1     Running   0          3m33s
kube-system        pod/etcd-core-10920x                           1/1     Running   0          3m40s
kube-system        pod/kube-apiserver-core-10920x                 1/1     Running   0          3m39s
kube-system        pod/kube-controller-manager-core-10920x        1/1     Running   0          3m40s
kube-system        pod/kube-proxy-jzdrp                           1/1     Running   0          3m33s
kube-system        pod/kube-scheduler-core-10920x                 1/1     Running   0          3m39s
tigera-operator    pod/tigera-operator-84dbcf95ff-2chkq           1/1     Running   0          3m33s

NAMESPACE          NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   service/calico-api                        ClusterIP   10.106.227.185   <none>        443/TCP                  3m26s
calico-system      service/calico-kube-controllers-metrics   ClusterIP   None             <none>        9094/TCP                 3m7s
calico-system      service/calico-typha                      ClusterIP   10.106.90.89     <none>        5473/TCP                 3m26s
default            service/kubernetes                        ClusterIP   10.96.0.1        <none>        443/TCP                  3m40s
kube-system        service/kube-dns                          ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   3m39s

NAMESPACE       NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   daemonset.apps/calico-node       1         1         1       1            1           kubernetes.io/os=linux   3m26s
calico-system   daemonset.apps/csi-node-driver   1         1         1       1            1           kubernetes.io/os=linux   3m26s
kube-system     daemonset.apps/kube-proxy        1         1         1       1            1           kubernetes.io/os=linux   3m39s

NAMESPACE          NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-apiserver   deployment.apps/calico-apiserver          2/2     2            2           3m26s
calico-system      deployment.apps/calico-kube-controllers   1/1     1            1           3m26s
calico-system      deployment.apps/calico-typha              1/1     1            1           3m26s
kube-system        deployment.apps/coredns                   2/2     2            2           3m39s
tigera-operator    deployment.apps/tigera-operator           1/1     1            1           3m38s

NAMESPACE          NAME                                                 DESIRED   CURRENT   READY   AGE
calico-apiserver   replicaset.apps/calico-apiserver-69d87bbf74          2         2         2       3m26s
calico-system      replicaset.apps/calico-kube-controllers-7868479fcd   1         1         1       3m26s
calico-system      replicaset.apps/calico-typha-6c66d57765              1         1         1       3m26s
kube-system        replicaset.apps/coredns-674b8bbfcf                   2         2         2       3m33s
tigera-operator    replicaset.apps/tigera-operator-84dbcf95ff           1         1         1       3m33s
```
```
core@core-10920x:~$ kubectl get nodes -o wide
NAME          STATUS   ROLES           AGE     VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION                     CONTAINER-RUNTIME
core-10920x   Ready    control-plane   4m28s   v1.33.2   192.168.181.215   <none>        Ubuntu 24.04.2 LTS   6.6.87.1-microsoft-standard-WSL2   containerd://1.7.27
```

### minikube
### `1_minikube_install.sh`
Install the latest minikube release using the `none` (bare-metal) driver and `containerd` as container runtime.

During the installation process, notice the following message:
>❗  Using the 'containerd' runtime with the 'none' driver is an untested configuration!

Nevertheless, I can confirm that I have not had any issues using this combination.
```
core@core-10920x:~$ kubectl get all -A
NAMESPACE     NAME                                           READY   STATUS    RESTARTS   AGE
kube-system   pod/calico-kube-controllers-7bfdc5b57c-fhj7m   1/1     Running   0          5m45s
kube-system   pod/calico-node-r85s8                          1/1     Running   0          5m45s
kube-system   pod/coredns-674b8bbfcf-hdzd8                   1/1     Running   0          5m45s
kube-system   pod/etcd-core-10920x                           1/1     Running   0          5m50s
kube-system   pod/kube-apiserver-core-10920x                 1/1     Running   0          5m50s
kube-system   pod/kube-controller-manager-core-10920x        1/1     Running   0          5m50s
kube-system   pod/kube-proxy-hvkxj                           1/1     Running   0          5m45s
kube-system   pod/kube-scheduler-core-10920x                 1/1     Running   0          5m50s
kube-system   pod/storage-provisioner                        1/1     Running   0          5m48s

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  5m51s
kube-system   service/kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   5m50s

NAMESPACE     NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/calico-node   1         1         1       1            1           kubernetes.io/os=linux   5m48s
kube-system   daemonset.apps/kube-proxy    1         1         1       1            1           kubernetes.io/os=linux   5m50s

NAMESPACE     NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/calico-kube-controllers   1/1     1            1           5m48s
kube-system   deployment.apps/coredns                   1/1     1            1           5m50s

NAMESPACE     NAME                                                 DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/calico-kube-controllers-7bfdc5b57c   1         1         1       5m46s
kube-system   replicaset.apps/coredns-674b8bbfcf                   1         1         1       5m46s
```
```
core@core-10920x:~$ kubectl get nodes -o wide
NAME          STATUS   ROLES           AGE     VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION                     CONTAINER-RUNTIME
core-10920x   Ready    control-plane   6m20s   v1.33.1   192.168.181.215   <none>        Ubuntu 24.04.2 LTS   6.6.87.1-microsoft-standard-WSL2   containerd://1.7.27
```
```
core@core-10920x:~$ minikube profile list
|----------|-----------|------------|-----------------|------|---------|--------|-------|----------------|--------------------|
| Profile  | VM Driver |  Runtime   |       IP        | Port | Version | Status | Nodes | Active Profile | Active Kubecontext |
|----------|-----------|------------|-----------------|------|---------|--------|-------|----------------|--------------------|
| minikube | none      | containerd | 192.168.181.215 | 8443 | v1.33.1 | OK     |     1 | *              | *                  |
|----------|-----------|------------|-----------------|------|---------|--------|-------|----------------|--------------------|
```
```
core@core-10920x:~$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

## Install NVIDIA Container Toolkit
### `2_nvidia_container_toolkit_install.sh`
```
core@core-10920x:~$ nvidia-container-cli --version
cli-version: 1.17.8
lib-version: 1.17.8
build date: 2025-05-30T13:47+00:00
build revision: 6eda4d76c8c5f8fc174e4abca83e513fb4dd63b0
build compiler: x86_64-linux-gnu-gcc-7 7.5.0
build platform: x86_64
build flags: -D_GNU_SOURCE -D_FORTIFY_SOURCE=2 -DNDEBUG -std=gnu11 -O2 -g -fdata-sections -ffunction-sections -fplan9-extensions -fstack-protector -fno-strict-aliasing -fvisibility=hidden -Wall -Wextra -Wcast-align -Wpointer-arith -Wmissing-prototypes -Wnonnull -Wwrite-strings -Wlogical-op -Wformat=2 -Wmissing-format-attribute -Winit-self -Wshadow -Wstrict-prototypes -Wunreachable-code -Wconversion -Wsign-conversion -Wno-unknown-warning-option -Wno-format-extra-args -Wno-gnu-alignof-expression -Wl,-zrelro -Wl,-znow -Wl,-zdefs -Wl,--gc-sections
```
```
core@core-10920x:~$ nvidia-container-cli info
NVRM version:   576.02
CUDA version:   12.9

Device Index:   0
Device Minor:   0
Model:          NVIDIA GeForce GTX 1070
Brand:          GeForce
GPU UUID:       GPU-a420e545-6c05-9323-2027-53d6edab213c
Bus Location:   00000000:65:00.0
Architecture:   6.1
```

## Verify GPU access from `docker`
### `3_docker_gpu_verify.sh`
Make sure that the current user belongs to the `docker` group.
```
core@core-10920x:~$ id
uid=1000(core) gid=1000(core) groups=1000(core),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users)
core@core-10920x:~$ newgrp docker
core@core-10920x:~$ id
uid=1000(core) gid=108(docker) groups=108(docker),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users),1000(core)
```
```
core@core-10920x:~$ docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
Sat Jun 28 17:10:43 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 575.51.02              Driver Version: 576.02         CUDA Version: 12.9     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce GTX 1070        On  |   00000000:65:00.0  On |                  N/A |
|  0%   37C    P8              8W /  151W |     847MiB /   8192MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A              27      G   /Xwayland                             N/A      |
+-----------------------------------------------------------------------------------------+
```
```
core@core-10920x:~$ docker run --gpus all nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark
Run "nbody -benchmark [-numbodies=<numBodies>]" to measure performance.
        -fullscreen       (run n-body simulation in fullscreen mode)
        -fp64             (use double precision floating point values for simulation)
        -hostmem          (stores simulation data in host memory)
        -benchmark        (run benchmark to measure performance)
        -numbodies=<N>    (number of bodies (>= 1) to run in simulation)
        -device=<d>       (where d=0,1,2.... for the CUDA device to use)
        -numdevices=<i>   (where i=(number of CUDA devices > 0) to use for simulation)
        -compare          (compares simulation results running once on the default GPU and once on the CPU)
        -cpu              (run n-body simulation on the CPU)
        -tipsy=<file.bin> (load a tipsy model file for simulation)

NOTE: The CUDA Samples are not meant for performance measurements. Results may vary when GPU Boost is enabled.

> Windowed mode
> Simulation data stored in video memory
> Single precision floating point simulation
> 1 Devices used for simulation
GPU Device 0: "Pascal" with compute capability 6.1

> Compute 6.1 CUDA device: [NVIDIA GeForce GTX 1070]
15360 bodies, total time for 10 iterations: 11.643 ms
= 202.639 billion interactions per second
= 4052.770 single-precision GFLOP/s at 20 flops per interaction
```

## Install NVIDIA GPU Operator
### `4_nvidia_gpu_operator_install.sh`
Deployment scenario:

| Parameter | |
|---|---|
| `driver.enabled=false` | By default, the Operator deploys NVIDIA drivers as a container on the system but WSL2 makes drivers available. |
| `toolkit.enabled=false` | By default, the Operator deploys the NVIDIA Container Toolkit as a container on the system but the NVIDIA runtimes have already been installed (step 2). |

The node has to be manually labeled with `feature.node.kubernetes.io/pci-10de.present=true` for the Operator to work correctly. The value `0x10de` is the PCI vendor ID that is assigned to NVIDIA.

NVIDIA GPU Feature Discovery is a component used to automatically detect and label GPU-enabled nodes. However, it seems incompatible with WSL2 and, therefore, it needs to be disabled via label.

Overall, these are the required node labels:
```
feature.node.kubernetes.io/pci-10de.present=true
nvidia.com/gpu.deploy.gpu-feature-discovery=false
nvidia.com/gpu.deploy.container-toolkit=false
nvidia.com/gpu.deploy.driver=false
```

```
core@core-10920x:~$ helm list -A
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
gpu-operator    gpu-operator    1               2025-06-28 13:22:44.040371345 -0400 EDT deployed        gpu-operator-v25.3.1    v25.3.1
```
```
core@core-10920x:~$ kubectl get all -n gpu-operator
NAME                                                              READY   STATUS      RESTARTS   AGE
pod/gpu-operator-857fc9cf65-sjfgp                                 1/1     Running     0          2m25s
pod/gpu-operator-node-feature-discovery-gc-86f6495b55-7hkns       1/1     Running     0          2m25s
pod/gpu-operator-node-feature-discovery-master-694467d5db-ft4bj   1/1     Running     0          2m25s
pod/gpu-operator-node-feature-discovery-worker-gqsz9              1/1     Running     0          2m25s
pod/nvidia-cuda-validator-nbwdm                                   0/1     Completed   0          2m
pod/nvidia-dcgm-exporter-djr5r                                    1/1     Running     0          2m6s
pod/nvidia-device-plugin-daemonset-wfkks                          1/1     Running     0          2m7s
pod/nvidia-operator-validator-6p99k                               1/1     Running     0          2m7s

NAME                           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/gpu-operator           ClusterIP   10.103.255.155   <none>        8080/TCP   2m8s
service/nvidia-dcgm-exporter   ClusterIP   10.103.244.26    <none>        9400/TCP   2m6s

NAME                                                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                          AGE
daemonset.apps/gpu-feature-discovery                        0         0         0       0            0           nvidia.com/gpu.deploy.gpu-feature-discovery=true                       2m6s
daemonset.apps/gpu-operator-node-feature-discovery-worker   1         1         1       1            1           <none>                                                                 2m25s
daemonset.apps/nvidia-dcgm-exporter                         1         1         1       1            1           nvidia.com/gpu.deploy.dcgm-exporter=true                               2m6s
daemonset.apps/nvidia-device-plugin-daemonset               1         1         1       1            1           nvidia.com/gpu.deploy.device-plugin=true                               2m7s
daemonset.apps/nvidia-device-plugin-mps-control-daemon      0         0         0       0            0           nvidia.com/gpu.deploy.device-plugin=true,nvidia.com/mps.capable=true   2m7s
daemonset.apps/nvidia-mig-manager                           0         0         0       0            0           nvidia.com/gpu.deploy.mig-manager=true                                 2m6s
daemonset.apps/nvidia-operator-validator                    1         1         1       1            1           nvidia.com/gpu.deploy.operator-validator=true                          2m7s

NAME                                                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/gpu-operator                                 1/1     1            1           2m25s
deployment.apps/gpu-operator-node-feature-discovery-gc       1/1     1            1           2m25s
deployment.apps/gpu-operator-node-feature-discovery-master   1/1     1            1           2m25s

NAME                                                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/gpu-operator-857fc9cf65                                 1         1         1       2m25s
replicaset.apps/gpu-operator-node-feature-discovery-gc-86f6495b55       1         1         1       2m25s
replicaset.apps/gpu-operator-node-feature-discovery-master-694467d5db   1         1         1       2m25s
```
```
core@core-10920x:~$ ls -ltr /run/nvidia/validations/
total 4
-rw------- 1 root root 110 Jun 28 13:23 driver-ready
-rw-r--r-- 1 root root   0 Jun 28 13:23 toolkit-ready
-rw-r--r-- 1 root root   0 Jun 28 13:23 cuda-ready
-rw-r--r-- 1 root root   0 Jun 28 13:23 plugin-ready
```

## Verify GPU access from Kubernetes
### `5_kubernetes_gpu_verify.sh`
```
core@core-10920x:~$ cat <<EOF | kubectl create -f -
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
pod/nvidia-version-check created
core@core-10920x:~$ kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/nvidia-version-check --timeout=60s
pod/nvidia-version-check condition met
core@core-10920x:~$ kubectl logs pod/nvidia-version-check
Sat Jun 28 18:30:12 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 575.51.02              Driver Version: 576.02         CUDA Version: 12.9     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce GTX 1070        On  |   00000000:65:00.0  On |                  N/A |
|  0%   39C    P2             29W /  151W |     926MiB /   8192MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A              27      G   /Xwayland                             N/A      |
+-----------------------------------------------------------------------------------------+
```
```
core@core-10920x:~$ cat <<EOF | kubectl create -f -
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
pod/cuda-vectoradd created
core@core-10920x:~$ kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/cuda-vectoradd --timeout=60s
pod/cuda-vectoradd condition met
core@core-10920x:~$ kubectl logs pod/cuda-vectoradd
[Vector addition of 50000 elements]
Copy input data from the host memory to the CUDA device
CUDA kernel launch with 196 blocks of 256 threads
Copy output data from the CUDA device to the host memory
Test PASSED
Done
```

## Enable GPU Time-Slicing
### `6_gpu_time-slicing_enable.sh`
Before enabling:
```
core@core-10920x:~$ kubectl get nodes -o jsonpath='node: {.items[].metadata.name}, nvidia.com/gpu capacity: {.items[].status.capacity.nvidia\.com/gpu}'
node: core-10920x, nvidia.com/gpu capacity: 1
```
After enabling and labeling the node:
```
nvidia.com/gpu.count=1
nvidia.com/gpu.replicas=4
```
```
core@core-10920x:~$ kubectl get nodes -o jsonpath='node: {.items[].metadata.name}, nvidia.com/gpu capacity: {.items[].status.capacity.nvidia\.com/gpu}'
node: core-10920x, nvidia.com/gpu capacity: 4
```

## Verify GPU Time-Slicing
### `7_gpu_time-slicing_verify.sh`
```
core@core-10920x:~$ cat <<EOF | kubectl apply -f -
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
deployment.apps/time-slicing-verification created
```
```
core@core-10920x:~$ kubectl wait --for=condition=Ready pod -l app=time-slicing-verification --timeout=60s
pod/time-slicing-verification-8974cf9bf-b7bb4 condition met
pod/time-slicing-verification-8974cf9bf-cqxsd condition met
pod/time-slicing-verification-8974cf9bf-j96f4 condition met
pod/time-slicing-verification-8974cf9bf-p6nk8 condition met
core@core-10920x:~$ kubectl get pods -l app=time-slicing-verification
NAME                                        READY   STATUS    RESTARTS   AGE
time-slicing-verification-8974cf9bf-b7bb4   1/1     Running   0          56s
time-slicing-verification-8974cf9bf-cqxsd   1/1     Running   0          56s
time-slicing-verification-8974cf9bf-j96f4   1/1     Running   0          56s
time-slicing-verification-8974cf9bf-p6nk8   1/1     Running   0          56s
```

Open (Windows) Task Manager `taskmgr` and check GPU usage...

```
core@core-10920x:~$ kubectl logs deploy/time-slicing-verification
Found 4 pods, using pod/time-slicing-verification-8974cf9bf-b7bb4
[Vector addition of 50000 elements]
Copy input data from the host memory to the CUDA device
CUDA kernel launch with 196 blocks of 256 threads
Copy output data from the CUDA device to the host memory
Test PASSED
Done
...
[Vector addition of 50000 elements]
Copy input data from the host memory to the CUDA device
CUDA kernel launch with 196 blocks of 256 threads
Copy output data from the CUDA device to the host memory
Test PASSED
Done
core@core-10920x:~$ kubectl delete deploy/time-slicing-verification
deployment.apps "time-slicing-verification" deleted
```

## Install TensorFlow with GPU support and Jupyter
### `8_tensorflow-notebook_install.sh`
```
core@core-10920x:~$ kubectl get pod tf-notebook
NAME          READY   STATUS    RESTARTS   AGE
tf-notebook   1/1     Running   0          8m16s
core@core-10920x:~$ kubectl get svc tf-notebook
NAME          TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
tf-notebook   NodePort   10.101.99.216   <none>        80:30001/TCP   8m19s
```
```
core@core-10920x:~$ kubectl logs tf-notebook
[I 2025-06-29 01:36:06.942 ServerApp] jupyter_lsp | extension was successfully linked.
[I 2025-06-29 01:36:06.944 ServerApp] jupyter_server_terminals | extension was successfully linked.
[I 2025-06-29 01:36:06.946 ServerApp] jupyterlab | extension was successfully linked.
[I 2025-06-29 01:36:06.948 ServerApp] notebook | extension was successfully linked.
[I 2025-06-29 01:36:06.950 ServerApp] Writing Jupyter server cookie secret to /root/.local/share/jupyter/runtime/jupyter_cookie_secret
[I 2025-06-29 01:36:07.109 ServerApp] notebook_shim | extension was successfully linked.
[I 2025-06-29 01:36:07.147 ServerApp] notebook_shim | extension was successfully loaded.
[I 2025-06-29 01:36:07.149 ServerApp] jupyter_lsp | extension was successfully loaded.
[I 2025-06-29 01:36:07.149 ServerApp] jupyter_server_terminals | extension was successfully loaded.
[I 2025-06-29 01:36:07.150 LabApp] JupyterLab extension loaded from /usr/local/lib/python3.11/dist-packages/jupyterlab
[I 2025-06-29 01:36:07.150 LabApp] JupyterLab application directory is /usr/local/share/jupyter/lab
[I 2025-06-29 01:36:07.150 LabApp] Extension Manager is 'pypi'.
[I 2025-06-29 01:36:07.211 ServerApp] jupyterlab | extension was successfully loaded.
[I 2025-06-29 01:36:07.213 ServerApp] notebook | extension was successfully loaded.
[I 2025-06-29 01:36:07.213 ServerApp] Serving notebooks from local directory: /tf
[I 2025-06-29 01:36:07.213 ServerApp] Jupyter Server 2.15.0 is running at:
[I 2025-06-29 01:36:07.214 ServerApp] http://tf-notebook:8888/tree?token=cbec1bd1618fac7ddd8c83170a7ce4dddf951b6f217236e1
[I 2025-06-29 01:36:07.214 ServerApp]     http://127.0.0.1:8888/tree?token=cbec1bd1618fac7ddd8c83170a7ce4dddf951b6f217236e1
[I 2025-06-29 01:36:07.214 ServerApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 2025-06-29 01:36:07.215 ServerApp]

    To access the server, open this file in a browser:
        file:///root/.local/share/jupyter/runtime/jpserver-1-open.html
    Or copy and paste one of these URLs:
        http://tf-notebook:8888/tree?token=cbec1bd1618fac7ddd8c83170a7ce4dddf951b6f217236e1
        http://127.0.0.1:8888/tree?token=cbec1bd1618fac7ddd8c83170a7ce4dddf951b6f217236e1
[I 2025-06-29 01:36:07.242 ServerApp] Skipped non-installed server(s): bash-language-server, dockerfile-language-server-nodejs, javascript-typescript-langserver, jedi-language-server, julia-language-server, pyright, python-language-server, python-lsp-server, r-languageserver, sql-language-server, texlab, typescript-language-server, unified-language-server, vscode-css-languageserver-bin, vscode-html-languageserver-bin, vscode-json-languageserver-bin, yaml-language-server
```
```
core@core-10920x:~$ kubectl port-forward svc/tf-notebook 8888:80
Forwarding from 127.0.0.1:8888 -> 8888
Forwarding from [::1]:8888 -> 8888
```

`Ctrl + Right click` on the 127.0.0.1 URL, then click `Upload` on the Jupyter UI to upload the `9_tensorflow_gpu_test.ipynb` file.

Click on the newly added notebook and `Run All Cells`.

```
import sys
import tensorflow as tf

print("Python: ", sys.version)
print("TensorFlow: ", tf.__version__)
print("Eager mode: ", tf.executing_eagerly())
print("GPU is", "available" if tf.config.list_physical_devices("GPU") else "NOT AVAILABLE")
>>>
Python:  3.11.11 (main, Dec  4 2024, 08:55:07) [GCC 11.4.0]
TensorFlow:  2.19.0
Eager mode:  True
GPU is available
```

```
from tensorflow.python.client import device_lib

device_lib.list_local_devices()
>>>
I0000 00:00:1751163887.720034    1687 gpu_device.cc:2019] Created device /device:GPU:0 with 6717 MB memory:  -> device: 0, name: NVIDIA GeForce GTX 1070, pci bus id: 0000:65:00.0, compute capability: 6.1
[name: "/device:CPU:0"
 device_type: "CPU"
 memory_limit: 268435456
 locality {
 }
 incarnation: 12976663978019435193
 xla_global_id: -1,
 name: "/device:GPU:0"
 device_type: "GPU"
 memory_limit: 7043284992
 locality {
   bus_id: 1
   links {
   }
 }
 incarnation: 10574522943424334714
 physical_device_desc: "device: 0, name: NVIDIA GeForce GTX 1070, pci bus id: 0000:65:00.0, compute capability: 6.1"
 xla_global_id: 416903419]
```

```
import tensorflow as tf

visible_devices = tf.config.get_visible_devices()
for devices in visible_devices:
  print(devices)
>>>
PhysicalDevice(name='/physical_device:CPU:0', device_type='CPU')
PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')
```
