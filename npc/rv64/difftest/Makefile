.DEFAULT_GOAL := reference
DIFFTEST_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CORE_REF ?= $(abspath $(DIFFTEST_DIR)/../../../nemu/build/rv64-rebuild-reference/riscv64-nemu-interpreter-so)
.PHONY: reference
reference:
	bash $(DIFFTEST_DIR)/scripts/prepare_r64_reference.sh $(dir $(CORE_REF))
