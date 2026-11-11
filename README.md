# Panduan Build Kernel Custom Redmi Note 8 (Ginkgo)

Panduan lengkap untuk build kernel custom dengan dukungan Docker, PostgreSQL, dan Droidspaces di Redmi Note 8 (ginkgo/willow).

## Persyaratan

- **Mac** dengan Homebrew, adb, fastboot, OrbStack
- **HP** Redmi Note 8 dengan TWRP dan Magisk (root)
- **ROM** crDroid 10.x Android 14 (atau ROM berbasis LineageOS)
- **Ruang kosong** ~30GB di Mac

## Struktur Folder

```
ginkgo-kernel-guide/
├── README.md                    # Panduan ini
├── QUICK-START.md              # Langkah cepat untuk rebuild
├── TROUBLESHOOTING.md          # Solusi masalah umum
├── scripts/
│   ├── 01-setup-ubuntu.sh      # Setup environment Ubuntu
│   ├── 02-clone-sources.sh     # Clone kernel & toolchain
│   ├── 03-setup-anykernel.sh   # Setup AnyKernel3
│   ├── build.sh                # Script build utama
│   └── flash.sh                # Script flash dari Mac
├── configs/
│   ├── ginkgo-stock_defconfig.patch  # Patch untuk defconfig
│   └── docker-configs.txt      # List config untuk Docker
└── backup/
    └── .gitkeep                # Folder untuk backup boot.img
```

## Fitur Kernel yang Diaktifkan

| Fitur | Config | Fungsi |
|-------|--------|--------|
| SysV IPC | `CONFIG_SYSVIPC` | PostgreSQL |
| User Namespace | `CONFIG_USER_NS` | Rootless containers |
| PID Namespace | `CONFIG_PID_NS` | Process isolation |
| IPC Namespace | `CONFIG_IPC_NS` | IPC isolation |
| UTS Namespace | `CONFIG_UTS_NS` | Hostname isolation |
| Network Namespace | `CONFIG_NET_NS` | Network isolation |
| Cgroups | `CONFIG_CGROUPS` | Resource control |
| Overlay FS | `CONFIG_OVERLAY_FS` | Docker storage |
| Devtmpfs | `CONFIG_DEVTMPFS` | Device nodes |

## Langkah Singkat

### 1. Persiapan (sekali saja)
```bash
# Di Mac
brew install --cask android-platform-tools orbstack
orb create --arch amd64 ubuntu:noble ginkgo

# Backup boot HP
mkdir -p ~/ginkgo-keep
adb shell su -c "dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot_backup.img"
adb pull /sdcard/boot_backup.img ~/ginkgo-keep/
```

### 2. Setup Ubuntu
```bash
orb -m ginkgo
cd ~
./ginkgo-kernel-guide/scripts/01-setup-ubuntu.sh
./ginkgo-kernel-guide/scripts/02-clone-sources.sh
./ginkgo-kernel-guide/scripts/03-setup-anykernel.sh
```

### 3. Build
```bash
cd ~/ginkgo-kernel
./build.sh 2  # Build dengan fitur Docker lengkap
```

### 4. Flash
```bash
# Di Mac
./ginkgo-kernel-guide/scripts/flash.sh
```

## Catatan Penting

### IKCONFIG Bug
Kernel ginkgo punya kondisi khusus di `kernel/Makefile`:
```makefile
ifdef CONFIG_MACH_XIAOMI_C3J
STOCK_DEFCONFIG := arch/arm64/configs/ginkgo-stock_defconfig
```

Ini menyebabkan `/proc/config.gz` diambil dari `ginkgo-stock_defconfig`, BUKAN dari `.config` yang dipakai build. Solusi: edit juga `ginkgo-stock_defconfig` untuk setiap config yang diubah.

### Restore jika Bootloop
```bash
# HP masuk FASTBOOT mode (Vol Down + Power)
fastboot flash boot ~/ginkgo-keep/boot_backup.img
fastboot reboot
```

## Versi & Sumber

- **Kernel**: 4.14.256-QuicksilveR-ginkgo-v2.5
- **Source**: https://github.com/user/android_kernel_xiaomi_ginkgo (branch 14.0)
- **Toolchain**: Clang sistem Ubuntu + GCC cross-compiler
- **AnyKernel3**: https://github.com/osm0sis/AnyKernel3

## Lisensi

Kernel Linux: GPLv2
