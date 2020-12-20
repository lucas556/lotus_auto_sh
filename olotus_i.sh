#!/bin/bash

echo "更新源开始"
sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
cat > /etc/apt/sources.list << EOF
##阿里源
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
apt-get update

echo "更新源成功"

echo "安装依赖"

sudo apt -y install mesa-opencl-icd ocl-icd-opencl-dev gcc make clang git bzr jq pkg-config llvm curl nfs-common supervisor hwloc libhwloc-dev ntpdate ubuntu-drivers-common
echo "安装成功"

echo "部署环境"
# time adjust
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate ntp.aliyun.com

# install ulimit
ulimit -n 1048576
sed -i "/nofile/d" /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "root hard nofile 1048576" >> /etc/security/limits.conf
echo "root soft nofile 1048576" >> /etc/security/limits.conf

sysctl vm.dirty_bytes=53687091200
sed -i "/dirty_bytes/d" /etc/sysctl.conf
echo "vm.dirty_bytes=53687091200" >> /etc/sysctl.conf

sysctl vm.dirty_background_bytes=10737418240
sed -i "/dirty_background_bytes/d" /etc/sysctl.conf
echo "vm.dirty_background_bytes=10737418240" >> /etc/sysctl.conf

sysctl vm.vfs_cache_pressure=1000
sed -i "/vfs_cache_pressure/d" /etc/sysctl.conf
echo "vm.vfs_cache_pressure=1000" >> /etc/sysctl.conf

sysctl vm.dirty_writeback_centisecs=100
sed -i "/dirty_writeback_centisecs/d" /etc/sysctl.conf
echo "vm.dirty_writeback_centisecs=100" >> /etc/sysctl.conf

sysctl vm.dirty_expire_centisecs=100
sed -i "/dirty_expire_centisecs/d" /etc/sysctl.conf
echo "vm.dirty_expire_centisecs=100" >> /etc/sysctl.conf

echo "设置SWAP"
sudo dd if=/dev/zero of=/swap bs=1G count=64
sudo chmod 600 /swap
sudo mkswap /swap
sudo swapon /swap
echo "swap修改完成,在/etc/fstab修改开机启动并重启"
echo "设置SWAP"

scp -r lucas@192.168.20.91:/lotus /
cp /lotus/* /usr/local/bin/
scp -r lucas@192.168.20.91:/lotusdaemon /
scp -r lucas@192.168.20.91:/proof /

scp lucas@192.168.20.91:/NVIDIA-Linux-x86_64-455.45.01.run ./

  cat >> ~/.bashrc << 'EOF'
export LOTUS_PATH=/lotusdaemon
export LOTUS_MINER_PATH=/lotusminer
export LOTUS_WORKER_PATH=/lotusworker
export FIL_PROOFS_PARAMETER_CACHE=/proof
export MINER_API_INFO=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBbGxvdyI6WyJyZWFkIiwid3JpdGUiLCJzaWduIiwiYWRtaW4iXX0._W3EuCHVFw1qdye3GBVnHRig0La3xTZvAKRIhvigswY:/ip4/192.168.20.21/tcp/2021/http
export IPFS_GATEWAY="https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/
EOF


  cat >> /etc/supervisor/conf.d/lotusworker.conf << 'EOF'
[program:lotusworker]
environment=LOTUS_PATH=/lotusdaemon,WORKER_PATH=/lotusworker,FIL_PROOFS_PARAMETER_CACHE=/proof,MINER_API_INFO=:/ip4/192.168.20.21/tcp/2021/http,FIL_PROOFS_USE_GPU_TREE_BUILDER=1,FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1,FIL_PROOFS_SDR_PARENTS_CACHE_SIZE=1073741824,RUST_LOG=Trace
directory=/lotus/
command=/lotus/lotus-worker run --listen=192.168.20.91:2091 --attach /lotus_attach
autostart=true
autorestart=true
startsecs=3
startretries=100
redirect_stderr=true
stdout_logfile = /lotusworker/lotusworker.log
loglevel=info
EOF

mkdir -p /lotusworker
mkdir -p /lotus_attach

