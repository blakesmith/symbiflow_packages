# FPGA (Symbiflow) Ubuntu Packages

This repository provides a Docker image to build Ubuntu 20.10 packages for
the [Symbiflow FPGA toolchain](https://symbiflow.github.io/). It provides a docker image that can
build the following packages:

- [Project Trellis (libtrellis)](https://github.com/YosysHQ/prjtrellis). For targeting Lattice ECP5 devices.
- [Project Icestorm](https://github.com/YosysHQ/icestorm). For targeting Lattice ice40 devices.
- [yosys](https://github.com/YosysHQ/yosys). Verilog RTL synthesis frontend.
- [nextpnr](https://github.com/YosysHQ/nextpnr). Place and route tool.

## Usage

To build a working docker image with the above packages installed from an Ubuntu 20.10 base image, run:

```
git clone https://github.com/blakesmith/symbiflow_packages.git
cd symbiflow_packages
make ubuntu_image
```

The docker image build process uses [Docker Multistage Building](https://docs.docker.com/develop/develop-images/multistage-build/), and
provides intermediate targets, depending on what you're trying to do:

1. `dependencies` - An ubuntu docker image with all the necessary dev / build dependencies to compile the above projects.
2. `builder` - An ubuntu docker image with all the above projects compiled with a prefix of `/opt`. Use `make ubuntu_builder` to build.
3. `packaging` - An ubuntu docker image with all the ubuntu packages built and placed in `/opt/packaging`. Use `make ubuntu_packaging` to build.
4. `image` - An ubuntu docker image with all development build artifacts removed, and the packages freshly installed via aptitude. Useful if you just want to use the docker image's compiled packages directly, much much slimmer in size than the above images. Use `make ubuntu_image` to build.
