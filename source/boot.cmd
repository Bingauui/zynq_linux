# 设置地址
setenv kernel_addr_r 0x00400000
setenv initramfs_addr_r 0x00100000
setenv fdt_addr_r 0x00000100
setenv fdt_overlay_addr 0x00080000
setenv bitstream_addr_r 0x01000000

# 尝试从uEnv.txt加载（MMC 0和1）
for mmc_dev in 0 1; do
    echo "eheck MMC ${mmc_dev}..."
    mmc dev ${mmc_dev}
    if fatload mmc ${mmc_dev}:1 ${kernel_addr_r} uEnv.txt; then
        echo "loading uEnv.txt from MMC ${mmc_dev}"
        env import -t ${kernel_addr_r} ${filesize}
        
        # 加载DTB
        if test -n "${dtb_file}"; then
       	    fatload mmc ${mmc_dev}:1 ${fdt_addr_r} ${dtb_file}
	    fdt addr ${fdt_addr_r}
  	    fdt resize 0x60000	
	    # 应用DTBO
            if test -n "${dtbo_files}"; then
                for dtbo in ${dtbo_files}; do
                    echo "apply DTBO: ${dtbo}"
                    if fatload mmc ${mmc_dev}:1 ${fdt_overlay_addr} ${dtbo}; then
                        fdt apply ${fdt_overlay_addr}
                    fi
                done
            fi
	fi

	# 加载fpga bitstream
	if test -n "${bitstream_file}"; then
           fatload mmc ${mmc_dev}:1 ${bitstream_addr_r} ${bitstream_file}
	   fpga loadb 0 ${bitstream_addr_r} ${filesize}
        fi

	# 加载kernel和initramfs
        test -n "${kernel_file}" && fatload mmc ${mmc_dev}:1 ${kernel_addr_r} ${kernel_file}
        test -n "${initramfs_file}" && fatload mmc ${mmc_dev}:1 ${initramfs_addr_r} ${initramfs_file}
        
        # 启动
        test -z "${bootargs}" && setenv bootargs "console=ttyPS0,115200 earlycon"
        bootz ${kernel_addr_r} ${initramfs_addr_r} ${fdt_addr_r}
    fi
done

# QSPI启动
echo "try QSPI..."
if mtd read qspi-linux ${kernel_addr_r}; then
	mtd read qspi-device-tree ${fdt_addr_r}
	fdt addr ${fdt_addr_r}
	# 尝试QSPI DTBO
    	mtd read qspi-rootfs ${initramfs_addr_r}
	mtd read qspi-bitstream ${bitstream_addr_r}
	fpga loadb 0 ${bitstream_addr_r} ${bitstream_size_r}
    	setenv bootargs "console=ttyPS0,115200 earlycon"
    	bootz ${kernel_addr_r} ${initramfs_addr_r} ${fdt_addr_r}
fi

