# 服务端

yum install -y nfs-utils


mkdir -p /data/{ro,rw} 

# vim /etc/exports
# /home/nfs/ 192.168.248.0/24(rw,sync,fsid=0)
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