#!/bin/bash
# centos7.9系统 主机为aws EC2 .使用的网络模型为Calico

##########################################################
# 1.做好服务器规划，初始化系统，例如，master 节点 ,node 节点  ,yum update ，yum upgrade 等操作
# 关闭 selinux firewalld ,开启iptables ,规则为空
yum -y update
yum -y install vim wget

timedatectl status
timedatectl set-timezone Asia/Shanghai

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

# 历史命令格式化
cat << 'EOF' >> /etc/bashrc
export HISTFILE=/var/log/.history_log
export HISTSIZE=5000
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S `who am i | awk '{print $1,$5}'` "
export HISTCONTROL=ignoredups 
EOF

source /etc/bashrc

# sys kernel conf
cat << 'EOF' > /etc/sysctl.conf 
vm.swappiness = 0
kernel.sysrq = 1
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2
#net.ipv4.tcp_max_tw_buckets = 5000
#net.ipv4.tcp_syncookies = 1
#net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_slow_start_after_idle = 0
#fs.file-max = 999999
#net.ipv4.tcp_tw_reuse = 1
#net.ipv4.tcp_keepalive_time = 600
#net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
net.core.netdev_max_backlog = 8096
net.core.rmem_default = 6291456
net.core.wmem_default = 6291456
net.core.rmem_max = 12582912
net.core.wmem_max = 12582912
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_recycle = 1
#net.core.somaxconn=262114
net.core.somaxconn=65535
net.ipv4.tcp_max_orphans=262114
fs.file-max = 999999
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_fin_timeout = 30
EOF

sysctl -p

# 文件数限制

cat  << 'EOF' >> /etc/security/limits.conf 
root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
EOF

# 重启

#########################
# 1.2修改主机名
#master
hostnamectl set-hostname master
#node1
hostnamectl set-hostname node1
#node2
hostnamectl set-hostname node2

# 1.3 编辑hosts
 #根据内网IP，配置master和node IP

172.31.0.64    master
172.31.15.134   master

172.31.43.70    node1
172.31.37.229   node1

172.31.24.189   node2

# 根据需要配置ntpdate 时间服务器
# 1.4 安装ntpdate并同步时间
yum -y install ntpdate
ntpdate ntp1.aliyun.com
systemctl start ntpdate
systemctl enable ntpdate
systemctl status ntpdate

# 1.5 安装并配置 bash-completion，添加命令自动补充
yum -y install bash-completion
source /etc/profile

# 1.6 关闭防火墙
systemctl stop firewalld.service 
systemctl disable firewalld.service

# 1.7 关闭selinux
sed -i 's/enforcing/disabled/' /etc/selinux/config  # 永久关闭

# 1.8 关闭 swap
free -h
sudo swapoff -a
sudo sed -i 's/.*swap.*/#&/' /etc/fstab
free -h

# 二：安装k8s 1.26.x
# 2.1 安装 Containerd
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 
sudo yum install -y containerd.io

systemctl stop containerd.service

cp /etc/containerd/config.toml /etc/containerd/config.toml.bak
sudo containerd config default > $HOME/config.toml
sudo cp $HOME/config.toml /etc/containerd/config.toml
# 修改 /etc/containerd/config.toml 文件后，要将 docker、containerd 停止后，再启动
# 一般不需要更改
sudo sed -i "s#registry.k8s.io/pause#registry.cn-hangzhou.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml
# https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/#containerd-systemd
# 确保 /etc/containerd/config.toml 中的 disabled_plugins 内不存在 cri
sudo sed -i "s#SystemdCgroup = false#SystemdCgroup = true#g" /etc/containerd/config.toml

#启动containerd
systemctl start containerd.service
systemctl status containerd.service

# 2.2 添加 k8s 镜像仓库
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.27/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.27/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl
EOF

# 2.3 将桥接的 IPv4 流量传递到 iptables 的链
# 设置所需的 sysctl 参数，参数在重新启动后保持不变
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# 应用 sysctl 参数而不重新启动
sudo sysctl --system

# 启动br_netfilter
modprobe br_netfilter
echo 1 > /proc/sys/net/ipv4/ip_forward

# 2.4 安装k8s 
# 可以安装1.24.0-1.26.3版本,本文使用1.26.0
# sudo yum install -y kubelet-1.24.0-0 kubeadm-1.24.0-0 kubectl-1.24.0-0 --disableexcludes=kubernetes --nogpgcheck


#sudo yum install -y kubelet-1.25.3-0 kubeadm-1.25.3-0 kubectl-1.25.3-0 --disableexcludes=kubernetes --nogpgcheck

# 2022-11-18，经过测试，版本号：1.25.4
# sudo yum install -y kubelet-1.25.4-0 kubeadm-1.25.4-0 kubectl-1.25.4-0 --disableexcludes=kubernetes --nogpgcheck

# 2023-02-07，经过测试，版本号：1.25.5，
# sudo yum install -y kubelet-1.25.5-0 kubeadm-1.25.5-0 kubectl-1.25.5-0 --disableexcludes=kubernetes --nogpgcheck

# 2023-02-07，经过测试，版本号：1.25.6，
# sudo yum install -y kubelet-1.25.6-0 kubeadm-1.25.6-0 kubectl-1.25.6-0 --disableexcludes=kubernetes --nogpgcheck

# 2023-02-07，经过测试，版本号：1.26.0，
# sudo yum install -y kubelet-1.26.0-0 kubeadm-1.26.0-0 kubectl-1.26.0-0 --disableexcludes=kubernetes --nogpgcheck

# 2023-02-07，经过测试，版本号：1.26.1，
# sudo yum install -y kubelet-1.26.1-0 kubeadm-1.26.1-0 kubectl-1.26.1-0 --disableexcludes=kubernetes --nogpgcheck

# 2023-03-02，经过测试，版本号：1.26.2，
# sudo yum install -y kubelet-1.26.2-0 kubeadm-1.26.2-0 kubectl-1.26.2-0 --disableexcludes=kubernetes --nogpgcheck

sudo yum install -y kubelet-1.26.3-0 kubeadm-1.26.3-0 kubectl-1.26.3-0 --disableexcludes=kubernetes --nogpgcheck

systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl enable kubelet

# 2.5 初始化,只需要在master节点

kubeadm init \
 --apiserver-advertise-address=172.31.10.28 \
# 更改apiserver 为master节点

# 此处会有执行结果输出，根据输出执行对应的命令


# master节点执行
export KUBECONFIG=/etc/kubernetes/admin.conf

# 从节点执行
kubeadm join 192.168.19.135:6443 --token i7w5xr.u3t483h07aksnzg6 \
	--discovery-token-ca-cert-hash sha256:04defa4d856cb5bcfe7ad0c3f2d71aa7d48e6c27e4e5821336db00c1e4bf7464

# 将 export KUBECONFIG=/etc/kubernetes/admin.conf 写入到 .bashrc 中，防止终端重启后报错
cd ~
vim .bashrc
# 新增以下内容

echo "export KUBECONFIG=/etc/kubernetes/admin.conf " >>/root/.bashrc

# 如果清屏可以在master执行以下命令,查看master节点初始化token
kubeadm token create --print-join-command

# 2.6 master查看状态
# 查看节点：
kubectl get node

# 2.7 maste节点配置网络,使用Calico
# 下载
wget --no-check-certificate https://projectcalico.docs.tigera.io/archive/v3.25/manifests/calico.yaml
# 修改 calico.yaml 文件
vim calico.yaml
# 在 - name: CLUSTER_TYPE 下方添加如下内容
- name: CLUSTER_TYPE
  value: "k8s,bgp"
  # 下方为新增内容
- name: IP_AUTODETECTION_METHOD
  value: "interface=网卡名称"
  # INTERFACE_NAME=ens33
# 配置网络
kubectl apply -f calico.yaml

#需要等待几分钟,再次查看pods,nodes,如下图状态为 Ready


# 三、创建服务 
# 创建命名空间

# 四。新增节点
# 在主节点上生成加入令牌
# 在控制平面（主）节点上运行 kubeadm token create --print-join-command

# 这个命令会生成一个 kubeadm join 命令，其中包含了加入集群所需的令牌和证书哈希。这个命令应该类似于这样：

kubeadm join <master-node-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# 在新的工作节点上运行加入命令
# 在新的工作节点上运行上一步生成的 kubeadm join 命令

# 确保工作节点能够访问主节点的 6443 端口。运行加入命令后，工作节点会开始下载所需的容器镜像，配置本地 Kubernetes 组件，然后加入到集群中。

# 在主节点上验证新节点的状态

# 运行以下命令来查看所有节点的状态：
kubectl get nodes




















