root@ai-work-nginx-h5-ldy:~# helm install redisalone --set auth.password=password123456 --set  architecture=standalone --set  auth.enabled=true --set master.persistence.enabled=false --set master.persistence.medium=Memory --set master.persistence.sizeLimit=1Gi bitnami/redis
NAME: redisalone
LAST DEPLOYED: Fri Oct 27 18:36:27 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: redis
CHART VERSION: 18.2.0
APP VERSION: 7.2.2

** Please be patient while the chart is being deployed **

Redis&reg; can be accessed via port 6379 on the following DNS name from within your cluster:

    redisalone-master.default.svc.cluster.local



To get your password run:

    export REDIS_PASSWORD=$(kubectl get secret --namespace default redisalone -o jsonpath="{.data.redis-password}" | base64 -d)

To connect to your Redis&reg; server:

1. Run a Redis&reg; pod that you can use as a client:

   kubectl run --namespace default redis-client --restart='Never'  --env REDIS_PASSWORD=$REDIS_PASSWORD  --image docker.io/bitnami/redis:7.2.2-debian-11-r0 --command -- sleep infinity

   Use the following command to attach to the pod:

   kubectl exec --tty -i redis-client \
   --namespace default -- bash

2. Connect using the Redis&reg; CLI:
   REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h redisalone-master

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace default svc/redisalone-master 6379:6379 &
    REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli -h 127.0.0.1 -p 6379


====================================
root@ai-work-nginx-h5-ldy:/data/yamlFile# helm install harbor bitnami/harbor -f  harbor.yaml --namespace harbor-ns
NAME: harbor
LAST DEPLOYED: Fri Oct 27 20:21:55 2023
NAMESPACE: harbor-ns
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: harbor
CHART VERSION: 19.0.5
APP VERSION: 2.9.0

** Please be patient while the chart is being deployed **

1. Get the Harbor URL:

  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        Watch the status with: 'kubectl get svc --namespace harbor-ns -w harbor'
    export SERVICE_IP=$(kubectl get svc --namespace harbor-ns harbor --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
    echo "Harbor URL: http://$SERVICE_IP/"

2. Login with the following credentials to see your Harbor application

  echo Username: "admin"
  echo Password: $(kubectl get secret --namespace harbor-ns harbor-core-envvars -o jsonpath="{.data.HARBOR_ADMIN_PASSWORD}" | base64 -d)