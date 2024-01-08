#env install 

yum -y update && 
yum -y install \
    gcc \
    pcre-devel \
    make zlib-devel \
    openssl-devel \
    libxml2-devel \
    libxslt-devel gd-devel \
    GeoIP-devel libatomic_ops-devel \
    luajit luajit-devel perl-devel \
    perl-ExtUtils-Embed \
    git \
    lrzsz \
    wget 
    
mkdir -p /data/openresty && cd /data/openresty && git clone https://github.com/TravelEngineers/ngx_http_geoip2_module

# 安装依赖
# 1.libmaxminddb
wget https://github.com/maxmind/libmaxminddb/releases/download/1.4.2/libmaxminddb-1.4.2.tar.gz 
tar xf libmaxminddb-1.4.2.tar.gz && cd libmaxminddb-1.4.2 
./configure &&    make &&    make check &&    make install
ldconfig 
echo /usr/local/lib >> /etc/ld.so.conf.d/local.conf && ldconfig 

# # 2 ngx_http_geoip2_module 模块
# git clone https://github.com/TravelEngineers/ngx_http_geoip2_module

# wget https://github.com/maxmind/libmaxminddb/releases/download/1.4.2/libmaxminddb-1.4.2.tar.gz

# 3 geoipupdate 更新IP地址库
#rpm -ivh ./package/geoipupdate_4.8.0_linux_386.rpm 
yum -y install https://github.com/maxmind/geoipupdate/releases/download/v4.8.0/geoipupdate_4.8.0_linux_386.rpm
# yum remove -y geoipupdate && 
rm -rf /etc/GeoIP.conf 
cat <<'EOF'> /etc/GeoIP.conf 
AccountID 643975
LicenseKey aZ5RobhhHTV03d08
EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country
EOF

geoipupdate
# \cp package/conf/GeoIp.conf /etc/ && geoipupdate 

# # 安装openresty
# cd ./package && 
cd /data/openresty && wget https://openresty.org/download/openresty-1.19.9.1.tar.gz && tar xf openresty-1.19.9.1.tar.gz &&  cd openresty-1.19.9.1 
./configure \
    --prefix=/usr/local/openresty \
    --with-threads \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-stream_ssl_preread_module \
    --add-module=../ngx_http_geoip2_module 


gmake && gmake install 

#tar xf package/conf.tar.gz -C /usr/local/openresty/nginx/conf/ && cp -a /usr/local/openresty/nginx/conf/ /usr/local/openresty/nginx 

# get waf code 
cd  /usr/local/openresty/nginx/conf/ && git clone https://github.com/unixhot/waf.git && mv waf waf1 && mv waf1/waf ./ && rm -rf waf1 && mkdir conf.d ssl vhost

ln -s /usr/local/openresty/bin/openresty   /usr/bin/openresty
ln -s /usr/local/openresty/lualib /usr/local/lib/lua
ln -s /usr/local/openresty/lualib/resty /usr/local/openresty/nginx/conf/waf/resty




# 添加配置文件



# 配置文件

# main nginx.conf
cat <<'EOF'> /usr/local/openresty/nginx/conf/nginx.conf
user  nobody;
worker_processes  8;
#worker_cpu_affinity 0001 0010 0100 1000;
worker_cpu_affinity 0001 0010 0100 1000 1001 1010 1100 1101;   
#worker_cpu_affinity auto;
worker_priority -20;
worker_rlimit_nofile 65535; 

error_log  logs/error.log;
pid        logs/nginx.pid;

events {
    use epoll;
    worker_connections 100000; 
    multi_accept on;  
    accept_mutex on; 
    accept_mutex_delay 10ms;  
}

http {
    server_tokens off; 
    sendfile on;
    autoindex off;
    tcp_nopush on;
    tcp_nodelay on;


    lua_shared_dict limit 10m;
    lua_package_path "/usr/local/openresty/nginx/conf/waf/?.lua";
    init_by_lua_file "/usr/local/openresty/nginx/conf/waf/init.lua";
    access_by_lua_file "/usr/local/openresty/nginx/conf/waf/access.lua";

    set_real_ip_from 0.0.0.0/0;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    map $http_x_forwarded_for $clientRealIp {
        "" $remote_addr;
        ~^(?P<firstAddr>[0-9\.]+),?.*$ $firstAddr;
    }
    #如果$http_x_forwarded_for为空(即未提供CDN之前的IP地址),则将$clientRealIp设置为$remote_addr,即Nginx服务器接收到的IP地址。
    #如果$http_x_forwarded_for不为空,则使用正则表达式匹配,从中提取第一个IP地址(通常是真实客户端IP)。正则表达式~^(?P<firstAddr>[0-9\.]+),?.*$会匹配以逗号分隔的IP地址列表,并从中提取第一个IP地址。

    map $http_upgrade $connection_upgrade {
         default upgrade;
         '' close;
    }


    map $geoip2_data_country_code $allowed_country {
                default no;
                CN yes;
                PH yes;
                AE yes;
                HK yes;
        }


    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    '$status $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
    #access_log /var/log/nginx/access.log main_json ;

    log_format main_json escape=json '{'
      '"msec": "$msec", ' # request unixtime in seconds with a milliseconds resolution
      '"connection": "$connection", ' # connection serial number
      '"connection_requests": "$connection_requests", ' # number of requests made in connection
      '"pid": "$pid", ' # process pid
      '"request_id": "$request_id", ' # the unique request id
      '"request_length": "$request_length", ' # request length (including headers and body)
      '"remote_addr": "$remote_addr", ' # client IP
      '"remote_user": "$remote_user", ' # client HTTP username
      '"remote_port": "$remote_port", ' # client port
      '"time_local": "$time_local", '
      '"time_iso8601": "$time_iso8601", ' # local time in the ISO 8601 standard format
      '"request": "$request", ' # full path no arguments if the request
      '"request_uri": "$request_uri", ' # full path and arguments if the request
      '"args": "$args", ' # args
      '"status": "$status", ' # response status code
      '"body_bytes_sent": "$body_bytes_sent", ' # the number of body bytes exclude headers sent to a client
      '"bytes_sent": "$bytes_sent", ' # the number of bytes sent to a client
      '"http_referer": "$http_referer", ' # HTTP referer
      '"http_user_agent": "$http_user_agent", ' # user agent
      '"http_x_forwarded_for": "$http_x_forwarded_for", ' # http_x_forwarded_for
      '"http_host": "$http_host", ' # the request Host: header
      '"server_name": "$server_name", ' # the name of the vhost serving the request
      '"request_time": "$request_time", ' # request processing time in seconds with msec resolution
      '"upstream": "$upstream_addr", ' # upstream backend server for proxied requests
      '"upstream_connect_time": "$upstream_connect_time", ' # upstream handshake time incl. TLS
      '"upstream_header_time": "$upstream_header_time", ' # time spent receiving upstream headers
      '"upstream_response_time": "$upstream_response_time", ' # time spend receiving upstream body
      '"upstream_response_length": "$upstream_response_length", ' # upstream response length
      '"upstream_cache_status": "$upstream_cache_status", ' # cache HIT/MISS where applicable
      '"upstream_status":"$upstream_status", '
      '"ssl_protocol": "$ssl_protocol", ' # TLS protocol
      '"ssl_cipher": "$ssl_cipher", ' # TLS cipher
      '"scheme": "$scheme", ' # http or https
      '"request_method": "$request_method", ' # request method
      '"server_protocol": "$server_protocol", ' # request protocol, like HTTP/1.1 or HTTP/2.0
      '"pipe": "$pipe", ' # “p” if request was pipelined, “.” otherwise
      '"gzip_ratio": "$gzip_ratio", '
      '"http_cf_ray": "$http_cf_ray",'
      '"geoip_country_code": "$geoip2_country_name", '
      '"geoip_city_code":"$geoip2_data_city_name"'
 '}';

    keepalive_timeout 60s;
    keepalive_requests 10000;
    client_header_timeout 60;
    client_body_timeout 10;
    send_timeout 60;
    reset_timedout_connection off;

    limit_conn_zone $binary_remote_addr zone=one:50m;
    limit_conn_log_level notice;
    limit_conn_status 503;

    limit_req_zone  $binary_remote_addr zone=two:50m rate=5r/s;
    limit_req_log_level notice;
    limit_req_status 503;

    include mime.types;
    default_type text/html;
    charset UTF-8;

    gzip_static off; 
    gzip on;
    gzip_disable "msie6";
    gzip_proxied any;
    gzip_min_length 1024;
    gzip_comp_level 5;
    gzip_buffers 4 16k;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    open_file_cache max=65535 inactive=30s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
 
    proxy_hide_header X-Powered-By;
    fastcgi_intercept_errors on;
    proxy_ignore_client_abort   on;

    #include /usr/local/openresty/nginx/conf/fastcgi.conf;
    include /usr/local/openresty/nginx/conf/conf.d/Geoip2.conf;
    include /usr/local/openresty/nginx/conf/conf.d/upstream;
    include /usr/local/openresty/nginx/conf/vhost/*.conf;
    #include /usr/local/openresty/nginx/conf/conf.d/black.conf;
    proxy_cache_path /usr/local/openresty/nginx/my_proxy_temp levels=1:2 keys_zone=web_cache:50m inactive=60m max_size=1g;

}
EOF

# Geoip2.conf
cat <<'EOF'>> /usr/local/openresty/nginx/conf/conf.d/Geoip2.conf 
geoip2 /usr/share/GeoIP/GeoLite2-Country.mmdb {
     auto_reload 5m;
     $geoip2_metadata_country_build metadata build_epoch; 
     $geoip2_country_code country iso_code;
     $geoip2_country_name country names en;
    }
geoip2 /usr/share/GeoIP/GeoLite2-City.mmdb {
      $geoip2_metadata_city_build metadata build_epoch;
      $geoip2_data_city_name city names en;
      $geoip2_data_continent_code continent code;
      $geoip2_data_continent_name continent names en;
      $geoip2_data_country_code country iso_code;
      $geoip2_data_country_name country names en;
      $geoip2_data_region_iso subdivisions 0 iso_code;
      $geoip2_data_region_name subdivisions 0 names en;
    }
EOF
 # proxy.conf
cat <<'EOF' >> /usr/local/openresty/nginx/conf/conf.d/proxy.conf 
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        #proxy_set_header Connection $http_connection;
        proxy_ignore_client_abort on;
        proxy_connect_timeout 60;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        proxy_intercept_errors on;
        proxy_headers_hash_max_size 51200;
        proxy_headers_hash_bucket_size 6400;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header REMOTE-HOST $remote_addr;
        #proxy_set_header X-Forwarded-For $http_x_forwarded_for;

        #proxy_set_header   X-Up-Ip      $server_addr;
        #proxy_set_header   X-Up-Port    $server_port;

        #send_timeout 600;
        set $max_rate 512k;
EOF
# IP的访问限流和链接限流
# limitip.conf 
cat <<'EOF'>> /usr/local/openresty/nginx/conf/conf.d/limitip.conf 
        if ($allowed_country = no ){ return 404 /404.html;}

        limit_req zone=two burst=20 ; #"nodelay"
        limit_conn one 1000;
        limit_rate_after 1m;
        limit_rate "$max_rate";

        error_page  404     /404.html;
EOF

# proxyCache.conf
cat <<'EOF'>> /usr/local/openresty/nginx/conf/conf.d/proxyCache.conf 
        proxy_cache web_cache;
        proxy_cache_valid  200 302 304 1d;
        proxy_cache_key $host$uri$is_args$args;

EOF

# api.conf 根据业务场景进行配置 
cat <<'EOF'>> /usr/local/openresty/nginx/conf/vhost/wlgj.conf 
server {
    listen       80;
    server_name  a1.epp7um.com defalut;
    rewrite ^(.*)$ https://a1.epp7um.com$1 permanent;
}
server {
    listen 443 ssl http2 ;
    server_name a1.epp7um.com;
    if ($host != 'a1.epp7um.com') {
        #rewrite ^(.*)$ https://a1.epp7um.com$1 permanent;
        return 444;
    }
    if ($http_user_agent ~* ApacheBench|WebBench|java/){
                return 403;
        }
    if ( $http_user_agent ~* (Wget|ab) ) {
        return 403;
    }

    if ( $http_user_agent ~* LWP::Simple|BBBike|wget) {
        return 403;
    }
    ssl_certificate /usr/local/openresty/nginx/conf/ssl/wlgj.pem;
    ssl_certificate_key /usr/local/openresty/nginx/conf/ssl/wlgj.key;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5";
    ssl_session_cache builtin:1000 shared:SSL:10m;
    access_log  /data/nginx/logs/a1.epp7um.com.log main_json;
    error_log /data/nginx/logs/a1.epp7um.com_error.log error;

    location / {
        #if (!-e $request_filename) {
        #       rewrite  ^(.*)$  /index.php?s=/$1  last;
        #}
        try_files $uri 404 /index.php =404;
        limit_except GET HEAD POST {
             deny all;
        }
    }


    location ^~ /static {
        proxy_pass  http://wlgjserver/static;
        include conf.d/limitip.conf;
        include conf.d/proxy.conf;
        include conf.d/proxyCache.conf;

    }

    location ^~ /api {  
        #try_files $uri =404;
        #try_files $uri /index.php =404;
        proxy_pass  http://wlgjserver/api;
        include conf.d/limitip.conf;
        include conf.d/proxy.conf;

        error_page  404     /404.html;

        limit_except GET HEAD POST {
             deny all;
        }

    }
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; } 
    error_page    404  /404.html;
}
EOF
# or like this 
cat  >>  /usr/local/openresty/nginx/conf/vhost/api.conf  << 'EOF'
upstream apiserver {
    server 16.162.115.22:7899;
    keepalive 60;
}
server {
    listen       80;
    server_name  a1.epp7um.com;
    #return 301 https://a1.epp7um.com$1 permanent;
    rewrite ^(.*)$ https://a1.epp7um.com$1 permanent;
    #return       301 https://$host$request_uri;

}
server {
    listen 443 ssl http2 default;
    server_name a1.epp7um.com;
    #if ($host != 'a1.epp7um.com') {
    #    #rewrite ^(.*)$ https://a1.epp7um.com$1 permanent;
    #    return 444;
    #}
    ssl_certificate /usr/local/openresty2/nginx/conf/ssl/full_chain.pem;
    ssl_certificate_key /usr/local/openresty2/nginx/conf/ssl/private.key;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5";
    ssl_session_cache builtin:1000 shared:SSL:10m;
    access_log  /data/nginx/logs/a1.epp7um.com.log main_json;
    error_log /data/nginx/logs/a1.epp7um.com_error.log error;

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; } 

    location ^~ /api {
        proxy_pass  http://apiserver/api;

        proxy_intercept_errors on;
        proxy_set_header Host $host;
        proxy_headers_hash_max_size 51200;
        proxy_headers_hash_bucket_size 6400;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header REMOTE-HOST $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $http_x_forwarded_for;
        #proxy_buffering off;
        #proxy_request_buffering off;
        #proxy_http_version 1.1;
        #proxy_set_header Connection "";
        #proxy_set_header Upgrade $http_upgrade;
        #proxy_ignore_client_abort on;
        #proxy_connect_timeout 60;
        #proxy_send_timeout 60s;
        #proxy_read_timeout 60s;
        proxy_cache off;
        proxy_cache_bypass 1;
        proxy_cache_valid any 10s;
    }   



        set $max_rate 512k;
        #if ($geoip2_Country_code ~* ^(HK|US|KR|JP|TW|SG|MO)$){
        #        set $max_rate 128k;
        #       }
        if ($allowed_country = no ){
            return 404 /404.html;
           }
        limit_req zone=two burst=20;
        limit_conn one 1000;
        limit_rate_after 1m;
        limit_rate "$max_rate";
        error_page  404     /404.html;
}
EOF

# 获取nginx_status conf
cat << 'EOF' >> /usr/local/openresty/nginx/conf/vhost/default.conf 
server {
    listen       88 ;
    server_name localhost;
    location /nginx_status
    {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }

}
server {
   listen 80 default_server;
   server_name _;
   return 501;
}
EOF

# 日志目录
mkdir -p /data/nginx/logs
# 日志切割
cat >>  /etc/logrotate.d/nginx << 'EOF'
/data/nginx/logs/*.log {
    daily
    missingok
    minsize 500M
    rotate 10
    compress
    delaycompress
    dateext
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        /usr/local/openresty/bin/openresty -s reload
    endscript
}
EOF

cat >>  /etc/logrotate.d/nginx << 'EOF'
/data/nginx/logs/*.log {
    
    daily
    missingok
    minsize 500M
    rotate 10
    compress
    delaycompress
    dateext
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        /usr/local/nginx/sbin/nginx -s reload
    endscript
}
EOF

cat >>  /etc/logrotate.d/site-api << 'EOF'
/tmp/serv100*.txt {
    su root root
    daily
    missingok
    minsize 500M
    rotate 10
    compress
    delaycompress
    dateext
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        for file in /etc/init.d/api*; do  $file restart  >/dev/null 2>&1; done
    endscript
}
EOF

cat >>  /etc/logrotate.d/site-admin << 'EOF'
/tmp/lottery.open.consumers*.txt 
/tmp/lottery.open.code*.txt
/tmp/consumers*.txt
{
    su root root
    daily
    missingok
    minsize 500M
    rotate 10
    compress
    delaycompress
    dateext
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        for file in /etc/init.d/api*; do  $file restart  >/dev/null 2>&1; done
    endscript
}
EOF

# 系统优化
    # 内核参数
cat > /etc/sysctl.conf << 'EOF'
vm.swappiness = 0
kernel.sysrq = 1

net.ipv4.neigh.default.gc_stale_time = 120

# see details in https://help.aliyun.com/knowledge_detail/39428.html
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2

# see details in https://help.aliyun.com/knowledge_detail/41334.html
#net.ipv4.tcp_max_tw_buckets = 5000
#net.ipv4.tcp_syncookies = 1
#net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_slow_start_after_idle = 0
#fs.file-max = 999999
#net.ipv4.tcp_tw_reuse = 1
#net.ipv4.tcp_keepalive_time = 600
#net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
net.core.netdev_max_backlog = 8096
net.core.rmem_default = 6291456
net.core.wmem_default = 6291456
net.core.rmem_max = 12582912
net.core.wmem_max = 12582912
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_recycle = 1
#net.core.somaxconn=262114
net.core.somaxconn=65535
net.ipv4.tcp_max_orphans=262114
fs.file-max = 999999
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_fin_timeout = 30
EOF

sysctl -p

 # 打开文件数
cat  >> /etc/security/limits.conf << 'EOF'
root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
EOF

# 攻击处理措施以及脚本方法
# 防火墙 以及攻击处理方法
cat  >> /tmp/iptables.sh << 'EOF'
# Generated by iptables-save v1.4.21 on Mon Dec  6 20:03:37 2021
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [4650:1972899]
-A INPUT -p icmp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -p tcp -m multiport --dports 22,80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
-A INPUT -p tcp --dport 9100 -s 159.138.20.107/32 -j ACCEPT
-A INPUT -s 127.0.0.1/32 -d 127.0.0.1/32 -j ACCEPT
-A INPUT -p udp -m udp --sport 53 -j ACCEPT
-A INPUT -p udp -m udp --dport 53 -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -j DROP
COMMIT
# Completed on Mon Dec  6 20:03:37 2021
EOF

# 加载防火墙规则
iptables-restore /tmp/iptables.sh
# iptables 限制连接数 如果 IP 在 60 秒内尝试连接到端口 80 的次数超过 15 次 处理方式
/sbin/iptables -A INPUT -p tcp --dport 80 -i eth0 -m state --state NEW -m recent --set
/sbin/iptables -A INPUT -p tcp --dport 80 -i eth0 -m state --state NEW -m recent --update --seconds 60  --hitcount 15 -j DROP

# 获取亚太地区非中国IP
cat  >> get_ip.sh << 'EOF'
#!/bin/sh
rm -rf delegated-apnic-latest && wget -cq http://ftp.apnic.net/stats/apnic/delegated-apnic-latest
rm -rf ip.txt && cat delegated-apnic-latest | awk -F '|' '/CN/&&/ipv4/ {print $4 "/" 32-log($5)/log(2)}' | cat > ip.txt
EOF
# 获取攻击IP，当前链接数最多的IP
netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n
# 获取服务器的SYN链接状态
netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'
# 针对连接数屏蔽IP大于3个的。并输出，上面是ESTABLISHED
netstat -ant |grep 80|awk '{print $5}'|awk -F":" '{print $1}'|sort |uniq -c |sort -rn |grep -v -E '192.168|127.0| $'|awk '{if ($2!=null && $1>3) {print $2}}'

#!/bin/bash
cd /data/nginx/script
cat << 'EOF' >> ban_ip.sh 
rm -f legacy-apnic-latest black_`date +%F`.conf && wget -cq http://ftp.apnic.net/apnic/stats/apnic/legacy-apnic-latest
awk -F '|' '{if(NR>2)printf("%s %s/%d%s\n","deny",$4,24,";")}' legacy-apnic-latest > black_`date +%F`.conf && rm -f /usr/local/openresty/nginx/conf/conf.d/black.conf && ln -s $PWD/black_`date +%F`.conf /usr/local/openresty/nginx/conf/conf.d/black.conf && /usr/local/openresty/bin/openresty -s   reload
EOF

# 获取DDOS脚本
chmod 0700 install.sh
./install.sh
# 卸载DDos default的操作如下：
# wget http://www.inetbase.com/scripts/ddos/uninstall.ddos
# chmod 0700 uninstall.ddos
# ./uninstall.ddos

# safedog install  安全狗
wget http://download.safedog.cn/safedog_linux64.tar.gz 


# 
