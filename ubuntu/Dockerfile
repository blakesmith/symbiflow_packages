ARG TAG=20.10
FROM ubuntu:${TAG} AS dependencies

## for apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

### Building

## preesed tzdata, update package index, upgrade packages and install needed software
RUN truncate -s0 /tmp/preseed.cfg; \
        echo "tzdata tzdata/Areas select US" >> /tmp/preseed.cfg; \
        echo "tzdata tzdata/Zones/US select Chicago" >> /tmp/preseed.cfg; \
        debconf-set-selections /tmp/preseed.cfg && \
        rm -f /etc/timezone /etc/localtime && \
        apt-get update && \
        apt-get -y install build-essential clang python3-dev cmake libboost-all-dev git libeigen3-dev \
        bison flex libreadline-dev gawk tcl-dev libffi-dev graphviz xdot pkg-config zlib1g-dev libftdi-dev

FROM dependencies as builder
# Build trellis
RUN mkdir /tmp/src && cd /tmp/src && \
        git clone --recursive https://github.com/YosysHQ/prjtrellis && \
        cd /tmp/src/prjtrellis/libtrellis && \
        cmake -DCMAKE_INSTALL_PREFIX=/opt/libtrellis && \
        make -j$(nproc) && make install

# Build icestorm
RUN mkdir /opt/icestorm && cd /tmp/src && \
        git clone https://github.com/YosysHQ/icestorm.git && \
        cd /tmp/src/icestorm && \
        PREFIX=/opt/icestorm make -j$(nproc) install
        
# Build nextpnr
RUN cd /tmp/src && \
        git clone https://github.com/YosysHQ/nextpnr.git && \
        cd /tmp/src/nextpnr && \
        cmake . -DARCH="ice40;ecp5" -DICESTORM_INSTALL_PREFIX=/opt/icestorm -DTRELLIS_INSTALL_PREFIX=/opt/libtrellis -DCMAKE_INSTALL_PREFIX=/opt/nextpnr && \
        make -j$(nproc) && \
        make install

# Build yosys
RUN mkdir /opt/yosys && cd /tmp/src && cd /tmp/src && \
        git clone https://github.com/YosysHQ/yosys.git && \
        cd /tmp/src/yosys && mkdir build && cd build && PREFIX=/opt/yosys make -f ../Makefile install

### Packaging
FROM builder AS packaging
RUN apt-get -y install ruby
RUN mkdir -p /opt/packaging/libtrellis/DEBIAN /opt/packaging/icestorm/DEBIAN /opt/packaging/nextpnr/DEBIAN /opt/packaging/yosys/DEBIAN

# Trellis packaging
COPY ubuntu/libtrellis.control.erb /tmp/libtrellis.control.erb
RUN cd /tmp/src/prjtrellis && cat /tmp/libtrellis.control.erb | ruby -e 'require "erb"; VERSION="0.1.0-" + `git rev-parse HEAD`; puts ERB.new($stdin.read, nil, "-").result' > /opt/packaging/libtrellis/DEBIAN/control
RUN mkdir -p /opt/packaging/libtrellis/usr && \
        cp -rv /opt/libtrellis/bin /opt/packaging/libtrellis/usr/bin && \
        cp -rv /opt/libtrellis/lib /opt/packaging/libtrellis/usr/lib && \
        cp -rv /opt/libtrellis/share /opt/packaging/libtrellis/usr/share
RUN dpkg-deb --build /opt/packaging/libtrellis

# icestorm packaging
COPY ubuntu/icestorm.control.erb /tmp/icestorm.control.erb
RUN cd /tmp/src/icestorm && cat /tmp/icestorm.control.erb | ruby -e 'require "erb"; VERSION="0.1.0-" + `git rev-parse HEAD`; puts ERB.new($stdin.read, nil, "-").result' > /opt/packaging/icestorm/DEBIAN/control
RUN mkdir -p /opt/packaging/icestorm/usr && \
        cp -rv /opt/icestorm/bin /opt/packaging/icestorm/usr/bin && \
        cp -rv /opt/icestorm/share /opt/packaging/icestorm/usr/share
RUN dpkg-deb --build /opt/packaging/icestorm

# nextpnr packaging
COPY ubuntu/nextpnr.control.erb /tmp/nextpnr.control.erb
RUN cd /tmp/src/nextpnr && cat /tmp/nextpnr.control.erb | ruby -e 'require "erb"; VERSION="0.1.0-" + `git rev-parse HEAD`; puts ERB.new($stdin.read, nil, "-").result' > /opt/packaging/nextpnr/DEBIAN/control
RUN mkdir -p /opt/packaging/nextpnr/usr && \
        cp -rv /opt/nextpnr/bin /opt/packaging/nextpnr/usr/bin
RUN dpkg-deb --build /opt/packaging/nextpnr

# yosys packaging
COPY ubuntu/yosys.control.erb /tmp/yosys.control.erb
RUN cd /tmp/src/yosys && cat /tmp/yosys.control.erb | ruby -e 'require "erb"; VERSION="0.1.0-" + `git rev-parse HEAD`; puts ERB.new($stdin.read, nil, "-").result' > /opt/packaging/yosys/DEBIAN/control
RUN mkdir -p /opt/packaging/yosys/usr && \
        cp -rv /opt/yosys/bin /opt/packaging/yosys/usr/bin && \
        cp -rv /opt/yosys/share /opt/packaging/yosys/usr/share
RUN dpkg-deb --build /opt/packaging/yosys


# Install into target
FROM ubuntu:${TAG} AS image
WORKDIR /tmp
COPY --from=packaging /opt/packaging/libtrellis.deb .
COPY --from=packaging /opt/packaging/icestorm.deb .
COPY --from=packaging /opt/packaging/nextpnr.deb .
COPY --from=packaging /opt/packaging/yosys.deb .
RUN apt-get update
RUN apt install -y /tmp/libtrellis.deb && apt install -y /tmp/icestorm.deb && apt install -y /tmp/nextpnr.deb && apt install -y /tmp/yosys.deb
