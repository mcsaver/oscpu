SHELL := bash

RUNNER := $(CURDIR)/scripts/act4-arch-run.sh
NEMU_HOME ?= $(abspath $(CURDIR)/../../nemu)
NPC_RV64_HOME ?= $(abspath $(CURDIR)/../../npc/rv64)
JOBS ?= 2

ACT4_TARGET ?= nemu
ACT4_SUITES ?= rv64i/I
ACT4_FILTER ?=
ACT4_LIMIT ?= 0
ACT4_TIMEOUT_SEC ?= 60
ACT4_MAX_INSTS ?= 20000000
ACT4_MAX_CYCLES ?= 20000000

RUN_ARGS := --target $(ACT4_TARGET) \
            --suites "$(ACT4_SUITES)" \
            --limit $(ACT4_LIMIT) \
            --timeout-sec $(ACT4_TIMEOUT_SEC) \
            --max-insts $(ACT4_MAX_INSTS) \
            --max-cycles $(ACT4_MAX_CYCLES)

ifneq ($(strip $(ACT4_FILTER)),)
RUN_ARGS += --filter "$(ACT4_FILTER)"
endif

.PHONY: run run-nemu run-npc run-both smoke list build-final build-nemu build-npc clean

run:
	bash "$(RUNNER)" $(RUN_ARGS)

run-nemu:
	$(MAKE) run ACT4_TARGET=nemu

run-npc:
	$(MAKE) run ACT4_TARGET=npc

run-both:
	$(MAKE) run ACT4_TARGET=both

smoke:
	$(MAKE) run ACT4_TARGET=nemu ACT4_SUITES=rv64i/I ACT4_FILTER=I-add-00 ACT4_LIMIT=1

list:
	bash "$(RUNNER)" --list-suites

build-final:
	bash "$(RUNNER)" --build-final --list-suites

build-nemu:
	$(MAKE) -C "$(NEMU_HOME)" NEMU_HOME="$(NEMU_HOME)" -j$(JOBS)

build-npc:
	$(MAKE) -C "$(NPC_RV64_HOME)" -j$(JOBS)

clean:
	rm -rf "$(CURDIR)/build"
