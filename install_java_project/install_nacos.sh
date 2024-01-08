docker run -d \
-v /data/nacos/logs:/home/nacos/logs \
-e TZ="Asia/Shanghai" \
-e PREFER_HOST_MODE=ip \
-e MODE=standalone \
-e SPRING_DATASOURCE_PLATFORM=mysql \
-e MYSQL_SERVICE_HOST=数据库IP地址 \
-e MYSQL_SERVICE_PORT=数据库端口 \
-e MYSQL_SERVICE_USER=数据库账户 \
-e MYSQL_SERVICE_PASSWORD=数据库密码 \
-e MYSQL_SERVICE_DB_NAME=nacos_config \
-e MYSQL_SERVICE_DB_PARAM= \
-e NACOS_APPLICATION_PORT=8848 \
-p 8848:8848 \
--name nacos-zjq-mysql \
--restart=always \
nacos/nacos-server:2.0.2


