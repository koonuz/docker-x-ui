FROM debian:11-slim
COPY x-ui.sh /usr/local/x-ui.sh
ENV GET_VERSION 0.3.3.18-1207
ENV GET_ARCH amd64
RUN apt-get -y update && \
    apt-get install -y --no-install-recommends ca-certificates wget runit curl socat cron && \
    apt-get clean && \
    cd /usr/local && \
    wget -q https://github.com/FranzKafkaYu/x-ui/releases/download/${GET_VERSION}/x-ui-linux-${GET_ARCH}.tar.gz && \
    tar -zxvf x-ui-linux-${GET_ARCH}.tar.gz && \
    rm x-ui-linux-${GET_ARCH}.tar.gz && \
    mv x-ui.sh x-ui/x-ui.sh && \
    chmod +x x-ui/x-ui x-ui/bin/xray-linux-${GET_ARCH} x-ui/x-ui.sh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY runit /etc/service
RUN chmod +x /etc/service/x-ui/run
WORKDIR /usr/local/x-ui
CMD [ "runsvdir", "-P", "/etc/service"]
