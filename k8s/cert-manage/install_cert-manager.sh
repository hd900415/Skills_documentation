kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.13.3 --set installCRDs=true \
   --set ingressShim.defaultIssuerName=letsencrypt-prod \
   --set ingressShim.defaultIssuerKind=ClusterIssuer \
   --set ingressShim.defaultIssuerGroup=cert-manager.io

# --set installCRDs=true表示安装Cert-Manager所需的自定义资源定义

# 验证安装
# 检查Cert-Manager pod的状态确保它们正常运行：

# kubectl get pods --namespace cert-manager
# 检查证书的状态：

# kubectl describe certificate mydomain-cert -n your-namespace
# 注意事项
# 确保你的Ingress资源配置了对应的域名，并且Ingress控制器正确配置，以允许ACME挑战的通信。
# 如果在内部网络或没有公网IP的环境中，你可能需要使用DNS挑战而不是HTTP挑战。这需要相应地配置Issuer或ClusterIssuer。
# Let's Encrypt有速率限制，因此在生产环境中要合理规划证书请求。

