FROM alpine:latest
ENV GLIBC_VERSION 2.35-r0
# Download and install glibc
RUN apk add --update curl && \
  curl -Lo /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
  curl -Lo glibc.apk "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" && \
  curl -Lo glibc-bin.apk "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk" && \
  apk add glibc-bin.apk glibc.apk && \
  /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
  echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
  apk del curl && \
  rm -rf glibc.apk glibc-bin.apk /var/cache/apk/*
WORKDIR /usr/local/
COPY x-ui.sh /usr/local/x-ui.sh
RUN apk update && \
    apk add --no-cache tzdata runit && \
    mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
    wget -q https://github.com/FranzKafkaYu/x-ui/releases/download/0.3.3.14/x-ui-linux-amd64.tar.gz && \
    tar -zxvf x-ui-linux-amd64.tar.gz && \
    rm x-ui-linux-amd64.tar.gz && \
    mv x-ui.sh x-ui/x-ui.sh && \
    cd x-ui && \
    chmod +x x-ui bin/xray-linux-amd64 x-ui.sh && \
    cp -f x-ui.sh /usr/bin/x-ui.sh && \
    rm -rf /var/cache/apk/*

COPY runit /etc/service
WORKDIR /usr/local/x-ui
CMD [ "runsvdir", "-P", "/etc/service"]
