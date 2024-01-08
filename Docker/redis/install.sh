docker run -d --name redis722 --network ai-work -p 6666:6379 -e "TZ=Asia/Shanghai"  -v /data/docker/redis/data:/data redis --requirepass "" --appendonly yes --dir "/data"

根据配置文件将数据进行持久化
redis-server
docker run -d --name redis722 \
    --network ai-work -p 6379:6379 \
    -e "TZ=Asia/Shanghai"  \
    -v /data/redis/data:/data redis --requirepass "facai555" --appendonly yes --dir "/data"

docker run -d --name redis \
    -p 6379:6379 \
    -e "TZ=Asia/Shanghai"  \
    -v /data/redis/data:/data redis --requirepass "facai555" --appendonly yes --dir "/data"