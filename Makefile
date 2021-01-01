all: ubuntu_image

ubuntu_builder:
	docker build --target builder -f ubuntu/Dockerfile_ubuntu2010 .

ubuntu_packages:
	docker build --target packaging -f ubuntu/Dockerfile_ubuntu2010 .

ubuntu_image:
	docker build --target image -f ubuntu/Dockerfile_ubuntu2010 .

.PHONY: ubuntu_builder ubuntu_packages ubuntu_image
