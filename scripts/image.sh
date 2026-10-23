#!/usr/bin/env bash

# 遇到错误立即退出 (-e)、未定义变量直接报错 (-u)、打印每行执行的命令及参数 (-x)
set -eux

# 禁用 apt 的交互式提示(避免构建过程中因 tzdata、键盘布局等弹出交互弹窗挂起 CI)
# disable apt prompts
export DEBIAN_FRONTEND=noninteractive
# export DEBIAN_FRONTEND=noninteractive

# 打印传入的关键环境变量:
# ARCH: 镜像架构 (如 amd64 或 arm64)
# BINFMT_ARCH: 对应的交叉编译/模拟架构 (如 aarch64)
# UBUNTU_VERSION: Ubuntu 版本 (如 24.04)
# DOCKER_VERSION: 预装的 Docker 版本
# RUNTIME: 容器运行时类型 (docker, containerd, incus, none)
# external variables that must be set
echo vars: $ARCH $BINFMT_ARCH $UBUNTU_VERSION $DOCKER_VERSION $RUNTIME
# vars: amd64 aarch64 24.04 29.5.2 docker

FILENAME="ubuntu-${UBUNTU_VERSION}-minimal-cloudimg-${ARCH}"
# FILENAME=ubuntu-24.04-minimal-cloudimg-amd64

SCRIPT_DIR=$(realpath "$(dirname "$(dirname $0)")")
# dirname /build/scripts/image.sh
# dirname /build/scripts
# realpath /build
# SCRIPT_DIR=/build

IMG_DIR="$SCRIPT_DIR/dist/img"
# IMG_DIR=/build/dist/img

CHROOT_DIR=/mnt/colima-img
# CHROOT_DIR=/mnt/colima-img

FILE="$IMG_DIR/$FILENAME"
# FILE=/build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64

# ==============================================================================
# 第一步: 准备构建容器宿主环境所需的依赖工具
# ==============================================================================
install_dependencies() (
    apt-get update
    # apt-get update

    # file: 用于查看文件类型
    # fdisk: 用于解析磁盘镜像的分区表(扇区偏移量)
    # libdigest-sha-perl: 提供 shasum 计算校验和
    # qemu-utils: 提供 qemu-img 工具, 用于镜像格式转换
    apt-get install -y file fdisk libdigest-sha-perl qemu-utils
    # apt-get install -y file fdisk libdigest-sha-perl qemu-utils
)

# ==============================================================================
# 第二步: 将 qcow2 格式转换为 raw 格式
# ==============================================================================
convert_file() (
    # 官方下载的云镜像是动态扩容的 qcow2 格式.
    # 为什么要转为 raw?
    # 因为 raw 格式是平铺的二进制扇区, Linux 原生的 loop 设备可以直接通过 offset 挂载.
    # 如果直接挂载 qcow2, 需要宿主机内核加载 nbd (Network Block Device) 驱动,
    # 而 Docker 容器内加载内核模块非常繁琐且容易受限; raw loop 挂载通用性最强.
    qemu-img convert -p -f qcow2 -O raw $FILE.img $FILE.raw
    # qemu-img convert -p -f qcow2 -O raw /build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64.img /build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64.raw
)

# ==============================================================================
# 第三步: 获取目标系统根分区(rootfs)的起始扇区号(Sector Offset)
# ==============================================================================
extract_partition_offset() (
    # 使用 fdisk 解析 raw 文件的 MBR/GPT 分区表.
    # 找到第 1 分区(raw1)的 Start Sector, 并提取数字(例如: 2099200).
    fdisk -l $FILE.raw | grep "$FILE.raw1 " | awk -F' ' '{print $2}'
    # fdisk -l /build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64.raw | grep '/build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64.raw1 ' | awk '-F ' '{print $2}'
)

# ==============================================================================
# 第四步: 挂载镜像分区到宿主机目录
# ==============================================================================
mount_partition() (
    mkdir -p $CHROOT_DIR
    # mkdir -p /mnt/colima-img

    # 标准硬盘扇区大小通常为 512 字节.
    # 将起始扇区号 * 512 计算出字节偏移量 (offset), 精准将 rootfs 挂载到 /mnt/colima-img
    mount -o loop,offset=$(($1 * 512)) $FILE.raw $CHROOT_DIR
    # mount -o loop,offset=1074790400 /build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64.raw /mnt/colima-img

)

unmount_partition() (
    umount $CHROOT_DIR
    # umount /mnt/colima-img
)

# 封装 chroot 执行命令的快捷函数
chroot_exec() (
    chroot $CHROOT_DIR "$@"
    # chroot /mnt/colima-img mount -t proc proc /proc
)

# ==============================================================================
# 第五步: 进入 chroot 进行"定制与瘦身手术"(核心逻辑)
# ==============================================================================
install_packages() (
    # 1. 挂载虚拟文件系统:
    # apt、dpkg、systemd 等程序在安装过程中需要检测进程信息(/proc)与伪终端(/dev/pts),
    # 如果不挂载, 许多包的 post-install 脚本会报错失败.
    # necessary
    chroot_exec mount -t proc proc /proc
    # chroot_exec mount -t proc proc /proc

    chroot_exec mount -t devpts devpts /dev/pts
    # chroot_exec mount -t devpts devpts /dev/pts

    # 2. 修复 chroot 内部的网络 DNS 解析:
    # 原始镜像中的 /etc/resolv.conf 往往是指向 systemd-resolved 的软链接, 在 chroot 下无法解析.
    # 临时备份它并写入 1.1.1.1, 确保在 chroot 内执行 apt-get/curl 时能正常联网.
    # internet
    chroot_exec mv /etc/resolv.conf /etc/resolv.conf.bak
    # chroot_exec mv /etc/resolv.conf /etc/resolv.conf.bak

    echo 'nameserver 1.1.1.1' >$CHROOT_DIR/etc/resolv.conf
    # echo 'nameserver 1.1.1.1' > /mnt/colima-img/etc/resolv.conf

    # 更新 chroot 内部系统的源索引
    # prepare packages
    chroot_exec apt-get update
    # chroot_exec apt-get update

    # 3. 安装 Colima 基础设施所需的必备依赖:
    # - iptables: 容器网络端口映射与 NAT 依赖
    # - socat: Colima 进行端口转发与宿主机通信的关键工具
    # - sshfs: 早期或备用的主机-虚拟机文件共享方案
    # - cloud-init: 虚拟机首次启动时的自动化配置(注入 SSH Key、配置主机名等)
    # - dnsmasq: 提供轻量级 DNS 解析能力
    # packages common to all runtimes, to prevent from final purging
    chroot_exec apt-get install -y iptables socat sshfs cloud-init lsb-release python3-apt gnupg curl wget dnsmasq
    # chroot_exec apt-get install -y iptables socat sshfs cloud-init lsb-release python3-apt gnupg curl wget dnsmasq

    # 4. 根据用户选择的 RUNTIME 安装不同的容器运行时:

    # [RUNTIME: none] 纯净虚拟机, 只安装基础网络与排错工具
    # none
    if [ "$RUNTIME" == "none" ]; then
        (
            chroot_exec apt-get install -y htop inetutils-ping dnsutils net-tools netcat-openbsd telnet vim-tiny nano
            chroot_exec apt-get purge -y dmsetup xz-utils
        )
    fi

    # [RUNTIME: docker] 安装 Docker 引擎
    # docker
    if [ "$RUNTIME" == "docker" ]; then
        (
            # 使用官方脚本安装指定版本的 Docker
            chroot_exec curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            # chroot_exec curl -fsSL https://get.docker.com -o /tmp/get-docker.sh

            chroot_exec sh /tmp/get-docker.sh --version $DOCKER_VERSION
            # chroot_exec sh /tmp/get-docker.sh --version 29.5.2

            chroot_exec rm /tmp/get-docker.sh
            # chroot_exec rm /tmp/get-docker.sh

            # 锁定版本! 防止用户在虚拟机内执行 apt upgrade 时误升级破坏兼容性
            chroot_exec apt-mark hold docker-ce docker-ce-cli containerd.io
            # chroot_exec apt-mark hold docker-ce docker-ce-cli containerd.io

            chroot_exec apt-get purge -y dmsetup xz-utils
            # chroot_exec apt-get purge -y dmsetup xz-utils
        )
    fi

    # [RUNTIME: containerd] 轻量化模式, 仅解压预编译的 containerd 及 CNI 插件
    # containerd
    if [ "$RUNTIME" == "containerd" ]; then
        (
            cd /tmp
            tar Cxfz ${CHROOT_DIR}/usr/local /build/dist/containerd/containerd-utils-${ARCH}.tar.gz
            chroot_exec mkdir -p /opt/cni
            chroot_exec mv /usr/local/libexec/cni /opt/cni/bin
            chroot_exec apt-get purge -y dmsetup xz-utils
        )
    fi

    # [RUNTIME: incus] 安装系统容器技术 Incus (LXD 的开源分支) 及相关存储驱动 (ZFS, Btrfs, LVM)
    # incus
    if [ "$RUNTIME" == "incus" ]; then
        (
            chroot_exec mkdir -p /etc/apt/keyrings/
            chroot_exec curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc
            chroot_exec sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-incus-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc

EOF'
            chroot_exec apt-get update
            chroot_exec apt-get install -y htop inetutils-ping dnsutils net-tools netcat-openbsd telnet vim-tiny nano
            chroot_exec apt-get install -y incus incus-base incus-client incus-extra incus-ui-canonical zfsutils-linux btrfs-progs lvm2 thin-provisioning-tools
            chroot_exec apt-mark hold incus incus-base incus-client incus-extra incus-ui-canonical zfsutils-linux btrfs-progs lvm2 thin-provisioning-tools
        )
    fi

    # 5. 激进的"瘦身"与"去臃肿化"(Purge Unnecessary Packages):
    # 彻底移除虚拟机根本不需要的服务(大幅减少体积、内存占用, 加快启动速度):
    # - snapd: 占用大量磁盘和内存, 虚拟机内用不到
    # - apport: 崩溃报告服务, 常驻后台消耗资源
    # - systemd-resolved: 经常与 macOS/Lima 复杂的内部网络转发发生 DNS 冲突, 彻底清除
    # - ubuntu-advantage-tools / unattended-upgrades: 禁用自动化升级后台服务
    # - lxd/pciutils 等杂项组件
    chroot_exec apt-get purge -y apport console-setup-linux dbus-user-session liblocale-gettext-perl lxd-agent-loader lxd-installer parted pciutils pollinate python3-gi snapd ssh-import-id
    # chroot_exec apt-get purge -y apport console-setup-linux dbus-user-session liblocale-gettext-perl lxd-agent-loader lxd-installer parted pciutils pollinate python3-gi snapd ssh-import-id

    chroot_exec apt-get purge -y ubuntu-advantage-tools ubuntu-cloud-minimal ubuntu-drivers-common ubuntu-release-upgrader-core unattended-upgrades systemd-resolved
    # chroot_exec apt-get purge -y ubuntu-advantage-tools ubuntu-cloud-minimal ubuntu-drivers-common ubuntu-release-upgrader-core unattended-upgrades systemd-resolved

    # 自动卸载无用孤立依赖
    chroot_exec apt-get autoremove -y
    # chroot_exec apt-get autoremove -y

    # 清空 apt 缓存与包元数据, 压榨每一兆磁盘空间
    chroot_exec apt-get clean -y
    # chroot_exec apt-get clean -y

    chroot_exec sh -c "rm -rf /var/lib/apt/lists/* /var/cache/apt/*"
    # chroot_exec sh -c 'rm -rf /var/lib/apt/lists/* /var/cache/apt/*'

    # 6. 为虚拟机内部注入 binfmt 与 QEMU 用户态执行程序:
    # 作用: 让这个虚拟机以后开机后, 其内部的 Docker 也能跨架构运行镜像!
    # (例如在 Apple Silicon 的 ARM64 VM 内部, 直接使用 docker run 跑 x86_64 容器)
    # binfmt
    (
        cd /tmp
        # cd /tmp

        tar xfz /build/dist/binfmt/binfmt-${ARCH}.tar.gz
        # tar xfz /build/dist/binfmt/binfmt-amd64.tar.gz

        chown root:root binfmt qemu-i386 qemu-${BINFMT_ARCH}
        # chown root:root binfmt qemu-i386 qemu-aarch64

        mv binfmt qemu-i386 qemu-${BINFMT_ARCH} ${CHROOT_DIR}/usr/bin
        # mv binfmt qemu-i386 qemu-aarch64 /mnt/colima-img/usr/bin
    )

    # 7. 开机自动加载 Virtio-VSOCK 模块:
    # 这是 Colima/Lima 在 macOS 上实现超低延迟通信的秘密武器!
    # macOS 的 Virtualization.framework 支持 virtio-vsock,
    # 这样宿主机 Mac 与虚拟机之间可以直接基于系统内部 Socket 交互(如转发 Docker Socket),
    # 无需经过 TCP 协议栈握手和端口转发, 性能极大提升.
    # enable vsock modules at boot
    cat >${CHROOT_DIR}/etc/modules-load.d/vsock.conf <<EOF
vsock
virtio_vsock
EOF

    # 8. 现场清理, 恢复挂载状态:
    # clean traces
    chroot_exec rm /etc/resolv.conf
    # chroot_exec rm /etc/resolv.conf

    chroot_exec mv /etc/resolv.conf.bak /etc/resolv.conf
    # chroot_exec mv /etc/resolv.conf.bak /etc/resolv.conf

    chroot_exec umount /dev/pts
    # chroot_exec umount /dev/pts

    chroot_exec umount /proc
    # chroot_exec umount /proc

    # 9. 极其精妙的一步: 用 0 填充未分配的磁盘空间(Zero-filling)
    # 原理: 删除文件只是抹除 inode, 磁盘上的数据块仍有脏数据.
    # 稍后使用 gzip 进行压缩时, 无法对随机的脏数据进行高比例压缩.
    # 用 /dev/zero 将剩余所有磁盘空间写满 0, 随后删掉.
    # 最终 gzip 看到几 GB 连续的 0x00, 压缩算法可以直接将其压缩为几个字节!
    # fill partition with zeros, to recover space during compression
    chroot_exec dd if=/dev/zero of=/root/zero || echo done
    # chroot_exec dd if=/dev/zero of=/root/zero

    chroot_exec rm -f /root/zero
    # chroot_exec rm -f /root/zero
)

# ==============================================================================
# 第六步: 极限压缩与生成校验和
# ==============================================================================
compress_file() (
    raw_file="${FILE}-${RUNTIME}.raw"
    # raw_file=/build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64-docker.raw

    # 重命名文件, 带上运行时标签(例如: ...-amd64-docker.raw)
    mv $FILE.raw $raw_file
    # mv /build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64.raw /build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64-docker.raw

    # -9: 最高级别压缩率(消耗 CPU 换取极小的分发体积)
    # -n: 不保存原始文件名和时间戳
    # -f: 强制覆盖
    gzip -9 -n -f $raw_file
    # gzip -9 -n -f /build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64-docker.raw

    dir="$(dirname $raw_file)"
    # dirname /build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64-docker.raw
    # dir=/build/dist/img

    filename="$(basename $raw_file)"
    # basename /build/dist/img/ubuntu-24.04-minimal-cloudimg-amd64-docker.raw
    # filename=ubuntu-24.04-minimal-cloudimg-amd64-docker.raw

    # 计算最终文件的 SHA-512 校验和, 供客户端安全比对
    (cd $dir && shasum -a 512 "${filename}.gz" >"${filename}.gz.sha512sum")
    # cd /build/dist/img
    # shasum -a 512 ubuntu-24.04-minimal-cloudimg-amd64-docker.raw.gz
)

# ----------------- 主流程执行 -----------------
# perform all actions
install_dependencies
convert_file
mount_partition "$(extract_partition_offset)"
# mount_partition 2099200

install_packages
unmount_partition
compress_file
