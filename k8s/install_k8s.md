### centos7.9系统 主机为aws EC2 .使用的网络模型为Calico

##########################################################
### 1.做好服务器规划，初始化系统，例如，master 节点 ,node 节点  ,yum update ，yum upgrade 等操作
### 关闭 selinux firewalld ,开启iptables ,规则为空
yum -y update
yum -y install vim wget

timedatectl status
timedatectl set-timezone Asia/Shanghai

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

### 历史命令格式化
cat << 'EOF' >> /etc/bashrc
export HISTFILE=/var/log/.history_log
export HISTSIZE=5000
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S `who am i | awk '{print $1,$5}'` "
export HISTCONTROL=ignoredups 
EOF

source /etc/bashrc

### sys kernel conf
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

### 文件数限制

cat  << 'EOF' >> /etc/security/limits.conf 
root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
EOF

### 重启

#########################
### 1.2修改主机名
#master
hostnamectl set-hostname master
#node1
hostnamectl set-hostname node1
#node2
hostnamectl set-hostname node2

### 1.3 编辑hosts
 #根据内网IP，配置master和node IP
echo '''
172.31.11.32  master
172.31.8.32   node1
172.31.13.161 node2
172.31.6.90   node3
''' >> /etc/hosts
### 根据需要配置ntpdate 时间服务器
### 1.4 安装ntpdate并同步时间
yum -y install ntpdate
ntpdate ntp1.aliyun.com
systemctl start ntpdate
systemctl enable ntpdate
systemctl status ntpdate

### 1.5 安装并配置 bash-completion，添加命令自动补充
yum -y install bash-completion
source /etc/profile

### 1.6 关闭防火墙
systemctl stop firewalld.service 
systemctl disable firewalld.service

### 1.7 关闭selinux
sed -i 's/enforcing/disabled/' /etc/selinux/config  # 永久关闭

### 1.8 关闭 swap
free -h
sudo swapoff -a
sudo sed -i 's/.*swap.*/#&/' /etc/fstab
free -h

## 二：安装k8s 1.26.x
### 2.1 安装 Containerd
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

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
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

# ====================================================================================
# install helm 
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

[root@master ingress-nginx]# helm version
version.BuildInfo{Version:"v3.13.1", GitCommit:"3547a4b5bf5edb5478ce352e18858d8a552a4110", GitTreeState:"clean", GoVersion:"go1.20.8"}

# install ingress-nginx
   helm install   ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx  --create-namespace  \
   --set controller.kind="Deployment"    \
   --set controller.replicaCount="3"    \
   --set controller.minAvailable="1"    \
   --set controller.ingressClassResource.name="nginx"    \
   --set controller.ingressClassResource.enable="true"    \
   --set controller.ingressClassResource.default="false"   \
   --set controller.service.enabled="true"    \
   --set controller.service.type="NodePort"    \
   --set controller.service.enableHttps="true"    \
   --set controller.admissionWebhooks.enabled="true"    \
   --set controller.metrics.enabled="true"    \
   --set-string controller.podAnnotations."prometheus\.io/scrape"="true"    \
   --set-string controller.podAnnotations."prometheus\.io/port"="10254"    \
   --set defaultBackend.enabled="true"    \
   --set defaultBackend.name="defaultbackend"    \
   --set defaultBackend.replicaCount="1"    \
   --set defaultBackend.minAvailable="1"    \
   --set serviceAccount.create="true"   \
   --set rbac.create="true"   \
   --set podSecurityPolicy.enabled="true"

  #  helm install   ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx \
  #  --set controller.kind="Deployment"    \
  #  --set controller.replicaCount="3"    \
  #  --set controller.minAvailable="1"    \
  #  --set controller.ingressClassResource.name="nginx"    \
  #  --set controller.ingressClassResource.enable="true"    \
  #  --set controller.ingressClassResource.default="false"   \
  #  --set controller.service.enabled="true"    \
  #  --set controller.service.type="NodePort"    \
  #  --set controller.service.enableHttps="true"    \
  #  --set controller.service.nodePorts.http="80"    \
  #  --set controller.service.nodePorts.https="443"    \
  #  --set controller.admissionWebhooks.enabled="true"    \
  #  --set controller.metrics.enabled="true"    \
  #  --set-string controller.podAnnotations."prometheus\.io/scrape"="true"    \
  #  --set-string controller.podAnnotations."prometheus\.io/port"="10254"    \
  #  --set defaultBackend.enabled="true"    \
  #  --set defaultBackend.name="defaultbackend"    \
  #  --set defaultBackend.replicaCount="1"    \
  #  --set defaultBackend.minAvailable="1"    \
  #  --set rbac.create="true"   \
  #  --set serviceAccount.create="true"   \
  #  --set podSecurityPolicy.enabled="true"


# install cert-manage
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml



helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.13.3 --set installCRDs=true \
   --set ingressShim.defaultIssuerName=letsencrypt-prod \
   --set ingressShim.defaultIssuerKind=ClusterIssuer \
   --set ingressShim.defaultIssuerGroup=cert-manager.io


[root@master cert-manager]# cat letsencrypt-cluster-issuer.yaml 
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cluster-issuer
spec:
  acme:
    email: hd900415@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-cluster-issuer-key
    solvers:
    - http01:
        ingress:
          class: nginx


# 4. 测试 Let's Encrypt 证书申请
# 创建一个测试证书申请，看看是否能够通过 HTTP-01 挑战：
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-cluster-issuer
    kind: ClusterIssuer
  commonName: yourdomain.com
  dnsNames:
  - yourdomain.com
# 将 yourdomain.com 替换为您的实际域名。

# 5. 监控和调试
# 监控 cert-manager 的日志和状态，确保证书能够成功签发：
# kubectl describe certificate example-com
# 如果出现问题，检查 cert-manager 和 ingress 控制器的日志，以便找到并解决问题。


配置 Ingress 资源
创建一个 ingress 资源，确保它可以正确路由到您的服务。例如，为一个名为 example-service 的服务创建一个基本的 ingress 资源：
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
这个资源将所有指向 yourdomain.com 的 HTTP 请求路由到 example-service。

3. 确保 Ingress 适用于 HTTP-01 挑战
cert-manager 会自动创建临时的 ingress 资源来响应 Let's Encrypt 的 HTTP-01 挑战。您已经通过之前的 ClusterIssuer 配置指示 cert-manager 使用 HTTP-01 挑战，所以一般情况下无需进一步配置。

4. 测试 Let's Encrypt 证书申请
创建一个测试证书申请，看看是否能够通过 HTTP-01 挑战：
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-cluster-issuer
    kind: ClusterIssuer
  commonName: yourdomain.com
  dnsNames:
  - yourdomain.com
将 yourdomain.com 替换为您的实际域名。


监控和调试
监控 cert-manager 的日志和状态，确保证书能够成功签发：
kubectl describe certificate example-com

如果出现问题，检查 cert-manager 和 ingress 控制器的日志，以便找到并解决问题。

# install kubernetes-dashaboard
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
--output
# Release "kubernetes-dashboard" does not exist. Installing it now.
# NAME: kubernetes-dashboard
# LAST DEPLOYED: Thu Jan 11 22:22:56 2024
# NAMESPACE: kubernetes-dashboard
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# *********************************************************************************
# *** PLEASE BE PATIENT: kubernetes-dashboard may take a few minutes to install ***
# *********************************************************************************

# Get the Kubernetes Dashboard URL by running:
#   export POD_NAME=$(kubectl get pods -n kubernetes-dashboard -l "app.kubernetes.io/name=kubernetes-dashboard,app.kubernetes.io/instance=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}")
#   echo https://127.0.0.1:8443/
#   kubectl -n kubernetes-dashboard port-forward $POD_NAME 8443:8443

# 如果您想从 Kubernetes 集群外部访问仪表板，请使用 NodePort 类型公开 Kubernetes 仪表板部署，如下所示：
kubectl expose deployment kubernetes-dashboard --name k8s-svc --type NodePort --port 8443 -n kubernetes-dashboard
# 获取svc端口
kubectl get svc -n kubernetes-dashboard
# NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
# k8s-svc                NodePort    10.107.17.49   <none>        8443:30638/TCP   45s
# kubernetes-dashboard   ClusterIP   10.110.81.78   <none>        443/TCP          22m

4)  Generate Token for Kubernetes Dashboard 生成token 
vi k8s-dashboard-account.yaml
'''
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
'''
应用 
kubectl create -f k8s-dashboard-account.yaml
kubectl -n kube-system create token admin-user

#  参考文档
https://www.linuxtechi.com/how-to-install-kubernetes-dashboard/



















