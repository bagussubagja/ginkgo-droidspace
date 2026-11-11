#!/bin/bash
# Build script untuk kernel Ginkgo dengan dukungan Docker/Container
# 
# Usage:
#   ./build.sh 0    # Build kernel apa adanya (test toolchain)
#   ./build.sh 1    # Build dengan SysV IPC (PostgreSQL)
#   ./build.sh 2    # Build dengan fitur lengkap (Docker/Droidspaces)
#
# Copy file ini ke ~/ginkgo-kernel/build.sh

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 [0|1|2]"
    echo "  0 = Kernel apa adanya"
    echo "  1 = Dengan SysV IPC (PostgreSQL)"
    echo "  2 = Fitur lengkap (Docker/Droidspaces)"
    exit 1
fi

BUILD_TYPE=$1
DEFCONFIG=vendor/ginkgo-perf_defconfig

cd ~/ginkgo-kernel/kernel

# Export environment
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

echo "=== Building Kernel (Type $BUILD_TYPE) ==="

# Generate defconfig
echo "[1/5] Generating defconfig..."
make O=out CC=clang $DEFCONFIG

C=out/.config

# Apply config based on build type
echo "[2/5] Applying config for build type $BUILD_TYPE..."
case $BUILD_TYPE in
    1)
        # SysV IPC untuk PostgreSQL
        scripts/config --file $C \
            -e SYSVIPC \
            -e POSIX_MQUEUE \
            -e NAMESPACES \
            -e IPC_NS \
            -e IKCONFIG \
            -e IKCONFIG_PROC
        ;;
    2)
        # Fitur lengkap untuk Docker/Droidspaces
        scripts/config --file $C \
            -e SYSVIPC \
            -e POSIX_MQUEUE \
            -e SYSCTL \
            -e NAMESPACES \
            -e UTS_NS \
            -e IPC_NS \
            -e PID_NS \
            -e NET_NS \
            -e USER_NS \
            -e SECCOMP \
            -e SECCOMP_FILTER \
            -e CGROUPS \
            -e CGROUP_DEVICE \
            -e CGROUP_PIDS \
            -e MEMCG \
            -e CGROUP_SCHED \
            -e FAIR_GROUP_SCHED \
            -e CGROUP_FREEZER \
            -e CGROUP_NET_PRIO \
            -e CGROUP_CPUACCT \
            -e CPUSETS \
            -e CFS_BANDWIDTH \
            -e DEVTMPFS \
            -e OVERLAY_FS \
            -e TMPFS_POSIX_ACL \
            -e TMPFS_XATTR \
            -e IKCONFIG \
            -e IKCONFIG_PROC \
            -e KEYS \
            -e VETH \
            -e BRIDGE \
            -e NETFILTER \
            -e BRIDGE_NETFILTER \
            -e NETFILTER_ADVANCED \
            -e NF_CONNTRACK \
            -e NF_CONNTRACK_IPV4 \
            -e IP_NF_IPTABLES \
            -e IP_NF_FILTER \
            -e IP_NF_NAT \
            -e IP_NF_TARGET_MASQUERADE \
            -e NF_NAT \
            -e NF_NAT_IPV4 \
            -d ANDROID_PARANOID_NETWORK
        
        # Update ginkgo-stock_defconfig untuk IKCONFIG bug
        STOCK_DEFCONFIG=arch/arm64/configs/ginkgo-stock_defconfig
        sed -i 's/# CONFIG_USER_NS is not set/CONFIG_USER_NS=y/' $STOCK_DEFCONFIG 2>/dev/null || true
        sed -i 's/# CONFIG_PID_NS is not set/CONFIG_PID_NS=y/' $STOCK_DEFCONFIG 2>/dev/null || true
        sed -i 's/# CONFIG_IPC_NS is not set/CONFIG_IPC_NS=y/' $STOCK_DEFCONFIG 2>/dev/null || true
        sed -i 's/# CONFIG_UTS_NS is not set/CONFIG_UTS_NS=y/' $STOCK_DEFCONFIG 2>/dev/null || true
        
        # Tambahkan jika belum ada
        grep -q "CONFIG_USER_NS=y" $STOCK_DEFCONFIG || echo "CONFIG_USER_NS=y" >> $STOCK_DEFCONFIG
        grep -q "CONFIG_PID_NS=y" $STOCK_DEFCONFIG || echo "CONFIG_PID_NS=y" >> $STOCK_DEFCONFIG
        grep -q "CONFIG_IPC_NS=y" $STOCK_DEFCONFIG || echo "CONFIG_IPC_NS=y" >> $STOCK_DEFCONFIG
        grep -q "CONFIG_UTS_NS=y" $STOCK_DEFCONFIG || echo "CONFIG_UTS_NS=y" >> $STOCK_DEFCONFIG
        ;;
esac

# Olddefconfig
echo "[3/5] Running olddefconfig..."
make O=out CC=clang olddefconfig

# Build
echo "[4/5] Building kernel..."
make -j$(nproc) O=out \
    ARCH=arm64 \
    CC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    AS=llvm-as \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    Image.gz-dtb

# Copy ke AnyKernel3
echo "[5/5] Copying to AnyKernel3..."
cp out/arch/arm64/boot/Image.gz-dtb ~/ginkgo-kernel/ak3/

# Buat ZIP
cd ~/ginkgo-kernel/ak3
rm -f ~/ginkgo-kernel/ginkgo-build${BUILD_TYPE}.zip
zip -r9 ~/ginkgo-kernel/ginkgo-build${BUILD_TYPE}.zip * -x README.md

echo ""
echo "=== BUILD SELESAI ==="
echo "Output: ~/ginkgo-kernel/ginkgo-build${BUILD_TYPE}.zip"
echo ""

# Verifikasi config jika build type 2
if [ "$BUILD_TYPE" = "2" ]; then
    echo "Verifikasi config:"
    cd ~/ginkgo-kernel/kernel
    scripts/extract-ikconfig out/arch/arm64/boot/Image.gz | grep -E "USER_NS|PID_NS|IPC_NS|UTS_NS"
fi
