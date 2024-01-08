From php-fpm-u:7421
ENV site_id 10000
ENV site_name admin.wlgj.777c.vip 

RUN useradd www && mkdir /home/wwwroot/
WORKDIR /var/www/html/${site_name}


# RUN echo "cd /var/www/html/ &&  php think consumers" /etc/init.d/admin${site_id}
RUN cd /var/www/html/${site_name}


ENTRYPOINT  ["/usr/local/bin/php", "think","consumers"]