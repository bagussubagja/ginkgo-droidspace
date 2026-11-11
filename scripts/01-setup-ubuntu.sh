#!/bin/bash
# Setup environment build di Ubuntu (OrbStack)
# Jalankan: ./01-setup-ubuntu.sh

set -e

echo "=== Setup Build Environment untuk Kernel Ginkgo ==="

# Install dependencies
echo "[1/2] Installing build dependencies..."
sudo apt update
sudo apt install -y \
    git make bc bison flex libssl-dev libelf-dev \
    zip unzip curl wget \
    python3 python-is-python3 \
    cpio ccache libncurses-dev \
    xz-utils zstd lz4 \
    device-tree-compiler patch \
    clang lld llvm \
    gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi

# Buat folder kerja
echo "[2/2] Creating work directory..."
mkdir -p ~/ginkgo-kernel

echo ""
echo "=== Setup selesai! ==="
echo "Lanjut jalankan: ./02-clone-sources.sh"
