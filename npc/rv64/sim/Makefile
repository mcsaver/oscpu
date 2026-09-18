.DEFAULT_GOAL := system
.DELETE_ON_ERROR:
include build.mk
.PHONY: all core system tensor lint reference
all system: $(SYSTEM_BIN)
core: $(CORE_BIN)
tensor: $(TENSOR_BIN)
lint: core-lint system-lint
reference:
	$(MAKE) --no-print-directory -C $(R64_HOME)/difftest reference CORE_REF=$(CORE_REF)
