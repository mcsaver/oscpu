COLOR_RED := $(shell echo "\033[1;31m")
COLOR_END := $(shell echo "\033[0m")

ifeq ($(wildcard .config),)
$(warning $(COLOR_RED)Warning: $(NPC_HOME)/.config does not exist!$(COLOR_END))
$(warning $(COLOR_RED)Run 'make default_defconfig' or 'make menuconfig' under $(NPC_HOME) first.$(COLOR_END))
endif

Q := @
KCONFIG_PATH := $(NEMU_HOME)/tools/kconfig
FIXDEP_PATH := $(NEMU_HOME)/tools/fixdep
Kconfig := $(NPC_HOME)/Kconfig
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
	@echo '  menuconfig         - Update $(NPC_HOME) config using a menu based program'
	@echo '  default_defconfig  - Load $(NPC_HOME)/configs/default_defconfig'
	@echo '  savedefconfig      - Save current config as configs/default_defconfig'

distclean-config:
	-@rm -rf $(rm-distclean)

.PHONY: help-config distclean-config
