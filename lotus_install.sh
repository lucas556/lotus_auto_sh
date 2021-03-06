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
cd /
git clone -b ntwk-calibration-8.1.0 https://gitclone.com/github.com/filecoin-project/lotus.git
cd /lotus
git checkout -b ntwk-calibration-8.1.0
# 编译
env RUSTFLAGS="-C target-cpu=native -g" FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1 FIL_PROOFS_USE_GPU_TREE_BUILDER=1 FFI_BUILD_FROM_SOURCE=1 make clean all
make install

# nfs mount
# mkdir -p /filecoin-proof-parameters
# sudo mount -t nfs -o vers=4 192.168.81.100:/ /filecoin-proof-parameters
# echo '192.168.81.100:/ /filecoin-proof-parameters nfs   defaults,timeo=900,retrans=5,_netdev  0 0' >> /etc/fstab

#lotus 环境变量
mkdir -p /lotus_daemon
cat >> ~/.bashrc << \EOF
export LOTUS_PATH=/lotus_daemon/
export LOTUS_STORAGE_PATH=/lotusstorage/
export FIL_PROOFS_PARAMETER_CACHE=/filecoin-proof-parameters/
export WORKER_PATH=/lotusworker/
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
export FIL_PROOFS_USE_GPU_TREE_BUILDER=1
export FIL_PROOFS_MAXIMIZE_CACHING=1
TOKEN=
API=
export MINER_API_INFO=$TOKEN:$API
EOF
source ~/.bashrc

cp /filecoin-proof-parameters/lotus_daemon/api /lotus_daemon
cp /filecoin-proof-parameters/lotus_daemon/token /lotus_daemon

/lotus/lotus new wallet bls  # 创建挖矿账户
# 水龙头地址: https://faucet.calibration.fildev.network/miner.html
# 如果是miner 初始化矿工
# /lotus/lotus-miner init --owner=t3w6pa5srdttgep6lifglec6zceq47xd5k7wjdwbi3h3wmnwwybdckva3enyiof3nbtwtumbh3im72quxsg5fa --sector-size=32GiB
# /lotus/lotus-miner init --actor=t023871 --owner=t3xbnqjt2ulvohp63obag77kaqheobyo3ypxgyre6smomojc43bsytkbqtx75awsxgj2frnbduelbfqyoa4dgq --sector-size=32GiB

cat > /etc/supervisor/conf.d/lotusminer.conf <<EOF
[program:lotus_miner]
environment=LOTUS_PATH=/lotus_daemon,LOTUS_STORAGE_PATH=/lotusstorage,FIL_PROOFS_PARAMETER_CACHE=/filecoin-proof-parameters,FIL_PROOFS_USE_GPU_TREE_BUILDER=1,FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1,FIL_PROOFS_MAXIMIZE_CACHING=1,RUST_LOG=Trace
directory=/lotus/
command=/lotus/lotus-miner run
autostart=true
autorestart=true
startsecs=3
startretries=100
redirect_stderr=true
stdout_logfile = /lotusstorage/lotusminer.log
loglevel=info
EOF

# worker
cat > /etc/supervisor/conf.d/lotusminer.conf <<EOF
[program:lotus_worker]
environment=LOTUS_PATH=/lotus_daemon,WORKER_PATH=/lotusworker,FIL_PROOFS_PARAMETER_CACHE=/proof,MINER_API_INFO=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBbGxvdyI6WyJyZWFkIiwid3JpdGUiLCJzaWduIiwiYWRtaW4iXX0.1Np4OEDgLcNPNH7LZDMk6aXvJZuih393mu6EiMWo8H0:/ip4/192.168.81.11/tcp/2255/http,FIL_PROOFS_USE_GPU_TREE_BUILDER=1,FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1,FIL_PROOFS_MAXIMIZE_CACHING=1,RUST_LOG=Trace
directory=/lotus/
command=/lotus/lotus-worker run
autostart=true
autorestart=true
startsecs=3
startretries=100
redirect_stderr=true
stdout_logfile = /lotusworker/lotusworker.log
loglevel=info
EOF


supervisorctl reread
supervisorctl update
# supervisor
# 设置SWAP
sudo dd if=/dev/zero of=/swap bs=1G count=128
sudo chmod 600 /swap
sudo mkswap /swap
sudo swapon /swap

# 显卡驱动
sudo apt-get -y install ubuntu-drivers-common
sudo ubuntu-drivers autoinstall
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda-repo-ubuntu1804-10-2-local-10.2.89-440.33.01_1.0-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1804-10-2-local-10.2.89-440.33.01_1.0-1_amd64.deb
sudo apt-key add /var/cuda-repo-10-2-local-10.2.89-440.33.01/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda

