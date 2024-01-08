docker run \
-d \
--name minio \
--restart=always \
--privileged=true \
-p 9000:9000 \
-p 9001:9001 \
-e "MINIO_ACCESS_KEY=admin" \
-e "MINIO_SECRET_KEY=admin1973984292@qq.com" \
-e MINIO_ROOT_USER=name \
-e MINIO_ROOT_PASSWORD=password \
-v /home/apps/minio/data:/data \
-v /home/apps/minio/config:/root/.minio \
minio/minio server /data \
--console-address ":9001"

.env
# MINIO_ROOT_USER and MINIO_ROOT_PASSWORD sets the root account for the MinIO server.
# This user has unrestricted permissions to perform S3 and administrative API operations on any resource in the deployment.
# Omit to use the default values 'minioadmin:minioadmin'.
# MinIO recommends setting non-default values as a best practice, regardless of environment

MINIO_ROOT_USER=myminioadmin
MINIO_ROOT_PASSWORD=minio-secret-key-change-me

# MINIO_VOLUMES sets the storage volume or path to use for the MinIO server.

MINIO_VOLUMES="/mnt/data"

# MINIO_SERVER_URL sets the hostname of the local machine for use with the MinIO Server
# MinIO assumes your network control plane can correctly resolve this hostname to the local machine

# Uncomment the following line and replace the value with the correct hostname for the local machine and port for the MinIO server (9000 by default).

#MINIO_SERVER_URL="http://minio.example.net:9000"

REDIS_ARGSdocker run -e REDIS_ARGS="--requirepass redis-stack" redis/redis-stack:latest
docker run -e REDIS_ARGS="--requirepass redis-stack" redis/redis-stack:latest
docker run -e REDIS_ARGS="--save 60 1000 --appendonly yes" redis/redis-stack:latest
