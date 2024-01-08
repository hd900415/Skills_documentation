# 查看（获取）各种资源，
kubectl -n (namespace) get pod(node pvc ns pv svc  等各种资源) -o wide 

kubectl -n kube-system get nodes -o wide --show-labels

# 描述资源详细
kubectl  -n (namespace)  describe pod(node pvc ns pv 等各种资源) 
        (描述)
# like this 
kubectl -n ai-work-k8s describe node node1 

# 查看日志






kubectl -n (namespace)  logs pod( pvc ns pv 等各种资源)  不可以查看node 日志
# like this 
kubectl -n ai-work-k8s describe node node1  -o wide  