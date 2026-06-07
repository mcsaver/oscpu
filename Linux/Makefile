# RV64 Linux/Ubuntu bring-up 顶层入口。
#
# 命令规范：
#   ARCH 表示仿真/目标架构，基准值是 riscv64-npc。
#   BOOT 表示启动场景，默认 ubuntu-rootfs，即完整 Ubuntu rootfs 路线。
#   已闭合的 shell initramfs gate 必须显式选择 BOOT=ubuntu-shell。

SHELL := /bin/bash

ARCH ?= riscv64-npc
BOOT ?= ubuntu-rootfs

LINUX_HOME := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO_ROOT := $(abspath $(LINUX_HOME)/..)
NPC_RV64 := $(REPO_ROOT)/npc/rv64
NPC_SIM ?= $(NPC_RV64)/build/NpcSimTop
NEMU_HOME := $(REPO_ROOT)/nemu
NEMU_SIM ?= $(NEMU_HOME)/build/riscv64-nemu-interpreter
NEMU_DEFCONFIG ?= riscv64-linux_defconfig

ENV_ROOT ?= $(LINUX_HOME)/env
BUILD_DIR ?= $(LINUX_HOME)/build
SCRIPT_DIR := $(LINUX_HOME)/scripts
TOOLS_DIR := $(LINUX_HOME)/tools
LINUX_CONFIG ?= $(LINUX_HOME)/configs/rv64_linux_defconfig
TRACE_CONFIG ?= $(LINUX_HOME)/configs/rv64_trace_defconfig
PLATFORM_CONFIG ?= $(LINUX_HOME)/platform/npc-rv64.yml
GEN_DTS ?= $(LINUX_HOME)/platform/gen_dts.py
PYTHON ?= $(if $(wildcard $(ENV_ROOT)/tools/python/bin/python3),$(ENV_ROOT)/tools/python/bin/python3,python3)
DTC ?= dtc
JOBS ?= $(shell nproc)

KCONFIG_PATH := $(REPO_ROOT)/nemu/tools/kconfig
FIXDEP_PATH := $(REPO_ROOT)/nemu/tools/fixdep
CONF := $(KCONFIG_PATH)/build/conf
FIXDEP := $(FIXDEP_PATH)/build/fixdep
LINUX_CONFIG_STAMP := $(NPC_RV64)/.linux-defconfig.stamp
TRACE_CONFIG_STAMP := $(NPC_RV64)/.linux-trace-defconfig.stamp
FORCE_CONFIG ?= 0

NEXT_ADDR ?= 0x80200000
DTB_ADDR ?= 0x82200000
INITRD_ADDR ?= 0x84000000

# NEMU 的 --max-insts=0 表示无限预算，更接近“启动系统后持续运行”的入口语义。
DEFAULT_MAX_CYCLES := $(if $(filter riscv64-nemu,$(ARCH)),0,3000000000)
MAX_CYCLES ?= $(DEFAULT_MAX_CYCLES)
PROGRESS ?= 50000000
LOG_ROOT ?= $(ENV_ROOT)/logs/linux-front
EXTRA_ARGS ?=
BOOTARGS_EXTRA ?=
NEMU_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-nemu-systemd-guest-check
NEMU_SYSTEMD_CHECK_MAX_CYCLES ?= 25000000000
NEMU_SYSTEMD_CHECK_TIMEOUT ?= 1800
NEMU_SYSTEMD_BOOT_TIMEOUT ?= 900
NEMU_SYSTEMD_SOAK_SECONDS ?= 20
NEMU_SYSTEMD_FS_STRESS_MIB ?= 4
NEMU_SYSTEMD_FS_TREE_FILES ?= 64
NEMU_SYSTEMD_PROCESS_LOOPS ?= 16
NEMU_SYSTEMD_INPUT_DELAY ?= 0
NEMU_SYSTEMD_UART_RX_STRESS_LINES ?= 512
NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS ?= 4
NEMU_SYSTEMD_BLOCK_JOB_MIB ?= 1
NEMU_SYSTEMD_LONG_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-nemu-systemd-guest-long-check
NEMU_SYSTEMD_LONG_CHECK_MAX_CYCLES ?= 30000000000
NEMU_SYSTEMD_LONG_CHECK_TIMEOUT ?= 1800
NEMU_SYSTEMD_LONG_SOAK_SECONDS ?= 120
NEMU_SYSTEMD_LONG_FS_STRESS_MIB ?= 16
NEMU_SYSTEMD_LONG_FS_TREE_FILES ?= 128
NEMU_SYSTEMD_LONG_PROCESS_LOOPS ?= 64
NEMU_SYSTEMD_LONG_UART_RX_STRESS_LINES ?= 768
NEMU_SYSTEMD_LONG_BLOCK_PARALLEL_JOBS ?= 4
NEMU_SYSTEMD_LONG_BLOCK_JOB_MIB ?= 2
NEMU_SYSTEMD_SOAK_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-nemu-systemd-guest-soak-check
NEMU_SYSTEMD_SOAK_CHECK_MAX_CYCLES ?= 60000000000
NEMU_SYSTEMD_SOAK_CHECK_TIMEOUT ?= 2400
NEMU_SYSTEMD_SOAK_SOAK_SECONDS ?= 300
NEMU_SYSTEMD_SOAK_FS_STRESS_MIB ?= 32
NEMU_SYSTEMD_SOAK_FS_TREE_FILES ?= 256
NEMU_SYSTEMD_SOAK_PROCESS_LOOPS ?= 128
NEMU_SYSTEMD_SOAK_UART_RX_STRESS_LINES ?= 1024
NEMU_SYSTEMD_SOAK_BLOCK_PARALLEL_JOBS ?= 4
NEMU_SYSTEMD_SOAK_BLOCK_JOB_MIB ?= 4
NEMU_PERFORMANCE_REQUIRED ?= 1

LINUX_IMAGE ?= $(ENV_ROOT)/src/linux/arch/riscv/boot/Image
BUSYBOX_INITRD ?= $(ENV_ROOT)/images/initramfs/rootfs.cpio
UBUNTU_PROBE_INITRD ?= $(ENV_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64-probe.cpio
UBUNTU_SHELL_INITRD ?= $(ENV_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64.cpio
UBUNTU_ROOTFS_IMAGE ?= $(ENV_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64.ext4

KERNEL_DTB ?= $(BUILD_DIR)/npc-rv64.dtb
BUSYBOX_INITRAMFS_DTB ?= $(BUILD_DIR)/npc-rv64-initramfs.dtb
UBUNTU_PROBE_DTB ?= $(BUILD_DIR)/npc-rv64-ubuntu-initramfs.dtb
UBUNTU_SHELL_DTB ?= $(BUILD_DIR)/npc-rv64-ubuntu-shell-initramfs.dtb
NPC_ROOTFS_DTB ?= $(BUILD_DIR)/npc-rv64-rootfs.dtb
NEMU_ROOTFS_DTB ?= $(BUILD_DIR)/npc-rv64-nemu-rootfs.dtb
ROOTFS_DTB ?= $(if $(filter riscv64-nemu,$(ARCH)),$(NEMU_ROOTFS_DTB),$(NPC_ROOTFS_DTB))

OPENSBI_PROFILE ?= $(if $(filter riscv64-nemu,$(ARCH)),nemu,npc)
OPENSBI_BUILD_DIR ?= $(ENV_ROOT)/build/opensbi-$(OPENSBI_PROFILE)
OPENSBI_BUSYBOX_BUILD_DIR ?= $(ENV_ROOT)/build/opensbi-$(OPENSBI_PROFILE)-initramfs
OPENSBI_UBUNTU_PROBE_BUILD_DIR ?= $(ENV_ROOT)/build/opensbi-$(OPENSBI_PROFILE)-ubuntu-initramfs
OPENSBI_UBUNTU_SHELL_BUILD_DIR ?= $(ENV_ROOT)/build/opensbi-$(OPENSBI_PROFILE)-ubuntu-shell-initramfs
OPENSBI_ROOTFS_BUILD_DIR ?= $(ENV_ROOT)/build/opensbi-$(OPENSBI_PROFILE)-rootfs
# NEMU 目前没有完整 PMU 设备模型，默认给它构建 no-PMU OpenSBI，避免用户手工补参数。
OPENSBI_DISABLE_PMU ?= $(if $(filter riscv64-nemu,$(ARCH)),1,0)

OPENSBI_FW ?= $(OPENSBI_BUILD_DIR)/platform/generic/firmware/fw_jump.bin
OPENSBI_BUSYBOX_FW ?= $(OPENSBI_BUSYBOX_BUILD_DIR)/platform/generic/firmware/fw_jump.bin
OPENSBI_UBUNTU_PROBE_FW ?= $(OPENSBI_UBUNTU_PROBE_BUILD_DIR)/platform/generic/firmware/fw_jump.bin
OPENSBI_UBUNTU_SHELL_FW ?= $(OPENSBI_UBUNTU_SHELL_BUILD_DIR)/platform/generic/firmware/fw_jump.bin
OPENSBI_ROOTFS_FW ?= $(OPENSBI_ROOTFS_BUILD_DIR)/platform/generic/firmware/fw_jump.bin

UBUNTU_PROBE_EXPECT ?= PRETTY_NAME="Ubuntu 22.04.5 LTS"
UBUNTU_SHELL_EXPECT ?= [ysyx-sh] /bin/sh -c marker

SUPPORTED_ARCHES := riscv64-npc riscv64-nemu
SUPPORTED_BOOTS := ubuntu-rootfs ubuntu-shell ubuntu-probe busybox-initramfs kernel
TOOL_SMOKES := smoke-jal-link smoke-branch-raw \
  smoke-sret-user smoke-sret-user-pagefault smoke-sret-user-sv39 \
  smoke-sret-user-sv39-halfword smoke-sret-restore \
  smoke-ras-trap-boundary smoke-fp-loadstore smoke-fp-fcsr smoke-fp-fmv-fclass \
  smoke-fp-convert smoke-fp-compare-sgnj smoke-fp-minmax smoke-fp-addsub \
  smoke-fp-mul smoke-fp-div smoke-fp-sqrt
TOOL_BOOT_SMOKES := smoke-dtb smoke-opensbi smoke-opensbi-sbi
TOOL_BOOT_SMOKES += smoke-virtio-blk

ifeq ($(filter $(ARCH),$(SUPPORTED_ARCHES)),)
$(error unsupported ARCH=$(ARCH); supported: $(SUPPORTED_ARCHES))
endif

ifeq ($(filter $(BOOT),$(SUPPORTED_BOOTS)),)
$(error unsupported BOOT=$(BOOT); supported: $(SUPPORTED_BOOTS))
endif

RUN_NAME := $(BOOT)
RUN_FW :=
RUN_DTB :=
RUN_INITRD :=
RUN_ROOTFS :=
RUN_EXPECT :=
RUN_DEPS := sim $(LINUX_IMAGE)

ifeq ($(BOOT),ubuntu-rootfs)
RUN_FW := $(OPENSBI_ROOTFS_FW)
RUN_DTB := $(ROOTFS_DTB)
RUN_ROOTFS := $(UBUNTU_ROOTFS_IMAGE)
RUN_DEPS += $(RUN_FW) $(RUN_DTB) $(RUN_ROOTFS)
endif

ifeq ($(BOOT),ubuntu-shell)
RUN_FW := $(OPENSBI_UBUNTU_SHELL_FW)
RUN_DTB := $(UBUNTU_SHELL_DTB)
RUN_INITRD := $(UBUNTU_SHELL_INITRD)
RUN_EXPECT := $(UBUNTU_SHELL_EXPECT)
RUN_DEPS += $(RUN_FW) $(RUN_DTB) $(RUN_INITRD)
endif

ifeq ($(BOOT),ubuntu-probe)
RUN_FW := $(OPENSBI_UBUNTU_PROBE_FW)
RUN_DTB := $(UBUNTU_PROBE_DTB)
RUN_INITRD := $(UBUNTU_PROBE_INITRD)
RUN_EXPECT := $(UBUNTU_PROBE_EXPECT)
RUN_DEPS += $(RUN_FW) $(RUN_DTB) $(RUN_INITRD)
endif

ifeq ($(BOOT),busybox-initramfs)
RUN_FW := $(OPENSBI_BUSYBOX_FW)
RUN_DTB := $(BUSYBOX_INITRAMFS_DTB)
RUN_INITRD := $(BUSYBOX_INITRD)
RUN_DEPS += $(RUN_FW) $(RUN_DTB) $(RUN_INITRD)
endif

ifeq ($(BOOT),kernel)
RUN_FW := $(OPENSBI_FW)
RUN_DTB := $(KERNEL_DTB)
RUN_DEPS += $(RUN_FW) $(RUN_DTB)
endif

LOG_DIR ?= $(LOG_ROOT)/$(ARCH)-$(RUN_NAME)
LOG_FILE ?= $(LOG_DIR)/$(if $(filter riscv64-nemu,$(ARCH)),nemu,npc).log
CONSOLE_LOG ?= $(LOG_DIR)/console.log
RUN_SIM := $(if $(filter riscv64-nemu,$(ARCH)),$(NEMU_SIM),$(NPC_SIM))
PROGRESS_OPT := $(if $(strip $(PROGRESS)),--progress=$(PROGRESS),--no-progress)
EXPECT_ENV := $(if $(strip $(RUN_EXPECT)),NPC_GUEST_EXPECT='$(RUN_EXPECT)',)
INITRD_LOAD := $(if $(strip $(RUN_INITRD)),--load=$(INITRD_ADDR):$(RUN_INITRD),)
ROOTFS_BLOCK := $(if $(strip $(RUN_ROOTFS)),--block='$(RUN_ROOTFS)',)

.DEFAULT_GOAL := help

.PHONY: help run run-ubuntu-rootfs run-ubuntu-shell run-ubuntu-probe run-busybox-initramfs run-kernel \
        prepare prepare-all setup-env linux-defconfig linux-trace-defconfig nemu-linux-defconfig sim check-sim \
        linux-image busybox-initramfs ubuntu-probe-initramfs \
        ubuntu-shell-initramfs ubuntu-rootfs-image dtb initramfs-dtb ubuntu-initramfs-dtb \
        ubuntu-shell-initramfs-dtb rootfs-dtb opensbi opensbi-busybox opensbi-ubuntu-probe \
        opensbi-ubuntu-shell opensbi-rootfs qemu qemu-build qemu-ubuntu-probe qemu-ubuntu-shell \
        tools-build boot-tools tools-smoke tools-clean paths check ubuntu-rootfs-check \
        check-ubuntu-rootfs check-ubuntu-rootfs-systemd ubuntu-rootfs-systemd-image \
        ubuntu-rootfs-systemd-overlay check-nemu-systemd-guest check-nemu-systemd-guest-long \
        check-nemu-systemd-guest-soak check-nemu-performance-config __check-nemu-systemd-guest clean clean-logs \
        $(TOOL_SMOKES) $(TOOL_BOOT_SMOKES)

help:
	@printf '%s\n' 'RV64 Linux/Ubuntu 顶层入口'
	@printf '%s\n' ''
	@printf '%s\n' '命令规范:'
	@printf '%s\n' '  ARCH=riscv64-npc 表示使用 NPC RV64 Verilator 目标'
	@printf '%s\n' '  ARCH=riscv64-nemu 表示使用 NEMU RV64 Linux 参考入口'
	@printf '%s\n' '  BOOT=ubuntu-rootfs 表示完整 Ubuntu rootfs 路线，默认值'
	@printf '%s\n' ''
	@printf '%s\n' '常用命令:'
	@printf '%s\n' '  make ARCH=riscv64-npc run'
	@printf '%s\n' '      启动完整 Ubuntu rootfs 路线，自动挂载 virtio-mmio block 镜像。'
	@printf '%s\n' '  make ARCH=riscv64-nemu run'
	@printf '%s\n' '      用 NEMU 启动同一条完整 Ubuntu rootfs 路线，默认无限预算并使用 no-PMU OpenSBI。'
	@printf '%s\n' '  make ARCH=riscv64-npc BOOT=ubuntu-shell run'
	@printf '%s\n' '      启动已闭合的 Ubuntu shell initramfs gate，命中 /bin/sh marker 自动退出。'
	@printf '%s\n' '  make ARCH=riscv64-npc BOOT=ubuntu-probe run'
	@printf '%s\n' '      启动轻量 Ubuntu os-release probe。'
	@printf '%s\n' '  make ARCH=riscv64-npc prepare'
	@printf '%s\n' '      构建当前 BOOT 所需资源。'
	@printf '%s\n' '  make ARCH=riscv64-npc smoke-sret-user-sv39'
	@printf '%s\n' '      在 Linux/tools 下跑指定 focused gate。'
	@printf '%s\n' '  make ARCH=riscv64-npc smoke-sret-user-sv39-halfword'
	@printf '%s\n' '      跑用户态 Sv39 半字地址 32-bit 取指 focused gate。'
	@printf '%s\n' '  make ARCH=riscv64-npc tools-smoke'
	@printf '%s\n' '      跑 Linux bring-up 相关 focused gates。'
	@printf '%s\n' '  make ARCH=riscv64-npc smoke-opensbi-sbi'
	@printf '%s\n' '      跑真实 OpenSBI runtime SBI 小 payload gate。'
	@printf '%s\n' '  make ARCH=riscv64-npc smoke-virtio-blk'
	@printf '%s\n' '      通过 virtio-mmio 读取 Ubuntu ext4 rootfs superblock。'
	@printf '%s\n' '  make ARCH=riscv64-npc paths'
	@printf '%s\n' '      打印当前 ARCH/BOOT 的资源路径。'
	@printf '%s\n' '  make ARCH=riscv64-nemu check-ubuntu-rootfs'
	@printf '%s\n' '      检查 ext4 rootfs 是否具备 /init、/bin/sh、os-release，并报告 systemd readiness。'
	@printf '%s\n' '  make ARCH=riscv64-nemu check-ubuntu-rootfs-systemd'
	@printf '%s\n' '      要求 rootfs 已包含 systemd；当前 Ubuntu Base fakeroot 镜像会明确失败。'
	@printf '%s\n' '  make ARCH=riscv64-nemu ubuntu-rootfs-systemd-image'
	@printf '%s\n' '      无 sudo 时用 apt/dpkg-deb overlay 把 systemd/udev/dbus 候选用户态放进 rootfs。'
	@printf '%s\n' '  make check-nemu-systemd-guest'
	@printf '%s\n' '      启动 NEMU Ubuntu rootfs，并在 guest 内检查 systemd target/getty/manager/journal/dbus、runtime unit、挂载、udev/sysfs/virtio-blk、TTY、syscall、timer、rootfs 写回和短 soak。'
	@printf '%s\n' '      默认要求 NEMU performance 配置已生效；调试 trace 时可显式传 NEMU_PERFORMANCE_REQUIRED=0。'
	@printf '%s\n' '  make check-nemu-systemd-guest-long'
	@printf '%s\n' '      更长时间的 NEMU Ubuntu/systemd 稳定性 gate，默认 120s soak、16MiB rootfs stress、128 个元数据文件、64 轮进程循环和 4 个 2MiB 并发 direct IO job。'
	@printf '%s\n' '  make check-nemu-systemd-guest-soak'
	@printf '%s\n' '      更重的 NEMU Ubuntu/systemd soak gate，默认 300s soak、32MiB rootfs stress、256 个元数据文件、128 轮进程循环和 4 个 4MiB 并发 direct IO job。'
	@printf '%s\n' ''
	@printf '%s\n' '别名:'
	@printf '%s\n' '  make ARCH=riscv64-npc run-ubuntu-rootfs'
	@printf '%s\n' '  make ARCH=riscv64-npc run-ubuntu-shell'
	@printf '%s\n' '  make ARCH=riscv64-npc run-ubuntu-probe'

run: $(RUN_DEPS)
	@mkdir -p '$(LOG_DIR)'
	@printf '[Linux] ARCH=%s BOOT=%s\n' '$(ARCH)' '$(BOOT)'
	@printf '[Linux] firmware: %s\n' '$(RUN_FW)'
	@printf '[Linux] kernel:   %s\n' '$(LINUX_IMAGE)'
	@printf '[Linux] dtb:      %s\n' '$(RUN_DTB)'
	@if [ -n '$(RUN_INITRD)' ]; then printf '[Linux] initrd:   %s\n' '$(RUN_INITRD)'; fi
	@if [ -n '$(RUN_ROOTFS)' ]; then \
	  printf '[Linux] rootfs:   %s\n' '$(RUN_ROOTFS)'; \
	fi
	@printf '[Linux] log:      %s\n' '$(CONSOLE_LOG)'
ifeq ($(ARCH),riscv64-nemu)
	NEMU_HOME='$(NEMU_HOME)' '$(NEMU_SIM)' -b --max-insts=$(MAX_CYCLES) \
	  --log='$(LOG_FILE)' \
	  --boot-hartid=0 \
	  --boot-dtb=$(DTB_ADDR) \
	  -i '$(RUN_FW)' \
	  --load=$(NEXT_ADDR):'$(LINUX_IMAGE)' \
	  --load=$(DTB_ADDR):'$(RUN_DTB)' \
	  $(INITRD_LOAD) \
	  $(ROOTFS_BLOCK) \
	  $(EXTRA_ARGS) 2>&1 | tee '$(CONSOLE_LOG)'
else
	$(EXPECT_ENV) '$(NPC_SIM)' -b $(PROGRESS_OPT) --no-diff --max=$(MAX_CYCLES) \
	  --log='$(LOG_FILE)' \
	  -i '$(RUN_FW)' \
	  --load=$(NEXT_ADDR):'$(LINUX_IMAGE)' \
	  --load=$(DTB_ADDR):'$(RUN_DTB)' \
	  $(INITRD_LOAD) \
	  $(ROOTFS_BLOCK) \
	  $(EXTRA_ARGS) 2>&1 | tee '$(CONSOLE_LOG)'
endif

run-ubuntu-rootfs:
	$(MAKE) ARCH=$(ARCH) BOOT=ubuntu-rootfs run

run-ubuntu-shell:
	$(MAKE) ARCH=$(ARCH) BOOT=ubuntu-shell run

run-ubuntu-probe:
	$(MAKE) ARCH=$(ARCH) BOOT=ubuntu-probe run

run-busybox-initramfs:
	$(MAKE) ARCH=$(ARCH) BOOT=busybox-initramfs run

run-kernel:
	$(MAKE) ARCH=$(ARCH) BOOT=kernel run

prepare: $(RUN_DEPS)

prepare-all: sim linux-image busybox-initramfs ubuntu-probe-initramfs ubuntu-shell-initramfs \
	ubuntu-rootfs-image dtb initramfs-dtb ubuntu-initramfs-dtb ubuntu-shell-initramfs-dtb \
	rootfs-dtb opensbi opensbi-busybox opensbi-ubuntu-probe opensbi-ubuntu-shell opensbi-rootfs

setup-env:
	bash '$(SCRIPT_DIR)/setup-env.sh'

$(CONF):
	$(MAKE) -s -C '$(KCONFIG_PATH)' NAME=conf

$(FIXDEP):
	$(MAKE) -s -C '$(FIXDEP_PATH)'

linux-defconfig: $(CONF) $(FIXDEP)
	@set -e; \
	need=0; \
	profile_hash=$$(sha256sum '$(LINUX_CONFIG)' | cut -d ' ' -f1); \
	config_hash=$$(if [ -f '$(NPC_RV64)/.config' ]; then sha256sum '$(NPC_RV64)/.config' | cut -d ' ' -f1; else echo missing; fi); \
	stamp_profile=$$(sed -n '1p' '$(LINUX_CONFIG_STAMP)' 2>/dev/null || true); \
	stamp_config=$$(sed -n '2p' '$(LINUX_CONFIG_STAMP)' 2>/dev/null || true); \
	if [ '$(FORCE_CONFIG)' = '1' ]; then need=1; fi; \
	if [ "$$profile_hash" != "$$stamp_profile" ]; then need=1; fi; \
	if [ "$$config_hash" != "$$stamp_config" ]; then need=1; fi; \
	if [ "$$need" = 1 ]; then \
	  cd '$(NPC_RV64)' && '$(CONF)' -s --defconfig='$(LINUX_CONFIG)' Kconfig; \
	  cd '$(NPC_RV64)' && '$(CONF)' -s --syncconfig Kconfig; \
	  config_hash=$$(sha256sum '$(NPC_RV64)/.config' | cut -d ' ' -f1); \
	  printf '%s\n%s\n' "$$profile_hash" "$$config_hash" > '$(LINUX_CONFIG_STAMP)'; \
	else \
	  echo '[Linux] rv64 linux defconfig up to date'; \
	fi

linux-trace-defconfig: $(CONF) $(FIXDEP)
	@set -e; \
	need=0; \
	profile_hash=$$(sha256sum '$(TRACE_CONFIG)' | cut -d ' ' -f1); \
	config_hash=$$(if [ -f '$(NPC_RV64)/.config' ]; then sha256sum '$(NPC_RV64)/.config' | cut -d ' ' -f1; else echo missing; fi); \
	stamp_profile=$$(sed -n '1p' '$(TRACE_CONFIG_STAMP)' 2>/dev/null || true); \
	stamp_config=$$(sed -n '2p' '$(TRACE_CONFIG_STAMP)' 2>/dev/null || true); \
	if [ '$(FORCE_CONFIG)' = '1' ]; then need=1; fi; \
	if [ "$$profile_hash" != "$$stamp_profile" ]; then need=1; fi; \
	if [ "$$config_hash" != "$$stamp_config" ]; then need=1; fi; \
	if [ "$$need" = 1 ]; then \
	  cd '$(NPC_RV64)' && '$(CONF)' -s --defconfig='$(TRACE_CONFIG)' Kconfig; \
	  cd '$(NPC_RV64)' && '$(CONF)' -s --syncconfig Kconfig; \
	  config_hash=$$(sha256sum '$(NPC_RV64)/.config' | cut -d ' ' -f1); \
	  printf '%s\n%s\n' "$$profile_hash" "$$config_hash" > '$(TRACE_CONFIG_STAMP)'; \
	else \
	  echo '[Linux] rv64 trace defconfig up to date'; \
	fi

ifeq ($(ARCH),riscv64-nemu)
nemu-linux-defconfig:
	$(MAKE) -C '$(NEMU_HOME)' NEMU_HOME='$(NEMU_HOME)' $(NEMU_DEFCONFIG)

sim: nemu-linux-defconfig
	$(MAKE) -C '$(NEMU_HOME)' NEMU_HOME='$(NEMU_HOME)' -j'$(JOBS)'

check-sim: nemu-linux-defconfig
	@if [ ! -x '$(NEMU_SIM)' ]; then \
	  $(MAKE) -C '$(NEMU_HOME)' NEMU_HOME='$(NEMU_HOME)' -j'$(JOBS)'; \
	else \
	  echo '[Linux] NEMU sim exists: $(NEMU_SIM)'; \
	fi

check-nemu-performance-config: nemu-linux-defconfig
	NEMU_PERFORMANCE_REQUIRED='$(NEMU_PERFORMANCE_REQUIRED)' \
	NEMU_CONFIG='$(NEMU_HOME)/.config' \
	NEMU_AUTOCONF='$(NEMU_HOME)/include/generated/autoconf.h' \
	  bash '$(SCRIPT_DIR)/check-nemu-performance-config.sh'
else
nemu-linux-defconfig:
	@echo '[Linux] skip NEMU defconfig for ARCH=$(ARCH)'

check-nemu-performance-config:
	@echo '[Linux] skip NEMU performance config check for ARCH=$(ARCH)'

sim: linux-defconfig
	$(MAKE) -C '$(NPC_RV64)' -j'$(JOBS)'

check-sim: linux-defconfig
	@if [ ! -x '$(NPC_SIM)' ]; then \
	  $(MAKE) -C '$(NPC_RV64)' -j'$(JOBS)'; \
	else \
	  echo '[Linux] NPC sim exists: $(NPC_SIM)'; \
	fi
endif

linux-image: $(LINUX_IMAGE)
busybox-initramfs: $(BUSYBOX_INITRD)
ubuntu-probe-initramfs: $(UBUNTU_PROBE_INITRD)
ubuntu-shell-initramfs: $(UBUNTU_SHELL_INITRD)
ubuntu-rootfs-image: $(UBUNTU_ROOTFS_IMAGE)
ubuntu-rootfs-systemd-image ubuntu-rootfs-systemd-overlay:
	UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1 UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
	  bash '$(SCRIPT_DIR)/build-ubuntu-rootfs.sh'

ubuntu-rootfs-check check-ubuntu-rootfs: $(UBUNTU_ROOTFS_IMAGE)
	UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_IMAGE)' bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'

check-ubuntu-rootfs-systemd: $(UBUNTU_ROOTFS_IMAGE)
	UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_IMAGE)' UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
	  bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'

check-nemu-systemd-guest:
	$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs __check-nemu-systemd-guest

check-nemu-systemd-guest-long:
	$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  NEMU_SYSTEMD_CHECK_LOG_DIR='$(NEMU_SYSTEMD_LONG_CHECK_LOG_DIR)' \
	  NEMU_SYSTEMD_CHECK_MAX_CYCLES='$(NEMU_SYSTEMD_LONG_CHECK_MAX_CYCLES)' \
	  NEMU_SYSTEMD_CHECK_TIMEOUT='$(NEMU_SYSTEMD_LONG_CHECK_TIMEOUT)' \
	  NEMU_SYSTEMD_SOAK_SECONDS='$(NEMU_SYSTEMD_LONG_SOAK_SECONDS)' \
	  NEMU_SYSTEMD_FS_STRESS_MIB='$(NEMU_SYSTEMD_LONG_FS_STRESS_MIB)' \
	  NEMU_SYSTEMD_FS_TREE_FILES='$(NEMU_SYSTEMD_LONG_FS_TREE_FILES)' \
	  NEMU_SYSTEMD_PROCESS_LOOPS='$(NEMU_SYSTEMD_LONG_PROCESS_LOOPS)' \
	  NEMU_SYSTEMD_UART_RX_STRESS_LINES='$(NEMU_SYSTEMD_LONG_UART_RX_STRESS_LINES)' \
	  NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS='$(NEMU_SYSTEMD_LONG_BLOCK_PARALLEL_JOBS)' \
	  NEMU_SYSTEMD_BLOCK_JOB_MIB='$(NEMU_SYSTEMD_LONG_BLOCK_JOB_MIB)' \
	  __check-nemu-systemd-guest

check-nemu-systemd-guest-soak:
	$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  NEMU_SYSTEMD_CHECK_LOG_DIR='$(NEMU_SYSTEMD_SOAK_CHECK_LOG_DIR)' \
	  NEMU_SYSTEMD_CHECK_MAX_CYCLES='$(NEMU_SYSTEMD_SOAK_CHECK_MAX_CYCLES)' \
	  NEMU_SYSTEMD_CHECK_TIMEOUT='$(NEMU_SYSTEMD_SOAK_CHECK_TIMEOUT)' \
	  NEMU_SYSTEMD_SOAK_SECONDS='$(NEMU_SYSTEMD_SOAK_SOAK_SECONDS)' \
	  NEMU_SYSTEMD_FS_STRESS_MIB='$(NEMU_SYSTEMD_SOAK_FS_STRESS_MIB)' \
	  NEMU_SYSTEMD_FS_TREE_FILES='$(NEMU_SYSTEMD_SOAK_FS_TREE_FILES)' \
	  NEMU_SYSTEMD_PROCESS_LOOPS='$(NEMU_SYSTEMD_SOAK_PROCESS_LOOPS)' \
	  NEMU_SYSTEMD_UART_RX_STRESS_LINES='$(NEMU_SYSTEMD_SOAK_UART_RX_STRESS_LINES)' \
	  NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS='$(NEMU_SYSTEMD_SOAK_BLOCK_PARALLEL_JOBS)' \
	  NEMU_SYSTEMD_BLOCK_JOB_MIB='$(NEMU_SYSTEMD_SOAK_BLOCK_JOB_MIB)' \
	  __check-nemu-systemd-guest

__check-nemu-systemd-guest: $(RUN_DEPS) check-ubuntu-rootfs-systemd check-nemu-performance-config
	LOG_DIR='$(NEMU_SYSTEMD_CHECK_LOG_DIR)' \
	LOG_FILE='$(NEMU_SYSTEMD_CHECK_LOG_DIR)/nemu.log' \
	CONSOLE_LOG='$(NEMU_SYSTEMD_CHECK_LOG_DIR)/console.log' \
	NEMU_SERIAL_FIFO='$(NEMU_SYSTEMD_CHECK_LOG_DIR)/nemu.serial' \
	NEMU_HOME='$(NEMU_HOME)' \
	NEMU_SIM='$(NEMU_SIM)' \
	LINUX_IMAGE='$(LINUX_IMAGE)' \
	RUN_FW='$(RUN_FW)' \
	RUN_DTB='$(RUN_DTB)' \
	RUN_ROOTFS='$(RUN_ROOTFS)' \
	NEXT_ADDR='$(NEXT_ADDR)' \
	DTB_ADDR='$(DTB_ADDR)' \
	MAX_CYCLES='$(NEMU_SYSTEMD_CHECK_MAX_CYCLES)' \
	NEMU_SYSTEMD_CHECK_TIMEOUT='$(NEMU_SYSTEMD_CHECK_TIMEOUT)' \
	NEMU_SYSTEMD_BOOT_TIMEOUT='$(NEMU_SYSTEMD_BOOT_TIMEOUT)' \
	NEMU_SYSTEMD_SOAK_SECONDS='$(NEMU_SYSTEMD_SOAK_SECONDS)' \
	NEMU_SYSTEMD_FS_STRESS_MIB='$(NEMU_SYSTEMD_FS_STRESS_MIB)' \
	NEMU_SYSTEMD_FS_TREE_FILES='$(NEMU_SYSTEMD_FS_TREE_FILES)' \
	NEMU_SYSTEMD_PROCESS_LOOPS='$(NEMU_SYSTEMD_PROCESS_LOOPS)' \
	NEMU_SYSTEMD_UART_RX_STRESS_LINES='$(NEMU_SYSTEMD_UART_RX_STRESS_LINES)' \
	NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS='$(NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS)' \
	NEMU_SYSTEMD_BLOCK_JOB_MIB='$(NEMU_SYSTEMD_BLOCK_JOB_MIB)' \
	NEMU_SYSTEMD_INPUT_DELAY='$(NEMU_SYSTEMD_INPUT_DELAY)' \
	  bash '$(SCRIPT_DIR)/check-nemu-systemd-guest.sh'

dtb: $(KERNEL_DTB)
initramfs-dtb: $(BUSYBOX_INITRAMFS_DTB)
ubuntu-initramfs-dtb: $(UBUNTU_PROBE_DTB)
ubuntu-shell-initramfs-dtb: $(UBUNTU_SHELL_DTB)
rootfs-dtb: $(ROOTFS_DTB)
opensbi: $(OPENSBI_FW)
opensbi-busybox: $(OPENSBI_BUSYBOX_FW)
opensbi-ubuntu-probe: $(OPENSBI_UBUNTU_PROBE_FW)
opensbi-ubuntu-shell: $(OPENSBI_UBUNTU_SHELL_FW)
opensbi-rootfs: $(OPENSBI_ROOTFS_FW)

$(LINUX_IMAGE):
	bash '$(SCRIPT_DIR)/build-linux.sh'

$(BUSYBOX_INITRD):
	bash '$(SCRIPT_DIR)/build-busybox-initramfs.sh'

$(UBUNTU_PROBE_INITRD):
	UBUNTU_INIT_MODE=syscall UBUNTU_INITRAMFS_PROFILE=probe \
	  UBUNTU_INITRD_IMAGE='$(UBUNTU_PROBE_INITRD)' \
	  bash '$(SCRIPT_DIR)/build-ubuntu-base-initramfs.sh'

$(UBUNTU_SHELL_INITRD):
	UBUNTU_INIT_MODE=shell UBUNTU_INITRAMFS_PROFILE=full \
	  UBUNTU_INITRD_IMAGE='$(UBUNTU_SHELL_INITRD)' \
	  bash '$(SCRIPT_DIR)/build-ubuntu-base-initramfs.sh'

$(UBUNTU_ROOTFS_IMAGE):
	bash '$(SCRIPT_DIR)/build-ubuntu-rootfs.sh'

$(BUILD_DIR):
	mkdir -p '$@'

$(BUILD_DIR)/generated:
	mkdir -p '$@'

$(KERNEL_DTB): $(GEN_DTS) $(PLATFORM_CONFIG) | $(BUILD_DIR) $(BUILD_DIR)/generated
	$(PYTHON) '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode kernel \
	  --bootargs-extra '$(BOOTARGS_EXTRA)' \
	  --output '$(BUILD_DIR)/generated/npc-rv64.dts'
	$(DTC) -I dts -O dtb -o '$@' '$(BUILD_DIR)/generated/npc-rv64.dts'

$(BUSYBOX_INITRAMFS_DTB): $(GEN_DTS) $(PLATFORM_CONFIG) $(BUSYBOX_INITRD) | $(BUILD_DIR) $(BUILD_DIR)/generated
	$(PYTHON) '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode initramfs \
	  --bootargs-extra '$(BOOTARGS_EXTRA)' \
	  --initrd-image '$(BUSYBOX_INITRD)' \
	  --output '$(BUILD_DIR)/generated/npc-rv64-initramfs.dts'
	$(DTC) -I dts -O dtb -o '$@' '$(BUILD_DIR)/generated/npc-rv64-initramfs.dts'

$(UBUNTU_PROBE_DTB): $(GEN_DTS) $(PLATFORM_CONFIG) $(UBUNTU_PROBE_INITRD) | $(BUILD_DIR) $(BUILD_DIR)/generated
	$(PYTHON) '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode initramfs \
	  --bootargs-key ubuntu_initramfs \
	  --bootargs-extra '$(BOOTARGS_EXTRA)' \
	  --initrd-image '$(UBUNTU_PROBE_INITRD)' \
	  --memory-size 0x08000000 \
	  --output '$(BUILD_DIR)/generated/npc-rv64-ubuntu-initramfs.dts'
	$(DTC) -I dts -O dtb -o '$@' '$(BUILD_DIR)/generated/npc-rv64-ubuntu-initramfs.dts'

$(UBUNTU_SHELL_DTB): $(GEN_DTS) $(PLATFORM_CONFIG) $(UBUNTU_SHELL_INITRD) | $(BUILD_DIR) $(BUILD_DIR)/generated
	$(PYTHON) '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode initramfs \
	  --bootargs-key ubuntu_initramfs \
	  --bootargs-extra '$(BOOTARGS_EXTRA)' \
	  --initrd-image '$(UBUNTU_SHELL_INITRD)' \
	  --memory-size 0x10000000 \
	  --output '$(BUILD_DIR)/generated/npc-rv64-ubuntu-shell-initramfs.dts'
	$(DTC) -I dts -O dtb -o '$@' '$(BUILD_DIR)/generated/npc-rv64-ubuntu-shell-initramfs.dts'

$(NPC_ROOTFS_DTB): $(GEN_DTS) $(PLATFORM_CONFIG) | $(BUILD_DIR) $(BUILD_DIR)/generated
	$(PYTHON) '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode rootfs \
	  --bootargs-extra '$(BOOTARGS_EXTRA)' \
	  --output '$(BUILD_DIR)/generated/npc-rv64-rootfs.dts'
	$(DTC) -I dts -O dtb -o '$@' '$(BUILD_DIR)/generated/npc-rv64-rootfs.dts'

$(NEMU_ROOTFS_DTB): $(GEN_DTS) $(PLATFORM_CONFIG) | $(BUILD_DIR) $(BUILD_DIR)/generated
	$(PYTHON) '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode rootfs \
	  --reset-syscon \
	  --virtio-rng \
	  --goldfish-rtc \
	  --bootargs-extra '$(BOOTARGS_EXTRA)' \
	  --output '$(BUILD_DIR)/generated/npc-rv64-nemu-rootfs.dts'
	$(DTC) -I dts -O dtb -o '$@' '$(BUILD_DIR)/generated/npc-rv64-nemu-rootfs.dts'

$(OPENSBI_FW): $(KERNEL_DTB)
	OPENSBI_DTB='$(KERNEL_DTB)' OPENSBI_BUILD_DIR='$(OPENSBI_BUILD_DIR)' \
	  OPENSBI_DISABLE_PMU='$(OPENSBI_DISABLE_PMU)' \
	  bash '$(SCRIPT_DIR)/build-opensbi.sh'

$(OPENSBI_BUSYBOX_FW): $(BUSYBOX_INITRAMFS_DTB)
	OPENSBI_DTB='$(BUSYBOX_INITRAMFS_DTB)' OPENSBI_BUILD_DIR='$(OPENSBI_BUSYBOX_BUILD_DIR)' \
	  OPENSBI_DISABLE_PMU='$(OPENSBI_DISABLE_PMU)' \
	  bash '$(SCRIPT_DIR)/build-opensbi.sh'

$(OPENSBI_UBUNTU_PROBE_FW): $(UBUNTU_PROBE_DTB)
	OPENSBI_DTB='$(UBUNTU_PROBE_DTB)' OPENSBI_BUILD_DIR='$(OPENSBI_UBUNTU_PROBE_BUILD_DIR)' \
	  OPENSBI_DISABLE_PMU='$(OPENSBI_DISABLE_PMU)' \
	  bash '$(SCRIPT_DIR)/build-opensbi.sh'

$(OPENSBI_UBUNTU_SHELL_FW): $(UBUNTU_SHELL_DTB)
	OPENSBI_DTB='$(UBUNTU_SHELL_DTB)' OPENSBI_BUILD_DIR='$(OPENSBI_UBUNTU_SHELL_BUILD_DIR)' \
	  OPENSBI_DISABLE_PMU='$(OPENSBI_DISABLE_PMU)' \
	  bash '$(SCRIPT_DIR)/build-opensbi.sh'

$(OPENSBI_ROOTFS_FW): $(ROOTFS_DTB)
	OPENSBI_DTB='$(ROOTFS_DTB)' OPENSBI_BUILD_DIR='$(OPENSBI_ROOTFS_BUILD_DIR)' \
	  OPENSBI_DISABLE_PMU='$(OPENSBI_DISABLE_PMU)' \
	  bash '$(SCRIPT_DIR)/build-opensbi.sh'

qemu: qemu-ubuntu-shell

qemu-build:
	bash '$(SCRIPT_DIR)/build-qemu.sh'

qemu-ubuntu-probe:
	bash '$(SCRIPT_DIR)/run-qemu-ubuntu-initramfs.sh'

qemu-ubuntu-shell:
	UBUNTU_INITRD_IMAGE='$(UBUNTU_SHELL_INITRD)' \
	LOG_FILE='$(ENV_ROOT)/logs/qemu/ubuntu-shell-initramfs.log' \
	QEMU_MEMORY=256M QEMU_GUEST_EXPECT='$(UBUNTU_SHELL_EXPECT)' \
	bash '$(SCRIPT_DIR)/run-qemu-ubuntu-initramfs.sh'

tools-build:
	$(MAKE) -C '$(TOOLS_DIR)' all

boot-tools:
	$(MAKE) -C '$(TOOLS_DIR)' boot-tools

tools-smoke: check-sim
	$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' $(TOOL_SMOKES)

$(TOOL_SMOKES): check-sim
	$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' $@

smoke-dtb: check-sim
	$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' $@

smoke-opensbi smoke-opensbi-sbi: check-sim opensbi
	$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' $@

smoke-virtio-blk: check-sim ubuntu-rootfs-image
	$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' VIRTIO_BLK_IMAGE='$(UBUNTU_ROOTFS_IMAGE)' $@

tools-clean:
	$(MAKE) -C '$(TOOLS_DIR)' clean

paths:
	@printf 'ARCH=%s\n' '$(ARCH)'
	@printf 'BOOT=%s\n' '$(BOOT)'
	@printf 'MAX_CYCLES=%s\n' '$(MAX_CYCLES)'
	@printf 'OPENSBI_PROFILE=%s\n' '$(OPENSBI_PROFILE)'
	@printf 'OPENSBI_DISABLE_PMU=%s\n' '$(OPENSBI_DISABLE_PMU)'
	@printf 'RUN_SIM=%s\n' '$(RUN_SIM)'
	@printf 'NPC_SIM=%s\n' '$(NPC_SIM)'
	@printf 'NEMU_SIM=%s\n' '$(NEMU_SIM)'
	@printf 'LINUX_IMAGE=%s\n' '$(LINUX_IMAGE)'
	@printf 'RUN_FW=%s\n' '$(RUN_FW)'
	@printf 'RUN_DTB=%s\n' '$(RUN_DTB)'
	@printf 'RUN_INITRD=%s\n' '$(RUN_INITRD)'
	@printf 'RUN_ROOTFS=%s\n' '$(RUN_ROOTFS)'
	@printf 'LOG_DIR=%s\n' '$(LOG_DIR)'

check:
	@test -x '$(RUN_SIM)' || { echo 'missing simulator: $(RUN_SIM)'; exit 1; }
	@test -f '$(LINUX_IMAGE)' || { echo 'missing LINUX_IMAGE: $(LINUX_IMAGE)'; exit 1; }
	@test -f '$(RUN_FW)' || { echo 'missing firmware: $(RUN_FW)'; exit 1; }
	@test -f '$(RUN_DTB)' || { echo 'missing dtb: $(RUN_DTB)'; exit 1; }
	@if [ -n '$(RUN_INITRD)' ]; then test -f '$(RUN_INITRD)' || { echo 'missing initrd: $(RUN_INITRD)'; exit 1; }; fi
	@if [ -n '$(RUN_ROOTFS)' ]; then test -f '$(RUN_ROOTFS)' || { echo 'missing rootfs: $(RUN_ROOTFS)'; exit 1; }; fi
	@if [ -n '$(RUN_ROOTFS)' ]; then UBUNTU_ROOTFS_IMAGE='$(RUN_ROOTFS)' bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'; fi
	@echo 'artifacts: OK'

clean:
	rm -rf '$(BUILD_DIR)'

clean-logs:
	rm -rf '$(LOG_ROOT)'
