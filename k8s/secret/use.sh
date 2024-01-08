# base64 解码
[root@k8s-master ~]# echo "eyJhdXRocyI6eyJoYXJib3IuZ2FsYXh5bWVldGluZy5saXZlIjp7InVzZXJuYW1lIjoiYWRtaW4iLCJwYXNzd29yZCI6IkhhaWRhbzEyMy4uLiIsImF1dGgiOiJZV1J0YVc0NlNHRnBaR0Z2TVRJekxpNHUifX19" |base64 -d
{"auths":{"harbor.galaxymeeting.live":{"username":"admin","password":"Haidao123...","auth":"YWRtaW46SGFpZGFvMTIzLi4u"}}}[root@k8s-master ~]# 

kubectl create secret docker-registry harbor-secret -n devops-test \
  --docker-server=harbor.galaxymeeting.live \
  --docker-username=admin \
  --docker-password=Facai555 \
  --docker-email=facaixm@gmail.com


kubectl create sa jenkins
serviceaccount/jenkins created

kubectl create clusterrolebinding jenkins --clusterrole cluster-admin --serviceaccount=default:jenkins
clusterrolebinding.rbac.authorization.k8s.io/jenkins created

kubectl get sa -n default 
NAME      SECRETS   AGE
default   0         3d17h
jenkins   0         57s

[root@k8s-master ~]# kubectl describe sa jenkins -n default 
Name:                jenkins
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>

