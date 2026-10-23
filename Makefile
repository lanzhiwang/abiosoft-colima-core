# core dependency
UBUNTU_VERSION ?= 24.04
UBUNTU_CODENAME ?= noble
BINFMT_VERSION ?= deploy/v7.0.0-28
BINFMT_QEMU_VERSION ?= 7.0.0

# runtime
RUNTIME ?= docker

# docker
DOCKER_VERSION=29.5.2

# containerd dependency
NERDCTL_VERSION ?= 2.3.1
FLANNEL_VERSION ?= 1.9.1-flannel1
FLANNEL_MINI_VERSION ?= 1.9.1

# architecture defaults to the current system's.
OS_ARCH ?= $(shell uname -m)
ifeq ($(strip $(OS_ARCH)),arm64)
OS_ARCH = aarch64
endif

# OS_ARCH is derived from `uname -m` but the alternate architecture name (e.g. amd64, arm64)
# is required for Docker and asset downloads.
ARCH_x86_64 = amd64
ARCH_aarch64 = arm64
ARCH = $(shell echo "$(ARCH_$(OS_ARCH))")

# binfmt needs the opposite of OS_ARCH
BINFMT_ARCH = aarch64
ifeq ($(strip $(OS_ARCH)),aarch64)
BINFMT_ARCH = x86_64
endif

printvar:
	@echo "UBUNTU_VERSION = $(UBUNTU_VERSION)"
	@echo "UBUNTU_CODENAME = $(UBUNTU_CODENAME)"
	@echo "BINFMT_VERSION = $(BINFMT_VERSION)"
	@echo "BINFMT_QEMU_VERSION = $(BINFMT_QEMU_VERSION)"
	@echo "RUNTIME = $(RUNTIME)"
	@echo "DOCKER_VERSION = $(DOCKER_VERSION)"
	@echo "NERDCTL_VERSION = $(NERDCTL_VERSION)"
	@echo "FLANNEL_VERSION = $(FLANNEL_VERSION)"
	@echo "FLANNEL_MINI_VERSION = $(FLANNEL_MINI_VERSION)"
	@echo "OS_ARCH = $(OS_ARCH)"
	@echo "ARCH_x86_64 = $(ARCH_x86_64)"
	@echo "ARCH_aarch64 = $(ARCH_aarch64)"
	@echo "ARCH = $(ARCH)"
	@echo "BINFMT_ARCH = $(BINFMT_ARCH)"

# $ make printvar
# UBUNTU_VERSION = 24.04
# UBUNTU_CODENAME = noble
# BINFMT_VERSION = deploy/v7.0.0-28
# BINFMT_QEMU_VERSION = 7.0.0
# RUNTIME = docker
# DOCKER_VERSION = 29.5.2
# NERDCTL_VERSION = 2.3.1
# FLANNEL_VERSION = 1.9.1-flannel1
# FLANNEL_MINI_VERSION = 1.9.1
# OS_ARCH = x86_64
# ARCH_x86_64 = amd64
# ARCH_aarch64 = arm64
# ARCH = amd64
# BINFMT_ARCH = aarch64
# $

#
# targets
#

all: image
# $ make -n --dry-run all
# ARCH=amd64 UBUNTU_VERSION=24.04 UBUNTU_CODENAME=noble scripts/cloud-image.sh
# ARCH=amd64 BINFMT_ARCH=aarch64 BINFMT_VERSION=deploy/v7.0.0-28 BINFMT_QEMU_VERSION=7.0.0 scripts/binfmt.sh
# ARCH=amd64 NERDCTL_VERSION=2.3.1 FLANNEL_VERSION=1.9.1-flannel1 FLANNEL_MINI_VERSION=1.9.1 RUNTIME=docker scripts/containerd.sh
# ARCH=amd64 BINFMT_ARCH=aarch64 UBUNTU_VERSION=24.04 DOCKER_VERSION=29.5.2 RUNTIME=docker scripts/image.docker.sh
# $

.PHONY: clean
clean:
	rm -rf dist
# $ make -n --dry-run clean
# rm -rf dist
# $

cloud-image:
	ARCH=$(ARCH) UBUNTU_VERSION=$(UBUNTU_VERSION) UBUNTU_CODENAME=$(UBUNTU_CODENAME) scripts/cloud-image.sh
# $ make -n --dry-run cloud-image
# ARCH=amd64 UBUNTU_VERSION=24.04 UBUNTU_CODENAME=noble scripts/cloud-image.sh
# $

binfmt:
	ARCH=$(ARCH) BINFMT_ARCH=$(BINFMT_ARCH) BINFMT_VERSION=$(BINFMT_VERSION) BINFMT_QEMU_VERSION=$(BINFMT_QEMU_VERSION) scripts/binfmt.sh
# $ make -n --dry-run binfmt
# ARCH=amd64 BINFMT_ARCH=aarch64 BINFMT_VERSION=deploy/v7.0.0-28 BINFMT_QEMU_VERSION=7.0.0 scripts/binfmt.sh
# $

containerd:
	ARCH=$(ARCH) NERDCTL_VERSION=$(NERDCTL_VERSION) FLANNEL_VERSION=$(FLANNEL_VERSION) FLANNEL_MINI_VERSION=$(FLANNEL_MINI_VERSION) RUNTIME=$(RUNTIME) scripts/containerd.sh
# $ make -n --dry-run containerd
# ARCH=amd64 NERDCTL_VERSION=2.3.1 FLANNEL_VERSION=1.9.1-flannel1 FLANNEL_MINI_VERSION=1.9.1 RUNTIME=docker scripts/containerd.sh
# $

image: cloud-image binfmt containerd
	ARCH=$(ARCH) BINFMT_ARCH=$(BINFMT_ARCH) UBUNTU_VERSION=$(UBUNTU_VERSION) DOCKER_VERSION=$(DOCKER_VERSION) RUNTIME=$(RUNTIME) scripts/image.docker.sh
# $ make -n --dry-run image
# ARCH=amd64 UBUNTU_VERSION=24.04 UBUNTU_CODENAME=noble scripts/cloud-image.sh
# ARCH=amd64 BINFMT_ARCH=aarch64 BINFMT_VERSION=deploy/v7.0.0-28 BINFMT_QEMU_VERSION=7.0.0 scripts/binfmt.sh
# ARCH=amd64 NERDCTL_VERSION=2.3.1 FLANNEL_VERSION=1.9.1-flannel1 FLANNEL_MINI_VERSION=1.9.1 RUNTIME=docker scripts/containerd.sh
# ARCH=amd64 BINFMT_ARCH=aarch64 UBUNTU_VERSION=24.04 DOCKER_VERSION=29.5.2 RUNTIME=docker scripts/image.docker.sh
# $
