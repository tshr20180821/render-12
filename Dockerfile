FROM debian:stable-slim

SHELL ["/bin/bash", "-c"]

EXPOSE 80
ENV DEBIAN_CODE_NAME=bookworm

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive
ENV DISTCCD_LOG_FILE=/var/www/html/auth/distccd_log.txt

RUN set -x \
 && TEST_STRING=$(cat /etc/os-release | grep VERSION_CODENAME) \
 && TEST_STRING=${TEST_STRING:17} \
 && echo "deb http://deb.debian.org/debian ${DEBIAN_CODE_NAME}-backports main contrib non-free" | tee /etc/apt/sources.list.d/backports.list \
 && time apt-get -qq update \
 && time apt-get -q -y --no-install-recommends install \
  apache2 \
  build-essential \
  ca-certificates \
  curl/"${DEBIAN_CODE_NAME}"-backports \
  distcc \
  dnsutils \
  dropbear \
  gcc-x86-64-linux-gnu \
  iproute2 \
  libpam-systemd \
  netcat-openbsd \
  openssh-server \
  openssl \
 && dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key \
 && mkdir /var/run/apache2 \
 && a2dissite -q 000-default.conf \
 && mkdir -p /var/www/html/auth \
 && chown www-data:www-data /var/www/html/auth -R \
 && echo '<HTML />' >/var/www/html/index.html \
 && \
  { \
    echo 'User-agent: *'; \
    echo 'Disallow: /'; \
  } >/var/www/html/robots.txt \
 && a2enmod \
  authz_groupfile \
  proxy \
  proxy_http \
 && touch "${DISTCCD_LOG_FILE}" \
 && chmod 666 "${DISTCCD_LOG_FILE}"

COPY ./apache.conf /etc/apache2/sites-enabled/
COPY --chmod=755 ./*.sh ./

STOPSIGNAL SIGWINCH

ENTRYPOINT ["/bin/bash","/app/start.sh"]
