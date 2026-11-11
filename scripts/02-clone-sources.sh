#!/bin/bash
# Clone kernel source dan AnyKernel3
# Jalankan: ./02-clone-sources.sh

set -e

cd ~/ginkgo-kernel

echo "=== Clone Kernel Source dan Tools ==="

# Clone AnyKernel3
if [ ! -d "ak3" ]; then
    echo "[1/2] Cloning AnyKernel3..."
    git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git ak3
    rm -rf ak3/.git
else
    echo "[1/2] AnyKernel3 sudah ada, skip..."
fi

# Clone kernel source (crDroid ginkgo Android 14)
if [ ! -d "kernel" ]; then
    echo "[2/2] Cloning kernel source (crDroid ginkgo 14.0)..."
    git clone --depth=1 -b 14.0 https://github.com/crdroidandroid/android_kernel_xiaomi_ginkgo.git kernel
else
    echo "[2/2] Kernel source sudah ada, skip..."
fi

# Verifikasi
echo ""
echo "=== Verifikasi ==="
head -5 kernel/Makefile
echo ""
find kernel/arch/arm64/configs -iname '*ginkgo*' | head -5

echo ""
echo "=== Clone selesai! ==="
echo "Lanjut jalankan: ./03-setup-anykernel.sh"
