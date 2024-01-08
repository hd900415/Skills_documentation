# 添加helm源
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
# 安装nfs驱动
helm install nfs  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set storageClass.name=storageclass1 --set nfs.server=172.31.8.80 --set nfs.path=/data/rw --set storageClass.defaultClass=true -n nfs-sc-default
# 解释
# helm install nfs  \                                      #helm的名字
# nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \    #源地址名字
# --set storageClass.name=storageclass1 \                  #storageclass名字
# --set nfs.server=10.0.0.160 \                            #nfs服务器地址
# --set nfs.path=/mnt/jenkins \                            #nfs共享目录
# --set storageClass.defaultClass=true \                   #默认
# -n nfs-sc-default  



helm install grafana grafana/grafana \
  --namespace monitoring \
  --set datasources."datasources\.yaml".apiVersion=1 \
  --set datasources."datasources\.yaml".datasources[0].name=Prometheus \
  --set datasources."datasources\.yaml".datasources[0].type=prometheus \
  --set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server.monitoring.svc.cluster.local \
  --set datasources."datasources\.yaml".datasources[0].access=proxy \
  --set persistence.enabled=true \
  --set persistence.storageClassName="storageclass1" \
  --set persistence.size=5Gi
