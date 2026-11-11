# Quick Start - Rebuild Kernel Ginkgo

Langkah cepat untuk rebuild kernel setelah setup awal selesai.

## Prasyarat
- Mesin Ubuntu `ginkgo` sudah ada di OrbStack
- Source kernel sudah di-clone di `~/ginkgo-kernel/kernel`
- Backup boot sudah ada di `~/ginkgo-keep/boot_backup.img`

## Rebuild Kernel

### 1. Masuk Ubuntu
```bash
orb -m ginkgo
cd ~/ginkgo-kernel/kernel
```

### 2. Clean Build (opsional, jika ada masalah)
```bash
rm -rf out
```

### 3. Setup Config
```bash
export ARCH=arm64 SUBARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
make O=out CC=clang vendor/ginkgo-perf_defconfig
```

### 4. Tambah Config Docker/Container
```bash
scripts/config --file out/.config -e USER_NS -e PID_NS -e IPC_NS -e UTS_NS -e SYSVIPC -e NAMESPACES -e CGROUPS -e OVERLAY_FS -e IKCONFIG -e IKCONFIG_PROC -e DEVTMPFS -e MEMCG -e CFS_BANDWIDTH -e CGROUP_PIDS
make O=out CC=clang olddefconfig
```

### 5. Build
```bash
make -j$(nproc) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip Image.gz-dtb
```

### 6. Verifikasi Config
```bash
scripts/extract-ikconfig out/arch/arm64/boot/Image.gz | grep -E "USER_NS|PID_NS|IPC_NS"
```

Harus semua `=y`. Jika ada yang `not set`, edit `arch/arm64/configs/ginkgo-stock_defconfig` dan rebuild.

### 7. Copy ke AnyKernel3
```bash
cp out/arch/arm64/boot/Image.gz-dtb ~/ginkgo-kernel/ak3/
exit
```

## Flash ke HP

### Via TWRP + Magiskboot (recommended)
```bash
# Di Mac
adb reboot recovery
# Tunggu TWRP
adb shell "cd /tmp && cat /dev/block/bootdevice/by-name/boot > boot_orig.img"
adb push ~/OrbStack/ginkgo/home/bagussubagja/ginkgo-kernel/ak3/Image.gz-dtb /tmp/
adb shell "cd /tmp && magiskboot unpack boot_orig.img && cp Image.gz-dtb kernel && magiskboot repack boot_orig.img && dd if=new-boot.img of=/dev/block/bootdevice/by-name/boot"
adb reboot
```

### Verifikasi
```bash
adb shell su -c "uname -a"
adb shell su -c "zcat /proc/config.gz | grep -E 'USER_NS|PID_NS|IPC_NS'"
```

## Update ROM

Setelah update ROM, kernel custom akan tertimpa. Ulangi langkah flash di atas dengan kernel yang sudah di-build sebelumnya, atau rebuild jika versi ROM berubah signifikan.
