helm upgrade --install  sonarqube  sonarqube/sonarqube \
    --namespace devops-test --create-namespace \
    --set service.type=NodePort \
    --set postgresql.enabled="true" \
    --set postgresql.postgresqlUsername="sonarUser" \
    --set postgresql.postgresqlPassword="sonarPass" \
    --set postgresql.postgresqlDatabase="sonarDB" \
    --set postgresql.service.port="5432" \
    --set postgresql.persistence.storageClass=storageclass1 \
    --set sonarqubePassword="Haidao123..." \
    --set persistence.enabled="true" \
    --set persistence.storageClass="storageclass1" \
    --set initSysctl.enabled="false" \
    --set initFs.enabled="false" \
    --set nginx.enabled="false"


An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
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
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls.





kubectl create namespace cert-manager
kubectl repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager --create-namespace \
    --version v1.13.3 \
    --set ingressShim.defaultIssuerName=letsencrypt-prod \
    --set ingressShim.defaultIssuerKind=ClusterIssuer \
    --set installCRDs=true 

helm upgrade --install sonarqube sonarqube --repo https://charts.kubesphere.io/main -n devops-test --create-namespace --set service.type=NodePort --set  postgresql.persistence.storageClass=storageclass1
