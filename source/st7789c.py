#!/usr/bin/env python3
import struct
import os

# 魔数: "panel-mipi-dbi" (16字节，不足补0)
MAGIC = b"MIPI DBI" + b"\x00" * 7
# 版本号
VERSION = 1

# ST7789V 初始化序列
# 格式: [命令] [参数数量] [参数...]
# 特殊: 0x00 0x01 [ms] 表示延时
commands = [
    # 软件复位
    (0x01, 0, []),
    # 延时 120ms
    (0x00, 1, [120]),
    
    # 退出睡眠模式
    (0x11, 0, []),
    # 延时 120ms
    (0x00, 1, [120]),
    
    # 设置颜色模式: 16-bit RGB565
    (0x3A, 1, [0x55]),
    
    # 内存访问控制: 正常方向 (可根据需要修改)
    (0x36, 1, [0x00]),
    
    # 列地址设置: 0-239 (0x00, 0xEF)
    (0x2A, 4, [0x00, 0x00, 0x00, 0xEF]),
    
    # 行地址设置: 0-319 (0x01, 0x3F)
    (0x2B, 4, [0x00, 0x00, 0x01, 0x3F]),
    
    # 写入像素格式: 0x55 = 16-bit
    (0x3A, 1, [0x55]),
    
    # 显示开启
    (0x29, 0, []),
    # 延时 50ms
    (0x00, 1, [50]),
]

# 构建命令缓冲区
cmd_buffer = bytearray()
for cmd, num_params, params in commands:
    cmd_buffer.append(cmd)
    cmd_buffer.append(num_params)
    cmd_buffer.extend(params)

# 构建完整固件
firmware = bytearray()
firmware.extend(MAGIC)
firmware.extend(struct.pack('<I', VERSION))  # 小端序
firmware.extend(cmd_buffer)

# 保存文件
with open('panel-mipi-dbi-spi.bin', 'wb') as f:
    f.write(firmware)

print(f"Generated firmware file: panel-mipi-dbi-spi.bin ({len(firmware)} bytes)")
print(f"Commands: {len(commands)}")
print(f"Command data: {len(cmd_buffer)} bytes")
