#!/usr/bin/env bash

# ARCH=amd64 BINFMT_ARCH=aarch64 UBUNTU_VERSION="24.04" DOCKER_VERSION="29.5.2" RUNTIME=docker scripts/image.docker.sh

set -eux

# disable apt prompts
export DEBIAN_FRONTEND=noninteractive
# export DEBIAN_FRONTEND=noninteractive

# external variables that must be set
echo vars: $ARCH $BINFMT_ARCH $UBUNTU_VERSION $DOCKER_VERSION $RUNTIME
# vars: amd64 aarch64 24.04 29.5.2 docker

# computed variables
SCRIPT_DIR=$(realpath "$(dirname "$(dirname $0)")")
# dirname scripts/image.docker.sh
# dirname scripts
# realpath .
# SCRIPT_DIR=/home/runner/work/colima-core/colima-core

# dependencies in case of cross-arch
docker run --privileged --rm tonistiigi/binfmt --install $BINFMT_ARCH
# docker run --privileged --rm tonistiigi/binfmt --install aarch64

# build disk image
docker run --rm --privileged \
    --platform linux/$ARCH \
    --volume $SCRIPT_DIR:/build \
    --env ARCH \
    --env BINFMT_ARCH \
    --env UBUNTU_VERSION \
    --env DOCKER_VERSION \
    --env RUNTIME \
    ubuntu:${UBUNTU_VERSION} /build/scripts/image.sh
# docker run --rm --privileged --platform linux/amd64 --volume /home/runner/work/colima-core/colima-core:/build --env ARCH --env BINFMT_ARCH --env UBUNTU_VERSION --env DOCKER_VERSION --env RUNTIME ubuntu:24.04 /build/scripts/image.sh
