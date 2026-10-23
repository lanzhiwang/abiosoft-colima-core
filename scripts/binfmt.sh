#!/usr/bin/env bash

set -eux

# ARCH=amd64 BINFMT_ARCH=aarch64 BINFMT_VERSION="deploy/v7.0.0-28" BINFMT_QEMU_VERSION="7.0.0" scripts/binfmt.sh

# external variables that must be set
echo vars: $ARCH $BINFMT_ARCH
# vars: amd64 aarch64

SCRIPT_DIR=$(realpath "$(dirname "$(dirname $0)")")
# dirname scripts/binfmt.sh
# dirname scripts
# realpath .
# SCRIPT_DIR=/home/runner/work/colima-core/colima-core

DIST_DIR="${SCRIPT_DIR}/dist/binfmt"
# DIST_DIR=/home/runner/work/colima-core/colima-core/dist/binfmt

mkdir -p $DIST_DIR
# mkdir -p /home/runner/work/colima-core/colima-core/dist/binfmt

TEMP_DIR=/tmp/binfmt
# TEMP_DIR=/tmp/binfmt

mkdir -p $TEMP_DIR
# mkdir -p /tmp/binfmt

cd $TEMP_DIR
# cd /tmp/binfmt

download_binfmt() (
    # download archive
    FILE="binfmt_linux-${1}.tar.gz"
    # FILE=binfmt_linux-amd64.tar.gz

    URL="https://github.com/tonistiigi/binfmt/releases/download/${BINFMT_VERSION}/${FILE}"
    # URL=https://github.com/tonistiigi/binfmt/releases/download/deploy/v7.0.0-28/binfmt_linux-amd64.tar.gz

    curl -LO $URL
    # curl -LO https://github.com/tonistiigi/binfmt/releases/download/deploy/v7.0.0-28/binfmt_linux-amd64.tar.gz

    # extract
    tar xvfz $FILE
    # tar xvfz binfmt_linux-amd64.tar.gz
    # binfmt
)

download_qemu() (
    # download archive
    FILE="qemu_v${BINFMT_QEMU_VERSION}_linux-${1}.tar.gz"
    # FILE=qemu_v7.0.0_linux-amd64.tar.gz

    URL="https://github.com/tonistiigi/binfmt/releases/download/${BINFMT_VERSION}/${FILE}"
    # URL=https://github.com/tonistiigi/binfmt/releases/download/deploy/v7.0.0-28/qemu_v7.0.0_linux-amd64.tar.gz

    curl -LO $URL
    # curl -LO https://github.com/tonistiigi/binfmt/releases/download/deploy/v7.0.0-28/qemu_v7.0.0_linux-amd64.tar.gz

    # extract
    tar xvfz $FILE
    # tar xvfz qemu_v7.0.0_linux-amd64.tar.gz
    # qemu-aarch64
    # qemu-arm
    # qemu-i386
    # qemu-mips64
    # qemu-mips64el
    # qemu-ppc64le
    # qemu-riscv64
    # qemu-s390x

)

create_archive() (
    # move required components
    FILE="binfmt-${1}.tar.gz"
    # FILE=binfmt-amd64.tar.gz

    tar cfz $FILE \
        binfmt \
        qemu-i386 \
        qemu-${2}
    # tar cfz binfmt-amd64.tar.gz binfmt qemu-i386 qemu-aarch64

    shasum -a 512 "${FILE}" >"${FILE}.sha512sum"
    # shasum -a 512 binfmt-amd64.tar.gz
)

copy_to_dist() (
    # copy to dist dir
    cp "binfmt-${1}.tar.gz" $DIST_DIR
    # cp binfmt-amd64.tar.gz /home/runner/work/colima-core/colima-core/dist/binfmt

    cp "binfmt-${1}.tar.gz.sha512sum" $DIST_DIR
    # cp binfmt-amd64.tar.gz.sha512sum /home/runner/work/colima-core/colima-core/dist/binfmt

    # cleanup
    rm -rf "$TEMP_DIR/*"
    # rm -rf '/tmp/binfmt/*'
)

download() (
    download_binfmt "${1}"
    # download_binfmt amd64

    download_qemu "${1}"
    # download_qemu amd64

    create_archive "${1}" "${2}"
    # create_archive amd64 aarch64

    copy_to_dist "${1}"
    # copy_to_dist amd64
)

# download
download $ARCH $BINFMT_ARCH
# download amd64 aarch64

echo download successful
ls -lh $DIST_DIR
# ls -lh /home/runner/work/colima-core/colima-core/dist/binfmt
# total 8.3M
# -rw-r--r-- 1 runner runner 8.3M Aug 23 17:33 binfmt-amd64.tar.gz
# -rw-r--r-- 1 runner runner  150 Aug 23 17:33 binfmt-amd64.tar.gz.sha512sum
