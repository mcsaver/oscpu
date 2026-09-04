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
# 工作区根：通用工具(tool/kconfig 等)定位锚点，独立于 nemu
YSYX_HOME ?= $(REPO_ROOT)
ARCH_SPLIT := $(subst -, ,$(ARCH))
LINUX_ISA := $(word 1,$(ARCH_SPLIT))
LINUX_PLATFORM := $(word 2,$(ARCH_SPLIT))
PLATFORM_MK := $(LINUX_HOME)/scripts/platform/$(LINUX_PLATFORM).mk
ifeq ($(wildcard $(PLATFORM_MK)),)
$(error unsupported Linux platform '$(LINUX_PLATFORM)' from ARCH=$(ARCH); missing $(PLATFORM_MK))
endif
include $(PLATFORM_MK)

NPC_RV64 := $(REPO_ROOT)/npc/rv64
NPC_OOO_CSR_QUEUE_HEAD ?= 0
NPC_OOO_TERMINAL_HOLDER_ASSERT ?= 0
NPC_SIM_BUILD_DIR := $(NPC_RV64)/build$(if $(filter 1 y,$(NPC_OOO_CSR_QUEUE_HEAD)),-csrqh,)
NPC_SIM ?= $(NPC_SIM_BUILD_DIR)/NpcSimTop
NPC_FAST_SIM ?= 1
NPC_FAST_NATIVE ?= 1
NPC_FAST_CXX_AUTO := $(shell \
	for cxx in /usr/bin/clang++ clang++; do \
	  if command -v "$$cxx" >/dev/null 2>&1; then \
	    out="$${TMPDIR:-/tmp}/npc-fast-cxx-test-$$$$"; \
	    if printf 'int main() { return 0; }\n' | "$$cxx" -x c++ - -o "$$out" >/dev/null 2>&1; then \
	      rm -f "$$out"; \
	      echo "$$cxx"; \
	      break; \
	    fi; \
	    rm -f "$$out"; \
	  fi; \
	done)
NPC_SIM_CXX ?= $(if $(filter command line environment override,$(origin CXX)),$(CXX),$(NPC_FAST_CXX_AUTO))
NPC_SIM_OPT_FAST ?= $(if $(filter undefined,$(origin VERILATOR_OPT_FAST)),$(if $(filter 1,$(NPC_FAST_SIM)),-O3$(if $(filter 1,$(NPC_FAST_NATIVE)), -march=native,),),$(VERILATOR_OPT_FAST))
NPC_SIM_OPT_GLOBAL ?= $(if $(filter undefined,$(origin VERILATOR_OPT_GLOBAL)),$(NPC_SIM_OPT_FAST),$(VERILATOR_OPT_GLOBAL))
NPC_SIM_MAKE_ARGS :=
ifeq ($(NPC_FAST_SIM),1)
NPC_SIM_MAKE_ARGS += $(if $(strip $(NPC_SIM_CXX)),CXX='$(NPC_SIM_CXX)' LINK='$(NPC_SIM_CXX)',)
NPC_SIM_MAKE_ARGS += $(if $(strip $(NPC_SIM_OPT_FAST)),VERILATOR_OPT_FAST='$(NPC_SIM_OPT_FAST)',)
NPC_SIM_MAKE_ARGS += $(if $(strip $(NPC_SIM_OPT_GLOBAL)),VERILATOR_OPT_GLOBAL='$(NPC_SIM_OPT_GLOBAL)',)
endif
NPC_SIM_MAKE_ARGS += OOO_CSR_QUEUE_HEAD='$(NPC_OOO_CSR_QUEUE_HEAD)'
NPC_SIM_MAKE_ARGS += OOO_TERMINAL_HOLDER_ASSERT='$(NPC_OOO_TERMINAL_HOLDER_ASSERT)'
NEMU_HOME := $(REPO_ROOT)/nemu
NEMU_BUILD_DIR ?= $(NEMU_HOME)/build
NEMU_CONFIG_DIR ?= $(NEMU_HOME)
NEMU_SIM ?= $(NEMU_BUILD_DIR)/riscv64-nemu-interpreter
NEMU_DEFCONFIG ?= riscv64-linux_defconfig
NEMU_SAFE_FLOCK := $(NEMU_HOME)/scripts/safe-flock.py

ENV_ROOT ?= $(LINUX_HOME)/env
NEMU_GUI_PLATFORM_ROOT ?= $(ENV_ROOT)/platforms/nemu
NEMU_GUI_BUILD_DIR ?= $(NEMU_HOME)/build/riscv64-linux-gui
NEMU_GUI_CONFIG_DIR ?= $(NEMU_HOME)/build/config-riscv64-linux-gui
NEMU_GUI_SIM ?= $(NEMU_GUI_BUILD_DIR)/riscv64-nemu-interpreter
NEMU_GUI_FRONT_BUILD_DIR ?= $(LINUX_HOME)/build/riscv64-nemu-gui
NEMU_GUI_KERNEL_BUILD_DIR ?= $(NEMU_GUI_PLATFORM_ROOT)/build/linux-gui
NEMU_GUI_OPENSBI_BUILD_ROOT ?= $(NEMU_GUI_PLATFORM_ROOT)/build/opensbi-gui
NEMU_GUI_LOG_DIR ?= $(NEMU_GUI_PLATFORM_ROOT)/logs/linux-front/riscv64-nemu-ubuntu-gui
NEMU_GUI_ROOTFS_OVERLAY ?= $(NEMU_GUI_LOG_DIR)/rootfs-overlay.raw
NEMU_GUI_SCREENSHOT ?= $(NEMU_GUI_LOG_DIR)/tty1.png
NEMU_GUI_CHECK_LOG_DIR ?= $(NEMU_GUI_PLATFORM_ROOT)/logs/linux-front/riscv64-nemu-ubuntu-gui-check
NEMU_GUI_CHECK_ROOTFS_OVERLAY ?= $(NEMU_GUI_CHECK_LOG_DIR)/rootfs-overlay.raw
NEMU_GUI_CHECK_SCREENSHOT ?= $(NEMU_GUI_CHECK_LOG_DIR)/tty1.png
NEMU_GUI_ROOTFS_WORK ?= $(NEMU_GUI_PLATFORM_ROOT)/images/ubuntu2204/work-gui
NEMU_GUI_CHECK_TIMEOUT ?= 1800
NEMU_GUI_BOOT_TIMEOUT ?= 900
NEMU_GUI_POWEROFF_TIMEOUT ?= 180
NEMU_GUI_MAX_CYCLES ?= 50000000000
NEMU_RETIRE_BUILD_DIR ?= $(NEMU_HOME)/build/riscv64-retirement-smoke
NEMU_RETIRE_CONFIG_DIR ?= $(NEMU_HOME)/build/config-riscv64-retirement-smoke
NEMU_RETIRE_SIM ?= $(NEMU_RETIRE_BUILD_DIR)/riscv64-nemu-interpreter
PLATFORM_ROOT ?= $(ENV_ROOT)/platforms/$(LINUX_PLATFORM)
PLATFORM_BUILD_ROOT ?= $(PLATFORM_ROOT)/build
PLATFORM_IMAGE_ROOT ?= $(PLATFORM_ROOT)/images
PLATFORM_LOG_ROOT ?= $(PLATFORM_ROOT)/logs
LINUX_BUILD_DIR ?= $(PLATFORM_BUILD_ROOT)/linux
LINUX_FEATURE_PROFILE ?= headless
LINUX_FEATURE_PROFILE_STAMP ?= $(LINUX_BUILD_DIR)/.ysyx-feature-profile
LINUX_ROOT ?= $(ENV_ROOT)/src/linux
LINUX_REF ?= v6.6
LINUX_PATCH ?= $(LINUX_HOME)/patches/linux-skip-riscv-unaligned-benchmark.patch
LINUX_DEFAULT_CROSS_COMPILE := $(if $(shell test -x '$(ENV_ROOT)/toolchains/riscv64-linux-gnu/bin/riscv64-linux-gnu-gcc' && printf 1),$(ENV_ROOT)/toolchains/riscv64-linux-gnu/bin/riscv64-linux-gnu-,riscv64-linux-gnu-)
LINUX_CROSS_COMPILE := $(if $(strip $(CROSS_COMPILE)),$(CROSS_COMPILE),$(LINUX_DEFAULT_CROSS_COMPILE))
BUILD_DIR ?= $(LINUX_HOME)/build/$(ARCH)
SCRIPT_DIR := $(LINUX_HOME)/scripts
TOOLS_DIR := $(LINUX_HOME)/tools
LINUX_SOURCE_INPUTS := $(SCRIPT_DIR)/build-linux.sh $(wildcard $(LINUX_PATCH))
LINUX_CONFIG ?= $(LINUX_HOME)/configs/rv64_linux_defconfig
TRACE_CONFIG ?= $(LINUX_HOME)/configs/rv64_trace_defconfig
# 平台 yml 按 ARCH 自动选择(npc-rv64.yml / nemu-rv64.yml),共享 SoC 契约在
# common-rv64.yml 由 gen_dts.py 经 base: 引用深合并;common 变更也要触发 DTB 重建。
PLATFORM_CONFIG ?= $(LINUX_HOME)/platform/$(LINUX_PLATFORM)-rv64.yml
PLATFORM_CONFIG_COMMON ?= $(LINUX_HOME)/platform/common-rv64.yml
GEN_DTS ?= $(LINUX_HOME)/platform/gen_dts.py
PYTHON ?= $(if $(wildcard $(ENV_ROOT)/tools/python/bin/python3),$(ENV_ROOT)/tools/python/bin/python3,python3)
DTC ?= dtc
JOBS ?= $(shell nproc)

KCONFIG_PATH := $(YSYX_HOME)/tool/kconfig
FIXDEP_PATH := $(YSYX_HOME)/tool/fixdep
CONF := $(KCONFIG_PATH)/build/conf
FIXDEP := $(FIXDEP_PATH)/build/fixdep
KCONFIG_TOOL_INPUTS := $(wildcard $(KCONFIG_PATH)/*.c $(KCONFIG_PATH)/*.h \
  $(KCONFIG_PATH)/*.l $(KCONFIG_PATH)/*.y $(KCONFIG_PATH)/lxdialog/*) \
  $(KCONFIG_PATH)/Makefile $(YSYX_HOME)/scripts/build.mk
FIXDEP_TOOL_INPUTS := $(wildcard $(FIXDEP_PATH)/*.c $(FIXDEP_PATH)/*.h) \
  $(FIXDEP_PATH)/Makefile $(YSYX_HOME)/scripts/build.mk
LINUX_CONFIG_STAMP := $(NPC_RV64)/.linux-defconfig.stamp
TRACE_CONFIG_STAMP := $(NPC_RV64)/.linux-trace-defconfig.stamp
NPC_KCONFIG_LOCK := $(NPC_RV64)/.linux-kconfig.lock
FORCE_CONFIG ?= 0

NEXT_ADDR ?= 0x80200000
DTB_ADDR ?= 0x82200000
INITRD_ADDR ?= 0x84000000

# NEMU 的 --max-insts=0 表示无限预算，更接近“启动系统后持续运行”的入口语义。
DEFAULT_MAX_CYCLES := $(PLATFORM_DEFAULT_MAX_CYCLES)
MAX_CYCLES ?= $(DEFAULT_MAX_CYCLES)
PROGRESS ?= 50000000
LOG_ROOT ?= $(PLATFORM_LOG_ROOT)/linux-front
EXTRA_ARGS ?=
BOOTARGS_EXTRA ?=
NEMU_ROOTFS_BOOTARGS_EXTRA ?= console=tty0
NEMU_DISPLAY ?= 0
NEMU_VIRTIO_INPUT ?= $(NEMU_DISPLAY)
NEMU_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-nemu-systemd-guest-check
NEMU_SYSTEMD_ROOTFS_OVERLAY ?= $(NEMU_SYSTEMD_CHECK_LOG_DIR)/rootfs-overlay.raw
NEMU_SYSTEMD_NET_TAP ?=
NEMU_SYSTEMD_NET_BACKEND ?= $(if $(strip $(NEMU_SYSTEMD_NET_TAP)),tap,hostless)
NEMU_SYSTEMD_TAP_IPV4_CIDR ?=
NEMU_SYSTEMD_TAP_GATEWAY ?=
NEMU_SYSTEMD_TAP_DNS ?=
NEMU_SYSTEMD_TAP_PING_TARGET ?=
NEMU_SYSTEMD_TAP_HTTP_URL ?=
NEMU_SYSTEMD_TAP_REQUIRE_EXTERNAL ?= 0
NEMU_SYSTEMD_TAP_REQUIRE_PACKETS ?= 0
NEMU_TAP_IFNAME ?= $(if $(strip $(NEMU_SYSTEMD_NET_TAP)),$(NEMU_SYSTEMD_NET_TAP),nemu-tap0)
NEMU_TAP_OWNER ?=
NEMU_TAP_HOST_IPV4_CIDR ?= 10.0.3.1/24
NEMU_TAP_GUEST_IPV4_CIDR ?= 10.0.3.15/24
NEMU_TAP_GATEWAY ?= 10.0.3.1
NEMU_TAP_DNS ?= 1.1.1.1
NEMU_TAP_NAT_SOURCE_CIDR ?= 10.0.3.0/24
NEMU_TAP_UPLINK_IFACE ?=
NEMU_TAP_ENABLE_NAT ?= 0
NEMU_TAP_REQUIRE_READY ?= 0
NEMU_TAP_PING_TARGET ?=
NEMU_TAP_HTTP_URL ?=
NEMU_TAP_REQUIRE_EXTERNAL ?= 0
NEMU_TAP_REQUIRE_PACKETS ?= 0
NEMU_SYSTEMD_CHECK_MAX_CYCLES ?= 50000000000
NEMU_SYSTEMD_CHECK_TIMEOUT ?= 1800
NEMU_SYSTEMD_FULL_CHECK_MAX_CYCLES ?= 80000000000
NEMU_SYSTEMD_FULL_CHECK_TIMEOUT ?= 7200
NEMU_SYSTEMD_BOOT_TIMEOUT ?= 900
NEMU_SYSTEMD_SOAK_SECONDS ?= 20
NEMU_SYSTEMD_FS_STRESS_MIB ?= 4
NEMU_SYSTEMD_FS_TREE_FILES ?= 64
NEMU_SYSTEMD_PROCESS_LOOPS ?= 16
NEMU_SYSTEMD_INPUT_DELAY ?= 0
NEMU_SYSTEMD_INPUT_CHUNK_BYTES ?= 8
NEMU_SYSTEMD_INPUT_CHUNK_DELAY ?= 0
NEMU_SYSTEMD_APT_INSTALL_DIAG ?= 0
NEMU_SYSTEMD_APT_INSTALL_ACTUAL ?= 0
NEMU_SYSTEMD_APT_INSTALL_DIAG_TIMEOUT ?= 300
NEMU_SYSTEMD_APT_REMOVE_DIAG_TIMEOUT ?= 600
NEMU_SYSTEMD_CRON_JOB_TIMEOUT ?= 180
NEMU_SYSTEMD_ANACRON_TIMEOUT ?= 120
NEMU_SYSTEMD_CALENDAR_TIMER_TIMEOUT ?= 90
NEMU_SYSTEMD_LOCALE_GEN_TIMEOUT ?= 600
NEMU_SYSTEMD_TIMEDATECTL_TIMEOUT ?= 120
NEMU_SYSTEMD_NETWORKD_DHCP_TIMEOUT ?= 90
NEMU_SYSTEMD_NETWORKD_WAIT_ONLINE_TIMEOUT ?= 90
NEMU_SYSTEMD_TIMESYNCD_NTP_TIMEOUT ?= 120
NEMU_SYSTEMD_RESOLVED_DNS_TIMEOUT ?= 90
NEMU_SYSTEMD_UART_RX_STRESS_LINES ?= 512
NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS ?= 4
NEMU_SYSTEMD_BLOCK_JOB_MIB ?= 1
NEMU_SYSTEMD_MIN_MEMTOTAL_KB ?= 900000
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
NEMU_SYSTEMD_INTERACTIVE_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-nemu-systemd-guest-interactive-check
NEMU_SYSTEMD_FULL_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-nemu-systemd-guest-full-check
NEMU_SYSTEMD_FULL_SOAK_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-nemu-systemd-guest-full-soak-check
NEMU_PYTHON_INT_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-nemu-python-int-preflight
NEMU_PYTHON_INT_ROOTFS_OVERLAY ?= $(NEMU_PYTHON_INT_CHECK_LOG_DIR)/rootfs-overlay.raw
NEMU_PYTHON_INT_CHECK_MAX_CYCLES ?= 20000000000
NEMU_PYTHON_INT_CHECK_TIMEOUT ?= 1200
NEMU_PYTHON_INT_BOOT_TIMEOUT ?= 900
NEMU_PYTHON_INT_LOOPS ?= 5
NEMU_PYTHON_INT_STAGE_MODE ?= focused
NEMU_PYTHON_INT_PROBE_MODE ?= args
NEMU_PYTHON_INT_STAGE_TIMEOUT ?= 120
NEMU_PYTHON_INT_STAGE_PREWARM ?= auto
NEMU_PYTHON_INT_TAGS ?=
NEMU_PYTHON_INT_POWEROFF ?= 1
NEMU_SYSTEMD_ROOTFS_FLAVOR ?= systemd-minimal
NEMU_SYSTEMD_ROOTFS_CHECK_TARGET = $(if $(filter full,$(NEMU_SYSTEMD_ROOTFS_FLAVOR)),check-ubuntu-rootfs-full,$(if $(filter interactive,$(NEMU_SYSTEMD_ROOTFS_FLAVOR)),check-ubuntu-rootfs-interactive,check-ubuntu-rootfs-systemd))
NEMU_REBOOT_PERSIST_LOG_DIR ?= $(LOG_ROOT)/riscv64-nemu-reboot-persistence-check
NEMU_REBOOT_PERSIST_ROOTFS_OVERLAY ?= $(NEMU_REBOOT_PERSIST_LOG_DIR)/rootfs-overlay.raw
NEMU_REBOOT_PERSIST_TIMEOUT ?= 2400
NEMU_REBOOT_PERSIST_BOOT_TIMEOUT ?= 900
NEMU_REBOOT_PERSIST_POWEROFF_TIMEOUT ?= 300
NEMU_REBOOT_PERSIST_FIFO_TIMEOUT ?= 60
NEMU_REBOOT_PERSIST_MAX_INSTS ?= 50000000000
NEMU_REBOOT_PERSIST_INPUT_CHUNK_BYTES ?= 8
NEMU_REBOOT_PERSIST_INPUT_CHUNK_DELAY ?= 0.002
NEMU_REBOOT_PERSIST_INPUT_LINE_DELAY ?= 0.05
NEMU_SYSTEMD_SOAK_CHECK_MAX_CYCLES ?= 300000000000
NEMU_SYSTEMD_SOAK_CHECK_TIMEOUT ?= 7200
NEMU_SYSTEMD_SOAK_SOAK_SECONDS ?= 300
NEMU_SYSTEMD_SOAK_FS_STRESS_MIB ?= 32
NEMU_SYSTEMD_SOAK_FS_TREE_FILES ?= 256
NEMU_SYSTEMD_SOAK_PROCESS_LOOPS ?= 128
NEMU_SYSTEMD_SOAK_UART_RX_STRESS_LINES ?= 1024
NEMU_SYSTEMD_SOAK_BLOCK_PARALLEL_JOBS ?= 4
NEMU_SYSTEMD_SOAK_BLOCK_JOB_MIB ?= 4
NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check
NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000
NPC_SYSTEMD_HOST_TIMEOUT ?= 10800
NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\#
NPC_SYSTEMD_UART_WAIT ?= $(NPC_SYSTEMD_PROMPT)
NPC_SYSTEMD_UART_TRACE_LIMIT ?= 128
NPC_SYSTEMD_UART_CYCLE_GAP ?= 10000
NPC_SYSTEMD_GUEST_COMMAND_MODE ?= autocheck
NPC_SYSTEMD_PROGRESS ?= 0
NPC_SYSTEMD_REQUIRE_PROMPT ?= 1
NPC_SYSTEMD_STRICT_CHECK ?= 0
NPC_SYSTEMD_GUEST_POWEROFF ?= 0
NPC_SYSTEMD_ROOTFS_WORK_IMAGE ?=
NPC_SYSTEMD_ROOTFS_EXPECTED_TEMPLATE_SHA256 ?=
NPC_SYSTEMD_TRANSACTION_EVIDENCE ?= $(NPC_SYSTEMD_CHECK_LOG_DIR)/systemd-transaction-evidence.json
UBUNTU_ROOTFS_NPC_CONSOLE_SHELL ?= $(if $(filter npc,$(LINUX_PLATFORM)),1,0)
UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL ?= $(UBUNTU_ROOTFS_NPC_CONSOLE_SHELL)
UBUNTU_ROOTFS_NPC_TTY_READER ?= 0
UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER ?= $(UBUNTU_ROOTFS_NPC_TTY_READER)
UBUNTU_ROOTFS_NPC_TTY_READER_MODE ?= line
UBUNTU_ROOTFS_NPC_STRICT_AUTORUN ?= 0
UBUNTU_ROOTFS_REQUIRE_NPC_STRICT_AUTORUN ?= $(UBUNTU_ROOTFS_NPC_STRICT_AUTORUN)
UBUNTU_ROOTFS_NPC_LOGIN_MARKER ?= 0
UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER ?= $(UBUNTU_ROOTFS_NPC_LOGIN_MARKER)
UBUNTU_ROOTFS_NPC_GENERATOR_TRACE ?= 0
UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE ?= $(UBUNTU_ROOTFS_NPC_GENERATOR_TRACE)
UBUNTU_ROOTFS_NPC_GENERATOR_SKIP ?=
UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP ?= $(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP)
UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE ?= shell
UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE ?= $(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE)
UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE ?= exec
UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE ?= $(UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE)
UBUNTU_ROOTFS_NEMU_LOGIN_MARKER ?= $(if $(filter nemu,$(LINUX_PLATFORM)),1,0)
UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER ?= $(UBUNTU_ROOTFS_NEMU_LOGIN_MARKER)
UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE ?= 0
UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE ?= $(UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE)
UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS ?= $(UBUNTU_ROOTFS_NPC_CONSOLE_SHELL)
UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS ?= $(if $(filter 1,$(UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS)),disabled,enabled)
NPC_ROOTFS_INIT ?= $(if $(filter 1,$(UBUNTU_ROOTFS_NPC_CONSOLE_SHELL)),/usr/local/sbin/ysyx-npc-systemd-wrapper,/lib/systemd/systemd)
NPC_ROOTFS_BOOTARGS ?= console=ttyS0,115200n8 earlycon=sbi loglevel=8 ignore_loglevel pty.legacy_count=0 root=/dev/vda rw init=$(NPC_ROOTFS_INIT)
NEMU_PERFORMANCE_REQUIRED ?= 1
NEMU_MACHINE_INFO_FILE ?= $(BUILD_DIR)/nemu-machine-info.txt
NEMU_MACHINE_INFO_LOG ?= $(BUILD_DIR)/nemu-machine-info.log
NEMU_ROOTFS_MACHINE_INFO_FILE ?= $(BUILD_DIR)/nemu-rootfs-machine-info.txt
NEMU_ROOTFS_MACHINE_INFO_LOG ?= $(BUILD_DIR)/nemu-rootfs-machine-info.log
NEMU_ROOTFS_OVERLAY_MACHINE_INFO_FILE ?= $(BUILD_DIR)/nemu-rootfs-overlay-machine-info.txt
NEMU_ROOTFS_OVERLAY_MACHINE_INFO_LOG ?= $(BUILD_DIR)/nemu-rootfs-overlay-machine-info.log
NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY ?= $(BUILD_DIR)/nemu-rootfs-overlay-machine-info.raw
NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY_STAT ?= $(BUILD_DIR)/nemu-rootfs-overlay-machine-info-overlay.stat
NEMU_MONITOR_CMD_SMOKE_LOG ?= $(BUILD_DIR)/nemu-monitor-cmd-smoke.log
NEMU_MONITOR_CMD_SMOKE_NEMU_LOG ?= $(BUILD_DIR)/nemu-monitor-cmd-smoke-nemu.log
NEMU_MONITOR_CMD_SMOKE_CMD ?= info r
NEMU_QMP_SMOKE_LOG ?= $(BUILD_DIR)/nemu-qmp-smoke.log
NEMU_QMP_SMOKE_NEMU_LOG ?= $(BUILD_DIR)/nemu-qmp-smoke-nemu.log
NEMU_QMP_SMOKE_CONT_NEMU_LOG ?= $(BUILD_DIR)/nemu-qmp-smoke-cont-nemu.log
NEMU_QMP_SMOKE_BLOCK_NEMU_LOG ?= $(BUILD_DIR)/nemu-qmp-smoke-block-nemu.log
NEMU_QMP_SMOKE_RUNTIME_NEMU_LOG ?= $(BUILD_DIR)/nemu-qmp-smoke-runtime-nemu.log
NEMU_QMP_SMOKE_DISCONNECT_NEMU_LOG ?= $(BUILD_DIR)/nemu-qmp-smoke-disconnect-nemu.log
NEMU_QMP_SMOKE_SYSTEM_POWERDOWN_NEMU_LOG ?= $(BUILD_DIR)/nemu-qmp-smoke-system-powerdown-nemu.log
NEMU_QMP_SMOKE_GUEST_SHUTDOWN_NEMU_LOG ?= $(BUILD_DIR)/nemu-qmp-smoke-guest-shutdown-nemu.log
NEMU_QMP_SMOKE_DISCONNECT_IMAGE ?= $(BUILD_DIR)/nemu-qmp-smoke-disconnect.bin
NEMU_QMP_SMOKE_OVERLAY ?= $(BUILD_DIR)/nemu-qmp-smoke-overlay.raw
NEMU_QMP_SMOKE_RUNTIME_OVERLAY ?= $(BUILD_DIR)/nemu-qmp-smoke-runtime-overlay.raw
NEMU_QMP_SMOKE_SYSTEM_POWERDOWN_IMAGE ?= $(BUILD_DIR)/nemu-qmp-smoke-system-powerdown.bin
NEMU_QMP_SMOKE_GUEST_SHUTDOWN_IMAGE ?= $(BUILD_DIR)/nemu-qmp-smoke-guest-shutdown.bin
NEMU_QMP_SMOKE_RUNTIME_MAX_INSTS ?= 1000000000
NEMU_GDBSTUB_SMOKE_LOG ?= $(BUILD_DIR)/nemu-gdbstub-smoke.log
NEMU_GDBSTUB_SMOKE_NEMU_LOG ?= $(BUILD_DIR)/nemu-gdbstub-smoke-nemu.log
NEMU_GDBSTUB_SMOKE_CMD ?= info r

LINUX_IMAGE ?= $(LINUX_BUILD_DIR)/arch/riscv/boot/Image
INITRAMFS_IMAGE_DIR ?= $(PLATFORM_IMAGE_ROOT)/initramfs
UBUNTU_IMAGE_DIR ?= $(PLATFORM_IMAGE_ROOT)/ubuntu2204
BUSYBOX_INITRD ?= $(INITRAMFS_IMAGE_DIR)/rootfs.cpio
UBUNTU_PROBE_INITRD ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64-probe.cpio
UBUNTU_SHELL_INITRD ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64.cpio
UBUNTU_ROOTFS_FLAVOR ?= systemd-minimal
UBUNTU_ROOTFS_SYSTEMD_IMAGE ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64.ext4
UBUNTU_ROOTFS_SYSTEMD_STRICT_IMAGE ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64-strict.ext4
UBUNTU_ROOTFS_INTERACTIVE_IMAGE ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64-interactive.ext4
UBUNTU_ROOTFS_FULL_IMAGE ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64-full.ext4
UBUNTU_ROOTFS_GUI_IMAGE ?= $(NEMU_GUI_PLATFORM_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64-gui.ext4
UBUNTU_ROOTFS_SYSTEMD_CPIO_IMAGE ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64-rootfs.cpio
UBUNTU_ROOTFS_SYSTEMD_STRICT_CPIO_IMAGE ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64-strict-rootfs.cpio
UBUNTU_ROOTFS_INTERACTIVE_CPIO_IMAGE ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64-interactive-rootfs.cpio
UBUNTU_ROOTFS_FULL_CPIO_IMAGE ?= $(UBUNTU_IMAGE_DIR)/ubuntu-22.04-riscv64-full-rootfs.cpio
UBUNTU_ROOTFS_GUI_CPIO_IMAGE ?= $(NEMU_GUI_PLATFORM_ROOT)/images/ubuntu2204/ubuntu-22.04-riscv64-gui-rootfs.cpio
UBUNTU_ROOTFS_SYSTEMD_DIR ?= $(UBUNTU_IMAGE_DIR)/rootfs
UBUNTU_ROOTFS_SYSTEMD_STRICT_DIR ?= $(UBUNTU_IMAGE_DIR)/rootfs-strict
UBUNTU_ROOTFS_INTERACTIVE_DIR ?= $(UBUNTU_IMAGE_DIR)/rootfs-interactive
UBUNTU_ROOTFS_FULL_DIR ?= $(UBUNTU_IMAGE_DIR)/rootfs-full
UBUNTU_ROOTFS_GUI_DIR ?= $(NEMU_GUI_ROOTFS_WORK)/rootfs-gui
UBUNTU_ROOTFS_WORK ?= $(UBUNTU_IMAGE_DIR)
UBUNTU_ROOTFS_BUILD_STAMP ?= $(UBUNTU_ROOTFS_WORK)/.ysyx-rootfs-build-profile
UBUNTU_ROOTFS_IMAGE ?= $(UBUNTU_ROOTFS_SYSTEMD_IMAGE)
UBUNTU_ROOTFS_CPIO_IMAGE ?= $(UBUNTU_ROOTFS_SYSTEMD_CPIO_IMAGE)
UBUNTU_ROOTFS_DIR ?= $(UBUNTU_ROOTFS_SYSTEMD_DIR)
UBUNTU_ROOTFS_INIT_SRC ?= $(TOOLS_DIR)/ysyx-rootfs-init.c
UBUNTU_ROOTFS_PROBE_SRC ?= $(TOOLS_DIR)/ysyx-ubuntu-init.c
UBUNTU_ROOTFS_NPC_TTY_PROBE_SRC ?= $(TOOLS_DIR)/ysyx-npc-tty-probe.c
UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_SRC ?= $(TOOLS_DIR)/ysyx-npc-generator-skip.c
UBUNTU_ROOTFS_NPC_STRICT_CHECK_SRC ?= $(SCRIPT_DIR)/npc-systemd-strict-check.sh
UBUNTU_RELEASE ?= jammy
UBUNTU_BASE_VERSION ?= 22.04.5
UBUNTU_ARCH ?= riscv64
UBUNTU_MIRROR ?= http://ports.ubuntu.com/ubuntu-ports
UBUNTU_BASE_URL ?= https://cdimages.ubuntu.com/ubuntu-base/releases/22.04/release
UBUNTU_BASE_TARBALL ?= $(ENV_ROOT)/downloads/ubuntu-base-$(UBUNTU_BASE_VERSION)-base-$(UBUNTU_ARCH).tar.gz
UBUNTU_BASE_SHA_FILE ?= $(ENV_ROOT)/downloads/SHA256SUMS
UBUNTU_ROOTFS_DEFAULT_CROSS_COMPILE := $(if $(shell test -x '$(ENV_ROOT)/toolchains/riscv64-linux-gnu/bin/riscv64-linux-gnu-gcc' && printf 1),$(ENV_ROOT)/toolchains/riscv64-linux-gnu/bin/riscv64-linux-gnu-,riscv64-linux-gnu-)
UBUNTU_ROOTFS_CROSS_COMPILE := $(if $(strip $(CROSS_COMPILE)),$(CROSS_COMPILE),$(UBUNTU_ROOTFS_DEFAULT_CROSS_COMPILE))
UBUNTU_ROOTFS_CC := $(if $(filter command line environment override,$(origin CC)),$(CC),$(UBUNTU_ROOTFS_CROSS_COMPILE)gcc)
UBUNTU_ROOTFS_FLAVOR_SCRIPT ?= $(SCRIPT_DIR)/ubuntu-rootfs-flavors.sh
UBUNTU_ROOTFS_SYSTEMD_OVERLAY_SCRIPT ?= $(SCRIPT_DIR)/build-ubuntu-systemd-overlay.sh
UBUNTU_ROOTFS_PROFILE_INPUTS := \
  $(SCRIPT_DIR)/build-ubuntu-rootfs.sh \
  $(SCRIPT_DIR)/check-ubuntu-rootfs.sh \
  $(UBUNTU_ROOTFS_SYSTEMD_OVERLAY_SCRIPT) \
  $(UBUNTU_ROOTFS_FLAVOR_SCRIPT) \
  $(UBUNTU_ROOTFS_INIT_SRC) \
  $(UBUNTU_ROOTFS_PROBE_SRC) \
  $(UBUNTU_ROOTFS_NPC_TTY_PROBE_SRC) \
  $(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_SRC) \
  $(UBUNTU_ROOTFS_NPC_STRICT_CHECK_SRC)
UBUNTU_ROOTFS_VT_AUTOLOGIN ?= 0
UBUNTU_ROOTFS_VT_AUTOLOGIN_USER ?= root
UBUNTU_ROOTFS_VT_AUTOLOGIN_TTY ?= tty1
UBUNTU_ROOTFS_REQUIRE_VT_AUTOLOGIN ?= $(UBUNTU_ROOTFS_VT_AUTOLOGIN)
UBUNTU_ROOTFS_CHECK_TARGET = $(if $(filter full,$(UBUNTU_ROOTFS_FLAVOR)),check-ubuntu-rootfs-full,$(if $(filter interactive,$(UBUNTU_ROOTFS_FLAVOR)),check-ubuntu-rootfs-interactive,check-ubuntu-rootfs-systemd))

KERNEL_DTB ?= $(BUILD_DIR)/npc-rv64.dtb
BUSYBOX_INITRAMFS_DTB ?= $(BUILD_DIR)/npc-rv64-initramfs.dtb
UBUNTU_PROBE_DTB ?= $(BUILD_DIR)/npc-rv64-ubuntu-initramfs.dtb
UBUNTU_SHELL_DTB ?= $(BUILD_DIR)/npc-rv64-ubuntu-shell-initramfs.dtb
NPC_ROOTFS_DTB ?= $(BUILD_DIR)/npc-rv64-rootfs.dtb
NEMU_ROOTFS_DTB ?= $(BUILD_DIR)/npc-rv64-nemu-rootfs.dtb
ROOTFS_DTB ?= $(if $(filter riscv64-nemu,$(ARCH)),$(NEMU_ROOTFS_DTB),$(NPC_ROOTFS_DTB))
DTB_BOOTARGS_STAMP_DIR ?= $(BUILD_DIR)/generated/.dtb-bootargs
KERNEL_DTB_BOOTARGS_STAMP := $(DTB_BOOTARGS_STAMP_DIR)/npc-rv64.stamp
BUSYBOX_INITRAMFS_DTB_BOOTARGS_STAMP := $(DTB_BOOTARGS_STAMP_DIR)/npc-rv64-initramfs.stamp
UBUNTU_PROBE_DTB_BOOTARGS_STAMP := $(DTB_BOOTARGS_STAMP_DIR)/npc-rv64-ubuntu-initramfs.stamp
UBUNTU_SHELL_DTB_BOOTARGS_STAMP := $(DTB_BOOTARGS_STAMP_DIR)/npc-rv64-ubuntu-shell-initramfs.stamp
NPC_ROOTFS_DTB_BOOTARGS_STAMP := $(DTB_BOOTARGS_STAMP_DIR)/npc-rv64-rootfs.stamp
NEMU_ROOTFS_DTB_BOOTARGS_STAMP := $(DTB_BOOTARGS_STAMP_DIR)/npc-rv64-nemu-rootfs.stamp

OPENSBI_PROFILE ?= $(PLATFORM_OPENSBI_PROFILE)
OPENSBI_BUILD_ROOT ?= $(PLATFORM_BUILD_ROOT)/opensbi
OPENSBI_BUILD_DIR ?= $(OPENSBI_BUILD_ROOT)/kernel
OPENSBI_BUSYBOX_BUILD_DIR ?= $(OPENSBI_BUILD_ROOT)/busybox-initramfs
OPENSBI_UBUNTU_PROBE_BUILD_DIR ?= $(OPENSBI_BUILD_ROOT)/ubuntu-initramfs
OPENSBI_UBUNTU_SHELL_BUILD_DIR ?= $(OPENSBI_BUILD_ROOT)/ubuntu-shell-initramfs
OPENSBI_ROOTFS_BUILD_DIR ?= $(OPENSBI_BUILD_ROOT)/rootfs
OPENSBI_ROOT ?= $(ENV_ROOT)/src/opensbi
OPENSBI_REF ?= v1.8
OPENSBI_NPC_PATCH ?= $(LINUX_HOME)/patches/opensbi-npc-no-pmp-hart-protection.patch
OPENSBI_PLATFORM ?= generic
OPENSBI_DEFAULT_CROSS_COMPILE := $(if $(shell test -x '$(ENV_ROOT)/toolchains/riscv/bin/riscv64-unknown-elf-gcc' && printf 1),$(ENV_ROOT)/toolchains/riscv/bin/riscv64-unknown-elf-,riscv64-linux-gnu-)
OPENSBI_CROSS_COMPILE := $(if $(strip $(CROSS_COMPILE)),$(CROSS_COMPILE),$(OPENSBI_DEFAULT_CROSS_COMPILE))
FW_JUMP_ADDR ?= $(NEXT_ADDR)
FW_JUMP_FDT_ADDR ?=
# NEMU 目前没有完整 PMU 设备模型，默认给它构建 no-PMU OpenSBI，避免用户手工补参数。
OPENSBI_DISABLE_PMU ?= $(PLATFORM_OPENSBI_DISABLE_PMU)

OPENSBI_PROFILE_STAMP ?= $(OPENSBI_BUILD_DIR)/.ysyx-build-profile
OPENSBI_BUSYBOX_PROFILE_STAMP ?= $(OPENSBI_BUSYBOX_BUILD_DIR)/.ysyx-build-profile
OPENSBI_UBUNTU_PROBE_PROFILE_STAMP ?= $(OPENSBI_UBUNTU_PROBE_BUILD_DIR)/.ysyx-build-profile
OPENSBI_UBUNTU_SHELL_PROFILE_STAMP ?= $(OPENSBI_UBUNTU_SHELL_BUILD_DIR)/.ysyx-build-profile
OPENSBI_ROOTFS_PROFILE_STAMP ?= $(OPENSBI_ROOTFS_BUILD_DIR)/.ysyx-build-profile
OPENSBI_PROFILE_STAMPS := $(OPENSBI_PROFILE_STAMP) \
  $(OPENSBI_BUSYBOX_PROFILE_STAMP) \
  $(OPENSBI_UBUNTU_PROBE_PROFILE_STAMP) \
  $(OPENSBI_UBUNTU_SHELL_PROFILE_STAMP) \
  $(OPENSBI_ROOTFS_PROFILE_STAMP)
OPENSBI_STAMP_COMMON_ENV = \
	OPENSBI_STAMP_ARCH='$(ARCH)' \
	OPENSBI_STAMP_LINUX_PLATFORM='$(LINUX_PLATFORM)' \
	OPENSBI_STAMP_PROFILE='$(OPENSBI_PROFILE)' \
	OPENSBI_STAMP_ROOT='$(OPENSBI_ROOT)' \
	OPENSBI_STAMP_REF='$(OPENSBI_REF)' \
	OPENSBI_STAMP_NPC_PATCH='$(OPENSBI_NPC_PATCH)' \
	OPENSBI_STAMP_CROSS_COMPILE='$(OPENSBI_CROSS_COMPILE)' \
	OPENSBI_STAMP_PLATFORM='$(OPENSBI_PLATFORM)' \
	OPENSBI_STAMP_FW_JUMP_ADDR='$(FW_JUMP_ADDR)' \
	OPENSBI_STAMP_FW_JUMP_FDT_ADDR='$(FW_JUMP_FDT_ADDR)' \
	OPENSBI_STAMP_DISABLE_PMU='$(OPENSBI_DISABLE_PMU)'
OPENSBI_SOURCE_INPUTS := $(SCRIPT_DIR)/build-opensbi.sh $(wildcard $(OPENSBI_NPC_PATCH))

OPENSBI_FW ?= $(OPENSBI_BUILD_DIR)/platform/$(OPENSBI_PLATFORM)/firmware/fw_jump.bin
OPENSBI_BUSYBOX_FW ?= $(OPENSBI_BUSYBOX_BUILD_DIR)/platform/$(OPENSBI_PLATFORM)/firmware/fw_jump.bin
OPENSBI_UBUNTU_PROBE_FW ?= $(OPENSBI_UBUNTU_PROBE_BUILD_DIR)/platform/$(OPENSBI_PLATFORM)/firmware/fw_jump.bin
OPENSBI_UBUNTU_SHELL_FW ?= $(OPENSBI_UBUNTU_SHELL_BUILD_DIR)/platform/$(OPENSBI_PLATFORM)/firmware/fw_jump.bin
OPENSBI_ROOTFS_FW ?= $(OPENSBI_ROOTFS_BUILD_DIR)/platform/$(OPENSBI_PLATFORM)/firmware/fw_jump.bin

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
RUN_DEPS += $(RUN_FW) $(RUN_DTB) $(RUN_ROOTFS) $(UBUNTU_ROOTFS_CHECK_TARGET)
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
# 默认 NEMU rootfs run 使用 sparse overlay，避免日常 make run 污染基准 Ubuntu ext4。
NEMU_RUN_ROOTFS_OVERLAY ?= $(if $(and $(filter riscv64-nemu,$(ARCH)),$(strip $(RUN_ROOTFS))),$(LOG_DIR)/rootfs-overlay.raw,)
NEMU_RUN_ROOTFS_OVERLAY_RESET ?= 1
NEMU_RUN_MAX_BOOTS ?= 2
RUN_SIM := $(if $(filter riscv64-nemu,$(ARCH)),$(NEMU_SIM),$(NPC_SIM))
PROGRESS_OPT := $(if $(strip $(PROGRESS)),--progress=$(PROGRESS),--no-progress)
EXPECT_ENV := $(if $(strip $(RUN_EXPECT)),NPC_GUEST_EXPECT='$(RUN_EXPECT)',)
INITRD_LOAD := $(if $(strip $(RUN_INITRD)),--load=$(INITRD_ADDR):$(RUN_INITRD),)
ROOTFS_BLOCK := $(if $(strip $(RUN_ROOTFS)),--block='$(RUN_ROOTFS)',)
ROOTFS_OVERLAY := $(if $(strip $(NEMU_RUN_ROOTFS_OVERLAY)),--block-overlay='$(NEMU_RUN_ROOTFS_OVERLAY)',)

.DEFAULT_GOAL := help

.PHONY: help run run-ubuntu-rootfs run-ubuntu-gui run-ubuntu-shell run-ubuntu-probe run-busybox-initramfs run-kernel \
        prepare prepare-all setup-env linux-defconfig linux-trace-defconfig nemu-linux-defconfig sim check-sim \
        linux-image busybox-initramfs ubuntu-probe-initramfs \
        ubuntu-shell-initramfs ubuntu-rootfs-image dtb initramfs-dtb ubuntu-initramfs-dtb \
        ubuntu-shell-initramfs-dtb rootfs-dtb opensbi opensbi-busybox opensbi-ubuntu-probe \
        opensbi-ubuntu-shell opensbi-rootfs qemu qemu-build qemu-ubuntu-probe qemu-ubuntu-shell \
        tools-build boot-tools tools-smoke tools-clean paths check ubuntu-rootfs-check \
        ubuntu-rootfs-flavors-check \
        check-ubuntu-rootfs check-ubuntu-rootfs-systemd ubuntu-rootfs-systemd-image \
        check-ubuntu-rootfs-systemd-strict ubuntu-rootfs-systemd-strict-image \
        ubuntu-rootfs-systemd-overlay ubuntu-rootfs-interactive-image ubuntu-rootfs-full-image \
        check-ubuntu-rootfs-interactive check-ubuntu-rootfs-full \
	        check-npc-systemd-guest check-npc-systemd-guest-full \
	        check-npc-systemd-guest-systemd-strict __check-npc-systemd-guest \
        check-nemu-systemd-guest check-nemu-systemd-guest-long \
        check-nemu-systemd-guest-interactive check-nemu-systemd-guest-full \
        check-nemu-systemd-guest-full-soak \
        check-nemu-tap-host show-nemu-tap-setup show-nemu-tap-teardown \
        check-nemu-systemd-guest-tap check-nemu-systemd-guest-full-tap \
        check-nemu-systemd-guest-soak check-nemu-virtio-blk-error \
        check-nemu-reboot-loop check-nemu-reboot-persistence \
        check-nemu-evolution check-nemu-gui check-nemu-gui-config \
        check-nemu-virtio-input check-nemu-retirement-sdtrig \
        __check-nemu-gui __check-nemu-virtio-input __check-nemu-retirement-sdtrig \
        __check-nemu-virtio-blk-error \
        __check-nemu-reboot-loop __check-nemu-reboot-persistence \
        check-nemu-performance-config check-nemu-kernel-config nemu-machine-info nemu-monitor-cmd-smoke nemu-qmp-smoke nemu-gdbstub-smoke nemu-rootfs-machine-info nemu-rootfs-overlay-machine-info __check-nemu-systemd-guest clean clean-logs \
        FORCE $(TOOL_SMOKES) $(TOOL_BOOT_SMOKES)

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
	@printf '%s\n' '  make run-ubuntu-gui'
	@printf '%s\n' '      启动隔离的 NEMU GUI profile：SDL simplefb/fbcon、tty1 与标准 virtio-input 键盘。'
	@printf '%s\n' '  make check-nemu-gui'
	@printf '%s\n' '      在 Xvfb 中验证 simplefb/fbcon/tty1、SDL 画面及 SDL→virtio-input→Linux→tty1 按键闭环。'
	@printf '%s\n' '  make check-nemu-retirement-sdtrig'
	@printf '%s\n' '      验证 minstret 只统计成功退休指令，并确认未实现的 Sdtrig CSR 产生非法指令异常。'
	@printf '%s\n' '  make check-nemu-virtio-input'
	@printf '%s\n' '      用裸机 payload 验证 virtio-input 配置、双队列、坏描述符、按键事件及 PLIC IRQ7。'
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
	@printf '%s\n' '  make ARCH=riscv64-nemu nemu-rootfs-machine-info'
	@printf '%s\n' '      不启动 guest，检查 NEMU 是否真实打开 Ubuntu ext4 rootfs block 镜像并导出容量/只读状态。'
	@printf '%s\n' '  make ARCH=riscv64-nemu nemu-rootfs-overlay-machine-info'
	@printf '%s\n' '      不启动 guest，检查 NEMU 是否真实打开 Ubuntu ext4 rootfs + 持久 sparse overlay/sidecar 并导出写入目标。'
	@printf '%s\n' '  make check-nemu-reboot-loop'
	@printf '%s\n' '      用裸机 syscon payload 验证 reboot=rc32、宿主单次重启与最终 poweroff。'
	@printf '%s\n' '  make check-nemu-virtio-blk-error'
	@printf '%s\n' '      在 persistent overlay 上验证零长度 IN/OUT 与异常 descriptor 边界。'
	@printf '%s\n' '  make check-nemu-reboot-persistence'
	@printf '%s\n' '      Ubuntu boot1 写入并 sync/reboot，boot2 从同一 overlay 读回后自然 poweroff，并证明 backing 未变。'
	@printf '%s\n' '  make check-nemu-evolution'
	@printf '%s\n' '      P0 聚合：顺序执行 block 异常边界、reboot smoke、完整 hostless 网络/RNG/systemd 和跨重启持久化 gate。'
	@printf '%s\n' '  make ARCH=riscv64-nemu nemu-monitor-cmd-smoke'
	@printf '%s\n' '      不进入交互提示符，验证 --monitor-cmd="info r" 一次性管理入口。'
	@printf '%s\n' '  make ARCH=riscv64-nemu nemu-qmp-smoke'
	@printf '%s\n' '      验证 QMP 查询/run-control/事件/quit，以及超长、截断、嵌套或重复字段请求的 fail-closed 帧边界。'
	@printf '%s\n' '  make ARCH=riscv64-nemu check-nemu-tap-host'
	@printf '%s\n' '      只读检查宿主 TAP/NAT 条件；show-nemu-tap-setup 只打印需 root 执行的配置命令。'
	@printf '%s\n' '  make ARCH=riscv64-nemu check-nemu-systemd-guest-full-tap'
	@printf '%s\n' '      先要求 TAP preflight ready，再用 full rootfs 跑 TAP 后端 guest gate。'
	@printf '%s\n' '  make ARCH=riscv64-nemu ubuntu-rootfs-systemd-image'
	@printf '%s\n' '      无 sudo 时用 apt/dpkg-deb overlay 把 systemd/udev/dbus 候选用户态放进 rootfs。'
	@printf '%s\n' '  make ARCH=riscv64-npc ubuntu-rootfs-systemd-strict-image'
	@printf '%s\n' '      构建独立严格验证 rootfs，由 sysinit.target 执行检查并经 syscon 自然关机。'
	@printf '%s\n' '  make ARCH=riscv64-nemu ubuntu-rootfs-flavors-check'
	@printf '%s\n' '      不重建镜像，检查 systemd-minimal/interactive/full flavor manifest 内部一致性。'
	@printf '%s\n' '  make ARCH=riscv64-nemu ubuntu-rootfs-interactive-image'
	@printf '%s\n' '      构建 interactive flavor 到独立 ext4，补 curl/wget/ping/ssh/htop/less/strace 等串口调试工具。'
	@printf '%s\n' '  make ARCH=riscv64-nemu ubuntu-rootfs-full-image'
	@printf '%s\n' '      构建 full flavor 到独立 ext4，补 ubuntu-standard/openssh-server/sudo/locales/man-db/cron/rsyslog 等 server 用户态。'
	@printf '%s\n' '  make ARCH=riscv64-nemu check-ubuntu-rootfs-full'
	@printf '%s\n' '      对 full flavor 独立 ext4 执行实物检查；未重建 full 镜像时应明确失败。'
	@printf '%s\n' '  make ARCH=riscv64-nemu check-nemu-systemd-guest-full'
	@printf '%s\n' '      用 full flavor 独立 ext4 启动 NEMU focused guest gate；缺镜像时先构建 full rootfs。'
	@printf '%s\n' '  make check-npc-systemd-guest'
	@printf '%s\n' '      启动 NPC Ubuntu rootfs，等待 root 串口提示符后由 UART RX 文件源逐字节发送最小 guest 检查脚本。'
	@printf '%s\n' '  make check-npc-systemd-guest-systemd-strict'
	@printf '%s\n' '      使用严格 rootfs，由 systemd one-shot 完成检查和 syscon 关机；UART RX 字节数保持为 0。'
	@printf '%s\n' '  make ARCH=riscv64-nemu check-nemu-systemd-guest-full-soak'
	@printf '%s\n' '      full flavor 独立 ext4 的重型稳定性 gate，复用 300s soak/32MiB fs stress 等 soak 参数，并保留 full 用户态 runtime hard gate。'
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
	@bash '$(SCRIPT_DIR)/guard-artifact-paths.sh' \
	  --input='$(RUN_SIM)' \
	  --input='$(LINUX_IMAGE)' \
	  $(if $(strip $(RUN_FW)),--input='$(RUN_FW)',) \
	  $(if $(strip $(RUN_DTB)),--input='$(RUN_DTB)',) \
	  $(if $(strip $(RUN_INITRD)),--input='$(RUN_INITRD)',) \
	  $(if $(strip $(RUN_ROOTFS)),--input='$(RUN_ROOTFS)',) \
	  --output='$(LOG_FILE)' \
	  --output='$(CONSOLE_LOG)' \
	  $(if $(strip $(NEMU_RUN_ROOTFS_OVERLAY)),--output='$(NEMU_RUN_ROOTFS_OVERLAY)' --output='$(NEMU_RUN_ROOTFS_OVERLAY).meta' --output='$(NEMU_RUN_ROOTFS_OVERLAY).meta.tmp' --output='$(NEMU_RUN_ROOTFS_OVERLAY).lock',)
	@mkdir -p '$(LOG_DIR)'
	@printf '[Linux] ARCH=%s BOOT=%s\n' '$(ARCH)' '$(BOOT)'
	@printf '[Linux] firmware: %s\n' '$(RUN_FW)'
	@printf '[Linux] kernel:   %s\n' '$(LINUX_IMAGE)'
	@printf '[Linux] dtb:      %s\n' '$(RUN_DTB)'
	@if [ -n '$(RUN_INITRD)' ]; then printf '[Linux] initrd:   %s\n' '$(RUN_INITRD)'; fi
	@if [ -n '$(RUN_ROOTFS)' ]; then \
	  printf '[Linux] rootfs:   %s\n' '$(RUN_ROOTFS)'; \
	fi
	@if [ -n '$(NEMU_RUN_ROOTFS_OVERLAY)' ]; then \
	  bash '$(SCRIPT_DIR)/prepare-nemu-overlay.sh' \
	    --backing='$(RUN_ROOTFS)' \
	    --overlay='$(NEMU_RUN_ROOTFS_OVERLAY)' \
	    --reset='$(NEMU_RUN_ROOTFS_OVERLAY_RESET)'; \
	  printf '[Linux] overlay:  %s reset=%s\n' '$(NEMU_RUN_ROOTFS_OVERLAY)' '$(NEMU_RUN_ROOTFS_OVERLAY_RESET)'; \
	fi
	@printf '[Linux] log:      %s\n' '$(CONSOLE_LOG)'
ifeq ($(ARCH),riscv64-nemu)
	@set -o pipefail; \
	NEMU_HOME='$(NEMU_HOME)' bash '$(SCRIPT_DIR)/run-nemu-reboot-loop.sh' \
	  --reboot-exit-code=32 --max-boots='$(NEMU_RUN_MAX_BOOTS)' -- \
	  '$(NEMU_SIM)' -b --max-insts=$(MAX_CYCLES) \
	  --log='$(LOG_FILE)' \
	  --boot-hartid=0 \
	  --boot-dtb=$(DTB_ADDR) \
	  -i '$(RUN_FW)' \
	  --load=$(NEXT_ADDR):'$(LINUX_IMAGE)' \
	  --load=$(DTB_ADDR):'$(RUN_DTB)' \
	  $(INITRD_LOAD) \
	  $(ROOTFS_BLOCK) \
	  $(ROOTFS_OVERLAY) \
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
	+$(MAKE) ARCH=$(ARCH) BOOT=ubuntu-rootfs run

# 显示 profile 与默认 headless Ubuntu 使用独立的 NEMU Kconfig/build、
# kernel、OpenSBI、DTB、rootfs、overlay 和日志产物。
run-ubuntu-gui:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs run \
	  BUILD_DIR='$(NEMU_GUI_FRONT_BUILD_DIR)' \
	  LINUX_BUILD_DIR='$(NEMU_GUI_KERNEL_BUILD_DIR)' \
	  OPENSBI_BUILD_ROOT='$(NEMU_GUI_OPENSBI_BUILD_ROOT)' \
	  LINUX_FEATURE_PROFILE=display \
	  NEMU_DEFCONFIG=riscv64-linux-gui_defconfig \
	  NEMU_BUILD_DIR='$(NEMU_GUI_BUILD_DIR)' \
	  NEMU_CONFIG_DIR='$(NEMU_GUI_CONFIG_DIR)' \
	  NEMU_SIM='$(NEMU_GUI_SIM)' \
	  NEMU_DISPLAY=1 NEMU_PERFORMANCE_REQUIRED=0 \
	  LOG_DIR='$(NEMU_GUI_LOG_DIR)' \
	  NEMU_RUN_ROOTFS_OVERLAY='$(NEMU_GUI_ROOTFS_OVERLAY)' \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_GUI_IMAGE)' \
	  UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_GUI_CPIO_IMAGE)' \
	  UBUNTU_ROOTFS_DIR='$(UBUNTU_ROOTFS_GUI_DIR)' \
	  UBUNTU_ROOTFS_WORK='$(NEMU_GUI_ROOTFS_WORK)' \
	  UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
	  UBUNTU_ROOTFS_VT_AUTOLOGIN=1 \
	  UBUNTU_ROOTFS_REQUIRE_VT_AUTOLOGIN=1 \
	  UBUNTU_ROOTFS_CHECK_TARGET=check-ubuntu-rootfs

check-nemu-gui:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs __check-nemu-gui \
	  BUILD_DIR='$(NEMU_GUI_FRONT_BUILD_DIR)' \
	  LINUX_BUILD_DIR='$(NEMU_GUI_KERNEL_BUILD_DIR)' \
	  LINUX_FEATURE_PROFILE=display \
	  OPENSBI_BUILD_ROOT='$(NEMU_GUI_OPENSBI_BUILD_ROOT)' \
	  NEMU_DEFCONFIG=riscv64-linux-gui_defconfig \
	  NEMU_BUILD_DIR='$(NEMU_GUI_BUILD_DIR)' \
	  NEMU_CONFIG_DIR='$(NEMU_GUI_CONFIG_DIR)' \
	  NEMU_SIM='$(NEMU_GUI_SIM)' \
	  NEMU_DISPLAY=1 NEMU_VIRTIO_INPUT=1 NEMU_PERFORMANCE_REQUIRED=0 \
	  NEMU_GUI_LOG_DIR='$(NEMU_GUI_CHECK_LOG_DIR)' \
	  NEMU_GUI_ROOTFS_OVERLAY='$(NEMU_GUI_CHECK_ROOTFS_OVERLAY)' \
	  NEMU_GUI_SCREENSHOT='$(NEMU_GUI_CHECK_SCREENSHOT)' \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_GUI_IMAGE)' \
	  UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_GUI_CPIO_IMAGE)' \
	  UBUNTU_ROOTFS_DIR='$(UBUNTU_ROOTFS_GUI_DIR)' \
	  UBUNTU_ROOTFS_WORK='$(NEMU_GUI_ROOTFS_WORK)' \
	  UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
	  UBUNTU_ROOTFS_VT_AUTOLOGIN=1 \
	  UBUNTU_ROOTFS_REQUIRE_VT_AUTOLOGIN=1 \
	  UBUNTU_ROOTFS_CHECK_TARGET=check-ubuntu-rootfs

check-nemu-virtio-input:
	+$(MAKE) ARCH=riscv64-nemu __check-nemu-virtio-input \
	  NEMU_DEFCONFIG=riscv64-linux-gui_defconfig \
	  NEMU_BUILD_DIR='$(NEMU_GUI_BUILD_DIR)' \
	  NEMU_CONFIG_DIR='$(NEMU_GUI_CONFIG_DIR)' \
	  NEMU_SIM='$(NEMU_GUI_SIM)'

check-nemu-retirement-sdtrig:
	+$(MAKE) ARCH=riscv64-nemu __check-nemu-retirement-sdtrig \
	  NEMU_DEFCONFIG=riscv64-linux_defconfig \
	  NEMU_BUILD_DIR='$(NEMU_RETIRE_BUILD_DIR)' \
	  NEMU_CONFIG_DIR='$(NEMU_RETIRE_CONFIG_DIR)' \
	  NEMU_SIM='$(NEMU_RETIRE_SIM)'

run-ubuntu-shell:
	+$(MAKE) ARCH=$(ARCH) BOOT=ubuntu-shell run

run-ubuntu-probe:
	+$(MAKE) ARCH=$(ARCH) BOOT=ubuntu-probe run

run-busybox-initramfs:
	+$(MAKE) ARCH=$(ARCH) BOOT=busybox-initramfs run

run-kernel:
	+$(MAKE) ARCH=$(ARCH) BOOT=kernel run

prepare: $(RUN_DEPS)

prepare-all: sim linux-image busybox-initramfs ubuntu-probe-initramfs ubuntu-shell-initramfs \
	ubuntu-rootfs-image dtb initramfs-dtb ubuntu-initramfs-dtb ubuntu-shell-initramfs-dtb \
	rootfs-dtb opensbi opensbi-busybox opensbi-ubuntu-probe opensbi-ubuntu-shell opensbi-rootfs

setup-env:
	bash '$(SCRIPT_DIR)/setup-env.sh'

$(CONF): $(KCONFIG_TOOL_INPUTS) $(NEMU_SAFE_FLOCK)
	@mkdir -p '$(KCONFIG_PATH)/build'
	python3 '$(NEMU_SAFE_FLOCK)' '$(KCONFIG_PATH)/build/.build.lock' -- \
	  $(MAKE) -s -C '$(KCONFIG_PATH)' NAME=conf BUILD_DIR='$(KCONFIG_PATH)/build'

$(FIXDEP): $(FIXDEP_TOOL_INPUTS) $(NEMU_SAFE_FLOCK)
	@mkdir -p '$(FIXDEP_PATH)/build'
	python3 '$(NEMU_SAFE_FLOCK)' '$(FIXDEP_PATH)/build/.build.lock' -- \
	  $(MAKE) -s -C '$(FIXDEP_PATH)' BUILD_DIR='$(FIXDEP_PATH)/build'

ifeq ($(NPC_KCONFIG_LOCK_HELD),1)
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
else
# The NPC configuration, generated headers, profile stamps and the simulator
# that consumes them form one mutable transaction.  Keep the lock outside all
# build*/ directories so clean cannot replace its inode, then re-enter make
# with the lock descriptor inherited for the complete writer/build graph.
linux-defconfig linux-trace-defconfig: $(CONF) $(FIXDEP)
	@mkdir -p '$(dir $(NPC_KCONFIG_LOCK))'
	@python3 '$(NEMU_SAFE_FLOCK)' '$(NPC_KCONFIG_LOCK)' -- \
	  $(MAKE) --no-print-directory NPC_KCONFIG_LOCK_HELD=1 '$@'
endif

ifeq ($(ARCH),riscv64-nemu)
nemu-linux-defconfig:
	+$(MAKE) -C '$(NEMU_HOME)' NEMU_HOME='$(NEMU_HOME)' \
	  NEMU_CONFIG_DIR='$(NEMU_CONFIG_DIR)' $(NEMU_DEFCONFIG)

sim: nemu-linux-defconfig
	+$(MAKE) -C '$(NEMU_HOME)' NEMU_HOME='$(NEMU_HOME)' \
	  NEMU_CONFIG_DIR='$(NEMU_CONFIG_DIR)' BUILD_DIR='$(NEMU_BUILD_DIR)' -j'$(JOBS)'

check-sim: sim
	@test -x '$(NEMU_SIM)'

check-nemu-performance-config: nemu-linux-defconfig
	NEMU_PERFORMANCE_REQUIRED='$(NEMU_PERFORMANCE_REQUIRED)' \
	NEMU_CONFIG='$(NEMU_CONFIG_DIR)/.config' \
	NEMU_AUTOCONF='$(NEMU_CONFIG_DIR)/include/generated/autoconf.h' \
	NEMU_POLICY_HEADER='$(NEMU_HOME)/include/nemu-config.h' \
	NEMU_DEVICE_ADDRESS_HEADER='$(NEMU_HOME)/include/device/device_address.h' \
	NEMU_GENERIC_MAP_HEADER='$(NEMU_HOME)/include/platform/generic-map.h' \
	  bash '$(SCRIPT_DIR)/check-nemu-performance-config.sh'

nemu-machine-info: sim
	@mkdir -p '$(BUILD_DIR)'
	NEMU_HOME='$(NEMU_HOME)' '$(NEMU_SIM)' -b \
	  --log='$(NEMU_MACHINE_INFO_LOG)' \
	  --machine-info='$(NEMU_MACHINE_INFO_FILE)'
	@cat '$(NEMU_MACHINE_INFO_FILE)'

nemu-monitor-cmd-smoke: sim
	@mkdir -p '$(BUILD_DIR)'
	NEMU_HOME='$(NEMU_HOME)' '$(NEMU_SIM)' -b \
	  --log='$(NEMU_MONITOR_CMD_SMOKE_NEMU_LOG)' \
	  --monitor-cmd='$(NEMU_MONITOR_CMD_SMOKE_CMD)' \
	  > '$(NEMU_MONITOR_CMD_SMOKE_LOG)' 2>&1
	@cat '$(NEMU_MONITOR_CMD_SMOKE_LOG)'

nemu-qmp-smoke: sim check-ubuntu-rootfs-systemd $(OPENSBI_ROOTFS_FW) $(NEMU_ROOTFS_DTB) $(LINUX_IMAGE)
	@mkdir -p '$(BUILD_DIR)'
	$(PYTHON) '$(SCRIPT_DIR)/check-nemu-qmp-smoke.py' \
	  --nemu '$(NEMU_SIM)' \
	  --log '$(NEMU_QMP_SMOKE_LOG)' \
	  --nemu-log '$(NEMU_QMP_SMOKE_NEMU_LOG)' \
	  --cont-nemu-log '$(NEMU_QMP_SMOKE_CONT_NEMU_LOG)' \
	  --block-nemu-log '$(NEMU_QMP_SMOKE_BLOCK_NEMU_LOG)' \
	  --runtime-nemu-log '$(NEMU_QMP_SMOKE_RUNTIME_NEMU_LOG)' \
	  --disconnect-nemu-log '$(NEMU_QMP_SMOKE_DISCONNECT_NEMU_LOG)' \
	  --system-powerdown-nemu-log '$(NEMU_QMP_SMOKE_SYSTEM_POWERDOWN_NEMU_LOG)' \
	  --guest-shutdown-nemu-log '$(NEMU_QMP_SMOKE_GUEST_SHUTDOWN_NEMU_LOG)' \
	  --block-image '$(UBUNTU_ROOTFS_IMAGE)' \
	  --overlay-image '$(NEMU_QMP_SMOKE_OVERLAY)' \
	  --runtime-overlay-image '$(NEMU_QMP_SMOKE_RUNTIME_OVERLAY)' \
	  --disconnect-image '$(NEMU_QMP_SMOKE_DISCONNECT_IMAGE)' \
	  --system-powerdown-image '$(NEMU_QMP_SMOKE_SYSTEM_POWERDOWN_IMAGE)' \
	  --guest-shutdown-image '$(NEMU_QMP_SMOKE_GUEST_SHUTDOWN_IMAGE)' \
	  --firmware '$(OPENSBI_ROOTFS_FW)' \
	  --kernel '$(LINUX_IMAGE)' \
	  --dtb '$(NEMU_ROOTFS_DTB)' \
	  --next-addr '$(NEXT_ADDR)' \
	  --dtb-addr '$(DTB_ADDR)' \
	  --runtime-max-insts '$(NEMU_QMP_SMOKE_RUNTIME_MAX_INSTS)'
	grep -Fq '__NEMU_QMP_SMOKE__:ok' '$(NEMU_QMP_SMOKE_LOG)'
	@cat '$(NEMU_QMP_SMOKE_LOG)'

nemu-gdbstub-smoke: sim
	@mkdir -p '$(BUILD_DIR)'
	$(PYTHON) '$(SCRIPT_DIR)/check-nemu-gdbstub-smoke.py' \
	  --nemu '$(NEMU_SIM)' \
	  --log '$(NEMU_GDBSTUB_SMOKE_LOG)' \
	  --nemu-log '$(NEMU_GDBSTUB_SMOKE_NEMU_LOG)' \
	  --monitor-cmd '$(NEMU_GDBSTUB_SMOKE_CMD)'
	grep -Fq '__NEMU_GDBSTUB_SMOKE__:ok' '$(NEMU_GDBSTUB_SMOKE_LOG)'
	@cat '$(NEMU_GDBSTUB_SMOKE_LOG)'

nemu-rootfs-machine-info: sim check-ubuntu-rootfs
	@bash '$(SCRIPT_DIR)/guard-artifact-paths.sh' \
	  --input='$(NEMU_SIM)' \
	  --input='$(UBUNTU_ROOTFS_IMAGE)' \
	  --output='$(NEMU_ROOTFS_MACHINE_INFO_LOG)' \
	  --output='$(NEMU_ROOTFS_MACHINE_INFO_FILE)'
	@mkdir -p '$(BUILD_DIR)'
	NEMU_HOME='$(NEMU_HOME)' '$(NEMU_SIM)' -b \
	  --log='$(NEMU_ROOTFS_MACHINE_INFO_LOG)' \
	  --block='$(UBUNTU_ROOTFS_IMAGE)' \
	  --machine-info='$(NEMU_ROOTFS_MACHINE_INFO_FILE)'
	@cat '$(NEMU_ROOTFS_MACHINE_INFO_FILE)'

nemu-rootfs-overlay-machine-info: sim check-ubuntu-rootfs
	@bash '$(SCRIPT_DIR)/guard-artifact-paths.sh' \
	  --input='$(NEMU_SIM)' \
	  --input='$(UBUNTU_ROOTFS_IMAGE)' \
	  --output='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_LOG)' \
	  --output='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_FILE)' \
	  --output='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY)' \
	  --output='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY).meta' \
	  --output='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY).meta.tmp' \
	  --output='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY).lock' \
	  --output='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY_STAT)'
	@mkdir -p '$(BUILD_DIR)'
	@bash '$(SCRIPT_DIR)/prepare-nemu-overlay.sh' \
	  --backing='$(UBUNTU_ROOTFS_IMAGE)' \
	  --overlay='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY)' --reset=1
	@rm -f -- '$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY_STAT)'
	NEMU_HOME='$(NEMU_HOME)' '$(NEMU_SIM)' -b \
	  --log='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_LOG)' \
	  --block='$(UBUNTU_ROOTFS_IMAGE)' \
	  --block-overlay='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY)' \
	  --machine-info='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_FILE)'
	@stat -c 'overlay_size=%s overlay_blocks=%b overlay_path=%n' \
	  '$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY)' > '$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY_STAT)'
	@cat '$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_FILE)'
	@cat '$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY_STAT)'
	@bash '$(SCRIPT_DIR)/prepare-nemu-overlay.sh' \
	  --backing='$(UBUNTU_ROOTFS_IMAGE)' \
	  --overlay='$(NEMU_ROOTFS_OVERLAY_MACHINE_INFO_OVERLAY)' --reset=1
else
nemu-linux-defconfig:
	@echo '[Linux] skip NEMU defconfig for ARCH=$(ARCH)'

check-nemu-performance-config:
	@echo '[Linux] skip NEMU performance config check for ARCH=$(ARCH)'

nemu-machine-info:
	@echo '[Linux] skip NEMU machine info for ARCH=$(ARCH)'

nemu-monitor-cmd-smoke:
	@echo '[Linux] skip NEMU monitor command smoke for ARCH=$(ARCH)'

nemu-qmp-smoke:
	@echo '[Linux] skip NEMU QMP smoke for ARCH=$(ARCH)'

nemu-gdbstub-smoke:
	@echo '[Linux] skip NEMU gdbstub smoke for ARCH=$(ARCH)'

nemu-rootfs-machine-info:
	@echo '[Linux] skip NEMU rootfs machine info for ARCH=$(ARCH)'

nemu-rootfs-overlay-machine-info:
	@echo '[Linux] skip NEMU rootfs overlay machine info for ARCH=$(ARCH)'

ifeq ($(NPC_KCONFIG_LOCK_HELD),1)
sim: linux-defconfig
	+$(MAKE) -C '$(NPC_RV64)' -j'$(JOBS)' $(NPC_SIM_MAKE_ARGS)

check-sim: sim
	@test -x '$(NPC_SIM)'
else
sim check-sim: $(CONF) $(FIXDEP)
	@mkdir -p '$(dir $(NPC_KCONFIG_LOCK))'
	@python3 '$(NEMU_SAFE_FLOCK)' '$(NPC_KCONFIG_LOCK)' -- \
	  $(MAKE) --no-print-directory NPC_KCONFIG_LOCK_HELD=1 '$@'
endif
endif

linux-image: $(LINUX_IMAGE)
busybox-initramfs: $(BUSYBOX_INITRD)
ubuntu-probe-initramfs: $(UBUNTU_PROBE_INITRD)
ubuntu-shell-initramfs: $(UBUNTU_SHELL_INITRD)
ubuntu-rootfs-image: $(UBUNTU_ROOTFS_IMAGE) $(UBUNTU_ROOTFS_CPIO_IMAGE)
ubuntu-rootfs-flavors-check:
	bash '$(SCRIPT_DIR)/ubuntu-rootfs-flavors.sh' --check
ubuntu-rootfs-systemd-image ubuntu-rootfs-systemd-overlay:
	UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
	UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_IMAGE)' \
	UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_CPIO_IMAGE)' \
	UBUNTU_ROOTFS_WORK='$(UBUNTU_IMAGE_DIR)' \
	UBUNTU_ROOTFS_DIR='$(UBUNTU_ROOTFS_SYSTEMD_DIR)' \
	UBUNTU_ROOTFS_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_NPC_CONSOLE_SHELL)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL)' \
	UBUNTU_ROOTFS_NPC_TTY_READER='$(UBUNTU_ROOTFS_NPC_TTY_READER)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER='$(UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER)' \
	UBUNTU_ROOTFS_NPC_TTY_READER_MODE='$(UBUNTU_ROOTFS_NPC_TTY_READER_MODE)' \
	UBUNTU_ROOTFS_NPC_STRICT_AUTORUN='$(UBUNTU_ROOTFS_NPC_STRICT_AUTORUN)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_STRICT_AUTORUN='$(UBUNTU_ROOTFS_REQUIRE_NPC_STRICT_AUTORUN)' \
	UBUNTU_ROOTFS_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_NPC_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_NPC_GENERATOR_TRACE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE)' \
	UBUNTU_ROOTFS_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_NEMU_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE)' \
	UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS)' \
	UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1 UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
	  bash '$(SCRIPT_DIR)/build-ubuntu-rootfs.sh'
ubuntu-rootfs-systemd-strict-image:
	+$(MAKE) ubuntu-rootfs-systemd-image \
	  UBUNTU_ROOTFS_SYSTEMD_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_STRICT_IMAGE)' \
	  UBUNTU_ROOTFS_SYSTEMD_CPIO_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_STRICT_CPIO_IMAGE)' \
	  UBUNTU_ROOTFS_SYSTEMD_DIR='$(UBUNTU_ROOTFS_SYSTEMD_STRICT_DIR)' \
	  UBUNTU_ROOTFS_NPC_CONSOLE_SHELL=1 \
	  UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=1 \
	  UBUNTU_ROOTFS_NPC_STRICT_AUTORUN=1 \
	  UBUNTU_ROOTFS_REQUIRE_NPC_STRICT_AUTORUN=1
ubuntu-rootfs-interactive-image:
	UBUNTU_ROOTFS_FLAVOR=interactive \
	UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_INTERACTIVE_IMAGE)' \
	UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_INTERACTIVE_CPIO_IMAGE)' \
	UBUNTU_ROOTFS_WORK='$(UBUNTU_IMAGE_DIR)' \
	UBUNTU_ROOTFS_DIR='$(UBUNTU_ROOTFS_INTERACTIVE_DIR)' \
	UBUNTU_ROOTFS_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_NPC_CONSOLE_SHELL)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL)' \
	UBUNTU_ROOTFS_NPC_TTY_READER='$(UBUNTU_ROOTFS_NPC_TTY_READER)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER='$(UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER)' \
	UBUNTU_ROOTFS_NPC_TTY_READER_MODE='$(UBUNTU_ROOTFS_NPC_TTY_READER_MODE)' \
	UBUNTU_ROOTFS_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_NPC_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_NPC_GENERATOR_TRACE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE)' \
	UBUNTU_ROOTFS_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_NEMU_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE)' \
	UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS)' \
	UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1 UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
	  bash '$(SCRIPT_DIR)/build-ubuntu-rootfs.sh'
ubuntu-rootfs-full-image:
	UBUNTU_ROOTFS_FLAVOR=full \
	UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_FULL_IMAGE)' \
	UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_FULL_CPIO_IMAGE)' \
	UBUNTU_ROOTFS_WORK='$(UBUNTU_IMAGE_DIR)' \
	UBUNTU_ROOTFS_DIR='$(UBUNTU_ROOTFS_FULL_DIR)' \
	UBUNTU_ROOTFS_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_NPC_CONSOLE_SHELL)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL)' \
	UBUNTU_ROOTFS_NPC_TTY_READER='$(UBUNTU_ROOTFS_NPC_TTY_READER)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER='$(UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER)' \
	UBUNTU_ROOTFS_NPC_TTY_READER_MODE='$(UBUNTU_ROOTFS_NPC_TTY_READER_MODE)' \
	UBUNTU_ROOTFS_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_NPC_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_NPC_GENERATOR_TRACE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE)' \
	UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE)' \
	UBUNTU_ROOTFS_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_NEMU_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE)' \
	UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE)' \
	UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS)' \
	UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1 UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
	  bash '$(SCRIPT_DIR)/build-ubuntu-rootfs.sh'

ubuntu-rootfs-check check-ubuntu-rootfs: $(UBUNTU_ROOTFS_IMAGE) $(UBUNTU_ROOTFS_CPIO_IMAGE)
	UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_IMAGE)' \
	UBUNTU_ROOTFS_REQUIRE_SYSTEMD='$(if $(filter 1,$(UBUNTU_ROOTFS_REQUIRE_VT_AUTOLOGIN)),1,0)' \
	UBUNTU_ROOTFS_REQUIRE_VT_AUTOLOGIN='$(UBUNTU_ROOTFS_REQUIRE_VT_AUTOLOGIN)' \
	UBUNTU_ROOTFS_VT_AUTOLOGIN_USER='$(UBUNTU_ROOTFS_VT_AUTOLOGIN_USER)' \
	UBUNTU_ROOTFS_VT_AUTOLOGIN_TTY='$(UBUNTU_ROOTFS_VT_AUTOLOGIN_TTY)' \
	UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' \
	UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS)' \
	  bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'

check-ubuntu-rootfs-systemd:
	@if ! UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_IMAGE)' UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL)' UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER='$(UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER)' UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE)' UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE)' UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS)' UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
	  bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'; then \
	  printf '%s\n' '[Linux] rootfs check failed; rebuilding systemd-minimal image'; \
	  "$${MAKE:-make}" ubuntu-rootfs-systemd-image; \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_IMAGE)' UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL)' UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER='$(UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER)' UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE)' UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE)' UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS)' UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
	    bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'; \
	fi
check-ubuntu-rootfs-systemd-minimal: check-ubuntu-rootfs-systemd

check-ubuntu-rootfs-systemd-strict:
	@if ! UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_STRICT_IMAGE)' \
	  UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
	  UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=1 \
	  UBUNTU_ROOTFS_REQUIRE_NPC_STRICT_AUTORUN=1 \
	  UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS=disabled \
	  UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
	    bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'; then \
	  printf '%s\n' '[Linux] strict rootfs check failed; rebuilding strict image'; \
	  "$${MAKE:-make}" ubuntu-rootfs-systemd-strict-image; \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_STRICT_IMAGE)' \
	  UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
	  UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=1 \
	  UBUNTU_ROOTFS_REQUIRE_NPC_STRICT_AUTORUN=1 \
	  UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS=disabled \
	  UBUNTU_ROOTFS_FLAVOR=systemd-minimal \
	    bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'; \
	fi

check-ubuntu-rootfs-interactive:
	@if ! UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_INTERACTIVE_IMAGE)' UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL)' UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER='$(UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER)' UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE)' UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE)' UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS)' UBUNTU_ROOTFS_FLAVOR=interactive \
	  bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'; then \
	  printf '%s\n' '[Linux] rootfs check failed; rebuilding interactive image'; \
	  "$${MAKE:-make}" ubuntu-rootfs-interactive-image; \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_INTERACTIVE_IMAGE)' UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL)' UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER='$(UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER)' UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE)' UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE)' UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS)' UBUNTU_ROOTFS_FLAVOR=interactive \
	    bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'; \
	fi
check-ubuntu-rootfs-full:
	@if ! UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_FULL_IMAGE)' UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL)' UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER='$(UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER)' UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE)' UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE)' UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS)' UBUNTU_ROOTFS_FLAVOR=full \
	  bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'; then \
	  printf '%s\n' '[Linux] rootfs check failed; rebuilding full image'; \
	  "$${MAKE:-make}" ubuntu-rootfs-full-image; \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_FULL_IMAGE)' UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL)' UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER='$(UBUNTU_ROOTFS_REQUIRE_NPC_TTY_READER)' UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NPC_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_TRACE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_SKIP_MODE)' UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_REQUIRE_NPC_GENERATOR_REAL_MODE)' UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_REQUIRE_NEMU_LOGIN_MARKER)' UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_REQUIRE_NPC_PRESEED_SYSTEMD_UPDATE)' UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_EXPECT_NPC_SYSTEMD_GENERATORS)' UBUNTU_ROOTFS_FLAVOR=full \
	    bash '$(SCRIPT_DIR)/check-ubuntu-rootfs.sh'; \
	fi

check-nemu-tap-host:
	NEMU_TAP_HOST_ACTION=check \
	NEMU_TAP_IFNAME='$(NEMU_TAP_IFNAME)' \
	NEMU_TAP_OWNER='$(NEMU_TAP_OWNER)' \
	NEMU_TAP_HOST_IPV4_CIDR='$(NEMU_TAP_HOST_IPV4_CIDR)' \
	NEMU_TAP_GUEST_IPV4_CIDR='$(NEMU_TAP_GUEST_IPV4_CIDR)' \
	NEMU_TAP_GATEWAY='$(NEMU_TAP_GATEWAY)' \
	NEMU_TAP_DNS='$(NEMU_TAP_DNS)' \
	NEMU_TAP_NAT_SOURCE_CIDR='$(NEMU_TAP_NAT_SOURCE_CIDR)' \
	NEMU_TAP_UPLINK_IFACE='$(NEMU_TAP_UPLINK_IFACE)' \
	NEMU_TAP_ENABLE_NAT='$(NEMU_TAP_ENABLE_NAT)' \
	NEMU_TAP_REQUIRE_READY='$(NEMU_TAP_REQUIRE_READY)' \
	  bash '$(SCRIPT_DIR)/check-nemu-tap-host.sh'

show-nemu-tap-setup:
	NEMU_TAP_HOST_ACTION=setup-plan \
	NEMU_TAP_IFNAME='$(NEMU_TAP_IFNAME)' \
	NEMU_TAP_OWNER='$(NEMU_TAP_OWNER)' \
	NEMU_TAP_HOST_IPV4_CIDR='$(NEMU_TAP_HOST_IPV4_CIDR)' \
	NEMU_TAP_GUEST_IPV4_CIDR='$(NEMU_TAP_GUEST_IPV4_CIDR)' \
	NEMU_TAP_GATEWAY='$(NEMU_TAP_GATEWAY)' \
	NEMU_TAP_DNS='$(NEMU_TAP_DNS)' \
	NEMU_TAP_NAT_SOURCE_CIDR='$(NEMU_TAP_NAT_SOURCE_CIDR)' \
	NEMU_TAP_UPLINK_IFACE='$(NEMU_TAP_UPLINK_IFACE)' \
	NEMU_TAP_ENABLE_NAT='$(NEMU_TAP_ENABLE_NAT)' \
	  bash '$(SCRIPT_DIR)/check-nemu-tap-host.sh'

show-nemu-tap-teardown:
	NEMU_TAP_HOST_ACTION=teardown-plan \
	NEMU_TAP_IFNAME='$(NEMU_TAP_IFNAME)' \
	NEMU_TAP_OWNER='$(NEMU_TAP_OWNER)' \
	NEMU_TAP_HOST_IPV4_CIDR='$(NEMU_TAP_HOST_IPV4_CIDR)' \
	NEMU_TAP_GUEST_IPV4_CIDR='$(NEMU_TAP_GUEST_IPV4_CIDR)' \
	NEMU_TAP_GATEWAY='$(NEMU_TAP_GATEWAY)' \
	NEMU_TAP_DNS='$(NEMU_TAP_DNS)' \
	NEMU_TAP_NAT_SOURCE_CIDR='$(NEMU_TAP_NAT_SOURCE_CIDR)' \
	NEMU_TAP_UPLINK_IFACE='$(NEMU_TAP_UPLINK_IFACE)' \
	NEMU_TAP_ENABLE_NAT='$(NEMU_TAP_ENABLE_NAT)' \
	  bash '$(SCRIPT_DIR)/check-nemu-tap-host.sh'

check-npc-systemd-guest:
	+$(MAKE) ARCH=riscv64-npc BOOT=ubuntu-rootfs __check-npc-systemd-guest

check-npc-systemd-guest-full:
	+$(MAKE) ARCH=riscv64-npc BOOT=ubuntu-rootfs \
	  NPC_SYSTEMD_GUEST_COMMAND_MODE=uart \
	  NPC_SYSTEMD_UART_WAIT=__NPC_CONSOLE_SHELL_READY__ \
	  NPC_SYSTEMD_REQUIRE_PROMPT=0 \
	  NPC_SYSTEMD_STRICT_CHECK=1 \
	  NPC_SYSTEMD_GUEST_POWEROFF=1 \
	  __check-npc-systemd-guest

check-npc-systemd-guest-systemd-strict:
	+$(MAKE) ARCH=riscv64-npc BOOT=ubuntu-rootfs \
	  UBUNTU_ROOTFS_SYSTEMD_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_STRICT_IMAGE)' \
	  UBUNTU_ROOTFS_SYSTEMD_CPIO_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_STRICT_CPIO_IMAGE)' \
	  UBUNTU_ROOTFS_SYSTEMD_DIR='$(UBUNTU_ROOTFS_SYSTEMD_STRICT_DIR)' \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_SYSTEMD_STRICT_IMAGE)' \
	  UBUNTU_ROOTFS_NPC_CONSOLE_SHELL=1 \
	  UBUNTU_ROOTFS_REQUIRE_NPC_CONSOLE_SHELL=1 \
	  UBUNTU_ROOTFS_NPC_STRICT_AUTORUN=1 \
	  UBUNTU_ROOTFS_REQUIRE_NPC_STRICT_AUTORUN=1 \
	  NPC_SYSTEMD_GUEST_COMMAND_MODE=systemd-strict \
	  NPC_SYSTEMD_REQUIRE_PROMPT=0 \
	  NPC_SYSTEMD_STRICT_CHECK=1 \
	  NPC_SYSTEMD_GUEST_POWEROFF=1 \
	  __check-npc-systemd-guest

check-nemu-systemd-guest:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs __check-nemu-systemd-guest

check-nemu-reboot-loop:
	+$(MAKE) ARCH=riscv64-nemu __check-nemu-reboot-loop

check-nemu-virtio-blk-error:
	+$(MAKE) ARCH=riscv64-nemu __check-nemu-virtio-blk-error

check-nemu-reboot-persistence:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs __check-nemu-reboot-persistence

check-nemu-evolution:
	+$(MAKE) check-nemu-virtio-blk-error
	+$(MAKE) check-nemu-reboot-loop
	+$(MAKE) check-nemu-systemd-guest
	+$(MAKE) check-nemu-reboot-persistence

check-nemu-systemd-guest-tap:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  NEMU_TAP_REQUIRE_READY=1 \
	  check-nemu-tap-host
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  NEMU_SYSTEMD_NET_TAP='$(NEMU_TAP_IFNAME)' \
	  NEMU_SYSTEMD_TAP_IPV4_CIDR='$(NEMU_TAP_GUEST_IPV4_CIDR)' \
	  NEMU_SYSTEMD_TAP_GATEWAY='$(NEMU_TAP_GATEWAY)' \
	  NEMU_SYSTEMD_TAP_DNS='$(NEMU_TAP_DNS)' \
	  NEMU_SYSTEMD_TAP_PING_TARGET='$(NEMU_TAP_PING_TARGET)' \
	  NEMU_SYSTEMD_TAP_HTTP_URL='$(NEMU_TAP_HTTP_URL)' \
	  NEMU_SYSTEMD_TAP_REQUIRE_EXTERNAL='$(NEMU_TAP_REQUIRE_EXTERNAL)' \
	  NEMU_SYSTEMD_TAP_REQUIRE_PACKETS='$(NEMU_TAP_REQUIRE_PACKETS)' \
	  check-nemu-systemd-guest

check-nemu-systemd-guest-full-tap:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  NEMU_TAP_REQUIRE_READY=1 \
	  check-nemu-tap-host
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  NEMU_SYSTEMD_NET_TAP='$(NEMU_TAP_IFNAME)' \
	  NEMU_SYSTEMD_TAP_IPV4_CIDR='$(NEMU_TAP_GUEST_IPV4_CIDR)' \
	  NEMU_SYSTEMD_TAP_GATEWAY='$(NEMU_TAP_GATEWAY)' \
	  NEMU_SYSTEMD_TAP_DNS='$(NEMU_TAP_DNS)' \
	  NEMU_SYSTEMD_TAP_PING_TARGET='$(NEMU_TAP_PING_TARGET)' \
	  NEMU_SYSTEMD_TAP_HTTP_URL='$(NEMU_TAP_HTTP_URL)' \
	  NEMU_SYSTEMD_TAP_REQUIRE_EXTERNAL='$(NEMU_TAP_REQUIRE_EXTERNAL)' \
	  NEMU_SYSTEMD_TAP_REQUIRE_PACKETS='$(NEMU_TAP_REQUIRE_PACKETS)' \
	  check-nemu-systemd-guest-full

check-nemu-systemd-guest-interactive:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  UBUNTU_ROOTFS_FLAVOR=interactive \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_INTERACTIVE_IMAGE)' \
	  UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_INTERACTIVE_CPIO_IMAGE)' \
	  NEMU_SYSTEMD_ROOTFS_FLAVOR=interactive \
	  NEMU_SYSTEMD_CHECK_LOG_DIR='$(NEMU_SYSTEMD_INTERACTIVE_CHECK_LOG_DIR)' \
	  NEMU_SYSTEMD_ROOTFS_OVERLAY='$(NEMU_SYSTEMD_INTERACTIVE_CHECK_LOG_DIR)/rootfs-overlay.raw' \
	  __check-nemu-systemd-guest

check-nemu-systemd-guest-full:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  UBUNTU_ROOTFS_FLAVOR=full \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_FULL_IMAGE)' \
	  UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_FULL_CPIO_IMAGE)' \
	  NEMU_SYSTEMD_ROOTFS_FLAVOR=full \
	  NEMU_SYSTEMD_CHECK_LOG_DIR='$(NEMU_SYSTEMD_FULL_CHECK_LOG_DIR)' \
	  NEMU_SYSTEMD_ROOTFS_OVERLAY='$(NEMU_SYSTEMD_FULL_CHECK_LOG_DIR)/rootfs-overlay.raw' \
	  NEMU_SYSTEMD_CHECK_MAX_CYCLES='$(NEMU_SYSTEMD_FULL_CHECK_MAX_CYCLES)' \
	  NEMU_SYSTEMD_CHECK_TIMEOUT='$(NEMU_SYSTEMD_FULL_CHECK_TIMEOUT)' \
	  __check-nemu-systemd-guest

check-nemu-python-int-preflight:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  UBUNTU_ROOTFS_FLAVOR=full \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_FULL_IMAGE)' \
	  UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_FULL_CPIO_IMAGE)' \
	  NEMU_PYTHON_INT_CHECK_LOG_DIR='$(NEMU_PYTHON_INT_CHECK_LOG_DIR)' \
	  NEMU_PYTHON_INT_ROOTFS_OVERLAY='$(NEMU_PYTHON_INT_ROOTFS_OVERLAY)' \
	  NEMU_PYTHON_INT_CHECK_MAX_CYCLES='$(NEMU_PYTHON_INT_CHECK_MAX_CYCLES)' \
	  NEMU_PYTHON_INT_CHECK_TIMEOUT='$(NEMU_PYTHON_INT_CHECK_TIMEOUT)' \
	  NEMU_PYTHON_INT_BOOT_TIMEOUT='$(NEMU_PYTHON_INT_BOOT_TIMEOUT)' \
	  NEMU_PYTHON_INT_LOOPS='$(NEMU_PYTHON_INT_LOOPS)' \
	  NEMU_PYTHON_INT_STAGE_MODE='$(NEMU_PYTHON_INT_STAGE_MODE)' \
	  NEMU_PYTHON_INT_PROBE_MODE='$(NEMU_PYTHON_INT_PROBE_MODE)' \
	  NEMU_PYTHON_INT_STAGE_TIMEOUT='$(NEMU_PYTHON_INT_STAGE_TIMEOUT)' \
	  NEMU_PYTHON_INT_STAGE_PREWARM='$(NEMU_PYTHON_INT_STAGE_PREWARM)' \
	  NEMU_PYTHON_INT_TAGS='$(NEMU_PYTHON_INT_TAGS)' \
	  NEMU_PYTHON_INT_POWEROFF='$(NEMU_PYTHON_INT_POWEROFF)' \
	  __check-nemu-python-int-preflight

check-nemu-systemd-guest-full-soak:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
	  UBUNTU_ROOTFS_FLAVOR=full \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_FULL_IMAGE)' \
	  UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_FULL_CPIO_IMAGE)' \
	  NEMU_SYSTEMD_ROOTFS_FLAVOR=full \
	  NEMU_SYSTEMD_CHECK_LOG_DIR='$(NEMU_SYSTEMD_FULL_SOAK_CHECK_LOG_DIR)' \
	  NEMU_SYSTEMD_ROOTFS_OVERLAY='$(NEMU_SYSTEMD_FULL_SOAK_CHECK_LOG_DIR)/rootfs-overlay.raw' \
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

check-nemu-systemd-guest-long:
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
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
	+$(MAKE) ARCH=riscv64-nemu BOOT=ubuntu-rootfs \
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

check-nemu-kernel-config: $(LINUX_IMAGE)
	LINUX_KERNEL_CONFIG='$(LINUX_BUILD_DIR)/.config' \
	  bash '$(SCRIPT_DIR)/check-nemu-kernel-config.sh'

check-nemu-gui-config: nemu-linux-defconfig $(LINUX_IMAGE)
	$(PYTHON) '$(SCRIPT_DIR)/check-nemu-gui-config.py' \
	  --platform '$(PLATFORM_CONFIG)' \
	  --generic-map '$(NEMU_HOME)/include/platform/generic-map.h' \
	  --nemu-config '$(NEMU_CONFIG_DIR)/.config' \
	  --linux-config '$(LINUX_BUILD_DIR)/.config'
__check-nemu-virtio-input: sim
	NEMU_HOME='$(NEMU_HOME)' NEMU_CONFIG_DIR='$(NEMU_CONFIG_DIR)' \
	NEMU_SIM='$(NEMU_SIM)' \
	  bash '$(NEMU_HOME)/tests/check-virtio-input.sh'

__check-nemu-retirement-sdtrig: sim
	NEMU_HOME='$(NEMU_HOME)' NEMU_CONFIG_DIR='$(NEMU_CONFIG_DIR)' \
	NEMU_SIM='$(NEMU_SIM)' \
	  bash '$(NEMU_HOME)/tests/check-rv64-retirement-sdtrig.sh'

__check-nemu-gui: $(RUN_DEPS) check-nemu-performance-config check-nemu-kernel-config check-nemu-gui-config __check-nemu-virtio-input
	NEMU_HOME='$(NEMU_HOME)' \
	NEMU_SIM='$(NEMU_SIM)' \
	LINUX_IMAGE='$(LINUX_IMAGE)' \
	RUN_FW='$(RUN_FW)' \
	RUN_DTB='$(RUN_DTB)' \
	RUN_ROOTFS='$(RUN_ROOTFS)' \
	NEMU_GUI_LOG_DIR='$(NEMU_GUI_LOG_DIR)' \
	NEMU_GUI_ROOTFS_OVERLAY='$(NEMU_GUI_ROOTFS_OVERLAY)' \
	NEMU_GUI_SCREENSHOT='$(NEMU_GUI_SCREENSHOT)' \
	NEMU_GUI_CHECK_TIMEOUT='$(NEMU_GUI_CHECK_TIMEOUT)' \
	NEMU_GUI_BOOT_TIMEOUT='$(NEMU_GUI_BOOT_TIMEOUT)' \
	NEMU_GUI_POWEROFF_TIMEOUT='$(NEMU_GUI_POWEROFF_TIMEOUT)' \
	NEMU_GUI_MAX_CYCLES='$(NEMU_GUI_MAX_CYCLES)' \
	NEXT_ADDR='$(NEXT_ADDR)' DTB_ADDR='$(DTB_ADDR)' \
	  xvfb-run -a -s '-screen 0 1024x768x24' \
	  bash '$(SCRIPT_DIR)/check-nemu-gui.sh'

__check-npc-systemd-guest: $(RUN_DEPS)
	LOG_DIR='$(NPC_SYSTEMD_CHECK_LOG_DIR)' \
	CONSOLE_LOG='$(NPC_SYSTEMD_CHECK_LOG_DIR)/console.log' \
	NPC_LOG='$(NPC_SYSTEMD_CHECK_LOG_DIR)/npc.log' \
	NPC_SYSTEMD_CHECK_MAX_CYCLES='$(NPC_SYSTEMD_CHECK_MAX_CYCLES)' \
	NPC_SYSTEMD_HOST_TIMEOUT='$(NPC_SYSTEMD_HOST_TIMEOUT)' \
	NPC_SYSTEMD_PROMPT='$(NPC_SYSTEMD_PROMPT)' \
	NPC_SYSTEMD_UART_WAIT='$(NPC_SYSTEMD_UART_WAIT)' \
	NPC_SYSTEMD_UART_TRACE_LIMIT='$(NPC_SYSTEMD_UART_TRACE_LIMIT)' \
	NPC_SYSTEMD_UART_CYCLE_GAP='$(NPC_SYSTEMD_UART_CYCLE_GAP)' \
	NPC_SYSTEMD_GUEST_COMMAND_MODE='$(NPC_SYSTEMD_GUEST_COMMAND_MODE)' \
	NPC_SYSTEMD_PROGRESS='$(NPC_SYSTEMD_PROGRESS)' \
	NPC_SYSTEMD_REQUIRE_PROMPT='$(NPC_SYSTEMD_REQUIRE_PROMPT)' \
	NPC_SYSTEMD_STRICT_CHECK='$(NPC_SYSTEMD_STRICT_CHECK)' \
	NPC_SYSTEMD_GUEST_POWEROFF='$(NPC_SYSTEMD_GUEST_POWEROFF)' \
	NPC_SYSTEMD_ROOTFS_WORK_IMAGE='$(NPC_SYSTEMD_ROOTFS_WORK_IMAGE)' \
	NPC_SYSTEMD_ROOTFS_EXPECTED_TEMPLATE_SHA256='$(NPC_SYSTEMD_ROOTFS_EXPECTED_TEMPLATE_SHA256)' \
	NPC_SYSTEMD_TRANSACTION_EVIDENCE='$(NPC_SYSTEMD_TRANSACTION_EVIDENCE)' \
	NPC_SIM='$(NPC_SIM)' \
	LINUX_IMAGE='$(LINUX_IMAGE)' \
	RUN_FW='$(RUN_FW)' \
	RUN_DTB='$(RUN_DTB)' \
	RUN_ROOTFS='$(RUN_ROOTFS)' \
	NEXT_ADDR='$(NEXT_ADDR)' \
	DTB_ADDR='$(DTB_ADDR)' \
	  bash '$(SCRIPT_DIR)/check-npc-systemd-guest.sh'

__check-nemu-systemd-guest: $(RUN_DEPS) $(NEMU_SYSTEMD_ROOTFS_CHECK_TARGET) check-nemu-performance-config check-nemu-kernel-config
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
	NEMU_SYSTEMD_ROOTFS_OVERLAY='$(NEMU_SYSTEMD_ROOTFS_OVERLAY)' \
	NEMU_SYSTEMD_NET_BACKEND='$(NEMU_SYSTEMD_NET_BACKEND)' \
	NEMU_SYSTEMD_NET_TAP='$(NEMU_SYSTEMD_NET_TAP)' \
	NEMU_SYSTEMD_TAP_IPV4_CIDR='$(NEMU_SYSTEMD_TAP_IPV4_CIDR)' \
	NEMU_SYSTEMD_TAP_GATEWAY='$(NEMU_SYSTEMD_TAP_GATEWAY)' \
	NEMU_SYSTEMD_TAP_DNS='$(NEMU_SYSTEMD_TAP_DNS)' \
	NEMU_SYSTEMD_TAP_PING_TARGET='$(NEMU_SYSTEMD_TAP_PING_TARGET)' \
	NEMU_SYSTEMD_TAP_HTTP_URL='$(NEMU_SYSTEMD_TAP_HTTP_URL)' \
	NEMU_SYSTEMD_TAP_REQUIRE_EXTERNAL='$(NEMU_SYSTEMD_TAP_REQUIRE_EXTERNAL)' \
	NEMU_SYSTEMD_TAP_REQUIRE_PACKETS='$(NEMU_SYSTEMD_TAP_REQUIRE_PACKETS)' \
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
		NEMU_SYSTEMD_MIN_MEMTOTAL_KB='$(NEMU_SYSTEMD_MIN_MEMTOTAL_KB)' \
		NEMU_SYSTEMD_INPUT_DELAY='$(NEMU_SYSTEMD_INPUT_DELAY)' \
		NEMU_SYSTEMD_INPUT_CHUNK_BYTES='$(NEMU_SYSTEMD_INPUT_CHUNK_BYTES)' \
		NEMU_SYSTEMD_INPUT_CHUNK_DELAY='$(NEMU_SYSTEMD_INPUT_CHUNK_DELAY)' \
		NEMU_SYSTEMD_APT_INSTALL_DIAG='$(NEMU_SYSTEMD_APT_INSTALL_DIAG)' \
		NEMU_SYSTEMD_APT_INSTALL_ACTUAL='$(NEMU_SYSTEMD_APT_INSTALL_ACTUAL)' \
		NEMU_SYSTEMD_APT_INSTALL_DIAG_TIMEOUT='$(NEMU_SYSTEMD_APT_INSTALL_DIAG_TIMEOUT)' \
		NEMU_SYSTEMD_APT_REMOVE_DIAG_TIMEOUT='$(NEMU_SYSTEMD_APT_REMOVE_DIAG_TIMEOUT)' \
		NEMU_SYSTEMD_CRON_JOB_TIMEOUT='$(NEMU_SYSTEMD_CRON_JOB_TIMEOUT)' \
		NEMU_SYSTEMD_ANACRON_TIMEOUT='$(NEMU_SYSTEMD_ANACRON_TIMEOUT)' \
		NEMU_SYSTEMD_CALENDAR_TIMER_TIMEOUT='$(NEMU_SYSTEMD_CALENDAR_TIMER_TIMEOUT)' \
		NEMU_SYSTEMD_LOCALE_GEN_TIMEOUT='$(NEMU_SYSTEMD_LOCALE_GEN_TIMEOUT)' \
		NEMU_SYSTEMD_TIMEDATECTL_TIMEOUT='$(NEMU_SYSTEMD_TIMEDATECTL_TIMEOUT)' \
		NEMU_SYSTEMD_NETWORKD_DHCP_TIMEOUT='$(NEMU_SYSTEMD_NETWORKD_DHCP_TIMEOUT)' \
		NEMU_SYSTEMD_NETWORKD_WAIT_ONLINE_TIMEOUT='$(NEMU_SYSTEMD_NETWORKD_WAIT_ONLINE_TIMEOUT)' \
		NEMU_SYSTEMD_TIMESYNCD_NTP_TIMEOUT='$(NEMU_SYSTEMD_TIMESYNCD_NTP_TIMEOUT)' \
		NEMU_SYSTEMD_RESOLVED_DNS_TIMEOUT='$(NEMU_SYSTEMD_RESOLVED_DNS_TIMEOUT)' \
		  bash '$(SCRIPT_DIR)/check-nemu-systemd-guest.sh'

__check-nemu-reboot-loop: sim
	NEMU_HOME='$(NEMU_HOME)' \
	NEMU_SIM='$(NEMU_SIM)' \
	  bash '$(SCRIPT_DIR)/check-nemu-reboot-loop.sh'

__check-nemu-virtio-blk-error: sim ubuntu-rootfs-image
	+$(MAKE) -C '$(TOOLS_DIR)' \
	  NEMU_HOME='$(NEMU_HOME)' NEMU_BUILD_JOBS='$(JOBS)' TOOL_PLATFORM=nemu \
	  VIRTIO_BLK_IMAGE='$(UBUNTU_ROOTFS_IMAGE)' smoke-nemu-virtio-blk-error

__check-nemu-reboot-persistence: $(RUN_DEPS) $(NEMU_SYSTEMD_ROOTFS_CHECK_TARGET) check-nemu-performance-config check-nemu-kernel-config
	NEMU_HOME='$(NEMU_HOME)' \
	NEMU_SIM='$(NEMU_SIM)' \
	NEMU_REBOOT_LOOP='$(SCRIPT_DIR)/run-nemu-reboot-loop.sh' \
	LINUX_IMAGE='$(LINUX_IMAGE)' \
	RUN_FW='$(RUN_FW)' \
	RUN_DTB='$(RUN_DTB)' \
	RUN_ROOTFS='$(RUN_ROOTFS)' \
	NEXT_ADDR='$(NEXT_ADDR)' \
	DTB_ADDR='$(DTB_ADDR)' \
	NEMU_REBOOT_EXIT_CODE=32 \
	NEMU_REBOOT_PERSIST_LOG_DIR='$(NEMU_REBOOT_PERSIST_LOG_DIR)' \
	NEMU_REBOOT_PERSIST_ROOTFS_OVERLAY='$(NEMU_REBOOT_PERSIST_ROOTFS_OVERLAY)' \
	NEMU_REBOOT_PERSIST_TIMEOUT='$(NEMU_REBOOT_PERSIST_TIMEOUT)' \
	NEMU_REBOOT_PERSIST_BOOT_TIMEOUT='$(NEMU_REBOOT_PERSIST_BOOT_TIMEOUT)' \
	NEMU_REBOOT_PERSIST_POWEROFF_TIMEOUT='$(NEMU_REBOOT_PERSIST_POWEROFF_TIMEOUT)' \
	NEMU_REBOOT_PERSIST_FIFO_TIMEOUT='$(NEMU_REBOOT_PERSIST_FIFO_TIMEOUT)' \
	NEMU_REBOOT_PERSIST_MAX_INSTS='$(NEMU_REBOOT_PERSIST_MAX_INSTS)' \
	NEMU_REBOOT_PERSIST_INPUT_CHUNK_BYTES='$(NEMU_REBOOT_PERSIST_INPUT_CHUNK_BYTES)' \
	NEMU_REBOOT_PERSIST_INPUT_CHUNK_DELAY='$(NEMU_REBOOT_PERSIST_INPUT_CHUNK_DELAY)' \
	NEMU_REBOOT_PERSIST_INPUT_LINE_DELAY='$(NEMU_REBOOT_PERSIST_INPUT_LINE_DELAY)' \
	  bash '$(SCRIPT_DIR)/check-nemu-reboot-persistence.sh'

__check-nemu-python-int-preflight: $(RUN_DEPS) check-ubuntu-rootfs-full check-nemu-performance-config check-nemu-kernel-config
	LOG_DIR='$(NEMU_PYTHON_INT_CHECK_LOG_DIR)' \
	LOG_FILE='$(NEMU_PYTHON_INT_CHECK_LOG_DIR)/nemu.log' \
	CONSOLE_LOG='$(NEMU_PYTHON_INT_CHECK_LOG_DIR)/console.log' \
	NEMU_SERIAL_FIFO='$(NEMU_PYTHON_INT_CHECK_LOG_DIR)/nemu.serial' \
	NEMU_HOME='$(NEMU_HOME)' \
	NEMU_SIM='$(NEMU_SIM)' \
	LINUX_IMAGE='$(LINUX_IMAGE)' \
	RUN_FW='$(RUN_FW)' \
	RUN_DTB='$(RUN_DTB)' \
	RUN_ROOTFS='$(RUN_ROOTFS)' \
	NEMU_PYTHON_INT_ROOTFS_OVERLAY='$(NEMU_PYTHON_INT_ROOTFS_OVERLAY)' \
	NEXT_ADDR='$(NEXT_ADDR)' \
	DTB_ADDR='$(DTB_ADDR)' \
	MAX_CYCLES='$(NEMU_PYTHON_INT_CHECK_MAX_CYCLES)' \
	NEMU_PYTHON_INT_CHECK_TIMEOUT='$(NEMU_PYTHON_INT_CHECK_TIMEOUT)' \
	NEMU_PYTHON_INT_BOOT_TIMEOUT='$(NEMU_PYTHON_INT_BOOT_TIMEOUT)' \
	NEMU_PYTHON_INT_LOOPS='$(NEMU_PYTHON_INT_LOOPS)' \
	NEMU_PYTHON_INT_STAGE_MODE='$(NEMU_PYTHON_INT_STAGE_MODE)' \
	NEMU_PYTHON_INT_PROBE_MODE='$(NEMU_PYTHON_INT_PROBE_MODE)' \
	NEMU_PYTHON_INT_STAGE_TIMEOUT='$(NEMU_PYTHON_INT_STAGE_TIMEOUT)' \
	NEMU_PYTHON_INT_STAGE_PREWARM='$(NEMU_PYTHON_INT_STAGE_PREWARM)' \
	NEMU_PYTHON_INT_TAGS='$(NEMU_PYTHON_INT_TAGS)' \
	NEMU_PYTHON_INT_POWEROFF='$(NEMU_PYTHON_INT_POWEROFF)' \
	  bash '$(SCRIPT_DIR)/check-nemu-python-int-preflight.sh'

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

# PROFILE_STAMP 是已成功消费对应输入的承诺，只允许 build-linux.sh 在
# canonical O= lock 内、Image 验证成功后发布。FORCE 让脚本在锁内比较
# payload 并走轻量 current fast-path；Make 自身不预写成功 stamp。
$(LINUX_FEATURE_PROFILE_STAMP): FORCE $(LINUX_SOURCE_INPUTS)
	LINUX_PLATFORM='$(LINUX_PLATFORM)' \
	LINUX_BUILD_DIR='$(LINUX_BUILD_DIR)' \
	LINUX_EXPECTED_IMAGE='$(LINUX_IMAGE)' \
	LINUX_FEATURE_PROFILE='$(LINUX_FEATURE_PROFILE)' \
	LINUX_FEATURE_PROFILE_STAMP='$(LINUX_FEATURE_PROFILE_STAMP)' \
	LINUX_ROOT='$(LINUX_ROOT)' \
	LINUX_REF='$(LINUX_REF)' \
	LINUX_PATCH='$(LINUX_PATCH)' \
	CROSS_COMPILE='$(LINUX_CROSS_COMPILE)' \
	LINUX_STAMP_PLATFORM='$(LINUX_PLATFORM)' \
	LINUX_STAMP_FEATURE_PROFILE='$(LINUX_FEATURE_PROFILE)' \
	LINUX_STAMP_ROOT='$(LINUX_ROOT)' \
	LINUX_STAMP_REF='$(LINUX_REF)' \
	LINUX_STAMP_PATCH='$(LINUX_PATCH)' \
	LINUX_STAMP_CROSS_COMPILE='$(LINUX_CROSS_COMPILE)' \
	LINUX_STAMP_BUILD_DIR='$(LINUX_BUILD_DIR)' \
	  bash '$(SCRIPT_DIR)/build-linux.sh'

$(LINUX_IMAGE): $(LINUX_FEATURE_PROFILE_STAMP)

$(BUSYBOX_INITRD):
	INITRAMFS_WORK='$(INITRAMFS_IMAGE_DIR)' \
	INITRAMFS_OUT='$(BUSYBOX_INITRD)' \
	  bash '$(SCRIPT_DIR)/build-busybox-initramfs.sh'

$(UBUNTU_PROBE_INITRD):
	UBUNTU_INIT_MODE=syscall UBUNTU_INITRAMFS_PROFILE=probe \
	  UBUNTU_ROOTFS_WORK='$(UBUNTU_IMAGE_DIR)' \
	  UBUNTU_INITRD_IMAGE='$(UBUNTU_PROBE_INITRD)' \
	  bash '$(SCRIPT_DIR)/build-ubuntu-base-initramfs.sh'

$(UBUNTU_SHELL_INITRD):
	UBUNTU_INIT_MODE=shell UBUNTU_INITRAMFS_PROFILE=full \
	  UBUNTU_ROOTFS_WORK='$(UBUNTU_IMAGE_DIR)' \
	  UBUNTU_INITRD_IMAGE='$(UBUNTU_SHELL_INITRD)' \
	  bash '$(SCRIPT_DIR)/build-ubuntu-base-initramfs.sh'

$(UBUNTU_ROOTFS_BUILD_STAMP): FORCE $(UBUNTU_ROOTFS_PROFILE_INPUTS)
	@set -e -o pipefail; expected=$$(mktemp); \
	  cleanup_expected() { status=$$?; trap - EXIT HUP INT TERM; \
	    rm -f -- "$$expected"; exit "$$status"; }; \
	  trap cleanup_expected EXIT; \
	  trap 'exit 129' HUP; trap 'exit 130' INT; trap 'exit 143' TERM; \
	  source_hash=$$(sha256sum $(foreach input,$(UBUNTU_ROOTFS_PROFILE_INPUTS),'$(input)') | sha256sum | cut -d ' ' -f1); \
	  printf '%s\n' \
	  'YSYX_LINUX_ENV_ROOT=$(ENV_ROOT)' \
	  'UBUNTU_RELEASE=$(UBUNTU_RELEASE)' \
	  'UBUNTU_BASE_VERSION=$(UBUNTU_BASE_VERSION)' \
	  'UBUNTU_ARCH=$(UBUNTU_ARCH)' \
	  'UBUNTU_MIRROR=$(UBUNTU_MIRROR)' \
	  'UBUNTU_BASE_URL=$(UBUNTU_BASE_URL)' \
	  'UBUNTU_ROOTFS_FLAVOR=$(UBUNTU_ROOTFS_FLAVOR)' \
	  'UBUNTU_ROOTFS_ARTIFACT_SUFFIX=$(UBUNTU_ROOTFS_ARTIFACT_SUFFIX)' \
	  'UBUNTU_ROOTFS_WORK=$(UBUNTU_ROOTFS_WORK)' \
	  'UBUNTU_ROOTFS_IMAGE=$(UBUNTU_ROOTFS_IMAGE)' \
	  'UBUNTU_ROOTFS_CPIO_IMAGE=$(UBUNTU_ROOTFS_CPIO_IMAGE)' \
	  'UBUNTU_ROOTFS_DIR=$(UBUNTU_ROOTFS_DIR)' \
	  'UBUNTU_ROOTFS_IMAGE_SIZE=$(UBUNTU_ROOTFS_IMAGE_SIZE)' \
	  'UBUNTU_ROOTFS_INCLUDE=$(UBUNTU_ROOTFS_INCLUDE)' \
	  'UBUNTU_DEBOOTSTRAP_VARIANT=$(UBUNTU_DEBOOTSTRAP_VARIANT)' \
	  'UBUNTU_ROOTFS_SERIAL_AUTOLOGIN=$(UBUNTU_ROOTFS_SERIAL_AUTOLOGIN)' \
	  'UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_USER=$(UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_USER)' \
	  'UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_TTYS=$(UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_TTYS)' \
	  'UBUNTU_ROOTFS_VT_AUTOLOGIN=$(UBUNTU_ROOTFS_VT_AUTOLOGIN)' \
	  'UBUNTU_ROOTFS_VT_AUTOLOGIN_USER=$(UBUNTU_ROOTFS_VT_AUTOLOGIN_USER)' \
	  'UBUNTU_ROOTFS_VT_AUTOLOGIN_TTY=$(UBUNTU_ROOTFS_VT_AUTOLOGIN_TTY)' \
	  'UBUNTU_ROOTFS_SERIAL_MASK_TTYS=$(UBUNTU_ROOTFS_SERIAL_MASK_TTYS)' \
	  'UBUNTU_ROOTFS_STATIC_INIT=$(UBUNTU_ROOTFS_STATIC_INIT)' \
	  'UBUNTU_ROOTFS_INIT_SRC=$(UBUNTU_ROOTFS_INIT_SRC)' \
	  'UBUNTU_ROOTFS_PROBE=$(UBUNTU_ROOTFS_PROBE)' \
	  'UBUNTU_ROOTFS_PROBE_SRC=$(UBUNTU_ROOTFS_PROBE_SRC)' \
	  'UBUNTU_ROOTFS_NPC_TTY_PROBE_SRC=$(UBUNTU_ROOTFS_NPC_TTY_PROBE_SRC)' \
	  'UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_SRC=$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_SRC)' \
	  'UBUNTU_ROOTFS_NPC_STRICT_CHECK_SRC=$(UBUNTU_ROOTFS_NPC_STRICT_CHECK_SRC)' \
	  'UBUNTU_BASE_TARBALL=$(UBUNTU_BASE_TARBALL)' \
	  'UBUNTU_BASE_SHA_FILE=$(UBUNTU_BASE_SHA_FILE)' \
	  'UBUNTU_ROOTFS_NEMU_LOGIN_MARKER=$(UBUNTU_ROOTFS_NEMU_LOGIN_MARKER)' \
	  'UBUNTU_ROOTFS_NPC_CONSOLE_SHELL=$(UBUNTU_ROOTFS_NPC_CONSOLE_SHELL)' \
	  'UBUNTU_ROOTFS_NPC_TTY_READER=$(UBUNTU_ROOTFS_NPC_TTY_READER)' \
	  'UBUNTU_ROOTFS_NPC_TTY_READER_MODE=$(UBUNTU_ROOTFS_NPC_TTY_READER_MODE)' \
	  'UBUNTU_ROOTFS_NPC_STRICT_AUTORUN=$(UBUNTU_ROOTFS_NPC_STRICT_AUTORUN)' \
	  'UBUNTU_ROOTFS_NPC_LOGIN_MARKER=$(UBUNTU_ROOTFS_NPC_LOGIN_MARKER)' \
	  'UBUNTU_ROOTFS_NPC_LOGIN_TRACE=$(UBUNTU_ROOTFS_NPC_LOGIN_TRACE)' \
	  'UBUNTU_ROOTFS_NPC_GENERATOR_TRACE=$(UBUNTU_ROOTFS_NPC_GENERATOR_TRACE)' \
	  'UBUNTU_ROOTFS_NPC_GENERATOR_SKIP=$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP)' \
	  'UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE=$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE)' \
	  'UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE=$(UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE)' \
	  'UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE=$(UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE)' \
	  'UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS=$(UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS)' \
	  'UBUNTU_ROOTFS_FLAVOR_SCRIPT=$(UBUNTU_ROOTFS_FLAVOR_SCRIPT)' \
	  'UBUNTU_ROOTFS_SYSTEMD_OVERLAY_SCRIPT=$(UBUNTU_ROOTFS_SYSTEMD_OVERLAY_SCRIPT)' \
	  'UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1' \
	  'UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1' \
	  'CROSS_COMPILE=$(UBUNTU_ROOTFS_CROSS_COMPILE)' \
	  'CC=$(UBUNTU_ROOTFS_CC)' \
	  "UBUNTU_ROOTFS_SOURCE_SHA256=$$source_hash" > "$$expected"; \
	  YSYX_LINUX_ENV_ROOT='$(ENV_ROOT)' \
	  UBUNTU_RELEASE='$(UBUNTU_RELEASE)' \
	  UBUNTU_BASE_VERSION='$(UBUNTU_BASE_VERSION)' \
	  UBUNTU_ARCH='$(UBUNTU_ARCH)' \
	  UBUNTU_MIRROR='$(UBUNTU_MIRROR)' \
	  UBUNTU_BASE_URL='$(UBUNTU_BASE_URL)' \
	  UBUNTU_ROOTFS_FLAVOR='$(UBUNTU_ROOTFS_FLAVOR)' \
	  UBUNTU_ROOTFS_ARTIFACT_SUFFIX='$(UBUNTU_ROOTFS_ARTIFACT_SUFFIX)' \
	  UBUNTU_ROOTFS_WORK='$(UBUNTU_ROOTFS_WORK)' \
	  UBUNTU_ROOTFS_IMAGE='$(UBUNTU_ROOTFS_IMAGE)' \
	  UBUNTU_ROOTFS_CPIO_IMAGE='$(UBUNTU_ROOTFS_CPIO_IMAGE)' \
	  UBUNTU_ROOTFS_DIR='$(UBUNTU_ROOTFS_DIR)' \
	  UBUNTU_ROOTFS_IMAGE_SIZE='$(UBUNTU_ROOTFS_IMAGE_SIZE)' \
	  UBUNTU_ROOTFS_INCLUDE='$(UBUNTU_ROOTFS_INCLUDE)' \
	  UBUNTU_DEBOOTSTRAP_VARIANT='$(UBUNTU_DEBOOTSTRAP_VARIANT)' \
	  UBUNTU_ROOTFS_SERIAL_AUTOLOGIN='$(UBUNTU_ROOTFS_SERIAL_AUTOLOGIN)' \
	  UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_USER='$(UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_USER)' \
	  UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_TTYS='$(UBUNTU_ROOTFS_SERIAL_AUTOLOGIN_TTYS)' \
	  UBUNTU_ROOTFS_VT_AUTOLOGIN='$(UBUNTU_ROOTFS_VT_AUTOLOGIN)' \
	  UBUNTU_ROOTFS_VT_AUTOLOGIN_USER='$(UBUNTU_ROOTFS_VT_AUTOLOGIN_USER)' \
	  UBUNTU_ROOTFS_VT_AUTOLOGIN_TTY='$(UBUNTU_ROOTFS_VT_AUTOLOGIN_TTY)' \
	  UBUNTU_ROOTFS_SERIAL_MASK_TTYS='$(UBUNTU_ROOTFS_SERIAL_MASK_TTYS)' \
	  UBUNTU_ROOTFS_STATIC_INIT='$(UBUNTU_ROOTFS_STATIC_INIT)' \
	  UBUNTU_ROOTFS_INIT_SRC='$(UBUNTU_ROOTFS_INIT_SRC)' \
	  UBUNTU_ROOTFS_PROBE='$(UBUNTU_ROOTFS_PROBE)' \
	  UBUNTU_ROOTFS_PROBE_SRC='$(UBUNTU_ROOTFS_PROBE_SRC)' \
	  UBUNTU_ROOTFS_NPC_TTY_PROBE_SRC='$(UBUNTU_ROOTFS_NPC_TTY_PROBE_SRC)' \
	  UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_SRC='$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_SRC)' \
	  UBUNTU_ROOTFS_NPC_STRICT_CHECK_SRC='$(UBUNTU_ROOTFS_NPC_STRICT_CHECK_SRC)' \
	  UBUNTU_BASE_TARBALL='$(UBUNTU_BASE_TARBALL)' \
	  UBUNTU_BASE_SHA_FILE='$(UBUNTU_BASE_SHA_FILE)' \
	  UBUNTU_ROOTFS_NEMU_LOGIN_MARKER='$(UBUNTU_ROOTFS_NEMU_LOGIN_MARKER)' \
	  UBUNTU_ROOTFS_NPC_CONSOLE_SHELL='$(UBUNTU_ROOTFS_NPC_CONSOLE_SHELL)' \
	  UBUNTU_ROOTFS_NPC_TTY_READER='$(UBUNTU_ROOTFS_NPC_TTY_READER)' \
	  UBUNTU_ROOTFS_NPC_TTY_READER_MODE='$(UBUNTU_ROOTFS_NPC_TTY_READER_MODE)' \
	  UBUNTU_ROOTFS_NPC_STRICT_AUTORUN='$(UBUNTU_ROOTFS_NPC_STRICT_AUTORUN)' \
	  UBUNTU_ROOTFS_NPC_LOGIN_MARKER='$(UBUNTU_ROOTFS_NPC_LOGIN_MARKER)' \
	  UBUNTU_ROOTFS_NPC_LOGIN_TRACE='$(UBUNTU_ROOTFS_NPC_LOGIN_TRACE)' \
	  UBUNTU_ROOTFS_NPC_GENERATOR_TRACE='$(UBUNTU_ROOTFS_NPC_GENERATOR_TRACE)' \
	  UBUNTU_ROOTFS_NPC_GENERATOR_SKIP='$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP)' \
	  UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE='$(UBUNTU_ROOTFS_NPC_GENERATOR_SKIP_MODE)' \
	  UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE='$(UBUNTU_ROOTFS_NPC_GENERATOR_REAL_MODE)' \
	  UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE='$(UBUNTU_ROOTFS_NPC_PRESEED_SYSTEMD_UPDATE)' \
	  UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS='$(UBUNTU_ROOTFS_NPC_DISABLE_SYSTEMD_GENERATORS)' \
	  UBUNTU_ROOTFS_FLAVOR_SCRIPT='$(UBUNTU_ROOTFS_FLAVOR_SCRIPT)' \
	  UBUNTU_ROOTFS_SYSTEMD_OVERLAY_SCRIPT='$(UBUNTU_ROOTFS_SYSTEMD_OVERLAY_SCRIPT)' \
	  UBUNTU_ROOTFS_SYSTEMD_OVERLAY=1 \
	  UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 \
	  UBUNTU_ROOTFS_BUILD_STAMP='$@' \
	  UBUNTU_ROOTFS_EXPECTED_PROFILE_STAMP="$$expected" \
	  CROSS_COMPILE='$(UBUNTU_ROOTFS_CROSS_COMPILE)' \
	  CC='$(UBUNTU_ROOTFS_CC)' \
	    bash '$(SCRIPT_DIR)/build-ubuntu-rootfs.sh'; \
	  rm -f -- "$$expected"; expected=; trap - EXIT HUP INT TERM

$(UBUNTU_ROOTFS_IMAGE) $(UBUNTU_ROOTFS_CPIO_IMAGE) &: $(UBUNTU_ROOTFS_BUILD_STAMP)
	@test -s '$(UBUNTU_ROOTFS_IMAGE)'
	@test -s '$(UBUNTU_ROOTFS_CPIO_IMAGE)'

$(BUILD_DIR):
	mkdir -p '$@'

$(BUILD_DIR)/generated:
	mkdir -p '$@'

$(DTB_BOOTARGS_STAMP_DIR):
	mkdir -p '$@'

# 每个 DTB 与其 profile stamp 是一个 grouped transaction。脚本在同一组
# canonical resource locks 内完成 current 比较、DTS/DTB 校验和 stamp-last 发布。
$(KERNEL_DTB) $(KERNEL_DTB_BOOTARGS_STAMP) &: FORCE $(SCRIPT_DIR)/build-dtb.sh $(GEN_DTS) $(PLATFORM_CONFIG) $(PLATFORM_CONFIG_COMMON) | $(BUILD_DIR) $(BUILD_DIR)/generated $(DTB_BOOTARGS_STAMP_DIR)
	@bash '$(SCRIPT_DIR)/build-dtb.sh' \
	  --build-dir '$(BUILD_DIR)' \
	  --dtb '$(KERNEL_DTB)' \
	  --dts '$(BUILD_DIR)/generated/npc-rv64.dts' \
	  --stamp '$(KERNEL_DTB_BOOTARGS_STAMP)' \
	  --python '$(PYTHON)' --dtc '$(DTC)' \
	  --input '$(GEN_DTS)' --input '$(PLATFORM_CONFIG)' --input '$(PLATFORM_CONFIG_COMMON)' \
	  --profile 'TARGET=kernel' --profile 'BOOTARGS_EXTRA=$(BOOTARGS_EXTRA)' -- \
	  '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode kernel \
	  --bootargs-extra '$(BOOTARGS_EXTRA)'

$(BUSYBOX_INITRAMFS_DTB) $(BUSYBOX_INITRAMFS_DTB_BOOTARGS_STAMP) &: FORCE $(SCRIPT_DIR)/build-dtb.sh $(GEN_DTS) $(PLATFORM_CONFIG) $(PLATFORM_CONFIG_COMMON) $(BUSYBOX_INITRD) | $(BUILD_DIR) $(BUILD_DIR)/generated $(DTB_BOOTARGS_STAMP_DIR)
	@bash '$(SCRIPT_DIR)/build-dtb.sh' \
	  --build-dir '$(BUILD_DIR)' \
	  --dtb '$(BUSYBOX_INITRAMFS_DTB)' \
	  --dts '$(BUILD_DIR)/generated/npc-rv64-initramfs.dts' \
	  --stamp '$(BUSYBOX_INITRAMFS_DTB_BOOTARGS_STAMP)' \
	  --python '$(PYTHON)' --dtc '$(DTC)' \
	  --input '$(GEN_DTS)' --input '$(PLATFORM_CONFIG)' --input '$(PLATFORM_CONFIG_COMMON)' \
	  --input '$(BUSYBOX_INITRD)' \
	  --profile 'TARGET=busybox-initramfs' --profile 'BOOTARGS_EXTRA=$(BOOTARGS_EXTRA)' -- \
	  '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode initramfs \
	  --bootargs-extra '$(BOOTARGS_EXTRA)' \
	  --initrd-image '$(BUSYBOX_INITRD)'

$(UBUNTU_PROBE_DTB) $(UBUNTU_PROBE_DTB_BOOTARGS_STAMP) &: FORCE $(SCRIPT_DIR)/build-dtb.sh $(GEN_DTS) $(PLATFORM_CONFIG) $(PLATFORM_CONFIG_COMMON) $(UBUNTU_PROBE_INITRD) | $(BUILD_DIR) $(BUILD_DIR)/generated $(DTB_BOOTARGS_STAMP_DIR)
	@bash '$(SCRIPT_DIR)/build-dtb.sh' \
	  --build-dir '$(BUILD_DIR)' \
	  --dtb '$(UBUNTU_PROBE_DTB)' \
	  --dts '$(BUILD_DIR)/generated/npc-rv64-ubuntu-initramfs.dts' \
	  --stamp '$(UBUNTU_PROBE_DTB_BOOTARGS_STAMP)' \
	  --python '$(PYTHON)' --dtc '$(DTC)' \
	  --input '$(GEN_DTS)' --input '$(PLATFORM_CONFIG)' --input '$(PLATFORM_CONFIG_COMMON)' \
	  --input '$(UBUNTU_PROBE_INITRD)' \
	  --profile 'TARGET=ubuntu-probe-initramfs' --profile 'BOOTARGS_EXTRA=$(BOOTARGS_EXTRA)' -- \
	  '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode initramfs \
	  --bootargs-key ubuntu_initramfs \
	  --bootargs-extra '$(BOOTARGS_EXTRA)' \
	  --initrd-image '$(UBUNTU_PROBE_INITRD)' \
	  --memory-size 0x08000000

$(UBUNTU_SHELL_DTB) $(UBUNTU_SHELL_DTB_BOOTARGS_STAMP) &: FORCE $(SCRIPT_DIR)/build-dtb.sh $(GEN_DTS) $(PLATFORM_CONFIG) $(PLATFORM_CONFIG_COMMON) $(UBUNTU_SHELL_INITRD) | $(BUILD_DIR) $(BUILD_DIR)/generated $(DTB_BOOTARGS_STAMP_DIR)
	@bash '$(SCRIPT_DIR)/build-dtb.sh' \
	  --build-dir '$(BUILD_DIR)' \
	  --dtb '$(UBUNTU_SHELL_DTB)' \
	  --dts '$(BUILD_DIR)/generated/npc-rv64-ubuntu-shell-initramfs.dts' \
	  --stamp '$(UBUNTU_SHELL_DTB_BOOTARGS_STAMP)' \
	  --python '$(PYTHON)' --dtc '$(DTC)' \
	  --input '$(GEN_DTS)' --input '$(PLATFORM_CONFIG)' --input '$(PLATFORM_CONFIG_COMMON)' \
	  --input '$(UBUNTU_SHELL_INITRD)' \
	  --profile 'TARGET=ubuntu-shell-initramfs' --profile 'BOOTARGS_EXTRA=$(BOOTARGS_EXTRA)' -- \
	  '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode initramfs \
	  --bootargs-key ubuntu_initramfs \
	  --bootargs-extra '$(BOOTARGS_EXTRA)' \
	  --initrd-image '$(UBUNTU_SHELL_INITRD)' \
	  --memory-size 0x10000000

$(NPC_ROOTFS_DTB) $(NPC_ROOTFS_DTB_BOOTARGS_STAMP) &: FORCE $(SCRIPT_DIR)/build-dtb.sh $(GEN_DTS) $(PLATFORM_CONFIG) $(PLATFORM_CONFIG_COMMON) | $(BUILD_DIR) $(BUILD_DIR)/generated $(DTB_BOOTARGS_STAMP_DIR)
	@bash '$(SCRIPT_DIR)/build-dtb.sh' \
	  --build-dir '$(BUILD_DIR)' \
	  --dtb '$(NPC_ROOTFS_DTB)' \
	  --dts '$(BUILD_DIR)/generated/npc-rv64-rootfs.dts' \
	  --stamp '$(NPC_ROOTFS_DTB_BOOTARGS_STAMP)' \
	  --python '$(PYTHON)' --dtc '$(DTC)' \
	  --input '$(GEN_DTS)' --input '$(PLATFORM_CONFIG)' --input '$(PLATFORM_CONFIG_COMMON)' \
	  --profile 'TARGET=npc-rootfs' --profile 'NPC_ROOTFS_BOOTARGS=$(NPC_ROOTFS_BOOTARGS)' \
	  --profile 'BOOTARGS_EXTRA=$(BOOTARGS_EXTRA)' -- \
	  '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode rootfs \
	  --reset-syscon \
	  --bootargs-override '$(NPC_ROOTFS_BOOTARGS)' \
	  --bootargs-extra '$(BOOTARGS_EXTRA)'

$(NEMU_ROOTFS_DTB) $(NEMU_ROOTFS_DTB_BOOTARGS_STAMP) &: FORCE $(SCRIPT_DIR)/build-dtb.sh $(GEN_DTS) $(PLATFORM_CONFIG) $(PLATFORM_CONFIG_COMMON) | $(BUILD_DIR) $(BUILD_DIR)/generated $(DTB_BOOTARGS_STAMP_DIR)
	@bash '$(SCRIPT_DIR)/build-dtb.sh' \
	  --build-dir '$(BUILD_DIR)' \
	  --dtb '$(NEMU_ROOTFS_DTB)' \
	  --dts '$(BUILD_DIR)/generated/npc-rv64-nemu-rootfs.dts' \
	  --stamp '$(NEMU_ROOTFS_DTB_BOOTARGS_STAMP)' \
	  --python '$(PYTHON)' --dtc '$(DTC)' \
	  --input '$(GEN_DTS)' --input '$(PLATFORM_CONFIG)' --input '$(PLATFORM_CONFIG_COMMON)' \
	  --profile 'TARGET=nemu-rootfs' \
	  --profile 'BOOTARGS_EXTRA=$(BOOTARGS_EXTRA)' \
	  --profile 'NEMU_ROOTFS_BOOTARGS_EXTRA=$(NEMU_ROOTFS_BOOTARGS_EXTRA)' \
	  --profile 'NEMU_DISPLAY=$(NEMU_DISPLAY)' \
	  --profile 'NEMU_VIRTIO_INPUT=$(NEMU_VIRTIO_INPUT)' -- \
	  '$(GEN_DTS)' --config '$(PLATFORM_CONFIG)' --mode rootfs \
	  --reset-syscon \
	  $(if $(filter 1,$(NEMU_DISPLAY)),--simple-framebuffer,) \
	  $(if $(filter 1,$(NEMU_VIRTIO_INPUT)),--virtio-input,) \
	  --virtio-rng \
	  --virtio-net \
	  --goldfish-rtc \
	  --bootargs-extra '$(BOOTARGS_EXTRA) $(NEMU_ROOTFS_BOOTARGS_EXTRA)'

$(OPENSBI_PROFILE_STAMP): private OPENSBI_TARGET_DTB := $(KERNEL_DTB)
$(OPENSBI_PROFILE_STAMP): private OPENSBI_TARGET_BUILD_DIR := $(OPENSBI_BUILD_DIR)
$(OPENSBI_PROFILE_STAMP): private OPENSBI_TARGET_FW := $(OPENSBI_FW)
$(OPENSBI_PROFILE_STAMP): $(KERNEL_DTB)
$(OPENSBI_BUSYBOX_PROFILE_STAMP): private OPENSBI_TARGET_DTB := $(BUSYBOX_INITRAMFS_DTB)
$(OPENSBI_BUSYBOX_PROFILE_STAMP): private OPENSBI_TARGET_BUILD_DIR := $(OPENSBI_BUSYBOX_BUILD_DIR)
$(OPENSBI_BUSYBOX_PROFILE_STAMP): private OPENSBI_TARGET_FW := $(OPENSBI_BUSYBOX_FW)
$(OPENSBI_BUSYBOX_PROFILE_STAMP): $(BUSYBOX_INITRAMFS_DTB)
$(OPENSBI_UBUNTU_PROBE_PROFILE_STAMP): private OPENSBI_TARGET_DTB := $(UBUNTU_PROBE_DTB)
$(OPENSBI_UBUNTU_PROBE_PROFILE_STAMP): private OPENSBI_TARGET_BUILD_DIR := $(OPENSBI_UBUNTU_PROBE_BUILD_DIR)
$(OPENSBI_UBUNTU_PROBE_PROFILE_STAMP): private OPENSBI_TARGET_FW := $(OPENSBI_UBUNTU_PROBE_FW)
$(OPENSBI_UBUNTU_PROBE_PROFILE_STAMP): $(UBUNTU_PROBE_DTB)
$(OPENSBI_UBUNTU_SHELL_PROFILE_STAMP): private OPENSBI_TARGET_DTB := $(UBUNTU_SHELL_DTB)
$(OPENSBI_UBUNTU_SHELL_PROFILE_STAMP): private OPENSBI_TARGET_BUILD_DIR := $(OPENSBI_UBUNTU_SHELL_BUILD_DIR)
$(OPENSBI_UBUNTU_SHELL_PROFILE_STAMP): private OPENSBI_TARGET_FW := $(OPENSBI_UBUNTU_SHELL_FW)
$(OPENSBI_UBUNTU_SHELL_PROFILE_STAMP): $(UBUNTU_SHELL_DTB)
$(OPENSBI_ROOTFS_PROFILE_STAMP): private OPENSBI_TARGET_DTB := $(ROOTFS_DTB)
$(OPENSBI_ROOTFS_PROFILE_STAMP): private OPENSBI_TARGET_BUILD_DIR := $(OPENSBI_ROOTFS_BUILD_DIR)
$(OPENSBI_ROOTFS_PROFILE_STAMP): private OPENSBI_TARGET_FW := $(OPENSBI_ROOTFS_FW)
$(OPENSBI_ROOTFS_PROFILE_STAMP): $(ROOTFS_DTB)

# 五类固件各自的 stamp 都只由 build-opensbi.sh 在对应 canonical O=
# lock 内发布；这里传入的字段同时驱动脚本的 current fast-path。
$(OPENSBI_PROFILE_STAMPS): FORCE $(OPENSBI_SOURCE_INPUTS)
	$(OPENSBI_STAMP_COMMON_ENV) \
	  OPENSBI_PROFILE_STAMP='$@' \
	  OPENSBI_STAMP_DTB='$(OPENSBI_TARGET_DTB)' \
	  OPENSBI_STAMP_BUILD_DIR='$(OPENSBI_TARGET_BUILD_DIR)' \
	  OPENSBI_PROFILE='$(OPENSBI_PROFILE)' \
	  LINUX_PLATFORM='$(LINUX_PLATFORM)' \
	  OPENSBI_ROOT='$(OPENSBI_ROOT)' OPENSBI_REF='$(OPENSBI_REF)' \
	  OPENSBI_NPC_PATCH='$(OPENSBI_NPC_PATCH)' CROSS_COMPILE='$(OPENSBI_CROSS_COMPILE)' \
	  FW_JUMP_ADDR='$(FW_JUMP_ADDR)' FW_JUMP_FDT_ADDR='$(FW_JUMP_FDT_ADDR)' \
	  OPENSBI_DTB='$(OPENSBI_TARGET_DTB)' OPENSBI_BUILD_DIR='$(OPENSBI_TARGET_BUILD_DIR)' \
	  OPENSBI_EXPECTED_FIRMWARE='$(OPENSBI_TARGET_FW)' \
	  OPENSBI_PLATFORM='$(OPENSBI_PLATFORM)' \
	  LINUX_MAKE_ARCH='$(ARCH)' \
	  OPENSBI_DISABLE_PMU='$(OPENSBI_DISABLE_PMU)' \
	  bash '$(SCRIPT_DIR)/build-opensbi.sh'

$(OPENSBI_FW): $(OPENSBI_PROFILE_STAMP)
$(OPENSBI_BUSYBOX_FW): $(OPENSBI_BUSYBOX_PROFILE_STAMP)
$(OPENSBI_UBUNTU_PROBE_FW): $(OPENSBI_UBUNTU_PROBE_PROFILE_STAMP)
$(OPENSBI_UBUNTU_SHELL_FW): $(OPENSBI_UBUNTU_SHELL_PROFILE_STAMP)
$(OPENSBI_ROOTFS_FW): $(OPENSBI_ROOTFS_PROFILE_STAMP)

qemu: qemu-ubuntu-shell

qemu-build:
	bash '$(SCRIPT_DIR)/build-qemu.sh'

qemu-ubuntu-probe:
	bash '$(SCRIPT_DIR)/run-qemu-ubuntu-initramfs.sh'

qemu-ubuntu-shell:
	UBUNTU_INITRD_IMAGE='$(UBUNTU_SHELL_INITRD)' \
	LOG_FILE='$(LOG_ROOT)/qemu/ubuntu-shell-initramfs.log' \
	QEMU_MEMORY=256M QEMU_GUEST_EXPECT='$(UBUNTU_SHELL_EXPECT)' \
	bash '$(SCRIPT_DIR)/run-qemu-ubuntu-initramfs.sh'

tools-build:
	+$(MAKE) -C '$(TOOLS_DIR)' all

boot-tools:
	+$(MAKE) -C '$(TOOLS_DIR)' boot-tools

tools-smoke: check-sim
	+$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' $(TOOL_SMOKES)

$(TOOL_SMOKES): check-sim
	+$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' $@

smoke-dtb: check-sim
	+$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' $@

smoke-opensbi smoke-opensbi-sbi: check-sim opensbi
	+$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' $@

smoke-virtio-blk: check-sim ubuntu-rootfs-image
	+$(MAKE) -C '$(TOOLS_DIR)' NPC_SIM='$(NPC_SIM)' VIRTIO_BLK_IMAGE='$(UBUNTU_ROOTFS_IMAGE)' $@

tools-clean:
	+$(MAKE) -C '$(TOOLS_DIR)' clean

paths:
	@printf 'ARCH=%s\n' '$(ARCH)'
	@printf 'LINUX_ISA=%s\n' '$(LINUX_ISA)'
	@printf 'LINUX_PLATFORM=%s\n' '$(LINUX_PLATFORM)'
	@printf 'LINUX_PLATFORM_DESC=%s\n' '$(LINUX_PLATFORM_DESC)'
	@printf 'BOOT=%s\n' '$(BOOT)'
	@printf 'ENV_ROOT=%s\n' '$(ENV_ROOT)'
	@printf 'PLATFORM_ROOT=%s\n' '$(PLATFORM_ROOT)'
	@printf 'PLATFORM_BUILD_ROOT=%s\n' '$(PLATFORM_BUILD_ROOT)'
	@printf 'PLATFORM_IMAGE_ROOT=%s\n' '$(PLATFORM_IMAGE_ROOT)'
	@printf 'PLATFORM_LOG_ROOT=%s\n' '$(PLATFORM_LOG_ROOT)'
	@printf 'BUILD_DIR=%s\n' '$(BUILD_DIR)'
	@printf 'LINUX_BUILD_DIR=%s\n' '$(LINUX_BUILD_DIR)'
	@printf 'MAX_CYCLES=%s\n' '$(MAX_CYCLES)'
	@printf 'OPENSBI_PROFILE=%s\n' '$(OPENSBI_PROFILE)'
	@printf 'OPENSBI_DISABLE_PMU=%s\n' '$(OPENSBI_DISABLE_PMU)'
	@printf 'OPENSBI_BUILD_ROOT=%s\n' '$(OPENSBI_BUILD_ROOT)'
	@printf 'RUN_SIM=%s\n' '$(RUN_SIM)'
	@printf 'NPC_SIM=%s\n' '$(NPC_SIM)'
	@printf 'NEMU_SIM=%s\n' '$(NEMU_SIM)'
	@printf 'LINUX_IMAGE=%s\n' '$(LINUX_IMAGE)'
	@printf 'RUN_FW=%s\n' '$(RUN_FW)'
	@printf 'RUN_DTB=%s\n' '$(RUN_DTB)'
	@printf 'RUN_INITRD=%s\n' '$(RUN_INITRD)'
	@printf 'RUN_ROOTFS=%s\n' '$(RUN_ROOTFS)'
	@printf 'UBUNTU_ROOTFS_SYSTEMD_IMAGE=%s\n' '$(UBUNTU_ROOTFS_SYSTEMD_IMAGE)'
	@printf 'UBUNTU_ROOTFS_INTERACTIVE_IMAGE=%s\n' '$(UBUNTU_ROOTFS_INTERACTIVE_IMAGE)'
	@printf 'UBUNTU_ROOTFS_FULL_IMAGE=%s\n' '$(UBUNTU_ROOTFS_FULL_IMAGE)'
	@printf 'NEMU_SYSTEMD_ROOTFS_FLAVOR=%s\n' '$(NEMU_SYSTEMD_ROOTFS_FLAVOR)'
	@printf 'NEMU_SYSTEMD_ROOTFS_CHECK_TARGET=%s\n' '$(NEMU_SYSTEMD_ROOTFS_CHECK_TARGET)'
	@printf 'NEMU_RUN_ROOTFS_OVERLAY=%s\n' '$(NEMU_RUN_ROOTFS_OVERLAY)'
	@printf 'NEMU_RUN_ROOTFS_OVERLAY_RESET=%s\n' '$(NEMU_RUN_ROOTFS_OVERLAY_RESET)'
	@printf 'NEMU_RUN_MAX_BOOTS=%s\n' '$(NEMU_RUN_MAX_BOOTS)'
	@printf 'NEMU_REBOOT_PERSIST_ROOTFS_OVERLAY=%s\n' '$(NEMU_REBOOT_PERSIST_ROOTFS_OVERLAY)'
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
