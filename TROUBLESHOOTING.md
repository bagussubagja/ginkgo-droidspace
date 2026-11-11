# Troubleshooting - Kernel Ginkgo

## Masalah Umum

### 1. Bootloop setelah flash

**Solusi:**
```bash
# HP masuk FASTBOOT (tahan Vol Down + Power 10-15 detik)
fastboot flash boot ~/ginkgo-keep/boot_backup.img
fastboot reboot
```

**Penyebab umum:**
- Config tidak cocok dengan ROM
- Source kernel berbeda dari yang dipakai ROM
- Missing driver/module

### 2. Config tidak masuk ke kernel (`/proc/config.gz` salah)

**Gejala:** `.config` menunjukkan `CONFIG_USER_NS=y` tapi di HP `# CONFIG_USER_NS is not set`

**Penyebab:** Kernel ginkgo punya kondisi khusus di `kernel/Makefile`:
```makefile
ifdef CONFIG_MACH_XIAOMI_C3J
STOCK_DEFCONFIG := arch/arm64/configs/ginkgo-stock_defconfig
```

**Solusi:** Edit juga `ginkgo-stock_defconfig`:
```bash
sed -i 's/# CONFIG_USER_NS is not set/CONFIG_USER_NS=y/' arch/arm64/configs/ginkgo-stock_defconfig
sed -i 's/# CONFIG_PID_NS is not set/CONFIG_PID_NS=y/' arch/arm64/configs/ginkgo-stock_defconfig
sed -i 's/# CONFIG_IPC_NS is not set/CONFIG_IPC_NS=y/' arch/arm64/configs/ginkgo-stock_defconfig
```

Lalu rebuild dengan:
```bash
rm -f out/kernel/config_data.h out/kernel/config_data.gz out/kernel/configs.o
make -j$(nproc) O=out ...
```

### 3. Build error: CROSS_COMPILE_ARM32 not defined

**Solusi:** Export environment variables:
```bash
export ARCH=arm64 SUBARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-
```

### 4. Build error: LITTLE_CPU_MASK loop

**Gejala:** Prompt terus minta input LITTLE_CPU_MASK

**Solusi:** Ketik nilai decimal:
- LITTLE_CPU_MASK: `63` (0x3f)
- BIG_CPU_MASK: `192` (0xc0)

Atau set manual:
```bash
sed -i 's/CONFIG_LITTLE_CPU_MASK=.*/CONFIG_LITTLE_CPU_MASK=63/' out/.config
sed -i 's/CONFIG_BIG_CPU_MASK=.*/CONFIG_BIG_CPU_MASK=192/' out/.config
```

### 5. Build error: implicit declaration (fingerprint/touchscreen driver)

**Penyebab:** Missing header includes

**Solusi:**
```bash
# Untuk fingerprint
sed -i '/#include <linux\/delay.h>/a #include <linux\/pinctrl\/consumer.h>\n#include <linux\/seq_file.h>' drivers/input/fingerprint/fpc1020/fpc1020_tee.c
sed -i '/#include <linux\/delay.h>/a #include <linux\/seq_file.h>' drivers/input/fingerprint/gf3208/gf_spi.c
```

### 6. AnyKernel3 error: Unable to determine boot partition

**Solusi:** Edit `anykernel.sh`:
```bash
sed -i 's|BLOCK=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot|BLOCK=/dev/block/bootdevice/by-name/boot|' ~/ginkgo-kernel/ak3/anykernel.sh
```

### 7. Droidspaces: Kernel not supported

**Cek requirements:**
- Settings → Requirements → Check Requirements
- Pastikan semua MUST HAVE centang hijau

**Config yang wajib:**
- `CONFIG_PID_NS=y`
- `CONFIG_UTS_NS=y`
- `CONFIG_IPC_NS=y`
- `CONFIG_USER_NS=y` (untuk sandboxing)

### 8. Docker error di Droidspaces container

**cgroup mountpoint error:**
```bash
# Di container
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "storage-driver": "vfs"
}
EOF
systemctl restart docker
```

**iptables error:**
```bash
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
systemctl restart docker
```

### 9. PostgreSQL: could not create shared memory segment

**Penyebab:** SysV IPC tidak aktif

**Verifikasi:**
```bash
adb shell su -c "ls /proc/sysvipc"
# Harus ada: msg sem shm
```

**Solusi:** Pastikan `CONFIG_SYSVIPC=y` di kernel

## Log & Debug

### Kernel panic log (jika ramoops aktif)
```bash
# Di TWRP/recovery
adb shell cat /sys/fs/pstore/console-ramoops-0 | tail -80
```

### Cek config di kernel yang running
```bash
adb shell su -c "zcat /proc/config.gz" > running_config.txt
grep -E "USER_NS|PID_NS|SYSVIPC" running_config.txt
```

### Cek kernel build info
```bash
adb shell su -c "uname -a"
adb shell su -c "cat /proc/version"
```
