#!/bin/bash
# USB Gadget 设置脚本
LOG="/var/log/usb_gadget.log"
echo "$(date): UDC 设备就绪 - $KERNEL" >> $LOG
check_networkmanager() {
	if systemctl is-active --quiet NetworkManager 2>/dev/null; then
		return 0
	fi
	return 1
}
# 等待系统稳定
sleep 1

# 加载 NCM 驱动
modprobe g_ncm 2>&1 | tee -a $LOG

# 等待接口出现
for i in {1..10}; do
    if check_networkmanager; then
        if ip link show usb0 &>/dev/null; then
            echo "$(date): usb0 接口已出现" >> $LOG
            ip link set usb0 up 2>&1 | tee -a $LOG
            sleep 1
	    nmcli connection up "USB-Ethernet" 2>&1 | tee -a $LOG
            break
    	fi
    fi
    sleep 1
done

echo "$(date): USB Gadget 设置完成" >> $LOG
