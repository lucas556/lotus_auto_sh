#!/bin/bash

# 更换中科大源
sudo cp sources.list /etc/apt/sources.list
# golang
sudo add-apt-repository -y ppa:longsleep/golang-backports

apt-get update
echo '更新源成功'

# lotus依赖
sudo apt -y install golang-go mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl

# rustc
mkdir -p $HOME/.cargo/
cp config $HOME/.cargo/
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -sSf | sh /dev/stdin "-y"
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
echo 'export GOPROXY=https://goproxy.cn' >> ~/.bashrc

source ~/.bashrc
# lotus

git clone -b ntwk-calibration https://github.com/filecoin-project/lotus.git /lotus
cd /lotus

# 编译
env RUSTFLAGS="-C target-cpu=native -g" FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1 FIL_PROOFS_USE_GPU_TREE_BUILDER=1 FFI_BUILD_FROM_SOURCE=1 make clean all


