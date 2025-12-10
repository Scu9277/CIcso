#!/bin/bash

#当前目录
cpath=$(pwd)

ver=$(cat version)
echo $ver

#前端编译 仅需要执行一次
#bash ./build_web.sh

bash build_docker.sh

deploy="scu-sslvpn-deploy-$ver"
docker container rm $deploy
docker container create --name $deploy bjdgyc/anylink:$ver
rm -rf scu-sslvpn-deploy scu-sslvpn-deploy.tar.gz
docker cp -a $deploy:/app ./scu-sslvpn-deploy
tar zcf ${deploy}.tar.gz scu-sslvpn-deploy


./scu-sslvpn-deploy/scu-sslvpn -v


echo "scu-sslvpn 编译完成，目录: scu-sslvpn-deploy"
ls -lh scu-sslvpn-deploy


