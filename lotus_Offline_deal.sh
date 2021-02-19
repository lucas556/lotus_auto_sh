#!/bin/bash


for line in $(cat fil.txt)
do
  echo '设置默认账户为:'$line
  /lotus/lotus wallet set-default $line
  proof_name=proof_${line:0:8}
  echo '生成随机文件'
  sudo dd if=/dev/random of=/$proof_name bs=1G count=7.6
  echo '生成证书'
  /lotus/lotus client generate-car /$proof_name /lotusdaemon/$proof_name.car
  rm -rf /$proof_name
  echo '生成cid'
  /lotus/lotus client commP /lotusdaemon/$proof_name.car | sed -n '1p' | cut -d \: -f 2 > cid.txt
  cid=$(cat cid.txt | sed 's/^[ \t]*//g')
  echo 'cid:'$cid
  echo '生成离线交易'
  /lotus/lotus client deal --manual-piece-cid=$cid --manual-piece-size=8522825728 $cid f061158 0 520553 > deal.txt
  sleep 5
  echo 'miner导入交易'
  deal=$(cat deal.txt)
  echo 'deal_cid:'$deal
  lotus-miner storage-deals import-data $deal /lotusdaemon/$proof_name.car
  sleep 5
done
