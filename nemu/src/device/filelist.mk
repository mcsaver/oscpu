#***************************************************************************************
# Copyright (c) 2014-2024 Zihao Yu, Nanjing University
#
# NEMU is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#          http://license.coscl.org.cn/MulanPSL2
#
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
#
# See the Mulan PSL v2 for more details.
#**************************************************************************************/

##+=的作用是追加变量到末尾
##如下的命令等价为，根据config的配置，若CONFIG_DEVICE为y，那么SRCS-y +=..后面的文件会被加到文件列表中进行编译
DIRS-y += src/device/io
SRCS-$(CONFIG_DEVICE) += src/device/device.c src/device/alarm.c src/device/intr.c

ifeq ($(CONFIG_SOC_SIM),y)
# ysyxSoC owns its UART/SPI/GPIO/PS2/VGA address windows.  Compile only the
# shared 16550 core required by the SoC adapter; generic IOMap providers belong
# exclusively to the generic NEMU platform below.
SRCS-y += src/device/uart16550.c
else
SRCS-$(CONFIG_HAS_SERIAL) += src/device/serial.c
ifeq ($(CONFIG_HAS_SERIAL),y)
SRCS-y += src/device/uart16550.c
endif
SRCS-$(CONFIG_HAS_TIMER) += src/device/timer.c
SRCS-$(CONFIG_HAS_KEYBOARD) += src/device/keyboard.c
SRCS-$(CONFIG_HAS_VGA) += src/device/vga.c
SRCS-$(CONFIG_HAS_AUDIO) += src/device/audio.c
SRCS-$(CONFIG_HAS_DISK) += src/device/disk.c
ifdef CONFIG_HAS_DISK
ifndef CONFIG_TARGET_AM
CFLAGS += -pthread
LIBS += -pthread
endif
endif
SRCS-$(CONFIG_HAS_VIRTIO_RNG) += src/device/rng.c
SRCS-$(CONFIG_HAS_VIRTIO_NET) += src/device/net.c
SRCS-$(CONFIG_HAS_GOLDFISH_RTC) += src/device/goldfish_rtc.c
SRCS-$(CONFIG_HAS_SDCARD) += src/device/sdcard.c
endif

# syscon has no interrupt dependency and remains an explicit, non-overlapping
# NEMU service extension when selected for either platform profile.
SRCS-$(CONFIG_HAS_SYSCON_RESET) += src/device/syscon.c

SRCS-BLACKLIST-$(CONFIG_TARGET_AM) += src/device/alarm.c

##判断CONFIG_DEVICE是否被定义(通常在menuconfig里启用了设备支持)--CONFIG_DEVICE
##只有启用了设备子系统时，下面的内容才会生效
##ifndef CONFIG_TARGET_AM:判断CONFIG_TARGET_AM是否没有被定义(即当前不是在abstract machine(AM)平台下编译)
##只有在本地NEMU仿真环境下，才需要链接SDL2库
##LIBS +=....执行shelll命令，获取sdl2库的链接参数
##把这些参数追加到LIBS中，确保编译时能正常链接SDL2库(用于图形、音频等设备模拟)
ifdef CONFIG_DEVICE
ifndef CONFIG_TARGET_AM
ifneq ($(filter y,$(CONFIG_HAS_KEYBOARD) $(CONFIG_HAS_VGA) $(CONFIG_HAS_AUDIO)),)
LIBS += $(shell sdl2-config --libs)
endif
endif
endif
