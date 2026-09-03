# Freeze the repository root before any future include can change
# MAKEFILE_LIST.  Command-line and environment overrides remain supported.
ifeq ($(origin NEMU_HOME), undefined)
NEMU_HOME := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
endif
BUILD_DIR ?= $(NEMU_HOME)/build/unit-tests

CC ?= cc
CPPFLAGS += -I$(NEMU_HOME)/tests -I$(NEMU_HOME)/include \
  -DCONFIG_CACHE_STATISTIC=1
CFLAGS ?= -O2 -g
CFLAGS += -std=gnu11 -Wall -Wextra

TESTS := bpu_unit cache_unit
TEST_BINS := $(addprefix $(BUILD_DIR)/,$(TESTS))

.PHONY: all check clean

all: check

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/bpu_unit: \
    $(NEMU_HOME)/tests/bpu_unit.c \
    $(NEMU_HOME)/src/cpu/bpu.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) $^ -o $@

$(BUILD_DIR)/cache_unit: \
    $(NEMU_HOME)/tests/cache_unit.c \
    $(NEMU_HOME)/src/memory/cache.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) $^ -o $@

check: $(TEST_BINS)
	@set -e; \
	for test_bin in $(TEST_BINS); do \
	  "$$test_bin"; \
	done

clean:
	$(RM) -r $(BUILD_DIR)
