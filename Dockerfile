FROM --platform=linux/amd64 golang:latest AS compiler

WORKDIR /build

RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git make gcc-aarch64-linux-gnu libmnl-dev:arm64 libc6-dev:arm64 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /build/out/usr/bin /build/out/etc/amnezia

RUN git clone https://github.com/amnezia-vpn/amneziawg-go.git && \
    cd amneziawg-go && \
    CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o /build/out/usr/bin/amneziawg-go .

RUN git clone https://github.com/amnezia-vpn/amneziawg-tools.git && \
    cd amneziawg-tools/src && \
    CC=aarch64-linux-gnu-gcc LDFLAGS="-static" make && \
    make install DESTDIR=/build/out WITH_BASHCOMPLETION=no WITH_SYSTEMDUNITS=no WITH_WGQUICK=yes


FROM --platform=linux/amd64 alpine:latest AS rootfs-builder
ARG ALPINE_VER=3.24.2
ARG ALPINE_ARCH=aarch64

WORKDIR /build

RUN apk add --no-cache curl tar && \
    mkdir -p /build/rootfs/opt && \
    curl -sL https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ALPINE_ARCH}/alpine-minirootfs-${ALPINE_VER}-${ALPINE_ARCH}.tar.gz -o alpine.tar.gz && \
    tar -xzf alpine.tar.gz -C /build/rootfs

RUN apk add --no-cache --root /build/rootfs --initdb --arch ${ALPINE_ARCH} --no-scripts \
    tzdata iproute2 iptables bash ca-certificates libmnl

COPY --from=compiler /build/out/ /build/rootfs/

COPY ./start.sh /build/rootfs/opt/start.sh
RUN chmod +x /build/rootfs/opt/start.sh


FROM --platform=linux/arm64 scratch
COPY --from=rootfs-builder /build/rootfs/ /
WORKDIR /opt
ENTRYPOINT ["/bin/bash", "/opt/start.sh"]
