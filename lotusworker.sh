#!/bin/bash

function replace_source()
{
  # 更换中科大源
  sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
  cat > /etc/apt/sources.list << 'EOF'
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
}

function install_environment()
{
  # 依赖
  sudo apt -y install golang-go mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl nfs-common supervisor

  # rustc
  mkdir -p $HOME/.cargo/
  cat > $HOME/.cargo/config << 'EOF'
  [source.crates-io]
  replace-with = 'tuna'
  [source.tuna]
  registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
  EOF

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -sSf | sh /dev/stdin "-y"
  echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
  echo 'export GOPROXY=https://goproxy.cn' >> ~/.bashrc
  # source ~/.bashrc
  echo '环境安装成功,请执行 source ~/.bashrc '
}

function install_lotus()
{
  # lotus
  cd /
  git clone -b ntwk-calibration-8.1.0 https://gitclone.com/github.com/filecoin-project/lotus.git
  cd /lotus
  git checkout -b ntwk-calibration-8.1.0
  # 编译
  env RUSTFLAGS="-C target-cpu=native -g" FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1 FIL_PROOFS_USE_GPU_TREE_BUILDER=1 FFI_BUILD_FROM_SOURCE=1 make clean all
  make install
  echo 'lotus安装成功'
}

function set_lotus()
{
  #lotus 环境变量
  mkdir -p /lotus_daemon
  read -p "请输入daemon token" d_token
  read -p "请输入daemon api" d_api
  echo '$d_token' > /lotus_daemon/token
  echo '$d_api' > /lotus_daemon/api
  echo 'daemon 设置成功'
  
  read -p "请输入miner token" i_token
  read -p "请输入miner api" i_api
  cat >> ~/.bashrc << \'EOF'
  export LOTUS_PATH=/lotus_daemon/
  # export LOTUS_STORAGE_PATH=/lotusstorage/
  export FIL_PROOFS_PARAMETER_CACHE=/proof
  export WORKER_PATH=/lotusworker/
  # export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
  # export FIL_PROOFS_USE_GPU_TREE_BUILDER=1
  export FIL_PROOFS_MAXIMIZE_CACHING=1
  export MINER_API_INFO=$i_token:$i_api
  EOF
  
  # worker
  cat > /etc/supervisor/conf.d/lotusminer.conf << 'EOF'
  [program:lotus_worker]
  environment=LOTUS_PATH=/lotus_daemon,WORKER_PATH=/lotusworker,FIL_PROOFS_PARAMETER_CACHE=/proof,FIL_PROOFS_USE_GPU_TREE_BUILDER=1,MINER_API_INFO=$i_token:$i_api,FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1,FIL_PROOFS_MAXIMIZE_CACHING=1,RUST_LOG=Trace
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

  read -p "是否开启GPU支持?[y/n]" input
  case $input in
    y|Y)
        echo 'export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1' >> ~/.bashrc
        echo 'export FIL_PROOFS_USE_GPU_TREE_BUILDER=1' >> ~/.bashrc
    ;;
    [nN]*)
      cat > /etc/supervisor/conf.d/lotusminer.conf << 'EOF'
        [program:lotus_worker]
        environment=LOTUS_PATH=/lotus_daemon,WORKER_PATH=/lotusworker,FIL_PROOFS_PARAMETER_CACHE=/proof,MINER_API_INFO=$i_token:$i_api,FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1,FIL_PROOFS_MAXIMIZE_CACHING=1,RUST_LOG=Trace
        directory=/lotus/
        command=/lotus/lotus-worker --enable-gpu-proving=false run
        autostart=true
        autorestart=true
        startsecs=3
        startretries=100
        redirect_stderr=true
        stdout_logfile = /lotusworker/lotusworker.log
        loglevel=info
      EOF
    ;;
    *)
        echo "Just input y or n,please"
        exit 1
    ;;
  esac
  echo 'lotus配置完成,请执行 source ~/.bashrc ,后运行lotus-miner测试'
}

function menu()
{
    cat <<eof
    
 *************************************
*                MENU                  *

*   1.更换中科大源        2.安装环境    *

*   3.安装lotus          4.配置lotus      *

*   5.exit                 *


 *************************************
eof
}

function usage()
{
    read -p "please input your choice: " choice
    case $choice in
        1)
            replace_source
            ;;
        2)
            install_environment
            ;;
        3)
            install_lotus
            ;;
        4)
            set_lotus
            ;;
        5)
            exit 0
            ;;

    esac
}

function  main()
{
  while true
    do
      menu
      usage
    done
}

main
