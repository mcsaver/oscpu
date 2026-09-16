# Run the captured old core with explicit external workspace dependencies.
.DEFAULT_GOAL := help
SHELL := /bin/bash
PACKAGE_DIR := $(abspath .)
WORKSPACE ?= $(abspath ../../..)
LEGACY_MAKE = $(MAKE) --no-print-directory -C $(PACKAGE_DIR)/rv64 -f Makefile.legacy -I $(WORKSPACE)/npc/rv64 NEMU_HOME=$(WORKSPACE)/nemu YSYX_HOME=$(WORKSPACE) YOSYS_STA_HOME=$(WORKSPACE)/yosys-sta OSS_CAD_SUITE_HOME=$(WORKSPACE)/oss-cad-suite
.PHONY: help verify all default lint print-synth-rtl print-product-rtl-config
help:
	@echo 'Legacy rv64core source snapshot: 2026-09-16'
	@echo 'make verify | lint | all | print-synth-rtl'
	@echo 'Set WORKSPACE=/absolute/ysyx-workbench when relocated.'
verify:
	@sha256sum --quiet -c SHA256SUMS
	@echo '[PASS] legacy source checksums'
all default:
	@$(LEGACY_MAKE) default
lint print-synth-rtl print-product-rtl-config:
	@$(LEGACY_MAKE) $@
