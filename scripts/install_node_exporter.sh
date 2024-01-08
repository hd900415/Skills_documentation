#/bin/bash
#!

mkdir -p /data/prometheus/client/ && cd /data/prometheus/client/ && wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz && 
tar xf node_exporter-1.3.1.linux-amd64.tar.gz &&  mv node_exporter-1.3.1.linux-amd64  node_exporter && 
cd node_exporter && rm -rf LICENSE NOTICE && mkdir -p /data/prometheus/client/node_exporter/client

yum -y  install epel-release && yum -y  install supervisor && 
cat << 'EOF' >> /etc/supervisord.d/node_exporter.ini 
[program:nodeexporter]
command=/data/prometheus/client/node_exporter/node_exporter --collector.tcpstat --collector.systemd --collector.processes
directory=/data/prometheus/client/node_exporter/client
stdout_logfile=/data/prometheus/client/node_exporter/node_exporter.log
autostart=true
autorestart=true
redirect_stderr=true
user=root
startsecs=3
EOF

systemctl enable supervisord && systemctl start supervisord && systemctl status supervisord 

supervisorctl status 



# 更好IP地址和主机名
,
  {
    "targets": [
      "18.167.105.42:9100"
    ],
    "labels": {
      "group": "linux",
      "app": "php",
      "hostname": "robot-wx"
    }
  },
  {
    "targets": [
      "119.13.84.127:9100"
    ],
    "labels": {
      "group": "linux",
      "app": "proxy",
      "hostname": "adminapi-proxy-hk-huawei-02"
    }
  }




# prometheus + grafana + mysql + Loki + node_exporter监控节点 监控系统部署

# 1. 下载Prometheus软件
mkdir -p  /data/prometheus{rule,file_config,prometheus-data,prometheus_bot,prome_alert} && cd  /data/prometheus && 
 wget https://github.com/prometheus/prometheus/releases/download/v2.33.3/prometheus-2.33.3.linux-amd64.tar.gz
 tar xf prometheus-2.33.3.linux-amd64.tar.gz -C ./ && rm -rf LICENSE NOTICE 

# 2. 部署配置文件
  2.1 主配置文件
  cat <<'EOF'>> prometheus.yml 
# my global config
global:
  scrape_interval: 60s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 60s # Evaluate rules every 15 seconds. The default is every 1 minute.
  scrape_timeout: 15s
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
           - localhost:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
   - "rules/*.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]
    
  - job_name: "linux"
    file_sd_configs:
    - files:
      - file_config/hosts/host.json
EOF
# 2.2 监控主机配置文件
cat <<'EOF'>> /data/prometheus/file_config/hosts/host.json 
[
  {
    "targets": [
      "2.59.155.30:9100"
    ],
    "labels": {
      "group": "linux",
      "app": "php",
      "hostname": "ceshi"
    }
  },
  {
    "targets": [
      "16.163.69.141:9100"
    ],
    "labels": {
      "group": "linux",
      "app": "php",
      "hostname": "admin2"
   }
  }
EOF
# 2.3 rules 配置文件
cat <<'EOF'>> /data/prometheus/rules/check_url_rule.yml 
groups:
  - name: httpd url check
    rules:
      - alert: http_url_check failed
        for: 5s
        expr: probe_success{job="http_url_check"} == 0
        labels:
          serverity: critical
        annotations:
          description: "{{ $labels.group }}的{{ $labels.app }} url检测失败,当前probe_success的值为{ { $value }}"
          summary: "{{ $labels.group }}组的应用 {{ $labels.app }} url接口检测不通"
EOF
cat <<'EOF'>> /data/prometheus/rules/linux_rules.yml 
groups: 
  - name: linux_alert
    rules: 
      - alert: "linux load5 over 10"
        for: 5s
        expr: node_load5 > 10
        labels:
          serverity: critical
        annotations:
          description: "{{ $labels.app }}  over 10,当前值:{{ $value }}"
          summary: "linux load5  over 10"
 
      - alert: "node explorter have down"
        for: 5s
        expr: up==0
        labels:
          serverity: critical
        annotations:
          description: "{{ $labels.app }} -- {{ $labels.instance }} ,当前值:{{ $value }}"
          summary: "node explorter value equle 0"
 
      - alert: "cpu used percent over 80% per 1 min"
        for: 5s
        expr: 100 * (1 - avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[1m])))  * on(instance) group_left(hostname) node_uname_info > 80
        labels:
          serverity: critical
        annotations:
          description: "{{ $labels.app }} -- {{ $labels.instance }} ,当前值:{{ $value }}"
          summary: "cpu used percent over 80% per 1 min"
 
      - alert: "memory used percent over 85%"
        for: 5m
        expr: ((node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Buffers_bytes - node_memory_Cached_bytes) / (node_memory_MemTotal_bytes{instance!~"172..*"})) * 100 > 85
        labels:
          serverity: critical
        annotations:
          description: "{{ $labels.app }} -- {{ $labels.instance }} ,当前值:{{ $value }}"
          summary: "memory used percent over 85%"
 
      - alert: "eth0 input traffic network over 10M"
        for: 3m
        expr: sum by(instance) (irate(node_network_receive_bytes_total{device="eth0",instance!~"172.1.*|172..*"}[1m]) / 128/1024) * on(instance) group_left(hostname) node_uname_info > 10
        labels:
          serverity: critical
        annotations:
          description: "{{ $labels.app }} -- {{ $labels.instance }} ,当前值:{{ $value }}"
          summary: "eth0 input traffic network over 10M"
 
      - alert: "eth0 output traffic network over 10M"
        for: 3m
        expr: sum by(instance) (irate(node_network_transmit_bytes_total{device="eth0",instance!~"172.1.*|175.*"}[1m]) / 128/1024) * on(instance) group_left(hostname) node_uname_info > 10
        labels:
          serverity: critical
        annotations:
          description: "{{ $labels.app }} -- {{ $labels.instance }} ,当前值:{{ $value }}"
          summary: "eth0 output traffic network over 10M"
 
      - alert: "disk usage over 80%"
        for: 10m
        expr: (node_filesystem_size_bytes{device=~"/dev/.+"} - node_filesystem_free_bytes{device=~"/dev/.+"} )/ node_filesystem_size_bytes{device=~"/dev/.+"} * 100 > 80
        labels:
          serverity: critical
        annotations:
          description: "{{ $labels.mountpoint }} 分区 over 80%,当前值:{{ $value }}"
          summary: "disk usage over 80%"
EOF

cat <<'EOF'>> /data/prometheus/rules/tcp_port_check.yml 
groups:
  - name: tcp port check
    rules:
      - alert: tcp_port_check failed
        for: 5s
        expr: probe_success{job="tcp_port_check"} == 0
        labels:
          serverity: critical
        annotations:
          description: "{{ $labels.group }}的{{ $labels.app }} tcp检测失败,当前probe_success的值为{ { $value }}"
          summary: "{{ $labels.group }}组的应用 {{ $labels.app }} 端口检测不通"
EOF
2.4


# 3. systemd 管理进程 or supervisord 管理进程

cat <<'EOF' >> /usr/lib/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring System
Documentation=Prometheus Monitoring System
[Service]
ExecStart=/data/prometheus/prometheus \
        --config.file=/data/prometheus/prometheus.yml \
        --storage.tsdb.path=/data/prometheus/prometheus-data 
        --web.console.templates=/data/prometheus/consoles \
        --web.console.libraries=/data/prometheus/console_libraries \
        --log.level=info
        --web.listen-address="0.0.0.0:9090"
[Install]
WantedBy=multi-user.target
EOF
systemctl start prometheus

cat <<'EOF' >> /etc/supervisord.d/prometheus.ini 
[program:prometheus]
command=/data/prometheus/prometheus --config.file=/data/prometheus/prometheus.yml --storage.tsdb.path=/data/prometheus/prometheus-data --web.console.templates=/data/prometheus/consoles --web.console.libraries=/data/prometheus/console_libraries  --log.level=info --web.listen-address="0.0.0.0:9090"
directory=/data/prometheus/
stdout_logfile=/data/prometheus/prometheus.log
autostart=true
autorestart=true
redirect_stderr=true
user=root
startsecs=3
EOF
supervisorctl reload

#######prometheus 已部署完成 准备部署grafana 
# 1. 安装grafana
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-8.4.1-1.x86_64.rpm
sudo yum install grafana-enterprise-8.4.1-1.x86_64.rpm
or yum -y install https://dl.grafana.com/enterprise/release/grafana-enterprise-8.4.1-1.x86_64.rpm
# 2.安装mysql
mkdir -p /data/mysql/{conf,data,log}

cat <<'EOF' >> my.cnf 
[mysql]
default-character-set=utf8
socket=/var/lib/mysql/mysql.sock

[mysqld]
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd
max_connections=200
character-set-server=utf8
default-storage-engine=INNODB
lower_case_table_names=1
max_allowed_packet=16M 
default-time_zone='+8:00'
[mysqld_safe]
log-error=/var/log/mysql/mysql.log
pid-file=/var/run/mysql/mysql.pid

#
# include all files from the config directory
#
EOF

docker run -d \
-p 3306:3306 \
--privileged=true \
--name mysql \
-v /data/mysql/conf:/etc/mysql \
-v /data/mysql/data:/var/lib/mysql \
-v /data/mysql/log:/var/log/mysql \
-e MYSQL_ROOT_PASSWORD=nRsMJ2MEYxyktcYh \
--restart always  \
mysql:5.7

# 创建grafana数据库

# 配置grafana.ini
vim /etc/grafana/grafana.ini
  # 1. 修改数据库链接方式
  # 2. 修改http 的监听地址
  # 3. 启动grafana
  # 4. 
systemctl restart grafana-server
systemctl enable grafana-server

# 根据日志排错  tail -f /var/log/grafana/grafana.log  


# alertmanager telegram 报警部署
docker run -d -e 'ALERTMANAGER_URL=http://alert.ouwosw.com' \
-e 'BOLT_PATH=/data/prometheus/alertmanager/data/bot.db' \
-e 'STORE=bolt' \
-e 'TELEGRAM_ADMIN=2143538719' \
-e 'TELEGRAM_TOKEN=5034420902:AAFo9TEywqSdh7mdlkzOR3f7vRrj6hTvRpw' \
-v '/data/prometheus/alertmanager/data/:/data'   \
-p 8080:8080 \
--name alertmanager-bot \
metalmatze/alertmanager-bot:0.4.3




docker run -d \
	-e 'ALERTMANAGER_URL=http://45.207.36.60:9093' \
	-e 'BOLT_PATH=/data/bot.db' \
	-e 'STORE=bolt' \
	-e 'TELEGRAM_ADMIN=2143538719' \
	-e 'TELEGRAM_TOKEN=5034420902:AAFo9TEywqSdh7mdlkzOR3f7vRrj6hTvRpw' \
	-v '/data/prometheus/alertmanager/data/:/data' \
  -v /data/prometheus/alertmanager/template/default.tmpl:/templates/default.tmpl \
  -p 8080:8080 \
	--name alertmanager-bot \
	metalmatze/alertmanager-bot:0.4.3



