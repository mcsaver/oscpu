# Default RV64 RTL catalog: the native two-wide rewrite.
# Historical Ooo* catalog is filelist.legacy.mk and is never mixed into this core.
VSRCDIR ?= $(abspath ./vsrc)
include $(VSRCDIR)/chengyue64/filelist.mk
RTL_INCLUDE_DIR := $(VSRCDIR)/include
RTL_CORE_SRCS := $(R64_RTL_SRCS)
RTL_HEADER_SRCS := $(wildcard $(VSRCDIR)/chengyue64/backend/*.vh $(VSRCDIR)/chengyue64/platform/*.vh)
SIM_TOP_SRCS := $(abspath $(VSRCDIR)/../testbench/chengyue64/R64SystemTestTop.sv)
VSRCS := $(RTL_CORE_SRCS) $(SIM_TOP_SRCS)
