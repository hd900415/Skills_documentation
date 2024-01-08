https://github.com/hd900415/nginxconf/blob/master/k8s

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update



helm install prometheus prometheus-community/prometheus \
  --namespace monitoring --create-namespace \
  --set server.persistentVolume.enabled=true \
  --set server.persistentVolume.storageClass="storageclass1" \
  --set server.persistentVolume.size=5Gi


# NAME: prometheus
# LAST DEPLOYED: Mon Dec 11 22:42:08 2023
# NAMESPACE: monitoring
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
# prometheus-server.monitoring.svc.cluster.local


# Get the Prometheus server URL by running these commands in the same shell:
#   export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
#   kubectl --namespace monitoring port-forward $POD_NAME 9090


# The Prometheus alertmanager can be accessed via port 9093 on the following DNS name from within your cluster:
# prometheus-alertmanager.monitoring.svc.cluster.local


# Get the Alertmanager URL by running these commands in the same shell:
#   export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=alertmanager,app.kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
#   kubectl --namespace monitoring port-forward $POD_NAME 9093
# #################################################################################
# ######   WARNING: Pod Security Policy has been disabled by default since    #####
# ######            it deprecated after k8s 1.25+. use                        #####
# ######            (index .Values "prometheus-node-exporter" "rbac"          #####
# ###### .          "pspEnabled") with (index .Values                         #####
# ######            "prometheus-node-exporter" "rbac" "pspAnnotations")       #####
# ######            in case you still need it.                                #####
# #################################################################################


# The Prometheus PushGateway can be accessed via port 9091 on the following DNS name from within your cluster:
# prometheus-prometheus-pushgateway.monitoring.svc.cluster.local


# Get the PushGateway URL by running these commands in the same shell:
#   export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus-pushgateway,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
#   kubectl --namespace monitoring port-forward $POD_NAME 9091

# For more information on running Prometheus, visit:
# https://prometheus.io/