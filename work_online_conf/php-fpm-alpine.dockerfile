FROM php:7.4-fpm-alpine

RUN \
    curl -sfL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
    chmod +x /usr/bin/composer                                                                     && \
    composer self-update --clean-backups 2.0.13                                    && \
    apk update && \
    apk add --no-cache libstdc++ && \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS curl-dev openssl-dev pcre-dev pcre2-dev zlib-dev tzdata rabbitmq-c-dev  && \
    /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai'>/etc/timezone && \
    docker-php-ext-install sockets && \
    docker-php-source extract 
RUN \
    wget http://pecl.php.net/get/redis-5.3.4.tgz -O /tmp/redis.tar.tgz \
    && pecl install /tmp/redis.tar.tgz \
    && rm -rf /tmp/redis.tar.tgz \
    && docker-php-ext-enable redis
RUN \
    mkdir /usr/src/php/ext/swoole && \
    curl -sfL https://github.com/swoole/swoole-src/archive/v4.6.7.tar.gz -o swoole.tar.gz && \
    tar xfz swoole.tar.gz --strip-components=1 -C /usr/src/php/ext/swoole && \
    docker-php-ext-configure swoole \
        --enable-http2   \
        --enable-mysqlnd \
        --enable-openssl \
        --enable-sockets --enable-swoole-curl --enable-swoole-json && \
    docker-php-ext-install -j$(nproc) swoole && \
    rm -f swoole.tar.gz $HOME/.composer/*-old.phar 
RUN pecl install amqp && docker-php-ext-enable amqp
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install bcmath

RUN wget -O async-ext.zip http://dl.appleasp.com/lnmp/src/async-ext.zip && \
    unzip async-ext.zip  && \
    rm async-ext.zip  && \
    cd async-ext  && \
    /usr/local/bin/phpize  && \
    chmod +x configure  && \
    ./configure   --with-php-config=/usr/local/bin/php-config  && \
    make -j  && \
    make install && \
    cd ../ && \
    rm -r async-ext  && \
    docker-php-ext-enable swoole_async && \
    docker-php-source delete && \
    apk del .build-deps


WORKDIR /var/www/

EXPOSE 9000
ENTRYPOINT ["php-fpm","-y","/usr/local/etc/php-fpm.conf"]
