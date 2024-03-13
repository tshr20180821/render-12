#!/bin/bash

set -x

export PS4='+(${BASH_SOURCE}:${LINENO}): '

SSH_USER=$(tr -dc '[:lower:]' </dev/urandom | fold -w 1 | head -n 1)$(tr -dc 'a-z0-9' </dev/urandom | fold -w 15 | head -n 1)
export SSH_USER
SSH_PASSWORD=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)
export SSH_PASSWORD

mkdir /var/run/sshd

export NOTVISIBLE='in users profile'
echo 'export VISIBLE=now' >> /etc/profile

useradd -b /home -m -N -s /bin/bash "${SSH_USER}"
echo "${SSH_USER}:${SSH_PASSWORD}" | chpasswd
usermod -aG root "${SSH_USER}"

mkdir -p /home/"${SSH_USER}"/.ssh
chmod 700 /home/"${SSH_USER}"/.ssh

ssh-keygen -f /home/"${SSH_USER}"/.ssh/"${RENDER_EXTERNAL_HOSTNAME}"-"${SSH_USER}" -t rsa -N "" &

/usr/bin/distccd --port=3632 --listen=127.0.0.1 --user=nobody --jobs=$(($(nproc)/2)) --log-level=debug --log-file="${DISTCCD_LOG_FILE}" --daemon --stats --stats-port=3633 --allow-private --job-lifetime=3600

wait

sed -i 's/root/'"${SSH_USER}"'/' /home/"${SSH_USER}"/.ssh/"${RENDER_EXTERNAL_HOSTNAME}"-"${SSH_USER}".pub
cat /home/"${SSH_USER}"/.ssh/"${RENDER_EXTERNAL_HOSTNAME}"-"${SSH_USER}".pub >>/etc/dropbear/authorized_keys
cat /home/"${SSH_USER}"/.ssh/"${RENDER_EXTERNAL_HOSTNAME}"-"${SSH_USER}".pub >>/home/"${SSH_USER}"/.ssh/authorized_keys

chown -R "${SSH_USER}":users /home/"${SSH_USER}"

# dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
/usr/sbin/dropbear -Eamswp 127.0.0.1:8022 -I 3600

PASSWORD="$(echo -n "${RENDER_EXTERNAL_HOSTNAME}""${DUMMY_STRING_1}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"
KEYWORD=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 64 | head -n 1)

KEYWORD_FILENAME="$(echo "${KEYWORD_FILENAME}""${DUMMY_STRING_2}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"
SSH_USER_FILENAME="$(echo "${SSH_USER_FILENAME}""${DUMMY_STRING_3}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"
SSH_KEY_FILENAME="$(echo "${SSH_KEY_FILENAME}""${DUMMY_STRING_4}""$(date +%Y/%m/%d)" | base64 -w 0 | sed 's/[+\/=]//g')"

echo -n "${KEYWORD}" >/var/www/html/auth/"${KEYWORD_FILENAME}"
echo -n "${SSH_USER}" >/var/www/html/auth/"${SSH_USER_FILENAME}"
cp /home/"${SSH_USER}"/.ssh/"${RENDER_EXTERNAL_HOSTNAME}"-"${SSH_USER}" /var/www/html/auth/"${SSH_KEY_FILENAME}"
chmod 666 /var/www/html/auth/"${SSH_KEY_FILENAME}"

CURL_OPT="${CURL_OPT} -m 3600 -sSN"

curl ${CURL_OPT} "${PIPING_SERVER}"/"${KEYWORD}"req \
  | stdbuf -i0 -o0 openssl aes-128-ctr -d -pass "pass:${PASSWORD}" -bufsize 1 -pbkdf2 -iter 1 -md md5 \
  | nc 127.0.0.1 8022 \
  | stdbuf -i0 -o0 openssl aes-128-ctr -pass "pass:${PASSWORD}" -bufsize 1 -pbkdf2 -iter 1 -md md5 \
  | curl ${CURL_OPT} -T - "${PIPING_SERVER}"/"${KEYWORD}"res &

for i in {1..2}; do \
  for j in {1..10}; do \
    sleep 60s \
     && echo "${i} ${j}" \
     && ps aux; \
  done \
   && ss -anpt \
   && ps aux \
   && curl -sS -A "keep instance" -u "${BASIC_USER}":"${BASIC_PASSWORD}" https://"${RENDER_EXTERNAL_HOSTNAME}"/?"$(date +%s)"; \
done &
