FROM alpine:latest
COPY runit /etc/service
COPY x-ui.sh /usr/bin/x-ui
ENV GET_VERSION 0.3.4.3
ENV GET_ARCH amd64
RUN apk update && \
    apk add --no-cache ca-certificates tzdata runit curl bash iptables && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
    wget -q -P /usr/local https://github.com/FranzKafkaYu/x-ui/releases/download/${GET_VERSION}/x-ui-linux-${GET_ARCH}.tar.gz && \
    tar -zxvf /usr/local/x-ui-linux-${GET_ARCH}.tar.gz -C /usr/local && \
    rm /usr/local/x-ui-linux-${GET_ARCH}.tar.gz /usr/local/x-ui/x-ui.service /usr/local/x-ui/x-ui.sh && \
    chmod +x /usr/local/x-ui/ /etc/service/x-ui/run /etc/service/x-ui/finish /usr/bin/x-ui && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

WORKDIR /usr/local/x-ui
CMD ["runsvdir", "-P", "/etc/service"]
