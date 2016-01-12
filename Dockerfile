FROM phusion/baseimage
MAINTAINER Alejandro F. Carrera <alej4fc@gmail.com>

# Exports
ENV HOME="/root" \
    COMPOSER_HOME="/var/www/html" \
    MYSQL_PASS="secret" \
    DEBIAN_FRONTEND="noninteractive"

RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d

#Install Apache2, PHP5 and MySQL Client
RUN apt-get -qq update && \
	apt-get -qq -y install \
		apache2 php5 curl git \
		pwgen php5-mcrypt \
		php5-json php5-mysqlnd \
		mysql-client-5.6 \
		npm

#Create a symlink for node
RUN update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10

#Configure PHP
RUN php5enmod mcrypt
RUN php5enmod json

#Configure apache	
RUN /usr/sbin/a2enmod rewrite
RUN /usr/sbin/a2enmod ssl
RUN /usr/sbin/a2ensite default-ssl
ADD ./files/000-default.conf /etc/apache2/sites-enabled/000-default.conf

#Install composer
RUN /usr/bin/curl -sS https://getcomposer.org/installer |/usr/bin/php
RUN /bin/mv composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

#Install bower
RUN npm install -g bower

# Configure runit
ADD ./my_init.d/ /etc/my_init.d/
ONBUILD ./my_init.d/ /etc/my_init.d/

CMD ["/sbin/my_init"]

# Ports
EXPOSE 80 443

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
