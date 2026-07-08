PROJ_PATH = $(shell pwd)
SHELL := /bin/bash

O ?= $(PROJ_PATH)/result
DESIGN ?= gcd
SDC_FILE ?= $(PROJ_PATH)/scripts/default.sdc
RTL_FILES ?= $(shell find $(PROJ_PATH)/example -name "*.v")
VERILOG_INCLUDE_DIRS ?=
VERILOG_DEFINES ?=
SYNTH_FLATTEN ?= 1
SYNTH_SHARE ?= 1
SYNTH_STOP_AFTER_COARSE ?= 0
SYNTH_PUBLIC_AUTONAME ?= 1
SYNTH_DFF_AUTONAME ?= 1
SYNTH_BLACKBOX_MODULES ?=
KEEP_HIERARCHY_MODULES ?=
# 额外 liberty(如黑盒宏的 non-signoff 占位 .lib),STA 时随标准单元库一并 read_liberty;
# 默认空,由上层(例如 npc/rv64 Makefile 的 STA_EXTRA_LIB_FILES)传绝对路径列表。
EXTRA_LIB_FILES ?=
export CLK_FREQ_MHZ ?= 500
export CLK_PORT_NAME ?= clk
export SYNTH_FLATTEN
export SYNTH_SHARE
export SYNTH_STOP_AFTER_COARSE
export SYNTH_PUBLIC_AUTONAME
export SYNTH_DFF_AUTONAME
export SYNTH_BLACKBOX_MODULES
export KEEP_HIERARCHY_MODULES
export EXTRA_LIB_FILES
PDK = icsprout55

RESULT_DIR = $(O)/$(DESIGN)-$(CLK_FREQ_MHZ)MHz
SCRIPT_DIR = $(PROJ_PATH)/scripts
NETLIST_SYN_V   = $(RESULT_DIR)/$(DESIGN).netlist.v
TIMING_RPT = $(RESULT_DIR)/$(DESIGN).rpt

init:
	bash -c "$$(wget -O - https://ysyx.oscc.cc/slides/resources/scripts/init-yosys-sta.sh)"
	mkdir -p pdk
	cd pdk && git clone -b ysyx --depth 1 git@github.com:openecos-projects/icsprout55-pdk.git icsprout55

syn: $(NETLIST_SYN_V)
$(NETLIST_SYN_V): $(RTL_FILES) $(SCRIPT_DIR)/yosys.tcl
	mkdir -p $(@D)
	echo tcl $(SCRIPT_DIR)/yosys.tcl $(DESIGN) $(PDK) \"$(RTL_FILES)\" $@ \"$(VERILOG_INCLUDE_DIRS)\" \"$(VERILOG_DEFINES)\" | yosys -g -l $(@D)/yosys.log -s -

sta: $(TIMING_RPT)
$(TIMING_RPT): $(SCRIPT_DIR)/sta.tcl $(SDC_FILE) $(NETLIST_SYN_V)
	set -o pipefail && ./bin/iEDA -script $^ $(DESIGN) $(PDK) 2>&1 | tee $(RESULT_DIR)/sta.log

clean:
	-rm -rf result/

.PHONY: init syn sta clean
