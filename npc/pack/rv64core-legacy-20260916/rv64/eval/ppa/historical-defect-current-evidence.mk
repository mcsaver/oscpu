SHELL := /bin/bash

PYTHON ?= python3
TOOL := eval/ppa/tools/historical_defect_current.py
TEST := eval/ppa/tests/test_historical_defect_current.py
RECEIPT := npc/rv64/eval/ppa/evidence/historical-defect-current.json
LEDGER := npc/rv64/design/arch/historical-defect-backfill-ledger.json

.PHONY: check-historical-defect-current test-historical-defect-current capture-historical-defect-current

check-historical-defect-current: test-historical-defect-current
	@$(PYTHON) -B $(TOOL) verify --input $(RECEIPT) --ledger $(LEDGER)

test-historical-defect-current:
	@$(PYTHON) -B -m unittest -q $(TEST)

capture-historical-defect-current:
	@$(PYTHON) -B $(TOOL) refresh --output $(RECEIPT) --ledger $(LEDGER)
