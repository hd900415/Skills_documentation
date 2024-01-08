NAME: nginx-ingress
LAST DEPLOYED: Mon Nov  6 16:27:24 2023
NAMESPACE: nginx-ingress
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: nginx-ingress-controller
CHART VERSION: 9.9.2
APP VERSION: 1.9.3

** Please be patient while the chart is being deployed **

The nginx-ingress controller has been installed.

Get the application URL by running these commands:

 NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch its status by running 'kubectl get --namespace nginx-ingress svc -w nginx-ingress-nginx-ingress-controller'

    export SERVICE_IP=$(kubectl get svc --namespace nginx-ingress nginx-ingress-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "Visit http://${SERVICE_IP} to access your application via HTTP."
    echo "Visit https://${SERVICE_IP} to access your application via HTTPS."

An example Ingress that makes use of the controller:

  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: nginx-ingress
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - backend:
                service:
                  name: example-service
                  port:
                    number: 80
              path: /
              pathType: Prefix
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
        - hosts:
            - www.example.com
          secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: nginx-ingress
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls

#  模板
helm upgrade ingress-nginx --namespace ingress-nginx --create-namespace --debug --wait --install --atomic \
   --set controller.kind="Deployment" \
   --set controller.replicaCount="3" \
   --set controller.minAvailable="1" \
   --set controller.image.registry="docker.io" \
   --set controller.image.image="kubelibrary/ingress-nginx-controller" \
   --set controller.image.tag="v1.5.1" \
   --set controller.image.digest="" \
   --set controller.ingressClassResource.name="nginx" \
   --set controller.ingressClassResource.enable="true" \
   --set controller.ingressClassResource.default="false" \
   --set controller.service.enabled="true" \
   --set controller.service.type="NodePort" \
   --set controller.service.enableHttps="false" \
   --set controller.service.nodePorts.http="32080" \
   --set controller.service.nodePorts.https="32443" \
   --set controller.admissionWebhooks.enabled="true" \
   --set controller.admissionWebhooks.patch.image.registry="docker.io" \
   --set controller.admissionWebhooks.patch.image.image="kubelibrary/kube-webhook-certgen" \
   --set controller.admissionWebhooks.patch.image.tag="v20220916-gd32f8c343" \
   --set controller.admissionWebhooks.patch.image.digest="" \
   --set controller.metrics.enabled="true" \
   --set-string controller.podAnnotations."prometheus\.io/scrape"="true" \
   --set-string controller.podAnnotations."prometheus\.io/port"="10254" \
   --set defaultBackend.enabled="true" \
   --set defaultBackend.name="defaultbackend" \
   --set defaultBackend.image.registry="docker.io" \
   --set defaultBackend.image.image="kubelibrary/defaultbackend-amd64" \
   --set defaultBackend.image.tag="1.5" \
   --set defaultBackend.replicaCount="1" \
   --set defaultBackend.minAvailable="1" \
   --set rbac.create="true" \
   --set serviceAccount.create="true" \
   --set podSecurityPolicy.enabled="true" \
   ./ingress-nginx-4.4.2.tgz
注意如下参数
controller.service.enableHttps  //是否打开https，如果ingress前有Nginx或者七层LB，这里可以设置为false
controller.ingressClassResource.name  //ingressclass的名称，根据自己的需求修改
controller.replicaCount  //pod数量,根据节点数量自行调整s




#  实际应用 

helm install ingress-nginx --namespace ingress-nginx --create-namespace --debug --wait --install --atomic \
   --set controller.kind="Deployment" \
   --set controller.replicaCount="3" \
   --set controller.minAvailable="1" \
   --set controller.ingressClassResource.name="nginx" \
   --set controller.ingressClassResource.enable="true" \
   --set controller.ingressClassResource.default="false" \
   --set controller.service.enabled="true" \
   --set controller.service.type="NodePort" \
   --set controller.service.enableHttps="true" \
   --set controller.service.nodePorts.http="80" \
   --set controller.service.nodePorts.https="443" \
   --set controller.admissionWebhooks.enabled="true" \
   --set controller.metrics.enabled="true" \
   --set-string controller.podAnnotations."prometheus\.io/scrape"="true" \
   --set-string controller.podAnnotations."prometheus\.io/port"="10254" \
   --set defaultBackend.enabled="true" \
   --set defaultBackend.name="defaultbackend" \
   --set defaultBackend.replicaCount="1" \
   --set defaultBackend.minAvailable="1" \
   --set rbac.create="true" \
   --set serviceAccount.create="true" \
   --set podSecurityPolicy.enabled="true" \


   helm install   ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx \
   --set controller.kind="Deployment"    \
   --set controller.replicaCount="3"    \
   --set controller.minAvailable="1"    \
   --set controller.ingressClassResource.name="nginx"    \
   --set controller.ingressClassResource.enable="true"    \
   --set controller.ingressClassResource.default="false"   \
   --set controller.service.enabled="true"    \
   --set controller.service.type="NodePort"    \
   --set controller.service.enableHttps="true"    \
   --set controller.service.nodePorts.http="80"    \
   --set controller.service.nodePorts.https="443"    \
   --set controller.admissionWebhooks.enabled="true"    \
   --set controller.metrics.enabled="true"    \
   --set-string controller.podAnnotations."prometheus\.io/scrape"="true"    \
   --set-string controller.podAnnotations."prometheus\.io/port"="10254"    \
   --set defaultBackend.enabled="true"    \
   --set defaultBackend.name="defaultbackend"    \
   --set defaultBackend.replicaCount="1"    \
   --set defaultBackend.minAvailable="1"    \
   --set rbac.create="true"   \
   --set serviceAccount.create="true"   \
   --set podSecurityPolicy.enabled="true"