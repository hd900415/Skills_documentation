# k8s 1.24版本之后，已经废弃的字段配置中包含RemoveSelfLink 参考https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/#feature-gates-for-graduated-or-deprecated-features
#需要使用新的方法使用nfs 自动创建pvc 和pv 在使用helm 进行部署的时候。

# 先部署NFS系统
# 服务端

yum install -y nfs-utils


mkdir -p /data/{ro,rw} 

vim /etc/exports
/home/nfs/ 192.168.248.0/24(rw,sync,fsid=0)
# 或者使用如下配置文件
### 配置文件
cat /etc/exports
/data/ro        172.31.0.0/16(ro,sync,no_root_squash,no_all_squash)
/data/rw        172.31.0.0/16(rw,sync,no_root_squash,no_all_squash)
/data: 共享目录位置。
# 192.168.0.0/24: 客户端 IP 范围，* 代表所有，即没有限制。
# rw: 权限设置，可读可写。
# sync: 同步共享目录。
# no_root_squash: 可以使用 root 授权。
# no_all_squash: 可以使用普通用户授权。


###


systemctl enable rpcbind.service
systemctl start rpcbind.service

systemctl enable nfs-server.service
systemctl start nfs-server.service


# 客户端
yum install -y nfs-utils

systemctl enable rpcbind.service
systemctl start rpcbind.service

showmount -e 192.168.248.208(服务端IP)  查看 是否有权限

[root@k8s-node3 data]#  showmount -e localhost
Export list for localhost:
/data/rw 172.31.0.0/16
/data/ro 172.31.0.0/16

# 挂载命令
创建挂载点
mkdir -p /mnt/{rw,ro}
mount -t nfs 172.31.8.80:/data/rw /mnt/rw/
mount -t nfs 172.31.8.80:/data/ro /mnt/ro

# 添加开机启动
[root@k8s-master mnt]# echo  "mount -t nfs 172.31.8.80:/data/rw /mnt/rw/" >>/etc/rc.d/rc.local 
[root@k8s-master mnt]# echo "mount -t nfs 172.31.8.80:/data/ro /mnt/ro" >>/etc/rc.d/rc.local 
[root@k8s-master mnt]# chmod +x /etc/rc.d/rc.local 

# helm 部署nfs-subdir-external-provisioner 并设置为default

1. helm添加 库
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

2.应用新的helm
# helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
#     --set nfs.server=172.31.3.204 \
#     --set nfs.path=/data/k8snfs \
#     --set storageClass.name=nfs-storage \
#     --set storageClass.defaultClass=true


helm install nfs  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set storageClass.name=storageclass1 \
    --set nfs.server=172.31.6.90 \
    --set nfs.path=/data/rw \
    --set storageClass.defaultClass=true \
    --namespace ingress-nginx  --create-namespace