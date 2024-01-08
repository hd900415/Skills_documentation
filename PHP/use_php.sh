# install openrestry 
# 参照openresty的安装方式
更改OPenresty 的nginx 配置
location~\.php${
	root	html;
	fastcgi_pass  127.0.0.1:9000;
	fastcgi_index  index.php;
	fastcgi_param SCRIPT_FIENAME      /www/web$fastcgi_script_name;
	#将/scripts 修改为nginx的发布目录
	include	fastcgi_params
}
# 2.编译安装PHP 
# 2.1 版本选择
# https://www.php.net/releases/  在官网选择对应版本的TRA包


wget https://www.php.net/distributions/php-7.4.29.tar.gz 

1.下载好之后，上传到自己的虚拟机中

 tar -zxvf php-7.4.29.tar.gz -C /usr/local/ //解压到指定目录 

2.进入php文件进行配置

## 安装依赖包
yum -y install libxml2 libxml2-devel \
    openssl openssl-devel bzip2 bzip2-devel \
    libcurl libcurl-devel libjpeg libjpeg-devel \
    libpng libpng-devel freetype freetype-devel gmp \
    gmp-devel libmcrypt libmcrypt-devel readline readline-devel \
    libxslt libxslt-devel zlib zlib-devel glibc glibc-devel glib2 \
    glib2-devel ncurses curl gdbm-devel db4-devel libXpm-devel \
    libX11-devel gd-devel gmp-devel expat-devel xmlrpc-c \
    xmlrpc-c-devel libicu-devel libmcrypt-devel \
    libmemcached-devel epel-release gcc 


yum localinstall http://www6.atomicorp.com/channels/atomic/centos/7/x86_64/RPMS/oniguruma-5.9.5-3.el7.art.x86_64.rpm 
yum localinstall http://www6.atomicorp.com/channels/atomic/centos/7/x86_64/RPMS/oniguruma-devel-5.9.5-3.el7.art.x86_64.rpm


cd  php-7.4.29
## 配置编译参数
./configure --prefix=/usr/local/php7 --with-config-file-path=/etc --with-fpm-user=www --with-fpm-group=www --with-curl --with-freetype-dir --enable-gd --with-gettext --with-iconv-dir --with-kerberos --with-libdir=lib64 --with-libxml-dir --with-mysqli --with-openssl --with-pcre-regex --with-pdo-mysql --with-pdo-sqlite --with-pear --with-png-dir --with-jpeg-dir --with-xmlrpc --with-xsl --with-zlib --with-bz2 --with-mhash --enable-fpm --enable-bcmath --enable-libxml --enable-inline-optimization --enable-mbregex --enable-mbstring --enable-opcache --enable-pcntl --enable-shmop --enable-soap --enable-sockets --enable-sysvsem --enable-sysvshm --enable-xml --enable-zip --enable-fpm
配置过程可能出现这样的问题：