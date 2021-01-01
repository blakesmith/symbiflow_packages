ARG TAG=20.10
FROM ubuntu:${TAG} AS dependencies

COPY ubuntu/build.sh /tmp/build.sh

## for apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN /tmp/build.sh install_dependencies

### Building

FROM dependencies as builder
RUN /tmp/build.sh build

### Packaging
FROM builder AS packaging
ARG TAG # Needed to pass to package dependencies

COPY ubuntu/libtrellis.control.erb /tmp/libtrellis.control.erb
COPY ubuntu/icestorm.control.erb /tmp/icestorm.control.erb
COPY ubuntu/nextpnr.control.erb /tmp/nextpnr.control.erb
COPY ubuntu/yosys.control.erb /tmp/yosys.control.erb

RUN /tmp/build.sh package

### Install into image
FROM ubuntu:${TAG} AS image
WORKDIR /tmp
COPY --from=packaging /opt/packaging/libtrellis.deb .
COPY --from=packaging /opt/packaging/icestorm.deb .
COPY --from=packaging /opt/packaging/nextpnr.deb .
COPY --from=packaging /opt/packaging/yosys.deb .
RUN apt-get update && apt install -y /tmp/libtrellis.deb && apt install -y /tmp/icestorm.deb && apt install -y /tmp/nextpnr.deb && apt install -y /tmp/yosys.deb
