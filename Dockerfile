FROM ubuntu:jammy

LABEL maintainer="JH <jh@localhost>"

ARG BUILD_DATE
ARG NAME
ARG VCS_REF
ARG BACULARIS_VERSION=6.0.0
ARG BACULA_VERSION=15.0.3
ARG PHP_VERSION=8.1

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name=$NAME \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/johann8/"


ENV BACULA_VERSION=${BACULA_VERSION}
ENV BACULARIS_VERSION=${BACULARIS_VERSION}
ENV PACKAGE_NAME=standalone
ENV UBUNTU_CODENAME=jammy
ENV UBUNTU_VERSION_ID=22.04

ENV PHP_VERSION=${PHP_VERSION}
ENV DEBIAN_FRONTEND noninteractive
ENV BACULA_KE=" https://www.bacula.org/downloads/Bacula-4096-Distribution-Verification-key.asc"
ENV BACULA_DESCRIPTION=="# Bacula Community"
ENV BACULA_REPO="https://www.bacula.org/packages/6367abb52d166/debs/${BACULA_VERSION}"

ENV WEB_USER=www-data
ENV MEMORY_LIMIT=128M

RUN apt-get update \
 && apt-get -y install curl gnupg apt-transport-https ca-certificates \
 && curl -Ls ${BACULA_KE} -o /tmp/bacula-key.asc \
 && apt-key add /tmp/bacula-key.asc \
 && rm /tmp/bacula-key.asc \
 && echo ${BACULA_DESCRIPTION} > /etc/apt/sources.list.d/Bacula-Community.list \
 && echo "deb ${BACULA_REPO} jammy main"  >> /etc/apt/sources.list.d/Bacula-Community.list \
 && apt-get update \
 && apt-get -y install --no-install-recommends bacula-common \
 && \
    if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'api-dir' ]; then \
       apt-get -y install --no-install-recommends \
                  postgresql-client \
                  dbconfig-pgsql \
                  bacula \
                  bacula-postgresql \
                  bacula-console \
                  bacula-cloud-storage-s3 \
                  #bacula-docker-plugin \
                  #bacula-docker-tools \
                  bacula-totp-dir-plugin \
                  bacula-storage-key-manager; \
       sed -i -e "/^dbc_install=/c\dbc_install='false'" -e "/^dbc_dbpass=/c\dbc_dbpass=" /etc/dbconfig-common/bacula-postgresql.conf; \
       dpkg-reconfigure bacula-postgresql; \
       # Fix job to backup catalog database
       #sed -i 's!make_catalog_backup MyCatalog!make_catalog_backup bacula!' /etc/bacula/bacula-dir.conf; \
       #sed -i 's!XXX_DBNAME_XXX!bacula!g; s!XXX_DBUSER_XXX!bacula!g; s!XXX_DBPASSWORD_XXX!bacula!g; /DirAddress = 127.0.0.1/d' /etc/bacula/bacula-dir.conf; \
    fi \
 && \
    if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'api-fd' ]; then \
       apt-get -qq -y install --no-install-recommends bacula-client; \
       #sed -i '/FDAddress = 127.0.0.1/d' /etc/bacula/bacula-fd.conf; \
    fi \
 && \
    if [ "${PACKAGE_NAME}" = 'standalone' ] || [ "${PACKAGE_NAME}" = 'web' ]; then \
       apt-get -qq -y install --no-install-recommends expect openssh-client; \
    fi \ 
 && apt-get -qq -y install --no-install-recommends nginx curl tzdata tar nano \
 && usermod -a -G bacula ${WEB_USER} \
 && chown bacula:bacula /opt/bacula/etc /opt/bacula/working \
 && chown bacula:tape /opt/bacula/archive \
 && chmod 775 /opt/bacula/etc /opt/bacula/archive /opt/bacula/working \
 && apt-get -qq -y install --no-install-recommends \
                   sudo \
                   zstd \
                   php-bcmath \
                   php-curl \
                   php-dom \
                   php-json \
                   php-ldap \
                   php-pgsql \
                   php-pgsql \
                   php-intl \
                   php-fpm \
 && apt-get clean

COPY "docker/systems/debian/sudoers.d/bacularis-${PACKAGE_NAME}" /etc/sudoers.d/

COPY "docker/systems/debian/entrypoint/docker-entrypoint.inc"  /

COPY "docker/systems/debian/entrypoint/docker-entrypoint-${PACKAGE_NAME}.sh" /docker-entrypoint.sh

#COPY rootfs/ /
COPY rootfs/etc/php/${PHP_VERSION}/cli/conf.d/ /etc/php/${PHP_VERSION}/cli/conf.d/

RUN chmod 755 /docker-entrypoint.sh

COPY bacularis /var/www/bacularis

COPY "docker/systems/debian/config/API/api-${PACKAGE_NAME}.conf" /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/api.conf

COPY --chown=${WEB_USER}:${WEB_USER} common/config/API/* /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/

COPY --chown=${WEB_USER}:${WEB_USER} common/config/Web/* /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/

RUN if [ "${PACKAGE_NAME}" = 'web' ]; then \
       rm /var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config/*.conf; \
       rm /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/*.conf; \
       sed -i '/service id="oauth"/d; /service id="api"/d; /service id="panel"/d; s!BasePath="Bacularis.Common.Pages"!BasePath="Bacularis.Web.Pages"!; s!DefaultPage="CommonPage"!DefaultPage="Dashboard"!;' /var/www/bacularis/protected/application.xml; \
    fi \
 && \
    if [ "${PACKAGE_NAME}" = 'api-dir' ] || [ "${PACKAGE_NAME}" = 'api-sd' ] || [ "${PACKAGE_NAME}" = 'api-fd' ]; then \
       rm /var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config/*.conf; \
       sed -i 's!BasePath="Bacularis.Common.Pages"!BasePath="Bacularis.API.Pages.Panel"!; s!DefaultPage="CommonPage"!DefaultPage="APIHome"!; /service id="web"/d;' /var/www/bacularis/protected/application.xml; \
    fi \
 && /var/www/bacularis/protected/tools/install.sh -w nginx -c /etc/nginx/sites-available -u ${WEB_USER} -d /var/www/bacularis/htdocs -p /var/run/php/php${PHP_VERSION}-fpm.sock \
 && ln -s /etc/nginx/sites-available/bacularis-nginx.conf /etc/nginx/sites-enabled/

RUN tar czf /bacula-dir.tgz /opt/bacula/etc /opt/bacula/scripts

RUN tar czf /bacularis-app.tgz /var/www/bacularis

RUN tar czf /bacula-sd.tgz /opt/bacula/archive /opt/bacula/working /opt/bacula/bsr

EXPOSE 9101/tcp 9102/tcp 9103/tcp 9097/tcp

VOLUME ["/opt/bacula/etc/", "/opt/bacula/archive", "/opt/bacula/working", "/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Config", "/var/www/bacularis/protected/vendor/bacularis/bacularis-api/API/Logs", "/var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Config", "/var/www/bacularis/protected/vendor/bacularis/bacularis-web/Web/Logs"]

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD ["nginx", "-g", "daemon off;"]
