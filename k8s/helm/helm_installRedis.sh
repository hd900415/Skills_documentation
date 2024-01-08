# 参数文档参考https://artifacthub.io/packages/helm/bitnami/redis

helm repo add bitnami https://charts.bitnami.com/bitnami

helm install redis bitnami/redis  \
    --namespace redis --create-namespace \
    --set global.redis.password="123456" \
    --set global.storageClass="storageclass1" \


[root@k8s-master redis]# helm install redis bitnami/redis  \
>     --namespace redis --create-namespace \
>     --set global.redis.password="123456" \
>     --set global.storageClass="storageclass1" \
> 
NAME: redis
LAST DEPLOYED: Thu Dec 14 21:21:17 2023
NAMESPACE: redis
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: redis
CHART VERSION: 18.5.0
APP VERSION: 7.2.3

** Please be patient while the chart is being deployed **

Redis&reg; can be accessed on the following DNS names from within your cluster:

    redis-master.redis.svc.cluster.local for read/write operations (port 6379)
    redis-replicas.redis.svc.cluster.local for read-only operations (port 6379)



To get your password run:

    export REDIS_PASSWORD=$(kubectl get secret --namespace redis redis -o jsonpath="{.data.redis-password}" | base64 -d)

To connect to your Redis&reg; server:

1. Run a Redis&reg; pod that you can use as a client:

   kubectl run --namespace redis redis-client --restart='Never'  --env REDIS_PASSWORD=$REDIS_PASSWORD  --image docker.io/bitnami/redis:7.2.3-debian-11-r1 --command -- sleep infinity

   Use the following command to attach to the pod:

   kubectl exec --tty -i redis-client \
   --namespace redis -- bash

2. Connect using the Redis&reg; CLI:
   REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h redis-master
   REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h redis-replicas

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace redis svc/redis-master 6379:6379 &
    REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h 127.0.0.1 -p 6379


# ============----------------------------------------更新

helm upgrade  redis bitnami/redis  \
    --namespace redis --create-namespace \
    --set global.redis.password="facai555" \
    --set global.storageClass="storageclass1" \
    --set image.pullPolicy="IfNotPresent" \
    --set master.coun="3"