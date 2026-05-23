SIM_HOME := $(abspath .)
NPC_ROOT ?= $(abspath ..)
NEMU_HOME ?= $(abspath $(NPC_ROOT)/../nemu)
DEFAULT_BACKEND := single
LEGACY_BACKEND_FILE ?= $(NPC_ROOT)/.platform
SUPPORTED_BACKENDS := single soc

remove_quote = $(patsubst "%",%,$(1))

-include $(SIM_HOME)/include/config/auto.conf

ifeq ($(origin BACKEND),undefined)
ifneq ($(origin NPC_SIM_BACKEND),undefined)
REQUESTED_BACKEND := $(strip $(NPC_SIM_BACKEND))
else ifneq ($(origin PLATFORM),undefined)
REQUESTED_BACKEND := $(strip $(PLATFORM))
else ifneq ($(origin NPC_PLATFORM),undefined)
REQUESTED_BACKEND := $(strip $(NPC_PLATFORM))
else ifneq ($(CONFIG_NPC_SIM_BACKEND),)
REQUESTED_BACKEND := $(call remove_quote,$(strip $(CONFIG_NPC_SIM_BACKEND)))
else ifneq ($(wildcard $(LEGACY_BACKEND_FILE)),)
REQUESTED_BACKEND := $(strip $(shell sed -n '1p' $(LEGACY_BACKEND_FILE)))
else
REQUESTED_BACKEND := $(DEFAULT_BACKEND)
endif
else
REQUESTED_BACKEND := $(strip $(BACKEND))
endif

ifeq ($(REQUESTED_BACKEND),am)
SELECTED_BACKEND := single
else ifeq ($(REQUESTED_BACKEND),ysyx-soc)
SELECTED_BACKEND := soc
else ifeq ($(REQUESTED_BACKEND),ysyxSoC)
SELECTED_BACKEND := soc
else
SELECTED_BACKEND := $(REQUESTED_BACKEND)
endif

ifeq ($(filter $(SELECTED_BACKEND),$(SUPPORTED_BACKENDS)),)
$(error Unsupported BACKEND='$(REQUESTED_BACKEND)'; choose one of: $(SUPPORTED_BACKENDS), or aliases: am, ysyx-soc)
endif

BACKEND_MK := $(SIM_HOME)/backends/$(SELECTED_BACKEND).mk
ifeq ($(wildcard $(BACKEND_MK)),)
$(error Missing backend descriptor: $(BACKEND_MK))
endif

include $(BACKEND_MK)
include $(SIM_HOME)/scripts/config.mk

.DEFAULT_GOAL := default

help:
	@echo 'NPC platform-independent simulation top'
	@echo ''
	@echo 'Usage:'
	@echo '  make -C npc/sim [target]                         # use current/default backend'
	@echo '  make -C npc/sim BACKEND=single [target]          # AM/NpcSimTop self-simulation'
	@echo '  make -C npc/sim BACKEND=soc [target]             # copied ysyxSoC integration tree'
	@echo '  make -C npc/sim menuconfig                       # choose backend using Kconfig'
	@echo '  make -C npc/sim switch BACKEND=soc               # persist selected backend in npc/sim/.config'
	@echo ''
	@echo 'External users:'
	@echo '  AM should call npc/sim and pass NPC_SIM_BACKEND when it needs a non-default backend.'
	@echo ''
	@echo 'Common targets:'
	@echo '  default all lint run sim clean menuconfig default_defconfig single_defconfig soc_defconfig'
	@echo '  backend-menuconfig backend-default_defconfig backend-perf_defconfig'
	@echo '  testbench pipe-test soc soc-lint status'

status:
	@echo '[npc-sim] selected backend: $(SELECTED_BACKEND)'
	@echo '[npc-sim] backend directory: $(BACKEND_DIR)'
	@echo '[npc-sim] backend description: $(BACKEND_DESC)'
	@if [ -f "$(SIM_HOME)/.config" ]; then \
		echo '[npc-sim] config file: '"$(SIM_HOME)/.config"; \
	else \
		echo '[npc-sim] config file: <none, default is $(DEFAULT_BACKEND)>'; \
	fi
	@echo '[npc-sim] configured backend: $(or $(call remove_quote,$(CONFIG_NPC_SIM_BACKEND)),<unset>)'
	@echo '[npc-sim] supported backends: $(SUPPORTED_BACKENDS)'

switch select:
	@# 后端选择落到 npc/sim 自己的 Kconfig 配置中；外部模块只读取这个稳定仿真顶层。
	@$(MAKE) -C $(SIM_HOME) $(SELECTED_BACKEND)_defconfig
	@echo '[npc-sim] selected backend persisted as $(SELECTED_BACKEND) in $(SIM_HOME)/.config'

default all lint run sim clean gprof-build prof-exec-build difftest-ref \
syn-check-env sta-check-env syn sta:
	@# 对外固定使用 npc/sim 接口；后端实现仍在 single/soc 内部独立维护。
	@$(MAKE) -C $(BACKEND_DIR) $@

testbench:
	@$(MAKE) -C $(BACKEND_DIR)/testbench run

pipe-test:
	@$(MAKE) -C $(BACKEND_DIR)/testbench pipe_test

soc soc-lint:
	@$(MAKE) -C $(NPC_ROOT)/soc $@

backend-menuconfig backend-savedefconfig backend-help-config backend-distclean-config:
	@$(MAKE) -C $(BACKEND_DIR) $(patsubst backend-%,%,$@)

backend-%_defconfig:
	@$(MAKE) -C $(BACKEND_DIR) $*_defconfig

.PHONY: help status switch select \
	default all lint run sim clean gprof-build prof-exec-build difftest-ref \
	syn-check-env sta-check-env syn sta testbench pipe-test soc soc-lint \
	backend-menuconfig backend-savedefconfig backend-help-config backend-distclean-config
