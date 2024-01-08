# 次文件内容记录linux 常用的使用记录

# token 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

# 获取接口的访问时间
curl -w '\ntime_namelookup=%{time_namelookup}\ntime_connect=%{time_connect}\ntime_appconnect=%{time_appconnect}\ntime_redirect=%{time_redirect}\ntime_pretransfer=%{time_pretransfer}\ntime_starttransfer=%{time_starttransfer}\ntime_total=%{time_total}\n\n' -o /dev/null -s -L http://api.appleasp.com/api/v1/token
# nginx 常用的安全配置
#记录真实IP
map $http_x_forwarded_for $clientRealIp {
"" $remote_addr;
~^(?P<firstAddr>[0-9\.]+),?.*$ $firstAddr;
}
log_format cdn '$clientRealIp - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"';

#REMOTE_ADDR：节点IP
#HTTP_X_FORWARDED_FOR：网民电脑IP,代理IP1,代理IP2
#HTTP_X_REAL_FORWARDED_FOR：网民电脑IP
#HTTP_X_CONNECTING_IP：代理IP2

#防止CC

#注意如果采用UA方式识别，要选择非常少见的UA标识，否则会造成误杀。
#map $http_user_agent $agent {
#default "";
#~*X11 $http_user_agent;
#~*Ubuntu $http_user_agent;
#}

map $request_uri $r_agent {
default "";
~*home.php\?mod=space&uid $clientRealIp;
~*sec\.baidu\.com $clientRealIp;
}

map $http_user_agent $agent {
default $r_agent;
~*X11 $clientRealIp;
~*Ubuntu $clientRealIp;
~*bingbot "";
~*yahoo "";
~*Googlebot "";
~*Baiduspider "";
~*Sogou "";
~*360Spider "";
}

#用来限制同一时间连接数，即并发限制名称设定为TotalConnLimitZone
limit_conn_zone $agent zone=TotalConnLimitZone:20m ;
limit_conn_log_level notice;

#用来限制单位时间内的请求数，即速率限制,采用的漏桶算法 "leaky bucket"名称设定为ConnLimitZone
limit_req_zone $agent zone=ConnLimitZone:20m rate=10r/s;
limit_req_log_level notice;

#IP黑名单
geo $clientRealIp $banip {
default 0;
include blockip.conf; #格式 xxx.xxx.xxx.xxx 1;
}

server
{
#记录CC拦截引起的503错误，防止误杀。
location ~ /ErrorPages/503\.html$
{
root /home/wwwroot/lnmp2015/domain/wfun.com/web;
access_log /home/wwwroot/lnmp2015/logs/err_503.log cdn; #access_log end combined
}
#识别IP黑名单，禁止访问
if ($banip = 1) {
return 403;
}

#以下可在伪静态里面设置
location ~ .*\.php$
{
limit_conn TotalConnLimitZone 50; #并发为 50 ，相当于最大开50个线程
limit_req zone=ConnLimitZone burst=10 nodelay; #最多 10 个排队， 由于每秒处理 20 个请求 + 10个排队，因此每秒最多刷新30次。
}

#防木马执行
location ~ /(attachment|upload|mov|center|static|zone|jkb|000|a\_img)/.*\.(php|php5|PHP|PHP5)?$ {
deny all;
}
}
}

# prometheus 使用telegram 报警
docker run -d -e 'ALERTMANAGER_URL=http://45.207.36.60:9093' \
-e 'BOLT_PATH=/data/prometheus/alertmanager/data/bot.db' \
-e 'STORE=bolt' \
-e 'TELEGRAM_ADMIN=2143538719' \
-e 'TELEGRAM_TOKEN=5034420902:AAFo9TEywqSdh7mdlkzOR3f7vRrj6hTvRpw' \
-v '/data/prometheus/alertmanager/data/:/data'   \
-p 8080:8080 \
--name alertmanager-bot \
metalmatze/alertmanager-bot:0.4.3

# confluence 使用dokcer 部署
## mysql docker 部署
docker run --name mysqlForConfluence --restart always \
-p 3306:3306 \
-v /opt/confluence/mysql/:/var/lib/mysql \
-v /opt/confluence/my.cnf:/etc/mysql/my.cnf \
-e MYSQL_ROOT_PASSWORD=78RiOG4ZP8c \
-d mysql:5.7

docker run -d --name confluence --restart always \
-p 8091:8091 \
-p 8090:8090 \
-e TZ="Asia/Shanghai" \
--link mysqlForConfluence:mysql \
-v /opt/confluence/data:/var/atlassian/confluence   \
confluence/confluence:7.13.0.1201


##############################

#jq 操作json数据