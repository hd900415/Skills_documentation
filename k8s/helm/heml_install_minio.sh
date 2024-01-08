helm install minio bitnami/minio --namespace minio \--create-namespace \
    --set global.storageClass="storageclass1" \
    --set auth.rootUser="admin" \
    --set auth.rootPassword="facai555" \
    --set defaultBuckets="bdb" \
    --set service.type=