#!/usr/bin/env bash

# ARCH=amd64 NERDCTL_VERSION="2.3.1" FLANNEL_VERSION="1.9.1-flannel1" FLANNEL_MINI_VERSION="1.9.1" RUNTIME=containerd scripts/containerd.sh

if [ "$RUNTIME" != "containerd" ]; then
    exit 0
fi

set -ex

SCRIPT_DIR=$(realpath "$(dirname "$(dirname $0)")")
# dirname scripts/containerd.sh
# dirname scripts
# realpath .
# SCRIPT_DIR=/home/runner/work/colima-core/colima-core

DIST_DIR="${SCRIPT_DIR}/dist/containerd"
# DIST_DIR=/home/runner/work/colima-core/colima-core/dist/containerd

mkdir -p $DIST_DIR
# mkdir -p /home/runner/work/colima-core/colima-core/dist/containerd

TEMP_DIR=/tmp/containerd
# TEMP_DIR=/tmp/containerd

mkdir -p $TEMP_DIR
# mkdir -p /tmp/containerd

cd $TEMP_DIR
# cd /tmp/containerd

download_containerd() (
    # download archive
    FILE="nerdctl-full-${NERDCTL_VERSION}-linux-${1}.tar.gz"
    # FILE=nerdctl-full-2.3.1-linux-amd64.tar.gz

    URL="https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/${FILE}"
    # URL=https://github.com/containerd/nerdctl/releases/download/v2.3.1/nerdctl-full-2.3.1-linux-amd64.tar.gz

    curl -LO $URL
    # curl -LO https://github.com/containerd/nerdctl/releases/download/v2.3.1/nerdctl-full-2.3.1-linux-amd64.tar.gz

    # validate
    curl -sL "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/SHA256SUMS" | grep "${FILE}" | shasum -a 256 --check --status
    # curl -sL https://github.com/containerd/nerdctl/releases/download/v2.3.1/SHA256SUMS | grep nerdctl-full-2.3.1-linux-amd64.tar.gz | shasum -a 256 --check --status

    # extract
    tar xvfz $FILE
    # tar xvfz nerdctl-full-2.3.1-linux-amd64.tar.gz
    # bin/
    # bin/buildctl
    # bin/buildg
    # bin/buildkit-cni-bandwidth
    # bin/buildkit-cni-bridge
    # bin/buildkit-cni-dhcp
    # bin/buildkit-cni-dummy
    # bin/buildkit-cni-firewall
    # bin/buildkit-cni-host-device
    # bin/buildkit-cni-host-local
    # bin/buildkit-cni-ipvlan
    # bin/buildkit-cni-loopback
    # bin/buildkit-cni-macvlan
    # bin/buildkit-cni-portmap
    # bin/buildkit-cni-ptp
    # bin/buildkit-cni-sbr
    # bin/buildkit-cni-static
    # bin/buildkit-cni-tap
    # bin/buildkit-cni-tuning
    # bin/buildkit-cni-vlan
    # bin/buildkit-cni-vrf
    # bin/buildkitd
    # bin/bypass4netns
    # bin/bypass4netnsd
    # bin/containerd
    # bin/containerd-fuse-overlayfs-grpc
    # bin/containerd-rootless-setuptool.sh
    # bin/containerd-rootless.sh
    # bin/containerd-shim-runc-v2
    # bin/containerd-stargz-grpc
    # bin/ctd-decoder
    # bin/ctr
    # bin/ctr-enc
    # bin/ctr-remote
    # bin/fuse-overlayfs
    # bin/gomodjail
    # bin/nerdctl
    # bin/nerdctl.gomodjail
    # bin/rootlessctl
    # bin/rootlesskit
    # bin/runc
    # bin/stargz-fuse-manager
    # bin/stargz-store-helper
    # bin/tini
    # lib/
    # lib/systemd/
    # lib/systemd/system/
    # lib/systemd/system/buildkit.service
    # lib/systemd/system/containerd.service
    # lib/systemd/system/stargz-snapshotter.service
    # libexec/
    # libexec/cni/
    # libexec/cni/LICENSE
    # libexec/cni/README.md
    # libexec/cni/bandwidth
    # libexec/cni/bridge
    # libexec/cni/dhcp
    # libexec/cni/dummy
    # libexec/cni/firewall
    # libexec/cni/host-device
    # libexec/cni/host-local
    # libexec/cni/ipvlan
    # libexec/cni/loopback
    # libexec/cni/macvlan
    # libexec/cni/portmap
    # libexec/cni/ptp
    # libexec/cni/sbr
    # libexec/cni/static
    # libexec/cni/tap
    # libexec/cni/tuning
    # libexec/cni/vlan
    # libexec/cni/vrf
    # share/
    # share/doc/
    # share/doc/nerdctl/
    # share/doc/nerdctl/README.md
    # share/doc/nerdctl/docs/
    # share/doc/nerdctl/docs/build.md
    # share/doc/nerdctl/docs/builder-debug.md
    # share/doc/nerdctl/docs/cni.md
    # share/doc/nerdctl/docs/command-reference.md
    # share/doc/nerdctl/docs/compose.md
    # share/doc/nerdctl/docs/config.md
    # share/doc/nerdctl/docs/cosign.md
    # share/doc/nerdctl/docs/cvmfs.md
    # share/doc/nerdctl/docs/dev/
    # share/doc/nerdctl/docs/dev/auditing_dockerfile.md
    # share/doc/nerdctl/docs/dev/store.md
    # share/doc/nerdctl/docs/dir.md
    # share/doc/nerdctl/docs/experimental.md
    # share/doc/nerdctl/docs/faq.md
    # share/doc/nerdctl/docs/freebsd.md
    # share/doc/nerdctl/docs/gpu.md
    # share/doc/nerdctl/docs/healthchecks.md
    # share/doc/nerdctl/docs/images/
    # share/doc/nerdctl/docs/images/nerdctl-white.svg
    # share/doc/nerdctl/docs/images/nerdctl.svg
    # share/doc/nerdctl/docs/images/rootlessKit-network-design.png
    # share/doc/nerdctl/docs/ipfs.md
    # share/doc/nerdctl/docs/multi-platform.md
    # share/doc/nerdctl/docs/notation.md
    # share/doc/nerdctl/docs/nydus.md
    # share/doc/nerdctl/docs/ocicrypt.md
    # share/doc/nerdctl/docs/overlaybd.md
    # share/doc/nerdctl/docs/registry.md
    # share/doc/nerdctl/docs/rootless.md
    # share/doc/nerdctl/docs/soci.md
    # share/doc/nerdctl/docs/stargz.md
    # share/doc/nerdctl/docs/testing/
    # share/doc/nerdctl/docs/testing/README.md
    # share/doc/nerdctl/docs/testing/tools.md
    # share/doc/nerdctl-full/
    # share/doc/nerdctl-full/README.md
    # share/doc/nerdctl-full/SHA256SUMS
)

download_flannel() (
    # download archive
    FILE="cni-plugin-flannel-linux-${1}-v${FLANNEL_MINI_VERSION}.tgz"
    # FILE=cni-plugin-flannel-linux-amd64-v1.9.1.tgz

    URL="https://github.com/flannel-io/cni-plugin/releases/download/v${FLANNEL_VERSION}/${FILE}"
    # URL=https://github.com/flannel-io/cni-plugin/releases/download/v1.9.1-flannel1/cni-plugin-flannel-linux-amd64-v1.9.1.tgz

    curl -LO $URL
    # curl -LO https://github.com/flannel-io/cni-plugin/releases/download/v1.9.1-flannel1/cni-plugin-flannel-linux-amd64-v1.9.1.tgz

    # validate
    curl -sL "${URL}.sha512" | shasum -a 512 --check --status
    # curl -sL https://github.com/flannel-io/cni-plugin/releases/download/v1.9.1-flannel1/cni-plugin-flannel-linux-amd64-v1.9.1.tgz.sha512 | shasum -a 512 --check --status

    # extract
    tar xvfz "$FILE"
    # tar xvfz cni-plugin-flannel-linux-amd64-v1.9.1.tgz
    # flannel-amd64

    mv "flannel-${1}" libexec/cni/flannel
    # mv flannel-amd64 libexec/cni/flannel
)

create_archive() (
    # move required components
    FILE="containerd-utils-${1}.tar.gz"
    # FILE=containerd-utils-amd64.tar.gz

    tar cfz $FILE \
        bin \
        lib \
        libexec \
        share
    # tar cfz containerd-utils-amd64.tar.gz bin lib libexec share

    shasum -a 512 "${FILE}" >"${FILE}.sha512sum"
    # shasum -a 512 containerd-utils-amd64.tar.gz
)

copy_to_dist() (
    # copy to dist dir
    cp "containerd-utils-${1}.tar.gz" $DIST_DIR
    # cp containerd-utils-amd64.tar.gz /home/runner/work/colima-core/colima-core/dist/containerd

    cp "containerd-utils-${1}.tar.gz.sha512sum" $DIST_DIR
    # cp containerd-utils-amd64.tar.gz.sha512sum /home/runner/work/colima-core/colima-core/dist/containerd

    # cleanup
    rm -rf "$TEMP_DIR/*"
    # rm -rf '/tmp/containerd/*'
)

download() (
    download_containerd "${1}"
    # download_containerd amd64

    download_flannel "${1}"
    # download_flannel amd64

    create_archive "${1}"
    # create_archive amd64

    copy_to_dist "${1}"
    # copy_to_dist amd64
)

# download
download $ARCH
# download amd64

echo download successful
ls -lh $DIST_DIR
# ls -lh /home/runner/work/colima-core/colima-core/dist/containerd
# total 277M
# -rw-r--r-- 1 runner runner 277M Aug 23 17:37 containerd-utils-amd64.tar.gz
# -rw-r--r-- 1 runner runner  160 Aug 23 17:37 containerd-utils-amd64.tar.gz.sha512sum
