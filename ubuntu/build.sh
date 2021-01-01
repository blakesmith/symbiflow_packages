#!/bin/bash

DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true

function install_build_dependencies() {
    truncate -s0 /tmp/preseed.cfg
    echo "tzdata tzdata/Areas select US" >> /tmp/preseed.cfg
    echo "tzdata tzdata/Zones/US select Chicago" >> /tmp/preseed.cfg
    debconf-set-selections /tmp/preseed.cfg
    rm -f /etc/timezone /etc/localtime
    apt-get update
    apt-get -y install build-essential clang python3-dev cmake libboost-all-dev git libeigen3-dev \
        bison flex libreadline-dev gawk tcl-dev libffi-dev graphviz xdot pkg-config zlib1g-dev libftdi-dev
}

function build_trellis() {
    mkdir /tmp/src
    cd /tmp/src
    git clone --recursive https://github.com/YosysHQ/prjtrellis
    cd /tmp/src/prjtrellis/libtrellis
    cmake -DCMAKE_INSTALL_PREFIX=/opt/libtrellis
    make -j$(nproc)
    make install
}

function build_icestorm() {
    mkdir /opt/icestorm
    cd /tmp/src
    git clone https://github.com/YosysHQ/icestorm.git
    cd /tmp/src/icestorm
    PREFIX=/opt/icestorm make -j$(nproc) install
}

function build_nextpnr() {
    cd /tmp/src
    git clone https://github.com/YosysHQ/nextpnr.git
    cd /tmp/src/nextpnr
    cmake . -DARCH="ice40;ecp5" -DICESTORM_INSTALL_PREFIX=/opt/icestorm -DTRELLIS_INSTALL_PREFIX=/opt/libtrellis -DCMAKE_INSTALL_PREFIX=/opt/nextpnr
    make -j$(nproc)
    make install
}

function build_yosys() {
    mkdir /opt/yosys
    cd /tmp/src
    git clone https://github.com/YosysHQ/yosys.git
    cd /tmp/src/yosys
    mkdir build
    cd build && PREFIX=/opt/yosys make -f ../Makefile install
}

function install_package_dependencies() {
    apt-get -y install ruby
    mkdir -p /opt/packaging/libtrellis/DEBIAN /opt/packaging/icestorm/DEBIAN /opt/packaging/nextpnr/DEBIAN /opt/packaging/yosys/DEBIAN
}

function package_trellis() {
    cd /tmp/src/prjtrellis
    cat /tmp/libtrellis.control.erb | ruby -e 'require "erb"; VERSION="0.1.0-" + `git rev-parse HEAD`; TAG=ENV["TAG"]; puts ERB.new($stdin.read, nil, "-").result' > /opt/packaging/libtrellis/DEBIAN/control
    mkdir -p /opt/packaging/libtrellis/usr
    cp -rv /opt/libtrellis/bin /opt/packaging/libtrellis/usr/bin
    cp -rv /opt/libtrellis/lib /opt/packaging/libtrellis/usr/lib
    cp -rv /opt/libtrellis/share /opt/packaging/libtrellis/usr/share
    dpkg-deb --build /opt/packaging/libtrellis
}

function package_icestorm() {
    cd /tmp/src/icestorm
    cat /tmp/icestorm.control.erb | ruby -e 'require "erb"; VERSION="0.1.0-" + `git rev-parse HEAD`; TAG=ENV["TAG"]; puts ERB.new($stdin.read, nil, "-").result' > /opt/packaging/icestorm/DEBIAN/control
    mkdir -p /opt/packaging/icestorm/usr
    cp -rv /opt/icestorm/bin /opt/packaging/icestorm/usr/bin
    cp -rv /opt/icestorm/share /opt/packaging/icestorm/usr/share
    dpkg-deb --build /opt/packaging/icestorm
}

function package_nextpnr() {
    cd /tmp/src/nextpnr
    cat /tmp/nextpnr.control.erb | ruby -e 'require "erb"; VERSION="0.1.0-" + `git rev-parse HEAD`; TAG=ENV["TAG"]; puts ERB.new($stdin.read, nil, "-").result' > /opt/packaging/nextpnr/DEBIAN/control
    mkdir -p /opt/packaging/nextpnr/usr
    cp -rv /opt/nextpnr/bin /opt/packaging/nextpnr/usr/bin
    dpkg-deb --build /opt/packaging/nextpnr
}

function package_yosys() {
    cd /tmp/src/yosys && cat /tmp/yosys.control.erb | ruby -e 'require "erb"; VERSION="0.1.0-" + `git rev-parse HEAD`; TAG=ENV["TAG"]; puts ERB.new($stdin.read, nil, "-").result' > /opt/packaging/yosys/DEBIAN/control
    mkdir -p /opt/packaging/yosys/usr
    cp -rv /opt/yosys/bin /opt/packaging/yosys/usr/bin
    cp -rv /opt/yosys/share /opt/packaging/yosys/usr/share
    dpkg-deb --build /opt/packaging/yosys
}

case $1 in
    install_dependencies)
        install_build_dependencies;
        ;;
    build)
        build_trellis;
        build_icestorm;
        build_nextpnr;
        build_yosys;
        ;;
    package)
        install_package_dependencies;
        package_trellis;
        package_icestorm;
        package_nextpnr;
        package_yosys;
        ;;
    *)
        echo "Unknown command. Should be one of 'install_dependencies', 'build', 'package'"
        ;;
esac
