#!/bin/bash

# 更换中科大源
sudo mv sources.list /etc/apt/sources.list.bak
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
cat > $HOME/.cargo/ <<EOF
[source.crates-io]
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -sSf | sh /dev/stdin "-y"
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
echo 'export GOPROXY=https://goproxy.cn' >> ~/.bashrc
EOF

source ~/.bashrc
# lotus

git clone -b ntwk-calibration https://github.com/filecoin-project/lotus.git /lotus
cd /lotus

# 编译
env RUSTFLAGS="-C target-cpu=native -g" FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1 FIL_PROOFS_USE_GPU_TREE_BUILDER=1 FFI_BUILD_FROM_SOURCE=1 make clean all
make install
# nfs mount
# supervisor



