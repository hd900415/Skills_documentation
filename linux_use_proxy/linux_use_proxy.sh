# use trojan proxy 
# 下载最新的客户端程序
cd /opt && wget https://github.com/trojan-gfw/trojan/releases/trojan-$version-linux-amd64.tar.xz  # trojan-1.16.0-linux-amd64.tar.xz 
tar xf trojan-1.16.0-linux-amd64.tar.xz 

# 配置trojan
cd /opt/trojan 
cp examples/client.json-example ./client.json 
# 编辑配置文件
vim .client.json 
run_type 修改为 "client"
local_port 修改为 1080
remote_addr 修改为 vpn.xxx.cn
remote_port 修改为 443
password 修改为 ["123456"] trojan服务端验证密码
# example like this 
"run_type": "client",
"local_addr": "0.0.0.0",
"local_port": 1080,
"remote_addr": "jpo123.ovod.me", # 更改
"remote_port": 443,
"password": ["123456"],  # 更改

# ssl中的 verify 值修改为 false （如果配置文件中没有，则添加这个配置）
# ssl中的 verify_hostname 值修改为 false （如果配置文件中没有，则添加这个配置）
# ssl中的 cert 修改为 “” （改成空的）
# like this 
"ssl": {
    "verify": false,
    "verify_hostname": false,
    "cert": "",
    }

cat <<'EOF' >> client.json 
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "youlecheng.vip",
    "remote_port": 443,
    "password": [
        "RN6ikPLe"
    ],
    "log_level": 1,
    "ssl": {
        "verify": false,
        "verify_hostname": false,
        "cert": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF

# 配置systemctl 启动
cat <<'EOF' >> /etc/systemd/system/trojan.service 
[Unit]
Description=trojan
After=network.target

[Service]
Type=simple
PIDFile=/opt/trojan/trojan.pid
ExecStart=/opt/trojan/trojan -c /opt/trojan/client.json -l /opt/trojan/trojan.log
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
EOF

# 启动 tonjan 
systemctl daemon-reload
systemctl restart trojan
systemctl enable trojan

# 安装代理工具

yum install -y epel-release proxychains-ng # or yum -y install   privoxy

# 配置proxychains-ng 
vim /etc/proxychains.conf # 最后一行添加 如下
socks5         127.0.0.1 1080

# 环境变量添加
vim ~/.bash_profile # 最后添加一下内容
alias pcx='proxychains -q'

source ~/.bash_profile

#使用  在命令前添加 pcx 

[root@hn ~]# pcx curl cip.cc
IP	: 154.31.24.37
地址	: 美国  美国
数据二	: 美国
数据三	: 
URL	: http://www.cip.cc/154.31.24.37

[root@hn ~]# curl cip.cc
IP	: 42.236.82.248
地址	: 中国  河南  郑州
运营商	: 联通
数据二	: 河南省郑州市 | 联通
数据三	: 中国河南省郑州市 | 联通
URL	: http://www.cip.cc/42.236.82.248

