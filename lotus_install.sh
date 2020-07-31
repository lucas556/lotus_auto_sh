#!/bin/sh

# 更换中科大源
sudo cp sources.list /etc/apt/sources.list
# golang
sudo add-apt-repository ppa:longsleep/golang-backports
apt-get update

# lotus依赖
sudo apt install golang-go mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl

# rustc
mkdir -p ~/.cargo/

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
