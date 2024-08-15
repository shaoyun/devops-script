#!/bin/bash

# 默认使用Docker官方源
DOMAIN="download.docker.com"

# 检查参数
if [ "$1" == "cn" ]; then
  DOMAIN="mirrors.aliyun.com/docker-ce"
fi

SOURCE="https://${DOMAIN}/linux/debian"
GPG_KEY="${SOURCE}/gpg"

# 移除旧的Docker相关包
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
  sudo apt-get remove -y $pkg
done

# 添加Docker的GPG密钥
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL $GPG_KEY -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 添加Docker仓库到Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $SOURCE \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新包索引并安装Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 运行测试镜像
sudo docker run hello-world
