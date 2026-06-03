ROOT ?= ..
PROJECT_NAME ?= npc_rv64_top
TOP ?= NpcTop
FPGA_PART ?= xc7s25csga225-1
CLOCK_PERIOD_NS ?= 10.000
VIVADO_THREADS ?= 2
SYNTH_DIRECTIVE ?= Default
SYNTH_FLATTEN_HIERARCHY ?= rebuilt
VIVADO_SETTINGS ?= /home/lyg/AMD/2025.2/2025.2/Vivado/settings64.sh
VIVADO ?= vivado

FILELIST := filelists/$(PROJECT_NAME)_files.f
REPORT_DIR := reports
PROJECT_DIR := vivado/$(PROJECT_NAME)
LOG_FILE := $(REPORT_DIR)/$(PROJECT_NAME)_vivado.log
JOU_FILE := $(REPORT_DIR)/$(PROJECT_NAME)_vivado.jou

.PHONY: all filelist project synth clean

all: synth

filelist:
	@mkdir -p filelists
	@bash scripts/gen_rv64_filelist.sh "$(abspath $(ROOT))" "$(abspath $(FILELIST))"

project: filelist
	@mkdir -p $(REPORT_DIR) vivado
	@bash -lc 'source "$(VIVADO_SETTINGS)" >/dev/null 2>&1 && $(VIVADO) -mode batch \
		-log "$(abspath $(LOG_FILE))" \
		-jou "$(abspath $(JOU_FILE))" \
		-source "$(abspath scripts/create_rv64_core_project.tcl)" \
		-tclargs \
		-root "$(abspath $(ROOT))" \
		-project-name "$(PROJECT_NAME)" \
		-project-dir "$(abspath $(PROJECT_DIR))" \
		-part "$(FPGA_PART)" \
		-top "$(TOP)" \
		-filelist "$(abspath $(FILELIST))" \
		-clock-period "$(CLOCK_PERIOD_NS)" \
		-vivado-threads "$(VIVADO_THREADS)" \
		-synth-directive "$(SYNTH_DIRECTIVE)" \
		-synth-flatten "$(SYNTH_FLATTEN_HIERARCHY)" \
		-run-synth 0'

synth: filelist
	@mkdir -p $(REPORT_DIR) vivado
	@bash -lc 'source "$(VIVADO_SETTINGS)" >/dev/null 2>&1 && $(VIVADO) -mode batch \
		-log "$(abspath $(LOG_FILE))" \
		-jou "$(abspath $(JOU_FILE))" \
		-source "$(abspath scripts/create_rv64_core_project.tcl)" \
		-tclargs \
		-root "$(abspath $(ROOT))" \
		-project-name "$(PROJECT_NAME)" \
		-project-dir "$(abspath $(PROJECT_DIR))" \
		-part "$(FPGA_PART)" \
		-top "$(TOP)" \
		-filelist "$(abspath $(FILELIST))" \
		-clock-period "$(CLOCK_PERIOD_NS)" \
		-vivado-threads "$(VIVADO_THREADS)" \
		-synth-directive "$(SYNTH_DIRECTIVE)" \
		-synth-flatten "$(SYNTH_FLATTEN_HIERARCHY)" \
		-run-synth 1'

clean:
	rm -rf vivado .Xil reports/*.log reports/*.jou reports/*.rpt reports/*.dcp filelists/*.f
