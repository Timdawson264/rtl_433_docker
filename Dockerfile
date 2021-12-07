FROM docker.io/library/alpine:latest as build

ADD https://github.com/libusb/libusb/archive/refs/heads/master.tar.gz  /libusb.tar.gz
ADD https://github.com/steve-m/librtlsdr/archive/refs/heads/master.tar.gz /librtlsdr.tar.gz
ADD https://github.com/merbanan/rtl_433/archive/refs/heads/master.tar.gz /rtl433.tar.gz

#libtool libusb-1.0-0-dev librtlsdr-dev rtl-sdr build-essential cmake pkg-config
RUN apk -U add alpine-sdk gcc make cmake tar gzip 
RUN apk add autoconf automake libtool
RUN apk add linux-headers

WORKDIR /src

#libusb
RUN mkdir -p /src/libusb && \
    tar --strip-components=1  -xf /libusb.tar.gz -C /src/libusb && \
    cd /src/libusb && \
    ./bootstrap.sh && \
    ./configure --enable-static --disable-shared --disable-udev --prefix /opt && \
    make -j$(nproc) && make install

env PKG_CONFIG_PATH=/opt/lib/pkgconfig/

#librtlsdr
RUN mkdir -p /src/librtlsdr && \
    tar --strip-components=1  -xf /librtlsdr.tar.gz -C /src/librtlsdr && \
    cd /src/librtlsdr/ && \
    autoreconf -ivf && \
    env LDFLAGS="--static" ./configure --prefix=/opt --enable-static --disable-shared && \
    make -j$(nproc) && make install

RUN mkdir -p /src/rtl433 && \
    tar --strip-components=1 -xf /rtl433.tar.gz -C /src/rtl433 && \
    mkdir -p /src/rtl433/build && cd /src/rtl433/build && \
    cmake -D CMAKE_INSTALL_PREFIX=/opt -DCMAKE_EXE_LINKER_FLAGS="-static" .. && \
    make -j$(nproc) && make install


FROM docker.io/library/alpine
COPY --from=build /opt/bin/ /bin/
COPY --from=build /opt/etc/rtl_433 /etc/rtl_433

RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]
