OWNER_TIMING_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
OWNER_TIMING_CONTRACT := $(OWNER_TIMING_DIR)/owner-timing-contract-v1.json
OWNER_TIMING_VSRC := $(OWNER_TIMING_DIR)/NpcOooOwnerTimingProbe.sv
OWNER_TIMING_CSRC := $(OWNER_TIMING_DIR)/owner_timing_collector.cpp

ifeq ($(filter y,$(CONFIG_NPC_OOO_STATS)),)
$(error owner-timing.mk requires CONFIG_NPC_OOO_STATS=y so ROB-head token observations are elaborated)
endif

override VSRCS += $(OWNER_TIMING_VSRC)
override CSRCS += $(OWNER_TIMING_CSRC)
override VERILATOR_FLAGS += +define+CONFIG_NPC_OOO_OWNER_TIMING

$(BIN): $(OWNER_TIMING_CONTRACT) $(OWNER_TIMING_VSRC) $(OWNER_TIMING_CSRC)
