sudo yum localinstall https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
#
# 安装 软件 包
sudo yum --enablerepo=mysql80-community install mysql-community-server
# To install MySQL 5.7, you need to disable mysql80-community repository then download it. 如果安装5.7 请禁用8.0的包
sudo yum --disablerepo=mysql80-community --enablerepo=mysql57-community install mysql-community-server
#
sudo systemctl enable  --now mysqld.service
#
sudo systemctl restart mysqld.service
# Set MySQL root password
grep 'A temporary password is generated for root@localhost' /var/log/mysqld.log |tail -1
# 
# Change mysql root user password and secure database server installation:
 sudo mysql_secure_installation

GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'xejlkj546i#$%!Q@Nlmd' WITH GRANT OPTION;


# Configure Firewall if Database Server is accessed remotely
# With iptables:
sudo iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT
sudo service iptables restartt
# Firewalld:
sudo firewall-cmd --add-service mysql --permanent
sudo firewall-cmd --reload
#Test your settings:
$ mysql -u root -p
# Enter password:
############finished 参考 https://computingforgeeks.com/installing-mysql-server-on-centos-rhel/?expand_article=1

# 二进制安装#
# 安装包
wget https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.32-linux-glibc2.12-x86_64.tar.xz
wget https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-8.0.32-26/binary/tarball/percona-xtrabackup-8.0.32-26-Linux-x86_64.glibc2.17.tar.gz

(2)系统和目录规划

<1>新建目录

mkdir -p /data/mysql/{conf,data,logs,run,tmp,mysql-bin,relay-logs,shell}
conf 配置文件
data 数据目录
logs 普通日志目录
shell 基础脚本目录
run 进程文件目录
tmp 临时文件目录
mysql-bin bin log目录
relay-logs relay log目录

 
groupadd mysql
useradd -r -s /bin/false -g mysql mysql

tar -xf mysql-8.0.32-linux-glibc2.12-x86_64.tar.xz -C /data/mysql/
cd /data/mysql/
mv mysql-8.0.32-linux-glibc2.12-x86_64 mysql-server

 
cat >> /data/mysql/conf/my.cnf  << 'EOF' 
[client]
port=3306
default-character-set=utf8mb4
socket = /data/mysql/run/mysql.sock

[mysql]
# 设置mysql客户端默认字符集
default-character-set=utf8mb4
#在mysql提示符中显示当前用户、数据库、时间等信息
prompt="\\u@\\h [\\d]>" 
#不使用自动补全功能
no-auto-rehash

[mysqld]
port=3306
user = mysql
server-id = 6

#time zone
default-time-zone = SYSTEM
log_timestamps = SYSTEM

#设置mysql的安装目录
basedir=/data/mysql/mysql-server

#设置mysql数据库的数据的存放目录
datadir=/data/mysql/data
max_connections=5000
max_connect_errors=5000

#定义sock文件
socket = /data/mysql/run/mysql.sock
pid_file=/data/mysql/run/mysqld.pid

#定义打开最大文件数
open_files_limit = 65535

#服务端使用的字符集默认为UTF8
character-set-server=utf8mb4

#创建新表时将使用的默认存储引擎
default-storage-engine=INNODB

#默认使用mysql_native_password插件认证
default_authentication_plugin=mysql_native_password

#是否对sql语句大小写敏感，1表示不敏感
lower_case_table_names = 1

#关闭dns解析
skip_name_resolve = 1

#开启gtid模式
gtid-mode = on
enforce-gtid-consistency=1

#MySQL连接闲置超过一定时间后(单位：秒)将会被强行关闭
#MySQL默认的wait_timeout  值为8个小时, interactive_timeout参数需要同时配置才能生效
interactive_timeout = 28800
wait_timeout = 28800

#Metadata Lock最大时长（秒）， 一般用于控制 alter操作的最大时长sine mysql5.6
#执行 DML操作时除了增加innodb事务锁外还增加Metadata Lock，其他alter（DDL）session将阻塞
lock_wait_timeout = 3600
#内部内存临时表的最大值
#比如大数据量的group by ,order by时可能用到临时表，
#超过了这个值将写入磁盘，系统IO压力增大
tmp_table_size = 64M
max_heap_table_size = 64M

###### slow log ######
#slow存储方式
log-output=file
#开启慢查询日志记录功能
slow_query_log = 1
#慢日志记录超过1秒的SQL执行语句,可调小到0.1秒
long_query_time = 1
#慢日志文件
slow_query_log_file = /data/mysql/logs/slow3306.log
#记录由Slave所产生的慢查询
#log-slow-slave-statements = 1
#开启DDL等语句慢记录到slow log
log_slow_admin_statements = 1
#记录没有走索引的查询语句
log_queries_not_using_indexes =1
#表示每分钟允许记录到slow log的且未使用索引的SQL语句次数
log_throttle_queries_not_using_indexes = 60
#查询检查返回少于该参数指定行的SQL不被记录到慢查询日志
min_examined_row_limit = 100

#错误日志
log_error_verbosity=3
log_error=/data/mysql/logs/mysql_error.log

#一般日志开启,默认关闭
general_log=on
#一般日志文件路径
general_log_file=/data/mysql/logs/general_log.logs

####### binlog ######
##binlog 格式
binlog_format = row
##binlog文件
log-bin = /data/mysql/mysql-bin/mysql-3306-bin
##binlog的cache大小
binlog_cache_size = 4M
##binlog 能够使用的最大cache
max_binlog_cache_size = 2G
##最大的binlog file size
max_binlog_size = 1G
##当事务提交之后，MySQL不做fsync之类的磁盘同步指令刷新binlog_cache中的信息到磁盘,而让Filesystem自行决定什么时候来做同步,注重binlog安全性可以设为1
sync_binlog = 0

##procedure 
log_bin_trust_function_creators=1
##保存bin log的天数
expire_logs_days = 10

#限制mysqld的导入导出只能发生在/tmp/目录下
secure_file_priv="/data/mysql/tmp/"

#relay log
#复制进程就不会随着数据库的启动而启动
skip_slave_start = 1
#relay log的最大的大小
max_relay_log_size = 128M
#SQL线程在执行完一个relay log后自动将其删除
relay_log_purge = 1
#relay log受损后,重新从主上拉取最新的一份进行重放
relay_log_recovery = 1
#relay log文件
relay-log=/data/mysql/relay-logs/relay-bin
relay-log-index=/data/mysql/relay-logs/relay-bin.index
#开启slave写realy log到binlog中
log_slave_updates
#开启relay log自动清理,如果是MHA架构,需要关闭
relay-log-purge = 1

#设置relay log保存在mysql表里面
master_info_repository = TABLE
relay_log_info_repository = TABLE

[mysqldump]
quick
max_allowed_packet = 32M

[xtrabackup]
socket = /data/mysql/run/mysql.sock
EOF


(3)初始化实例

<1>授权
chown mysql:mysql -R /data/mysql


<2>初始化

/data/mysql/mysql-server/bin/mysqld --defaults-file=/data/mysql/conf/my.cnf --lower-case-table-names=1 --initialize-insecure

注：此处必须加上 --lower-case-table-names=1 忽略表名大小写，这个是 mysql 8 必须加的

<3>配置环境变量

echo 'export PATH=/data/mysql/mysql-server/bin:$PATH' >> /etc/profile.d/mysql8.sh
source /etc/profile.d/mysql8.sh

<4>授权

chown mysql:mysql -R /data/mysql
chown mysql:mysql /etc/profile.d/mysql8.sh

(4)启动操作
<1>基础启动关闭
1>启动

/data/mysql/mysql-server/bin/mysqld --defaults-file=/data/mysql/conf/my.cnf --user=mysql >> /data/mysql/logs/mysql-server.logs 2>&1 &

2>关闭(此处初始化没有密码)

/data/mysql/mysql-server/bin/mysqladmin -uroot -p -S /data/mysql/run/mysql.sock shutdown

<2>supervisorctl方式管理

[program:mysqld]
command=/data/mysql/mysql-server/bin/mysqld  --basedir=/data/mysql/mysql-server --datadir=/data/mysql/data --plugin-dir=/data/mysql/mysql-server/lib/plugin --log-error=/data/mysql/logs/mysql_error.log --pid-file=/data/mysql/run/mysqld.pid --socket=/data/mysql/run/mysql.sock
priority=99
user=mysql
directory=/data/tmp
autostart=true
autorestart=false
startsecs=3
startretries=999999
redirect_stderr=false
stdout_logfile=/data/logs/supervisord/mysqld.log


(5)授权操作

#进入控制台
mysql -uroot -p -S /data/mysql/run/mysql.sock

<1>root用户权限修改
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'xxxxxx';


<2>普通用户
#创建普通用户
CREATE user 'user1'@'x.x.x.%';

#添加密码
alter user 'user1'@'x.x.x.%' identified with mysql_native_password by 'xxxxxx'; 

#授权
grant select,insert,update,delete,create on *.* to 'user1'@'x.x.x.%';

#检查权限
show grants for 'user1'@'x.x.x.%'
flush privileges;

#用户检查
select Host,User,authentication_string from mysql.user;
select user,host,grant_priv from mysql.user;

#如果root用户无授权能力(grant_priv = 'N'), 则可以开起来
update mysql.user set grant_priv='Y' where user='root';

#创建新的数据库
create database data_num default character set utf8mb4 collate utf8mb4_unicode_ci;


(6)xtrabackup部署


tar -xf percona-xtrabackup-8.0.32-26-Linux-x86_64.glibc2.17.tar.gz -C /data/mysql/
cd /data/mysql/
mv percona-xtrabackup-8.0.32-26-Linux-x86_64.glibc2.17 xtrabackup

#vim /etc/profile.d/xbk.sh
export XBK=/data/mysql/xtrabackup/
export PATH=$XBK/bin:$PATH

#加载
source /etc/profile.d/xbk.sh

#查看版本：
#xtrabackup --version
2023-04-26T11:43:08.664949+08:00 0 [Note] [MY-011825] [Xtrabackup] recognized server arguments: --datadir=/var/lib/mysql --innodb_buffer_pool_size=512M 
xtrabackup version 8.0.32-26 based on MySQL server 8.0.32 Linux (x86_64) (revision id: 34cf2908)




https://www.cnblogs.com/fanrui/p/17384106.html




3 完整的脚本安装

#!/bin/bash

echo "###################################install redis#####################################################"
groupadd mysql
useradd -r -s /bin/false -g mysql mysql

curl -# -O https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.32-linux-glibc2.12-x86_64.tar.xz;
mkdir -p /data/mysql/{conf,data,logs,run,tmp,mysql-bin,relay-logs,shell}
tar -xf mysql-8.0.32-linux-glibc2.12-x86_64.tar.xz -C /data/mysql/
cd /data/mysql/
mv mysql-8.0.32-linux-glibc2.12-x86_64 mysql-server

echo '[client]
port=3306
default-character-set=utf8mb4
socket=/data/mysql/run/mysql.sock

[mysql]
#设置mysql客户端默认字符集
default-character-set=utf8mb4
#在mysql提示符中显示当前用户、数据库、时间等信息
prompt="\\u@\\h [\\d]>"
#不使用自动补全功能
no-auto-rehash

[mysqld]
port=3306
user=mysql
server-id=36

#time zone
default-time-zone=SYSTEM
log_timestamps=SYSTEM

#设置mysql的安装目录
basedir=/data/mysql/mysql-server

#设置mysql数据库的数据的存放目录
datadir=/data/mysql/data

#连接数
max_connections=5000
max_connect_errors=10000

#定义sock文件
socket=/data/mysql/run/mysql.sock
pid_file=/data/mysql/run/mysqld.pid

#定义打开最大文件数
open_files_limit=65535

#服务端使用的字符集默认为UTF8
character-set-server=utf8mb4

#创建新表时将使用的默认存储引擎
default-storage-engine=INNODB

#默认使用mysql_native_password插件认证
default_authentication_plugin=mysql_native_password

#是否对sql语句大小写敏感，1表示不敏感
lower_case_table_names=1

#关闭dns解析
skip_name_resolve=1

#开启gtid模式
gtid-mode=on
enforce-gtid-consistency=1

#MySQL连接闲置超过一定时间后(单位：秒)将会被强行关闭
#MySQL默认的wait_timeout  值为8个小时, interactive_timeout参数需要同时配置才能生效
interactive_timeout=28800
wait_timeout=28800

#Metadata Lock最大时长(秒),一般用于控制 alter操作的最大时长sine mysql5.6
#执行 DML操作时除了增加innodb事务锁外还增加Metadata Lock，其他alter(DDL)session将阻塞
lock_wait_timeout=3600
#内部内存临时表的最大值
#比如大数据量的group by ,order by时可能用到临时表，
#超过了这个值将写入磁盘，系统IO压力增大
tmp_table_size=64M
max_heap_table_size=64M

###### slow log ######
#slow存储方式
log-output=file
#开启慢查询日志记录功能
slow_query_log=1
#慢日志记录超过1秒的SQL执行语句,可调小到0.1秒
long_query_time=1
#慢日志文件
slow_query_log_file=/data/mysql/logs/slow3306.log
#记录由Slave所产生的慢查询
#log-slow-slave-statements=1
#开启DDL等语句慢记录到slow log
log_slow_admin_statements=1
#记录没有走索引的查询语句
log_queries_not_using_indexes =1
#表示每分钟允许记录到slow log的且未使用索引的SQL语句次数
log_throttle_queries_not_using_indexes=60
#查询检查返回少于该参数指定行的SQL不被记录到慢查询日志
min_examined_row_limit=100

#错误日志
log_error_verbosity=3
log_error=/data/mysql/logs/mysql_error.log

#一般日志开启,默认关闭
general_log=on
#一般日志文件路径
general_log_file=/data/mysql/logs/general_log.logs

####### binlog ######
##binlog 格式
binlog_format=row
##binlog文件
log-bin=/data/mysql/mysql-bin/mysql-3306-bin
##binlog的cache大小
binlog_cache_size=4M
##binlog 能够使用的最大cache
max_binlog_cache_size=2G
##最大的binlog file size
max_binlog_size=1G
##当事务提交之后，MySQL不做fsync之类的磁盘同步指令刷新binlog_cache中的信息到磁盘,而让Filesystem自行决定什么时候来做同步,注重binlog安全性可以设为1
sync_binlog=0

##procedure
log_bin_trust_function_creators=1
##保存bin log的天数
expire_logs_days=14

#限制mysqld的导入导出只能发生在/tmp/目录下
secure_file_priv="/data/mysql/tmp/"

#relay log
#复制进程就不会随着数据库的启动而启动
skip_slave_start=1
#relay log的最大的大小
max_relay_log_size=128M
#SQL线程在执行完一个relay log后自动将其删除
relay_log_purge=1
#relay log受损后,重新从主上拉取最新的一份进行重放
relay_log_recovery=1
#relay log文件
relay-log=/data/mysql/relay-logs/relay-bin
relay-log-index=/data/mysql/relay-logs/relay-bin.index
#开启slave写realy log到binlog中
log_slave_updates
#开启relay log自动清理,如果是MHA架构,需要关闭
relay-log-purge=1

#设置relay log保存在mysql表里面
master_info_repository=TABLE
relay_log_info_repository=TABLE

[mysqldump]
quick
max_allowed_packet=32M

[xtrabackup]
socket=/data/mysql/run/mysql.sock' >> /data/mysql/conf/my.cnf

echo "########################### primary mysql #################################"
chown mysql:mysql -R /data/mysql
/data/mysql/mysql-server/bin/mysqld --defaults-file=/data/mysql/conf/my.cnf --user=mysql --lower-case-table-names=1 --basedir=/data/mysql/mysql-server --datadir=/data/mysql/data --initialize-insecure

echo 'export PATH=/data/mysql/mysql-server/bin:$PATH' >> /etc/profile.d/mysql8.sh
source /etc/profile.d/mysql8.sh
chown mysql:mysql /etc/profile.d/mysql8.sh
chown mysql:mysql -R /data/mysql

echo '/data/mysql/mysql-server/bin/mysqld --defaults-file=/data/mysql/conf/my.cnf --user=mysql >> /data/mysql/logs/mysql-server.logs 2>&1 &' >> /data/mysql/shell/run.sh
echo '/data/mysql/mysql-server/bin/mysqladmin -uroot -p -S /data/mysql/run/mysql.sock shutdown' >> /data/mysql/shell/stop.sh
su -l
curl -# -O https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-8.0.32-26/binary/tarball/percona-xtrabackup-8.0.32-26-Linux-x86_64.glibc2.17.tar.gz;
tar -xf percona-xtrabackup-8.0.32-26-Linux-x86_64.glibc2.17.tar.gz -C /data/mysql/
cd /data/mysql/
mv percona-xtrabackup-8.0.32-26-Linux-x86_64.glibc2.17 xtrabackup

chown -R mysql:mysql /data/mysql/xtrabackup
echo 'export XBK=/data/mysql/xtrabackup/' >> /etc/profile.d/xbk.sh
echo 'export PATH=$XBK/bin:$PATH' >> /etc/profile.d/xbk.sh
chown mysql:mysql /etc/profile.d/xbk.sh
source /etc/profile.d/xbk.sh
xtrabackup --version
echo "################################## install mysql end #####################################"

echo "#### info ####
#进入控制台
mysql -uroot -p -S /data/mysql/run/mysql.sock

#root用户权限修改
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'xxxxxx';


#普通用户
#创建普通用户
CREATE user 'user1'@'x.x.x.%';

#添加密码
alter user 'user1'@'x.x.x.%' identified with mysql_native_password by 'xxxxxx';

#授权
grant select,insert,update,delete,create on *.* to 'user1'@'x.x.x.%';

#检查权限
show grants for 'user1'@'x.x.x.%'
flush privileges;

#用户检查
select Host,User,authentication_string from mysql.user;
select user,host,grant_priv from mysql.user;

#如果root用户无授权能力(grant_priv='N'), 则可以开起来
update mysql.user set grant_priv='Y' where user='root';

#创建新的数据库
create database data_num default character set utf8mb4 collate utf8mb4_unicode_ci;"








