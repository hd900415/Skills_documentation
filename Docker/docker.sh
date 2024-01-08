# 安装docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 安装软件包
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl start docker

# 安装docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# 安装harbor
# 下载在线安装包

# GitHub 地址  https://github.com/goharbor/harbor/releases 
mkdir /data/harbor && cd /data/harbor
wget https://github.com/goharbor/harbor/releases/download/v2.9.1/harbor-online-installer-v2.9.1.tgz
# 
tar xf harbor-online-installer-v2.9.1.tgz

cd /data/harbor 
cp harbor.yml.tmpl harbor.yml

# 更改配置文件，
1. 更改hostname
=========================================================================================
# Configuration file of Harbor

# The IP address or hostname to access admin UI and registry service.
# DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
hostname: harbor.galaxymeeting.live ------------------ #更改域名

# http related config
http:
  # port for http, default is 80. If https enabled, this port will redirect to https port
  port: 80

# https related config
https:
  # https port for harbor, default is 443
  port: 443
  # The path of cert and key files for nginx
  certificate: /data/harbor/ssl/galaxymeeting.live.cer  # 购买证书部署位置
  private_key: /data/harbor/ssl/galaxymeeting.live.key  

------更改数据存储位置
# The default data volume
data_volume: /data/harbor
=========================================================================================
2.可以使用acme.sh 进行证书申请

# 安装 
./install.sh --help
# 
./install.sh --with-trivy

# 配置docker https访问
cat /etc/docker/daemon.json 
{
  "live-restore": true,
  "group": "dockerroot",
  "insecure-registries": ["https://harbor.galaxymeeting.live"]
}




















