# Verilator 仿真包装和宿主；生产 RTL 清单独立位于 ../vsrc/filelist.mk。
SIM_HOME := $(NPC_HOME)/sim
SIM_VSRC_DIR := $(SIM_HOME)/vsrc
SIM_TOP_SRCS := $(SIM_VSRC_DIR)/AxiDpiSlave.sv $(SIM_VSRC_DIR)/NpcSimTop.sv
SIM_HOST_SRCS := $(sort $(shell find $(SIM_HOME)/src -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' \)))
SIM_HEADER_SRCS := $(sort $(shell find $(SIM_HOME)/include -type f -name '*.h'))
VSRCS = $(RTL_CORE_SRCS) $(SIM_TOP_SRCS)
