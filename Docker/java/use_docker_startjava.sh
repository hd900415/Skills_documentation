cat Dockerfile
# 使用OpenJDK官方镜像作为基础镜像
FROM openjdk:11-jre-slim
# 设置容器内的工作目录
WORKDIR /data
# 将你的jar文件复制到工作目录中
COPY cash-agent-front.jar /data/cash-agent-front.jar
# 告诉docker运行容器时监听哪个端口
EXPOSE 8094
# 设置环境变量，例如时区设置，如果需要的话
ENV TZ=Asia/Shanghai
# 当容器启动时，执行Java应用程序
CMD ["java",  "-Xms256m", "-Xmx256m", "-jar", "/data/cash-agent-front.jar", "--spring.config.location=file:/data/application.yml"]

#####################

#  打包镜像
docker build -t harbor.galaxymeeting.live/aiwork/admin:20231108v1 .

docker build -t harbor.galaxymeeting.live/aiwork/admin:20231108_bitnamiv1 .

# 上传镜像到仓库
docker push harbor.galaxymeeting.live/aiwork/admin:20231108v1


docker run -d --name front -v ./application.yml:/data/application.yml -p 8094:8094 harbor.galaxymeeting.live/aiwork/admin:20231108v2

docker run -d --name front -v ./application.yml:/data/application.yml -p 8094:8094 harbor.galaxymeeting.live/aiwork/admin:20231108_bitnamiv1


#####

docker run -d  --name java -p 8094:8094 -v /data/docker/front/cash-agent-front.jar:/app/cash-agent-front.jar -v /data/docker/front/application.yml:/app/application.yml  bitnami/java java -jar /app/cash-agent-front.jar --spring.config.location=file:/app/application.yml

docker run -d --name front --network ai-work -p 8094:8094 -v /data/docker/front/cash-agent-front.jar:/app/cash-agent-front.jar -v /data/docker/front/application.yml:/app/application.yml  bitnami/java java -jar /app/cash-agent-front.jar --spring.config.location=file:/app/application.yml
# 启动docker 
### mysql 容器
docker run -d --name mysql8_cash     -p 3307:3306     --network ai-work     -e MYSQL_DATABASE=cash     -e MYSQL_ROOT_PASSWORD=123456     -v /data/docker/mysql/data:/var/lib/mysql     -v /data/docker/mysql/conf:/etc/mysql/conf.d     -e TZ=Asia/Shanghai     mysql:8.0.35
docker run -d --name mysql8_cash     -p 3307:3306 -e MYSQL_DATABASE=cash     -e MYSQL_ROOT_PASSWORD=123456     -v /data/docker/mysql/data:/var/lib/mysql     -v /data/docker/mysql/conf:/etc/mysql/conf.d     -e TZ=Asia/Shanghai     mysql:8.0.35 
### redis 容器
docker run -d --name redis722 --network ai-work -p 6666:6379 -e "TZ=Asia/Shanghai"  -v /data/docker/redis/data:/data redis --requirepass "redis123" --appendonly yes
docker run -d --name redis722 --network=host -p 6666:6379 -e "TZ=Asia/Shanghai"  -v /data/docker/redis/data:/data redis --requirepass "redis123" --appendonly yes
#     #添加Java启动的必要镜像
#     FROM  java:8
#     #将本地文件挂载到当前容器
#     VOLUME  /tmp
#     #复制jar文件和配置文件所在的目录到容器里
#     ADD  my-app.jar  /app.jar
#     ADD  conf       /conf
#     #声明需要暴露的端口
#     EXPOSE  8006
#     #配置容器启动后执行的命令,并指定使用项目外部的配置文件
#     ENTRYPOINT  ["java", "-Xms256m", "-Xmx256m", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app.jar", "--spring.config.location=/conf/application.yml"]




