SHELL := /bin/bash

PYTHON ?= python3
TOOL := eval/ppa/tools/architecture_debt_current.py
TEST := eval/ppa/tests/test_architecture_debt_current.py
DELTA_TOOL := eval/ppa/tools/architecture_debt_delta_rebind.py
DELTA_TEST := eval/ppa/tests/test_architecture_debt_delta_rebind.py
MUTATION_TEST := testbench/scripts/test_run_architecture_delta_mutations.py
RECEIPT := npc/rv64/eval/ppa/evidence/architecture-debt-current.json
DELTA_RECEIPT := npc/rv64/eval/ppa/evidence/architecture-debt-delta-rebind-current.json
LEDGER := npc/rv64/design/arch/architecture-debt-ledger.json

.PHONY: check-architecture-debt-current test-architecture-debt-current capture-architecture-debt-current

check-architecture-debt-current: test-architecture-debt-current
	@$(PYTHON) -B $(DELTA_TOOL) verify --input $(DELTA_RECEIPT)
	@$(PYTHON) -B $(TOOL) verify --input $(RECEIPT) --ledger $(LEDGER)

test-architecture-debt-current:
	@$(PYTHON) -B -m unittest -q $(TEST)
	@$(PYTHON) -B -m unittest -q $(DELTA_TEST)
	@$(PYTHON) -B -m unittest -q $(MUTATION_TEST)

capture-architecture-debt-current:
	@$(PYTHON) -B $(TOOL) refresh --output $(RECEIPT) --ledger $(LEDGER)
