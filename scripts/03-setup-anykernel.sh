#!/bin/bash
# Setup AnyKernel3 config untuk Ginkgo
# Jalankan: ./03-setup-anykernel.sh

set -e

cd ~/ginkgo-kernel

echo "=== Setup AnyKernel3 untuk Ginkgo ==="

AK3_FILE="ak3/anykernel.sh"

# Backup original
cp "$AK3_FILE" "${AK3_FILE}.bak"

# Update config
echo "[1/3] Updating device config..."
sed -i 's/kernel.string=.*/kernel.string=Ginkgo custom kernel/' "$AK3_FILE"
sed -i 's/do.devicecheck=.*/do.devicecheck=1/' "$AK3_FILE"
sed -i 's/do.modules=.*/do.modules=0/' "$AK3_FILE"
sed -i 's/do.systemless=.*/do.systemless=1/' "$AK3_FILE"
sed -i 's/do.cleanup=.*/do.cleanup=1/' "$AK3_FILE"
sed -i 's/do.cleanuponabort=.*/do.cleanuponabort=0/' "$AK3_FILE"
sed -i 's/device.name1=.*/device.name1=ginkgo/' "$AK3_FILE"
sed -i 's/device.name2=.*/device.name2=willow/' "$AK3_FILE"

# Fix boot partition path
echo "[2/3] Fixing boot partition path..."
sed -i 's|BLOCK=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot|BLOCK=/dev/block/bootdevice/by-name/boot|' "$AK3_FILE"

# Verifikasi
echo "[3/3] Verifying..."
echo ""
echo "Device config:"
grep -E "kernel.string|device.name1|device.name2" "$AK3_FILE"
echo ""
echo "Boot block:"
grep "BLOCK=" "$AK3_FILE" | head -1

echo ""
echo "=== AnyKernel3 setup selesai! ==="
echo "Lanjut copy build.sh ke ~/ginkgo-kernel/ dan jalankan build"
