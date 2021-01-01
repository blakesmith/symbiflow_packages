 # Default to building with Ubuntu 20.10, override using `make ubuntu_image TAG=20.04`
TAG ?= 20.10

all: ubuntu_image

ubuntu_builder:
	docker build --target builder --build-arg "TAG=$(TAG)" -f ubuntu/Dockerfile_ubuntu2010 -t symbiflow_fpga-builder .

ubuntu_packaging:
	docker build --target packaging --build-arg "TAG=$(TAG)" -f ubuntu/Dockerfile_ubuntu2010 -t symbiflow_fpga-packaging .

ubuntu_image:
	docker build --target image --build-arg "TAG=$(TAG)" -f ubuntu/Dockerfile_ubuntu2010 -t symbiflow_fpga .

.PHONY: ubuntu_builder ubuntu_packages ubuntu_image
