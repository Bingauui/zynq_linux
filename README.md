# ZYNQ Boooom Linux 安装流程

## 1. 硬件准备

| 硬件 | 数量 |
|------|------|
| ZYNQ Boooom 核心板 | 1 |
| ZYNQ Boooom 底板 | 1 |
| FTDI 调试器 | 1 |

## 2. 软件安装

| 工具 | 用途 |
|------|------|
| **Vivado 2023.02** | FPGA bit 流生成、PS 外设引脚导出 |
| **Vitis 2023.02** | BOOT.bin 生成、QSPI Flash 烧录、FSBL 固件编译 |

## 3. 目录结构

### 启动文件 (`boot/`)

```
boot/
├── boot.bin                   # BOOT.bin 文件，合并 fsbl.elf + uboot.elf + zynq-boooom.dtb
├── boot.scr                   # u-boot 启动脚本
├── design_1_wrapper.bit       # FPGA bit 流
├── fsbl.elf                   # 一级引导程序 (FSBL)
├── fsbl.elf.size
├── linux_boooom.img           # QSPI 全分区镜像文件
├── linux_hello_world.bif      # BOOT.bin 合并配置文件
├── openocd.cfg                # OpenOCD 调试器配置
├── u-boot.elf                 # u-boot 引导程序
├── uRamdisk                   # initramfs 内存文件系统
├── zImage                     # Linux 内核镜像
└── zynq-booom.dtb             # 设备树文件
```

### 根文件系统 (`rootfs/`)

```
rootfs/
└── ubuntu-base-22.04-base-armhf.tar.gz   # Ubuntu 22.04 基础根文件系统
```

### 源码与配置 (`source/`)

```
source/
├── zynq_boooom_defconfig      # Linux 内核编译配置
├── zynq-booom.dts             # 设备树源文件
├── u-boot.config              # u-boot 编译配置
├── st7789c.py                 # LCD 屏幕初始化固件生成脚本
├── panel-mipi-dbi-spi.bin     # 屏幕初始化序列固件（复制到 /lib/firmware）
├── zynq-7000-*.dts            # 设备树插件，编译后在 uEnv 中启用
├── boot.cmd                   # u-boot 启动脚本源文件
├── etc/rc.local               # 启动脚本：加载 SPI LCD 驱动 / 固定 ETH MAC 地址
└── usb_ncm_setup.sh           # USB NCM 网卡 DHCP 配置脚本
```

## 4. QSPI 分区表

| 起始地址 | 结束地址 | 分区名 | 大小 |
|----------|----------|--------|------|
| `0x000000000000` | `0x000000200000` | qspi-fsbl-uboot | 2 MB |
| `0x000000200000` | `0x000000a00000` | qspi-linux | 8 MB |
| `0x000000a00000` | `0x000000a80000` | qspi-device-tree | 512 KB |
| `0x000000a80000` | `0x000000b00000` | qspi-uboot-cmd | 512 KB |
| `0x000000b00000` | `0x000000d00000` | qspi-rootfs | 2 MB |
| `0x000000d00000` | `0x000001000000` | qspi-bitstream | 3 MB |

## 5. 烧录 QSPI Flash

### 准备工作

- 将启动模式切换为 **JTAG 启动**
- 将以下命令中的 `$Vitis_INSTALL_PATH` 和 `$BOOT_PATH` 替换为实际绝对路径

### 方式一：全量烧录（推荐，适用于新板）

一次性烧录整个镜像文件：

```bash
$Vitis_INSTALL_PATH/program_flash \
  -f $BOOT_PATH/linux_boooom.img \
  -offset 0x0 \
  -flash_type qspi-x4-single \
  -fsbl $BOOT_PATH/fsbl.elf \
  -verify \
  -url TCP:127.0.0.1:3121
```

### 方式二：分区烧录

按分区逐一烧录：

```bash
# 1. 烧录 BOOT.bin（偏移 0x0，大小 2 MB）
$Vitis_INSTALL_PATH/program_flash \
  -f $BOOT_PATH/boot.bin \
  -offset 0x0 \
  -flash_type qspi-x4-single \
  -fsbl $BOOT_PATH/fsbl.elf \
  -verify \
  -url TCP:127.0.0.1:3121

# 2. 烧录 Kernel（偏移 0x200000，大小 8 MB）
$Vitis_INSTALL_PATH/program_flash \
  -f $BOOT_PATH/zImage \
  -offset 0x200000 \
  -flash_type qspi-x4-single \
  -fsbl $BOOT_PATH/fsbl.elf \
  -verify \
  -url TCP:127.0.0.1:3121

# 3. 烧录 DTB（偏移 0xa00000，大小 512 KB）
$Vitis_INSTALL_PATH/program_flash \
  -f $BOOT_PATH/zynq-booom.dtb \
  -offset 0xa00000 \
  -flash_type qspi-x4-single \
  -fsbl $BOOT_PATH/fsbl.elf \
  -verify \
  -url TCP:127.0.0.1:3121

# 4. 烧录 uRamdisk（偏移 0xb00000，大小 2 MB）
$Vitis_INSTALL_PATH/program_flash \
  -f $BOOT_PATH/uRamdisk \
  -offset 0xb00000 \
  -flash_type qspi-x4-single \
  -fsbl $BOOT_PATH/fsbl.elf \
  -verify \
  -url TCP:127.0.0.1:3121
```

### 烧录完成

1. 将启动模式切换为 **QSPI 启动**
2. 连接调试器，打开串口终端
3. 上电后系统将进入 initramfs

## 6. 安装 Ubuntu Base

### 6.1 网络配置

```bash
# 通过 DHCP 获取 IP（可选）
udhcpc

# 或手动配置静态 IP
ip addr add 192.168.x.x/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.x.1

# 配置 DNS 服务器
vi /etc/resolv.conf
```

`/etc/resolv.conf` 内容（仅保留 nameserver 行）：

```
nameserver 223.5.5.5
nameserver 223.6.6.6
```

### 6.2 分区与格式化

```bash
# 对 SD 卡 / eMMC 进行分区
fdisk /dev/mmcblk1
# 创建 MBR 分区表
Command (m for help): o
# 创建新分区 FAT32 BOOT
Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 1
First sector (2048-2097151, default 2048): 2048
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-2097151, default 2097151): +64M

Created a new partition 1 of type 'Linux' and of size 64 MiB.

# 创建新分区 Linux ROOT
Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p):

Using default response p.
Partition number (2-4, default 2):
First sector (133120-2097151, default 133120):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (133120-2097151, default 2097151):

Created a new partition 2 of type 'Linux' and of size 959 MiB.

# 设置分区为 FAT32 格式
Command (m for help): t
Partition number (1,2, default 2): 1
Hex code or alias (type L to list all): c

Changed type of partition 'Linux' to 'W95 FAT32 (LBA)'.

# 设置 BOOT Flag
Command (m for help): a
Partition number (1,2, default 2): 1

The bootable flag on partition 1 is enabled now.

# 写入并保存
Command (m for help): w

# 格式化分区
mkfs.vfat /dev/mmcblk1p1
mkfs.ext2 /dev/mmcblk1p2
```

分区方案：

| 分区 | 类型 | 用途 |
|------|------|------|
| `/dev/mmcblk1p1` | FAT32 | boot 分区 |
| `/dev/mmcblk1p2` | ext4 | rootfs 分区 |

### 6.3 创建BOOT分区
``` bash
# 挂载 /dev/mmcblk1p1 到 /boot 目录
mount /dev/mmcblk1p1 /boot
# 复制 fat32_boot 的内容到 /boot 目录
# uboot启动脚本优先使用 /boot 分区的内核和设备树启动Linux
# 失败则回退到QSPI内的内核启动

```

### 6.4 解压根文件系统

```bash
# 挂载 rootfs 分区
mount /dev/mmcblk1p2 /rootfs

# 获取 Ubuntu Base（可通过 wget 下载或 nc 本地传输）

# 解压到 rootfs
cd /rootfs
tar -xvf ubuntu-base.tar.gz
```

### 6.5 配置 Ubuntu 系统

```bash
# 切换到 Ubuntu 环境
chroot /rootfs /bin/bash

# 配置 APT 镜像源
vi /etc/apt/sources.list

deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-security main restricted universe multiverse
# 更新软件包列表
apt update

# 安装 systemd 及相关组件
apt install -y systemd systemd-sysv systemd-timesyncd \
  systemd-resolved dbus dbus-user-session libpam-systemd

# 安装网络管理工具
apt install -y network-manager netplan.io ifupdown \
  net-tools iputils-ping iproute2

# 安装基础工具
apt install -y vim nano sudo bash-completion htop less curl wget

# 设置默认启动目标
systemctl set-default multi-user.target
ln -sf /lib/systemd/system/multi-user.target \
  /etc/systemd/system/default.target

# 启用核心服务
systemctl enable systemd-journald
systemctl enable systemd-logind
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd
systemctl enable dbus

# 配置 DNS 解析
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

### 6.6 创建用户

```bash
# 创建管理员用户
useradd -m -s /bin/bash admin
passwd admin

# 添加 sudo 权限
usermod -aG sudo admin
```

### 6.7 安装 SSH（可选）

```bash
apt install -y openssh-server
systemctl enable ssh
```

配置完成后可通过 SSH 远程连接：

```bash
# Windows 终端连接
ssh user@192.168.x.x

# 通过 SCP 传输文件
scp file user@192.168.x.x:~/
```

### 添加BOOT自动挂载
```bash
vi /etc/fstab
# UNCONFIGURED FSTAB FOR BASE SYSTEM
/dev/mmcblk1p1 /boot vfat defaults 0 0
```

## 7. 常用操作

### ST7789V LCD屏幕驱动
``` bash
# 编译zynq-7000-spi0.dts设备树文件
dtc -@ -I dts -O dtb zynq-7000-spi0.dts -o zynq-7000-spi0.dtbo
# 复制到boot分区
sudo cp zynq-7000-spi0.dtbo /boot/
# 修改uEnv.txt 加载设备树,多个文件使用空格分隔
dtbo_files=zynq-7000-spi0.dtbo zynq-xxx.dtbo
# 重启并加载驱动
sudo reboot
```
因为是通过initramfs加载的根文件系统，无法在内核启动阶段读取到屏幕初始化固件，需要在启动后手动触发驱动加载。
也可以重新生成initramfs添加panel-mipi-dbi-spi.bin固件在内核启动阶段自动加载驱动。
```bash
sudo cp panel-mipi-dbi-spi.bin /lib/firmware
echo "spi1.1" | sudo tee /sys/bus/spi/drivers/panel-mipi-dbi-spi/bind
# 加载成功后会出现 /dev/dri/card0 /dev/fb0 两个设备
# 安装 drmtests
sudo apt install drmtests
# 执行后屏幕应正常显示
sudo modetests -M panel
# 刷屏测试
sudo dd if=/dev/zero of=/dev/fb0 bs=1M status=progress
watch -n 0.015 sudo dd if=/dev/random of=/dev/fb0 bs=1M status=progress
# 卸载驱动
echo "spi1.1" | sudo tee /sys/bus/spi/drivers/panel-mipi-dbi-spi/unbind
```


### initramfs 切换到 root
```bash
# /rootfs 根文件系统路径
exec switch_root /rootfs /sbin/init
```
### u-boot 手动引导

```bash
fatload 0x400000 zImage
fatload 0x100000 uRamdisk
fatload 0x100 zynq-boooom.dtb
bootz 0x400000 0x100000 0x100
```

### FPGA bit 流加载

```bash
fatload 0x1000000 design_1_wrapper.bit
fpga load 0 0x1000000
```

### 硬件相关文档
切换启动模式/硬件原理图等
[Boooom ZYNQ硬件项目](https://boooom.cn/archives/BoooomZYNQ)
