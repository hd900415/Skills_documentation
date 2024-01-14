# 使用k8s 安装 harbor并且自动证书

https://ruzickap.github.io/k8s-harbor/part-04/#install-harbor-using-helm

# 首先创建证书

kubectl get secrets ingress-cert-${LETSENCRYPT_ENVIRONMENT} -n harbor-system -o json | jq ".metadata | .annotations, .labels"

helm repo add harbor https://helm.goharbor.io

helm install harbor  harbor/harbor  --wait   --namespace harbor-system  --create-namespace   --set persistence.enabled=false   --set harborAdminPassword=admin


helm upgrade harbor  harbor/harbor  --wait   --namespace harbor-system  \
  --set expose.ingress.hosts.core=harbor.galaxymeeting.live \
  --set expose.ingress.hosts.notary=notary.galaxymeeting.live \
  --set expose.tls.secretName=harbor-cert \
  --set persistence.enabled=false \
  --set externalURL=https://harbor.galaxymeeting.live \
  --set harborAdminPassword=admin