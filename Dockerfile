# ==========================================
# СТАДИЯ 1: Компиляция бинарников (в официальном Golang-образе x86_64)
# ==========================================
FROM --platform=linux/amd64 golang:latest AS compiler

WORKDIR /build

# 1. Добавляем архитектуру ARM64 и ставим кросс-компилятор вместе с заголовочными файлами libc
RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git make gcc-aarch64-linux-gnu libmnl-dev:arm64 libc6-dev:arm64 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Создаем структуру папок
RUN mkdir -p /build/out/usr/bin /build/out/etc/amnezia

# 2. Кросс-компилируем amneziawg-go
RUN git clone https://github.com/amnezia-vpn/amneziawg-go.git && \
    cd amneziawg-go && \
    CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o /build/out/usr/bin/amneziawg-go .

# 3. Кросс-компилируем awg и awg-quick статически
RUN git clone https://github.com/amnezia-vpn/amneziawg-tools.git && \
    cd amneziawg-tools/src && \
    CC=aarch64-linux-gnu-gcc LDFLAGS="-static" make && \
    make install DESTDIR=/build/out WITH_BASHCOMPLETION=no WITH_SYSTEMDUNITS=no WITH_WGQUICK=yes


# ==========================================
# СТАДИЯ 2: Сборка файловой системы ARM64 (в Alpine x86_64)
# ==========================================
FROM --platform=linux/amd64 alpine:latest AS rootfs-builder
ARG ALPINE_VER=3.24.2
ARG ALPINE_ARCH=aarch64

WORKDIR /build

# 1. Скачиваем чистый rootfs ARM64
RUN apk add --no-cache curl tar && \
    mkdir -p /build/rootfs/opt && \
    curl -sL https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ALPINE_ARCH}/alpine-minirootfs-${ALPINE_VER}-${ALPINE_ARCH}.tar.gz -o alpine.tar.gz && \
    tar -xzf alpine.tar.gz -C /build/rootfs

# 2. Накатываем пакеты под ARM64 с помощью нативного apk x86_64
RUN apk add --no-cache --root /build/rootfs --initdb --arch ${ALPINE_ARCH} --no-scripts \
    tzdata iproute2 iptables bash ca-certificates libmnl

# 3. Забираем скомпилированные бинарники из первой стадии
COPY --from=compiler /build/out/ /build/rootfs/

# 4. Кладем скрипт запуска
COPY ./start.sh /build/rootfs/opt/start.sh
RUN chmod +x /build/rootfs/opt/start.sh


# ==========================================
# СТАДИЯ 3: Финальный образ для MikroTik (ARM64)
# ==========================================
FROM --platform=linux/arm64 scratch
COPY --from=rootfs-builder /build/rootfs/ /
WORKDIR /opt
ENTRYPOINT ["/bin/bash", "/opt/start.sh"]
