ARG TAG=3.15

FROM alpine:${TAG} AS builder

ARG COLLECTD_FLAVOR=stable
ARG COLLECTD_DEBUG=n
ARG COLLECTD_CONFIG_CMD_ARGS

RUN apk update && \
        apk add --no-cache bash=~5.1 sudo=~1.9 git=~2.34 && \
        git config --global http.sslVerify false

ENV DOCKER y
# LDCONFIG for libpqos install is disabled because syntax is not compatible with Alpine linux,
# but it is not necessary for build.
ENV PQOSINSTALLENV "NOLDCONFIG=y"
ENV BUILD_LIBPQOS y
ENV BUILD_PMU_TOOLS y
ENV build_dir /src

WORKDIR ${build_dir}
COPY . ${build_dir}/
RUN ./build.sh

FROM alpine:${TAG}

COPY --from=builder /usr/lib/libpqos.* /usr/lib/
COPY --from=builder /usr/share/snmp/mibs/ /usr/share/snmp/mibs/
COPY --from=builder /usr/local/src/ /usr/local/src/
WORKDIR /opt/collectd
COPY --from=builder /opt/collectd/ .
COPY docker/collectd-alpine/run_collectd.sh /run_collectd.sh
COPY docker/collectd-alpine/resolve_missing.sh .

RUN apk update && \
        apk add --no-cache bash=~5.1 sudo=~1.9 python3=~3.9 dpkg=~1.20 dmidecode=~3 && \
        chmod +x resolve_missing.sh && ./resolve_missing.sh && rm -f resolve_missing.sh && \
        update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
        chmod +x /run_collectd.sh && \
        adduser -Ds /bin/bash collectd_exec && \
        echo "collectd_exec ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ENTRYPOINT ["/run_collectd.sh"]
