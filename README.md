# ZYNQ Boooom Linux 安装流程
## BOOT 烧录

### 目录结构
``` bash
boot 
    boot.bin # BOOT.bin 文件 合并fsbl.elf uboot.elf zynq-boooom.dtb
    boot.scr # u-boot 启动脚本
    design_1_wrapper.bit # FPGA bit流
    fsbl.elf # 一级引导程序
    fsbl.elf.size 
    linux_boooom.img # 全分区镜像文件
    linux_hello_world.bif # BOOT.bin 合并配置文件 
    openocd.cfg # openocd 配置
    u-boot.elf # u-boot引导程序
    uRamdisk # initramfs 
    zImage # kernel 内核镜像
    zynq-booom.dtb #设备树文件
rootfs
    ubuntu-base-22.04-base-armhf.tar.gz # 基础 ubuntu 根文件系统
source # 最新的主线代码即可
    zynq_boooom_defconfig # kernel 编译配置文件
    zynq-booom.dts # 设备树
    u-boot.config # u-boot 编译配置文件
    panel-mipi-dbi-spi.bin # 屏幕初始化序列固件
    device-overlay # 设备树插件，编译后在uEnv添加启用
    boot.cmd # u-boot 启动脚本
```

### QSPI 分区表
``` bash
0x000000000000-0x000000200000 : "qspi-fsbl-uboot"  : 2M
0x000000200000-0x000000a00000 : "qspi-linux"       : 8M
0x000000a00000-0x000000a80000 : "qspi-device-tree" : 512K
0x000000a80000-0x000000b00000 : "qspi-uboot-cmd"   : 512K
0x000000b00000-0x000000d00000 : "qspi-rootfs"      : 2M
0x000000d00000-0x000001000000 : "qspi-bitstream"   : 3M
```

### 直接烧录全量镜像
#### 烧录镜像前切换为 JTAG 启动
#### 所有路径替换为实际文件的绝对路径
``` bash
($Vitis_INSTALL_PATH)\program_flash -f $BOOT_PATH\linux_boooom.img -offset 0x0 -flash_type qspi-x4-single -fsbl $BOOT_PATH\fsbl.elf -verify -url TCP:127.0.0.1:3121
```

### 分区烧录 (二选一，新板子可直接进行全量烧录)
#### 烧录镜像前切换为 JTAG 启动
``` bash
# 烧录BOOT.bin
($Vitis_INSTALL_PATH)\program_flash -f $BOOT_PATH\boot.bin -offset 0x0 -flash_type qspi-x4-single -fsbl $BOOT_PATH\fsbl.elf -verify -url TCP:127.0.0.1:3121

# 烧录Kernel
($Vitis_INSTALL_PATH)\program_flash -f $BOOT_PATH\zImage -offset 0x200000 -flash_type qspi-x4-single -fsbl $BOOT_PATH\fsbl.elf -verify -url TCP:127.0.0.1:3121

# 烧录dtb
($Vitis_INSTALL_PATH)\program_flash -f $BOOT_PATH\zynq-booom.dtb -offset 0xa00000 -flash_type qspi-x4-single -fsbl $BOOT_PATH\fsbl.elf -verify -url TCP:127.0.0.1:3121

# 烧录uRamDisk
($Vitis_INSTALL_PATH)\program_flash -f $BOOT_PATH\uRamdisk -offset 0xa00000 -flash_type qspi-x4-single -fsbl $BOOT_PATH\fsbl.elf -verify -url TCP:127.0.0.1:3121
```

### 烧录完成后切换为 QSPI 启动
#### 连接调试器后启用串口终端
#### 烧录完成后会进入initramfs系统

## ubuntu base 安装
``` bash
# dchp 获取 IP (可选)
udhcpc 
# 配置网口进行连接
ip addr add 192.168.x.x/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.x.1
# 配置dns服务器
vi /etc/resolv.conf
# 写入以下内容（注意：只保留 nameserver 行）
nameserver 223.5.5.5
nameserver 223.6.6.6

# 格式化 mmcblkp0
fdisk /dev/mmcblk0
创建 boot分区 fat32
创建 root分区 ext4

# 挂载root分区
mount /dev/mmcblk0p2 /rootfs

# wget 或 xz 获取 ubuntu base文件

# 解压到rootfs
cd rootfs
tar -xvf ubuntu-base.tar.gz

# 切换到ubuntu
chroot /rootfs /bin/bash

# 配置 apt 镜像源
vi /etc/apt/source.list
apt update

# 安装systemd服务, 安装ssh服务
apt install systemd network-manager sshd

# 网络连接后可通过 ssh 连接 shell
# windows 终端执行
ssh user@192.168.x.x
# 后续可通过 scp 传输文件
scp file user@192.168.x.x:~/


```

## 常用功能
``` bash
# u-boot 手动引导 linux 启动
fatload 0x400000 zImage
fatload 0x100000 uRawdisk
fatload 0x100 zynq-boooom.dtb
bootz 0x400000 0x100000 

# fpga bit流加载
fatload 0x1000000 design_1.bit
fpga load 0 0x1000000
```