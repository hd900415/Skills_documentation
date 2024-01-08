# 使用官方的 Redis 镜像作为基础镜像
FROM redis

WORKDIR /data

# 创建并设置持久化目录

# 复制你的 Redis 配置文件到容器
COPY redis.conf /data/redis.conf

# 启用内存过度提交以避免上述警告
RUN echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf

# 指定Redis的配置文件路径
CMD [ "redis-server", "/data/redis.conf" ]

# 暴露Redis的端口
EXPOSE 6379