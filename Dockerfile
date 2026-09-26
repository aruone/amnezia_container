FROM --platform=$BUILDPLATFORM alpine:latest AS builder
ARG TARGET_PLATFORM=linux
ARG TARGET_ARCH=arm64
ARG ALPINE_VER=3.24.2
ARG ALPINE_ARCH=aarch64

WORKDIR /build

RUN apk add --no-cache curl unzip gzip tar go git build-base libmnl-dev linux-headers && \
    curl -sL https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ALPINE_ARCH}/alpine-minirootfs-${ALPINE_VER}-${ALPINE_ARCH}.tar.gz -o alpine.tar.gz && \
    mkdir rootfs && tar -xzf alpine.tar.gz -C rootfs

RUN go install github.com/amnezia-vpn/amneziawg-go@latest && \
    git clone https://github.com/amnezia-vpn/amneziawg-tools.git && \
    cd amneziawg-tools/src && env -u TARGET_ARCH -u TARGETARCH -u ARCH make && \
    mkdir -p /build/rootfs/usr/bin /build/rootfs/opt /build/rootfs/etc/amnezia && \
    make install DESTDIR=/build/rootfs WITH_BASHCOMPLETION=no WITH_SYSTEMDUNITS=no WITH_WGQUICK=yes && \
    cp /root/go/bin/amneziawg-go /build/rootfs/usr/bin/

RUN apk add --no-cache --root /build/rootfs --initdb --arch ${ALPINE_ARCH} --no-scripts \
        tzdata iproute2 iptables bash ca-certificates libmnl

COPY ./start.sh ./rootfs/opt/start.sh
RUN chmod +x ./rootfs/opt/start.sh

FROM --platform=${TARGET_PLATFORM}/${TARGET_ARCH} scratch
COPY --from=builder /build/rootfs/ /
WORKDIR /opt
ENTRYPOINT ["/bin/bash", "/opt/start.sh"]