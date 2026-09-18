# ChengYue64 (承岳64) official RV64 engineering entry.
# Legacy rv64core is archived in ../pack/rv64core-legacy-20260916.
.DEFAULT_GOAL := default
.DELETE_ON_ERROR:
SHELL := /bin/bash
NPC_HOME := $(abspath .)
WORKSPACE := $(abspath ../..)
include $(NPC_HOME)/core-version.mk
NEMU_HOME ?= $(WORKSPACE)/nemu
YOSYS_STA_HOME ?= $(WORKSPACE)/yosys-sta
OSS_CAD_SUITE_HOME ?= $(WORKSPACE)/oss-cad-suite
VSRCDIR := $(NPC_HOME)/vsrc
include $(VSRCDIR)/filelist.mk
BUILD_DIR ?= $(NPC_HOME)/build/chengyue64
TEST_DIR := $(NPC_HOME)/testbench/chengyue64
SYSTEM_BUILD_DIR ?= $(abspath $(BUILD_DIR)/system)
CORE_BUILD_DIR ?= $(abspath $(BUILD_DIR)/core)
TENSOR_BUILD_DIR ?= $(abspath $(BUILD_DIR)/tensor-system)
CORE_REF ?= $(NEMU_HOME)/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so
CORE_JOBS ?= 6
BIN := $(SYSTEM_BUILD_DIR)/obj/VR64SystemTestTop
IMG ?=
RUN_ARGS ?=
SUBMAKE := $(MAKE) --no-print-directory -C $(TEST_DIR) SYSTEM_BUILD_DIR=$(SYSTEM_BUILD_DIR) CORE_BUILD_DIR=$(CORE_BUILD_DIR) TENSOR_BUILD_DIR=$(TENSOR_BUILD_DIR) CORE_REF=$(CORE_REF) CORE_JOBS=$(CORE_JOBS)
SIMMAKE := $(MAKE) --no-print-directory -C $(NPC_HOME)/sim SYSTEM_BUILD_DIR=$(SYSTEM_BUILD_DIR) CORE_BUILD_DIR=$(CORE_BUILD_DIR) TENSOR_BUILD_DIR=$(TENSOR_BUILD_DIR) CORE_REF=$(CORE_REF) CORE_JOBS=$(CORE_JOBS)

.PHONY: default all run sim lint testbench test core-test device-test tensor-test difftest-ref regression software-test
default all:
	@$(SIMMAKE) system
run sim: default difftest-ref
	@test -n "$(IMG)" || { echo 'IMG must identify the RV64 boot image'; exit 2; }
	@$(BIN) "$(abspath $(IMG))" "$(CORE_REF)" $(RUN_ARGS)
lint:
	@$(SIMMAKE) lint
testbench test:
	@$(SUBMAKE) -j4 run negative pipeline-matrix admission-matrix store-matrix trigger-matrix rr-qcredit-matrix
device-test:
	@$(SUBMAKE) block-run
core-test:
	@$(SUBMAKE) core-run system-run system-throughput system-io
tensor-test:
	@$(SUBMAKE) tensor-run
software-test:
	@$(SUBMAKE) software-run
# Linux and NPU are part of replacement acceptance; their longer workloads
# have separate explicit targets and must be reported alongside this cohort.
regression: lint test core-test software-test device-test
difftest-ref:
	@$(MAKE) --no-print-directory -C $(NPC_HOME)/difftest reference CORE_REF=$(CORE_REF)

# Native layered system acceptance. A supplied SYSTEM_IMAGES directory uses
# the existing L2/L3 artifact ABI; otherwise build the checked-in payloads.
SYSTEM_IMAGES ?=
SYSTEM_CASE ?= all
SYSTEM_TIMEOUT ?= 14400
SYSTEM_RUN_ARGS ?=
.PHONY: l2-test l3-test
l2-test l3-test: all difftest-ref
	@set -e; \
	layer="$(@:-test=)"; \
	mkdir -p "$(BUILD_DIR)"; \
	out=$$(mktemp -d "$(BUILD_DIR)/$$layer-run-XXXXXX"); \
	images="$(SYSTEM_IMAGES)"; \
	if [ -z "$$images" ]; then \
	  images="$$out/images"; \
	  script=build-rv64-mini-system.sh; \
	  if [ "$$layer" = l3 ]; then script=build-rv64-lightweight-linux.sh; fi; \
	  bash "$(WORKSPACE)/Linux/scripts/$$script" --output-dir "$$images" --work-dir "$$out/build" --jobs "$(CORE_JOBS)" >"$$out/build.log" 2>&1; \
	fi; \
	python3 "$(TEST_DIR)/scripts/run_r64_system.py" --layer "$$layer" --case "$(SYSTEM_CASE)" \
	  --images "$$images" --out "$$out" --sim "$(BIN)" --ref "$(CORE_REF)" \
	  --host-timeout "$(SYSTEM_TIMEOUT)" $(SYSTEM_RUN_ARGS)

# Real 1ns standard-cell mapping. Every CPU array and numerical engine is
# synthesized; there are no SRAM/FP/BPU placeholder cells or blackbox libraries.
STA_DESIGN ?= R64CoreTop
STA_PDK ?= icsprout55
STA_CLK_FREQ_MHZ ?= 1000
SYNTH_MAX_FANOUT ?= 8
# Match the current measured 1ns point; ABC delay is an internal map target.
SYNTH_MAP_DELAY_PS ?= 600
STA_CLK_PORT ?= clk_i
STA_SDC_FILE ?= $(NPC_HOME)/syn/chengyue64.sdc
STA_RESULT_ROOT ?= $(abspath $(BUILD_DIR)/sta)
OPENSTA ?= $(abspath $(NPC_HOME)/../../tmp/rv64-opensta/build/sta)
STA_MEMORY_KIB ?= 12582912
SYN_MEMORY_KIB ?= 12582912
STA_RTL_FILES := $(RTL_CORE_SRCS)
STA_INCLUDE_DIRS ?= $(VSRCDIR)/include $(VSRCDIR)/chengyue64/backend $(VSRCDIR)/chengyue64/platform
STA_ARGS = DESIGN=$(STA_DESIGN) PDK=$(STA_PDK) CLK_PORT_NAME=$(STA_CLK_PORT) CLK_FREQ_MHZ=$(STA_CLK_FREQ_MHZ) SDC_FILE=$(STA_SDC_FILE) O=$(STA_RESULT_ROOT) VERILOG_INCLUDE_DIRS="$(STA_INCLUDE_DIRS)" RTL_FILES="$(STA_RTL_FILES)" YOSYS_ARGS= SYNTH_FLATTEN=0 SYNTH_SHARE=0 SYNTH_PUBLIC_AUTONAME=0 SYNTH_DFF_AUTONAME=0 SYNTH_STA_FLATTEN_EXPORT=1 SYNTH_LOAD_FF=20 SYNTH_MAX_FANOUT=$(SYNTH_MAX_FANOUT) SYNTH_MAP_DELAY_PS=$(SYNTH_MAP_DELAY_PS) SYNTH_BLACKBOX_MODULES="" EXTRA_LIB_FILES=""
.PHONY: syn sta syn-check-env sta-check-env print-synth-rtl help force-syn-config
STA_RESULT_DIR := $(STA_RESULT_ROOT)/$(STA_DESIGN)-$(STA_CLK_FREQ_MHZ)MHz
STA_MAPPED := $(STA_RESULT_DIR)/$(STA_DESIGN).netlist.v
STA_FLAT := $(STA_RESULT_DIR)/$(STA_DESIGN).sta.v
STA_CONFIG := $(STA_RESULT_DIR)/synthesis-config.txt
STA_LIBS := $(wildcard $(YOSYS_STA_HOME)/pdk/$(STA_PDK)/IP/STD_cell/*/*/liberty/*_typ_tt_*.lib)
syn-check-env:
	@test -x "$(OSS_CAD_SUITE_HOME)/bin/yosys"
	@test -f "$(YOSYS_STA_HOME)/scripts/pdk/$(STA_PDK).tcl"
sta-check-env: syn-check-env
	@test -x "$(YOSYS_STA_HOME)/bin/iEDA"
force-syn-config:
$(STA_CONFIG): force-syn-config | syn-check-env
	@mkdir -p "$(@D)"
	@printf '%s\n' '$(STA_ARGS)' > "$@.tmp"
	@cmp -s "$@.tmp" "$@" && rm "$@.tmp" || mv "$@.tmp" "$@"
$(STA_MAPPED): $(STA_RTL_FILES) $(RTL_HEADER_SRCS) $(STA_CONFIG) $(STA_LIBS) $(YOSYS_STA_HOME)/scripts/yosys.tcl $(YOSYS_STA_HOME)/scripts/common.tcl $(YOSYS_STA_HOME)/scripts/pdk/$(STA_PDK).tcl | syn-check-env
	@ulimit -v $(SYN_MEMORY_KIB) && PATH="$(OSS_CAD_SUITE_HOME)/bin:$$PATH" $(MAKE) -B -C $(YOSYS_STA_HOME) syn $(STA_ARGS)
syn: $(STA_MAPPED)
$(STA_FLAT): $(STA_MAPPED) $(NPC_HOME)/syn/export_sta.tcl
	@cd "$(YOSYS_STA_HOME)" && ulimit -v $(SYN_MEMORY_KIB) && set -o pipefail && printf '%s\n' 'tcl $(NPC_HOME)/syn/export_sta.tcl $(STA_MAPPED) $(STA_FLAT) $(STA_DESIGN) $(STA_PDK)' | "$(OSS_CAD_SUITE_HOME)/bin/yosys" -l "$(STA_RESULT_DIR)/sta_export.log" -s - > "$(STA_RESULT_DIR)/sta_export.stdout" 2>&1
$(STA_RESULT_DIR)/constraints.sdc: $(STA_FLAT) $(STA_SDC_FILE) $(NPC_HOME)/syn/prepare_sdc.py
	@python3 $(NPC_HOME)/syn/prepare_sdc.py --netlist $(STA_FLAT) --top $(STA_DESIGN) --clock $(STA_CLK_PORT) --template $(STA_SDC_FILE) --output $@
sta-ieda: $(STA_FLAT) $(STA_RESULT_DIR)/constraints.sdc sta-check-env
	@cd "$(YOSYS_STA_HOME)" && ulimit -v $(STA_MEMORY_KIB) && export CLK_FREQ_MHZ="$(STA_CLK_FREQ_MHZ)" CLK_PORT_NAME=$(STA_CLK_PORT) && set -o pipefail && ./bin/iEDA -script "$(NPC_HOME)/syn/timing.tcl" "$(STA_RESULT_DIR)/constraints.sdc" "$(STA_FLAT)" "$(STA_DESIGN)" "$(STA_PDK)" 2>&1 | tee "$(STA_RESULT_DIR)/sta.log"
	@python3 $(NPC_HOME)/syn/check_timing.py --report "$(STA_RESULT_DIR)/$(STA_DESIGN).rpt" --uncertainty 0.05 --output "$(STA_RESULT_DIR)/timing-summary.json"
.PHONY: sta-opensta sta-ieda
$(STA_RESULT_DIR)/opensta.sdc: $(STA_FLAT) $(STA_SDC_FILE) $(NPC_HOME)/syn/prepare_sdc.py
	@python3 $(NPC_HOME)/syn/prepare_sdc.py --netlist $(STA_FLAT) --top $(STA_DESIGN) --clock $(STA_CLK_PORT) --template $(STA_SDC_FILE) --engine opensta --output $@
# The bundled iEDA misses clock uncertainty on its ICG path group. OpenSTA
# supplies the native decision; sta-ieda remains available for diagnostics.
sta: sta-opensta
sta-opensta: $(STA_FLAT) $(STA_RESULT_DIR)/opensta.sdc
	@test -x "$(OPENSTA)" || { echo 'Set OPENSTA to a built OpenSTA executable.'; exit 1; }
	@cd "$(YOSYS_STA_HOME)" && ulimit -v $(STA_MEMORY_KIB) && export CLK_FREQ_MHZ="$(STA_CLK_FREQ_MHZ)" STA_PDK="$(STA_PDK)" STA_NETLIST="$(STA_FLAT)" STA_DESIGN="$(STA_DESIGN)" STA_SDC="$(STA_RESULT_DIR)/opensta.sdc" STA_OUTPUT="$(STA_RESULT_DIR)" && set -o pipefail && "$(OPENSTA)" -exit "$(NPC_HOME)/syn/opensta.tcl" 2>&1 | tee "$(STA_RESULT_DIR)/opensta.log"
	@python3 $(NPC_HOME)/syn/check_opensta.py --paths "$(STA_RESULT_DIR)/opensta.json" --report "$(STA_RESULT_DIR)/opensta.rpt" --log "$(STA_RESULT_DIR)/opensta.log" --output "$(STA_RESULT_DIR)/timing-summary.json"
print-synth-rtl:
	@echo $(RTL_CORE_SRCS)
version:
	@printf '%s (%s) v%s [%s]\n' '$(CORE_RTL_NAME)' '$(CORE_RTL_NAME_ZH)' '$(CORE_RTL_VERSION)' '$(CORE_RTL_RELEASE_DATE)'
.PHONY: version
help:
	@printf '%s (%s) v%s\n' '$(CORE_RTL_NAME)' '$(CORE_RTL_NAME_ZH)' '$(CORE_RTL_VERSION)'
	@echo 'make [all|lint|test|core-test|device-test|tensor-test|software-test|l2-test|l3-test|regression|syn|sta]'
	@echo 'make run IMG=/absolute/guest.bin RUN_ARGS="--maxcycles=20000000 --progress"'
	@echo 'Default hardware: R64CoreTop; system: R64SystemTop; optional NPU: R64TensorSystemTop.'
	@echo 'All simulation profiles keep actual RTL assertions and full reference comparison.'
	@echo 'Legacy archive: make -C ../pack/rv64core-legacy-20260916 <target>.'

# Physical input-branch hold repair. This inserts real Liberty buffers into a
# separate mapped netlist, proves contracted connectivity and reruns both setup
# and hold using exactly the original SDC. Unhandled violations still fail.
STA_HOLD_BUFFER ?= BUFX0P5H7L
STA_HOLD_STAGES ?= 2
STA_HOLD_ARGS ?=
STA_HOLD_DIR := $(STA_RESULT_DIR)/hold-repaired
.PHONY: sta-hold
sta-hold: $(STA_FLAT) $(STA_RESULT_DIR)/opensta.sdc
	@test -x "$(OPENSTA)"
	@mkdir -p "$(STA_HOLD_DIR)"
	@cd "$(YOSYS_STA_HOME)" && ulimit -v $(STA_MEMORY_KIB) && export STA_PDK="$(STA_PDK)" STA_NETLIST="$(STA_FLAT)" STA_DESIGN="$(STA_DESIGN)" STA_SDC="$(STA_RESULT_DIR)/opensta.sdc" STA_OUTPUT="$(STA_RESULT_DIR)" STA_HOLD_PATHS="$(STA_HOLD_DIR)/negative-input.json" && set -o pipefail && "$(OPENSTA)" -exit "$(NPC_HOME)/syn/opensta.tcl" 2>&1 | tee "$(STA_RESULT_DIR)/opensta.log"
	@python3 "$(NPC_HOME)/syn/repair_input_hold.py" --netlist "$(STA_FLAT)" --checks "$(STA_HOLD_DIR)/negative-input.json" $(foreach lib,$(STA_LIBS),--liberty "$(lib)") --buffer "$(STA_HOLD_BUFFER)" --stages "$(STA_HOLD_STAGES)" $(STA_HOLD_ARGS) --output "$(STA_HOLD_DIR)/repaired.v" --manifest "$(STA_HOLD_DIR)/cell-changes.json"
	@cd "$(YOSYS_STA_HOME)" && ulimit -v $(STA_MEMORY_KIB) && export STA_PDK="$(STA_PDK)" STA_NETLIST="$(STA_HOLD_DIR)/repaired.v" STA_DESIGN="$(STA_DESIGN)" STA_SDC="$(STA_RESULT_DIR)/opensta.sdc" STA_OUTPUT="$(STA_HOLD_DIR)" && set -o pipefail && "$(OPENSTA)" -exit "$(NPC_HOME)/syn/opensta.tcl" 2>&1 | tee "$(STA_HOLD_DIR)/opensta.log"
	@python3 "$(NPC_HOME)/syn/check_opensta.py" --paths "$(STA_HOLD_DIR)/opensta.json" --report "$(STA_HOLD_DIR)/opensta.rpt" --log "$(STA_HOLD_DIR)/opensta.log" --output "$(STA_HOLD_DIR)/timing-summary.json"
