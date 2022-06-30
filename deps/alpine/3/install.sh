#!/bin/bash
#
# Install specific dependencies for Alpine
#
set -eux
# Install required packages for build process
apk add --no-cache build-base linux-headers bsd-compat-headers dpkg-dev dpkg \
automake autoconf flex bison libtool pkgconfig procps

# Install required dependencies for collectd
# shellcheck disable=SC2046
apk add --no-cache $(echo "
python3-dev
libgcrypt-dev
curl-dev
libcurl
libmicrohttpd-dev
protobuf-c-dev
protobuf-dev
librdkafka-dev
openipmi-dev
libatasmart-dev
hiredis-dev
yajl-dev
jansson-dev
net-snmp-dev
rrdtool-dev
libvirt-dev
libxml2-dev
rabbitmq-c-dev
libdbi-dev
libmemcached-dev
mariadb-connector-c-dev
libnotify-dev
postgresql-dev
lm-sensors-dev
mongo-c-driver-dev
libmnl-dev
libpcap-dev
iptables-dev
openldap-dev
liboping-dev
sqlite-dev
" | grep -v ^#)

mkdir -p /usr/local/src
update-alternatives --install /usr/bin/python python /usr/bin/python3 1
