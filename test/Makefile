PROJ_PATH = $(shell pwd)
SHELL := /bin/bash

O ?= $(PROJ_PATH)/result
## 请在调用 make 时显式指定 DESIGN 变量（例如：make syn DESIGN=light）
DESIGN ?= light
SDC_FILE ?= $(PROJ_PATH)/../yosys-sta/scripts/default.sdc
RTL_FILES ?= $(shell find $(PROJ_PATH) -name "*.v")
export CLK_FREQ_MHZ ?= 500
export CLK_PORT_NAME ?= clk
PDK = icsprout55

RESULT_DIR = $(O)/$(DESIGN)-$(CLK_FREQ_MHZ)MHz
SCRIPT_DIR = $(PROJ_PATH)/scripts
NETLIST_SYN_V   = $(RESULT_DIR)/$(DESIGN).netlist.v
TIMING_RPT = $(RESULT_DIR)/$(DESIGN).rpt

IEDA_BIN ?= $(PROJ_PATH)/../yosys-sta/bin/iEDA
YOSYS_STA_SCRIPT_DIR ?= $(PROJ_PATH)/../yosys-sta/scripts

init:
	bash -c "$$(wget -O - https://ysyx.oscc.cc/slides/resources/scripts/init-yosys-sta.sh)"
	mkdir -p pdk
	cd pdk && git clone -b ysyx --depth 1 git@github.com:openecos-projects/icsprout55-pdk.git icsprout55
 

syn: $(NETLIST_SYN_V)

$(NETLIST_SYN_V): $(RTL_FILES) $(YOSYS_STA_SCRIPT_DIR)/yosys.tcl
	mkdir -p $(@D)
	echo tcl $(YOSYS_STA_SCRIPT_DIR)/yosys.tcl $(DESIGN) $(PDK) "$(RTL_FILES)" $@ | yosys -g -l $(@D)/yosys.log -s -

sta: $(TIMING_RPT)

$(TIMING_RPT): $(YOSYS_STA_SCRIPT_DIR)/sta.tcl $(SDC_FILE) $(NETLIST_SYN_V)
	@mkdir -p $(@D)
	set -o pipefail && "$(IEDA_BIN)" -script $^ $(DESIGN) $(PDK) 2>&1 | tee $(RESULT_DIR)/sta.log

clean:
	-rm -rf result/

.PHONY: init syn sta clean
