# 添加helm 仓库
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# 创建namespace
kubectl create namespace cert-manager
kubectl create namespace ingress-nginx

# 部署 配置 SSL/TLS 证书
helm install cert-manager jetstack/cert-manager \
>   --namespace cert-manager \
>   --version v1.5.4 \
>   --set installCRDs=true

# 创建一个集群发行者 
cluster-issuer.yaml
# apiVersion: cert-manager.io/v1
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-prod
# spec:
#   acme:
#     email: your-email@example.com
#     server: https://acme-v02.api.letsencrypt.org/directory
#     privateKeySecretRef:
#       name: letsencrypt-prod
#     solvers:
#     - http01:
#         ingress:
#           class: nginx



#  Let's Encrypt 
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.galaxymeeting.live \
  --set bootstrapPassword=admin \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=hd900415@gmail.com \
  --set letsEncrypt.ingress.class=nginx


 ✘ ⚡ root@ai-work-nginx-h5-ldy  ~  helm install rancher rancher-stable/rancher \ 
  --namespace cattle-system \
  --set hostname=rancher.stbd06.com \
  --set bootstrapPassword=admin
NAME: rancher
LAST DEPLOYED: Mon Nov  6 18:59:09 2023
NAMESPACE: cattle-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Rancher Server has been installed.

NOTE: Rancher may take several minutes to fully initialize. Please standby while Certificates are being issued, Containers are started and the Ingress rule comes up.

Check out our docs at https://rancher.com/docs/

If you provided your own bootstrap password during installation, browse to https://rancher.stbd06.com to get started.

If this is the first time you installed Rancher, get started by running this command and clicking the URL it generates:

```
echo https://rancher.stbd06.com/dashboard/?setup=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')
```

To get just the bootstrap password on its own, run:

```
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'