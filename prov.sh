#!/bin/bash

set -e  # Stop jika ada error

# Update & Install Dependencies
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
sudo apt-add-repository main
# Buat Direktori Keyrings
sudo mkdir -p -m 755 /etc/apt/keyrings

# Tambahkan Kubernetes Repo
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.26/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

# Install Kubernetes Components
sudo apt install -y kubelet=1.26.11-1.1 kubeadm=1.26.11-1.1 kubectl=1.26.11-1.1

# Disable Swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Load Kernel Modules
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set sysctl for Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# Tambahkan Docker Repository
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Download dan Install Containerd
CONTAINERD_VERSION="1.7.13"
wget https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

# Ekstrak & Pindahkan Containerd ke /usr/local/bin
tar -xzf containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
sudo cp bin/* /usr/local/bin
rm -f containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz  # Hapus file tar setelah ekstraksi

# Buat Direktori Config
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Download dan Install Service Systemd untuk Containerd
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /etc/systemd/system/

# Reload systemd, enable, dan start containerd
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

echo "Installation Completed Successfully!"
