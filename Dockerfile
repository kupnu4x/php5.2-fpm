FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install software-properties-common -y
RUN apt-get upgrade -y
RUN apt-get install -y wget curl build-essential git autoconf bison libcurl4-openssl-dev libgmp-dev libmcrypt-dev libaspell-dev libpspell-dev libssl-dev libbz2-dev libfreetype6-dev libjpeg-dev libmysqlclient-dev libpng-dev librecode-dev libXpm-dev libz-dev libxml2-dev apache2 apache2-dev apache2-threaded-dev libapache2-mod-geoip libapache2-mod-rpaf libtool exim4-base exim4 exim4-daemon-light
RUN a2dismod mpm_event && a2enmod mpm_prefork && a2enmod rewrite && a2enmod geoip && a2enmod rpaf
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf
RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/
RUN ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib/
RUN ln -s /usr/lib/x86_64-linux-gnu/libXpm.so /usr/lib/
RUN ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib/
RUN ln -s /usr/lib/x86_64-linux-gnu/libpng.so /usr/lib/
RUN mkdir /usr/include/freetype2/freetype
RUN ln -s /usr/include/freetype2/freetype.h /usr/include/freetype2/freetype/freetype.h
RUN cd /usr/local/src/ && wget http://museum.php.net/php5/php-5.2.17.tar.gz && tar xfz php-5.2.17.tar.gz
RUN cd /usr/local/src/php-5.2.17 && curl -s https://php-fpm.org/downloads/php-5.2.17-fpm-0.5.14.diff.gz | gunzip | patch -p1
COPY ./mod_proxy_fcgi-support-v3_for_fpm-5.2.17.patch /usr/local/src/
RUN cd /usr/local/src/php-5.2.17 && patch -p1 < ../mod_proxy_fcgi-support-v3_for_fpm-5.2.17.patch
COPY ./libxml29_compat.patch /usr/local/src/
RUN cd /usr/local/src/php-5.2.17 && patch -p0 < ../libxml29_compat.patch
COPY ./openssl.patch /usr/local/src/
RUN cd /usr/local/src/php-5.2.17 && patch -p0 < ../openssl.patch
COPY ./gmp.patch /usr/local/src/
RUN cd /usr/local/src/php-5.2.17 && patch -p0 < ../gmp.patch
COPY ./php5.2_with_apache2.4.patch /usr/local/src/
RUN cd /usr/local/src/php-5.2.17 && patch -p1 < ../php5.2_with_apache2.4.patch
COPY ./bug61172.patch /usr/local/src/
RUN cd /usr/local/src/php-5.2.17 && patch -p0 < ../bug61172.patch ; /bin/true
RUN cd /usr/local/src/php-5.2.17 && ./configure --prefix=/opt/php52 --with-config-file-path=/opt/php52/etc --with-config-file-scan-dir=/opt/php52/etc/php.d --with-apxs2=/usr/bin/apxs --with-libdir=/lib/x86_64-linux-gnu --enable-cgi --with-mysql=shared --enable-bcmath=shared --enable-calendar=shared --enable-exif=shared --enable-ftp=shared --enable-json=shared --enable-mbstring=shared --enable-pcntl=shared --enable-sockets --enable-sysvmsg=shared --enable-sysvsem=shared --enable-sysvshm=shared --enable-wddx=shared --enable-zip=shared --with-curl=shared --with-gd=shared --with-gmp=shared --with-iconv=shared --with-mcrypt=shared --with-pspell=shared --with-openssl --enable-gd-jis-conv --enable-gd-native-ttf --with-bz2=/usr --with-freetype-dir=/usr --with-gettext=/usr --with-jpeg-dir=/usr --with-mysqli=/usr/bin/mysql_config --with-pdo-mysql=/usr --with-png-dir=/usr --with-xpm-dir=/usr --with-zlib-dir=/usr --with-zlib=/usr
RUN cd /usr/local/src/php-5.2.17 && make
RUN cd /usr/local/src/php-5.2.17 && make install
COPY ./php5.conf /etc/apache2/mods-available/
RUN a2enmod php5
COPY ./000-default.conf /etc/apache2/sites-available/
RUN mkdir -p /opt/php52/etc/php.d/
RUN /opt/php52/bin/pecl install memcache
RUN echo 'extension=memcache.so' >> /opt/php52/etc/php.d/memcache.ini
RUN /opt/php52/bin/pecl install apc
RUN echo 'extension=apc.so' >> /opt/php52/etc/php.d/apc.ini
RUN /opt/php52/bin/pecl install --ignore-errors timezonedb
RUN echo 'extension=timezonedb.so' >> /opt/php52/etc/php.d/timezonedb.ini
COPY ./php.ini /opt/php52/etc/
RUN mkdir -p /var/lib/php/session
RUN chown www-data:www-data /var/lib/php/session
EXPOSE 80
VOLUME /var/www/vhosts/default/
RUN update-rc.d apache2 defaults
COPY ./entrypoint.sh /
ENTRYPOINT /entrypoint.sh
