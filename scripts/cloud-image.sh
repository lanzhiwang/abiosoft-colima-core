#!/usr/bin/env bash

set -eux

# ARCH=amd64 UBUNTU_VERSION="24.04" UBUNTU_CODENAME="noble" scripts/cloud-image.sh

# external variables that must be set
echo vars: $ARCH
# vars: amd64

# switch to dist dir
SCRIPT_DIR=$(realpath "$(dirname "$(dirname $0)")")
# dirname scripts/cloud-image.sh
# dirname scripts
# realpath .
# SCRIPT_DIR=/home/runner/work/colima-core/colima-core

DIST_DIR="${SCRIPT_DIR}/dist/img"
# DIST_DIR=/home/runner/work/colima-core/colima-core/dist/img

mkdir -p $DIST_DIR
# mkdir -p /home/runner/work/colima-core/colima-core/dist/img

cd $DIST_DIR
# cd /home/runner/work/colima-core/colima-core/dist/img

download() (
    FILE="ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-${1}.img"
    # FILE=ubuntu-24.04-minimal-cloudimg-amd64.img

    URL="https://cloud-images.ubuntu.com/minimal/releases/${UBUNTU_CODENAME}/release/${FILE}"
    # URL=https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img

    curl -LO $URL
    # curl -LO https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img

    shasum -a 512 "${FILE}" >"${FILE}.sha512sum"
    # shasum -a 512 ubuntu-24.04-minimal-cloudimg-amd64.img
)

# download
download $ARCH
# download amd64

# validate
(
    curl -sL https://cloud-images.ubuntu.com/minimal/releases/${UBUNTU_CODENAME}/release/SHA256SUMS | grep "${ARCH}\.img$" | shasum -a 256 --check --status
    # curl -sL https://cloud-images.ubuntu.com/minimal/releases/noble/release/SHA256SUMS | grep 'amd64\.img$' | shasum -a 256 --check --status
)

echo download successful
ls -lh .
# ls -lh .
# total 253M
# -rw-r--r-- 1 runner runner 253M Aug 23 17:33 ubuntu-24.04-minimal-cloudimg-amd64.img
# -rw-r--r-- 1 runner runner  170 Aug 23 17:33 ubuntu-24.04-minimal-cloudimg-amd64.img.sha512sum
