WRITE_PATH_BUBBLE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
WRITE_PATH_BUBBLE_VSRC := $(WRITE_PATH_BUBBLE_DIR)/NpcOooWritePathBubbleProbe.sv

ifeq ($(filter y,$(CONFIG_NPC_OOO_STATS)),)
$(error write-path-bubble.mk requires CONFIG_NPC_OOO_STATS=y)
endif

override VSRCS += $(WRITE_PATH_BUBBLE_VSRC)
override VERILATOR_FLAGS += +define+CONFIG_NPC_OOO_WRITE_PATH_BUBBLE -Wno-PINCONNECTEMPTY

.PHONY: write-path-bubble-lint
write-path-bubble-lint:
	$(VERILATOR) --lint-only --timescale 1ns/1ps \
		-Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC \
		-Wno-UNUSEDSIGNAL -Wno-PINCONNECTEMPTY \
		-I$(VSRCDIR) -I$(RTL_INCLUDE_DIR) $(RTL_VERILATOR_DEFINES) \
		+define+CONFIG_NPC_OOO_WRITE_PATH_BUBBLE \
		--top-module $(TOPNAME) $(VSRCS)

$(BIN): $(WRITE_PATH_BUBBLE_VSRC)
