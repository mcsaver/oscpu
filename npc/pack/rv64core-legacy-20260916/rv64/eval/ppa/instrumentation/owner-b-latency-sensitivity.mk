OWNER_B_LATENCY_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
OWNER_B_LATENCY_PROBE := $(OWNER_B_LATENCY_DIR)/AxiDpiSlaveOwnerBDelayProbe.sv
OWNER_B_LATENCY_BASE ?=

ifeq ($(strip $(OWNER_B_LATENCY_BASE)),)
$(error owner-b-latency-sensitivity.mk requires OWNER_B_LATENCY_BASE=<generated source>)
endif
ifeq ($(wildcard $(OWNER_B_LATENCY_BASE)),)
$(error OWNER_B_LATENCY_BASE does not name an existing generated source)
endif

OWNER_B_LATENCY_INPUT_VSRCS := $(VSRCS)
ifneq ($(words $(filter $(RTL_AXI_DPI_SLAVE),$(OWNER_B_LATENCY_INPUT_VSRCS))),1)
$(error expected exactly one production AxiDpiSlave source before substitution)
endif

override VSRCS := \
  $(filter-out $(RTL_AXI_DPI_SLAVE),$(OWNER_B_LATENCY_INPUT_VSRCS)) \
  $(OWNER_B_LATENCY_BASE) \
  $(OWNER_B_LATENCY_PROBE)

$(BIN): $(OWNER_B_LATENCY_BASE) $(OWNER_B_LATENCY_PROBE)
