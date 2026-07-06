COLOR_RED := $(shell echo "\033[1;31m")
COLOR_END := $(shell echo "\033[0m")

ifeq ($(wildcard .config),)
$(warning $(COLOR_RED)Warning: $(SIM_HOME)/.config does not exist!$(COLOR_END))
$(warning $(COLOR_RED)Run 'make default_defconfig' or 'make menuconfig' under $(SIM_HOME) first.$(COLOR_END))
endif

Q := @
KCONFIG_PATH := $(YSYX_HOME)/tool/kconfig
FIXDEP_PATH := $(YSYX_HOME)/tool/fixdep
Kconfig := $(SIM_HOME)/Kconfig
rm-distclean += include/generated include/config .config .config.old
silent := -s

CONF := $(KCONFIG_PATH)/build/conf
MCONF := $(KCONFIG_PATH)/build/mconf
FIXDEP := $(FIXDEP_PATH)/build/fixdep

$(CONF):
	$(Q)$(MAKE) $(silent) -C $(KCONFIG_PATH) NAME=conf

$(MCONF):
	$(Q)$(MAKE) $(silent) -C $(KCONFIG_PATH) NAME=mconf

$(FIXDEP):
	$(Q)$(MAKE) $(silent) -C $(FIXDEP_PATH)

menuconfig: $(MCONF) $(CONF) $(FIXDEP)
	$(Q)$(MCONF) $(Kconfig)
	$(Q)$(CONF) $(silent) --syncconfig $(Kconfig)

savedefconfig: $(CONF)
	$(Q)$< $(silent) --$@=configs/default_defconfig $(Kconfig)

%defconfig: $(CONF) $(FIXDEP)
	$(Q)$< $(silent) --defconfig=configs/$@ $(Kconfig)
	$(Q)$< $(silent) --syncconfig $(Kconfig)

.PHONY: menuconfig savedefconfig defconfig

help-config:
	@echo '  menuconfig         - Update npc/sim backend config using a menu based program'
	@echo '  default_defconfig  - Load npc/sim/configs/default_defconfig'
	@echo '  single_defconfig   - Select npc/single backend'
	@echo '  soc_defconfig      - Select npc/soc backend'
	@echo '  savedefconfig      - Save current config as configs/default_defconfig'
	@echo '  backend-menuconfig - Configure the selected concrete backend'

distclean-config:
	-@rm -rf $(rm-distclean)

.PHONY: help-config distclean-config
