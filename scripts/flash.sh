#!/bin/bash
# Flash kernel ke HP via TWRP + Magiskboot
# Jalankan dari Mac: ./flash.sh
#
# Prasyarat:
# - HP sudah di TWRP
# - adb terkoneksi

set -e

IMAGE_PATH="$HOME/OrbStack/ginkgo/home/bagussubagja/ginkgo-kernel/ak3/Image.gz-dtb"

# Cek file exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "ERROR: Image.gz-dtb tidak ditemukan di:"
    echo "$IMAGE_PATH"
    echo ""
    echo "Pastikan build sudah selesai di Ubuntu"
    exit 1
fi

echo "=== Flash Kernel Ginkgo ==="

# Cek adb connection
echo "[1/6] Checking ADB connection..."
adb devices | grep -q "device$" || {
    echo "ERROR: HP tidak terdeteksi. Pastikan:"
    echo "  1. HP sudah di TWRP"
    echo "  2. USB debugging aktif"
    exit 1
}

# Backup current boot
echo "[2/6] Backing up current boot partition..."
adb shell "cd /tmp && cat /dev/block/bootdevice/by-name/boot > boot_orig.img"

# Push new kernel
echo "[3/6] Pushing new kernel..."
adb push "$IMAGE_PATH" /tmp/

# Unpack, replace, repack
echo "[4/6] Repacking boot image..."
adb shell "cd /tmp && magiskboot unpack boot_orig.img"
adb shell "cd /tmp && cp Image.gz-dtb kernel"
adb shell "cd /tmp && magiskboot repack boot_orig.img"

# Flash
echo "[5/6] Flashing new boot image..."
adb shell "cd /tmp && dd if=new-boot.img of=/dev/block/bootdevice/by-name/boot"

# Reboot
echo "[6/6] Rebooting..."
adb reboot

echo ""
echo "=== Flash selesai! ==="
echo "Tunggu HP boot, lalu verifikasi dengan:"
echo "  adb shell su -c 'uname -a'"
echo "  adb shell su -c 'zcat /proc/config.gz | grep USER_NS'"
