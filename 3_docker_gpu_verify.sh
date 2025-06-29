#!/bin/bash
# https://github.com/mrdominguez/WSL2-Ubuntu-K8s-GPU

docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
echo
docker run --gpus all nvcr.io/nvidia/k8s/cuda-sample:nbody nbody -gpu -benchmark