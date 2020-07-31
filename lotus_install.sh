#!/bin/bash

# 更换中科大源
sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
cat > /etc/apt/sources.list <<EOF
##中科大源

deb https://mirrors.ustc.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
EOF

# golang
sudo add-apt-repository -y ppa:longsleep/golang-backports

apt-get update
echo '更新源成功'

# 依赖
sudo apt -y install golang-go mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl nfs-common supervisor

# rustc
mkdir -p $HOME/.cargo/
cat > $HOME/.cargo/config <<EOF
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
EOF

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -sSf | sh /dev/stdin "-y"
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
echo 'export GOPROXY=https://goproxy.cn' >> ~/.bashrc
source ~/.bashrc

# lotus
git clone -b ntwk-calibration https://gitclone.com/github.com/filecoin-project/lotus.git /lotus
cd /lotus
# 编译
env RUSTFLAGS="-C target-cpu=native -g" FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1 FIL_PROOFS_USE_GPU_TREE_BUILDER=1 FFI_BUILD_FROM_SOURCE=1 make clean all
make install

# nfs mount
mkdir -p /filecoin-proof-parameters
sudo mount -t nfs -o vers=4 192.168.81.100:/ /filecoin-proof-parameters
echo '192.168.81.100:/ /filecoin-proof-parameters nfs   defaults,timeo=900,retrans=5,_netdev  0 0' >> /etc/fstab

#lotus 环境变量
mkdir -p /lotus_daemon
cat >> ~/.bashrc << \EOF
export LOTUS_PATH=/lotus_daemon/
export LOTUS_STORAGE_PATH=/lotusstorage/
export FIL_PROOFS_PARAMETER_CACHE=/filecoin-proof-parameters/
export WORKER_PATH=/lotusworker/
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
export FIL_PROOFS_USE_GPU_TREE_BUILDER=1
TOKEN=
API=
export MINER_API_INFO=$TOKEN:$API
EOF
source ~/.bashrc

cp /filecoin-proof-parameters/lotus_daemon/api /lotus_daemon
cp /filecoin-proof-parameters/lotus_daemon/token /lotus_daemon

# supervisor



