FROM drud/nginx-php-fpm7:0.1.0

ENV MAILHOG_VERSION 0.2.1
ENV PHP_INI /etc/php/7.0/fpm/php.ini

ADD files /

RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        build-essential && \
    git clone http://github.com/bmc/daemonize.git && \
    cd daemonize && \
    sh configure && \
    make && \
    make install && \
    cd - && \
    rm -rf /daemonize && \
    apt-get remove --purge -y build-essential && \
    apt-get autoremove -y && \
    apt-get clean -y && \
	rm -rf /var/lib/apt/lists/*

ADD https://github.com/mailhog/MailHog/releases/download/v${MAILHOG_VERSION}/MailHog_linux_amd64 /usr/bin/mailhog

RUN chmod ugo+x /usr/bin/mailhog

# Set development values for php.
# We want to see errors and have opcache always revalidate.
RUN sed -i -e "s/display_errors = Off/display_errors = On/g" ${PHP_INI} && \
    sed -i -e "s/display_startup_errors = Off/display_startup_errors = On/g" ${PHP_INI} && \
    sed -i -e "s/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/g" ${PHP_INI} && \
    sed -i -e "s/track_errors = Off/track_errors = On/g" ${PHP_INI} && \
    sed -i -e "s/opcache.revalidate_freq=2/opcache.revalidate_freq=0/g" ${PHP_INI}


EXPOSE 443 80 8025
