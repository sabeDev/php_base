FROM php:8.3-apache-bookworm

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libaio1 \
    libaio-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libssl-dev \
    libxml2-dev \
    libldap2-dev \
    unixodbc-dev \
    gnupg2 \
    apt-transport-https \
    wget \
    unzip \
    libonig-dev \
    libsodium-dev \
    curl \
    libcurl4-openssl-dev \
    apt-utils \
    && rm -rf /var/lib/apt/lists/*

# Oracle Instant Client (x64)
RUN mkdir -p /opt/oracle \
    && cd /opt/oracle \
    && wget -q https://download.oracle.com/otn_software/linux/instantclient/1918000/instantclient-basiclite-linux.x64-19.18.0.0.0dbru.zip \
    && wget -q https://download.oracle.com/otn_software/linux/instantclient/1918000/instantclient-sdk-linux.x64-19.18.0.0.0dbru.zip \
    && unzip -q instantclient-basiclite-linux.x64-19.18.0.0.0dbru.zip \
    && unzip -q instantclient-sdk-linux.x64-19.18.0.0.0dbru.zip \
    && rm -f *.zip \
    && ln -s /opt/oracle/instantclient_19_18 /opt/oracle/instantclient \
    && echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

ENV LD_LIBRARY_PATH=/opt/oracle/instantclient
ENV ORACLE_HOME=/opt/oracle/instantclient

# Microsoft ODBC Driver 18 for SQL Server (x64)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 \
    && rm -rf /var/lib/apt/lists/*

# PHP core extensions (auto-detects architecture library path)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure ldap --with-libdir=lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)/ \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/opt/oracle/instantclient \
    && docker-php-ext-install -j$(nproc) gd soap pdo_mysql ldap oci8 opcache

# PECL extensions (sqlsrv, pdo_sqlsrv, and xdebug)
RUN pecl install xdebug sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable xdebug sqlsrv pdo_sqlsrv

# Universal PHP runtime configuration
RUN { \
        echo "date.timezone=Europe/Brussels"; \
        echo "max_execution_time=120"; \
        echo "default_socket_timeout=120"; \
        echo "memory_limit=128M"; \
        echo "opcache.enable=1"; \
        echo "opcache.validate_timestamps=1"; \
        echo "opcache.revalidate_freq=2"; \
    } >> /usr/local/etc/php/conf.d/custom.ini

# Shared Xdebug configuration (controlled per environment via XDEBUG_MODE env var)
RUN { \
        echo "xdebug.mode=debug"; \
        echo "xdebug.start_with_request=trigger"; \
        echo "xdebug.client_host=host.containers.internal"; \
        echo "xdebug.client_port=9003"; \
        echo "xdebug.log_level=0"; \
    } >> /usr/local/etc/php/conf.d/xdebug.ini

RUN a2enmod rewrite
WORKDIR /var/www/html
EXPOSE 80
CMD ["apache2-foreground"]