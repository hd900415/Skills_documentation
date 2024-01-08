#!/bin/bash
#1.安装客户端包
#下载trojan包：https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
wget https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
tar xf trojan-1.16.0-linux-amd64.tar.xz -C /opt/
#2.编辑配置文件 client.json
# 复制一份客户端json配置文件 (压缩包解压在/opt/trojan目录下面)
cd /opt/trojan
cp examples/client.json-example client.json
chmod +x trojan

# 基本配置修改
    "run_type": "client",  // 运行类型
    "local_addr": "127.0.0.1",  // 本地监听地址
    "local_port": 1080,  // 本地监听端口
    "remote_addr": "",  // 服务端的ip或域名
    "remote_port": 443,  // 对应服务端的端口
    "password": [
        "passwd" // 对应服务端设置的密码
    ],

# ssl配置修改 (这里不用证书，修改true为false)
    "verify": false, 
    "verify_hostname": false,
    "cert": "",
    "sni": "",

# 其他的默认不用修改

# 3. 启动trojan服务
# 测试配置文件是否有问题
/opt/trojan/trojan -t /opt/trojan/client.json

# 后台运行
/opt/trojan/trojan -c /opt/trojan/client.json -l /opt/trojan/trojan.log 2>&1 &

# 确认本机1080端口是否存在
netstat -tnlp 

# 4.安装 proxychains 代理

# 安装epel 源
yum install epel-release

# 安装 proxychains 
yum install proxychains-ng -y
# 配置文件：/etc/proxychains.conf （配置文件最下面注释掉socks4 添加一个socks5）

[ProxyList]
# add proxy here ...
# meanwile
# defaults set to "tor"
#socks4     127.0.0.1 9050

# ip和端口client.json配置文件中对应
socks5     127.0.0.1 1080  


# 5. 代理测试
# 给命令做一个别名方便使用（全局生效配置加在 /etc/profile，指定用户生效加在用户目录下配置文件）
echo "alias proxy='proxychains -q'" >> ~/.bash_profile
source ~/.bash_profile

# 使用本地网络
curl http://xxxxxx

# 使用代理网络（只用前面加上proxy就可以）
proxy curl http://xxxxx

