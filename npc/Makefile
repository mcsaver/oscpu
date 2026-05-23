NPC_ROOT := $(abspath .)
NPC_SIM_HOME ?= $(NPC_ROOT)/sim

.DEFAULT_GOAL := default

default all lint run sim clean gprof-build prof-exec-build difftest-ref \
menuconfig savedefconfig help-config distclean-config \
backend-menuconfig backend-savedefconfig backend-help-config backend-distclean-config \
syn-check-env sta-check-env syn sta help status switch select \
testbench pipe-test soc soc-lint:
	@# 外部仍可从 npc/ 调用；真正的平台无关仿真入口统一收口到 npc/sim。
	@$(MAKE) -C $(NPC_SIM_HOME) $@

%defconfig:
	@$(MAKE) -C $(NPC_SIM_HOME) $@

.PHONY: default all lint run sim clean gprof-build prof-exec-build difftest-ref \
	menuconfig savedefconfig help-config distclean-config \
	backend-menuconfig backend-savedefconfig backend-help-config backend-distclean-config \
	syn-check-env sta-check-env syn sta help status switch select \
	testbench pipe-test soc soc-lint
