# Literal RV64 IFU evidence dispatch only.  Keep this file free of includes,
# variables, conditionals and generated rules so `make -n` is side-effect free.
.PHONY: check-ifu-axi-flush-drain
check-ifu-axi-flush-drain:
	@bash ../../.github/task-runs/2026-07-22-rv64-v9g-ifu-axi-current-design/run-focused.sh

.PHONY: check-ifu-access
check-ifu-access:
	@bash ../../.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/run-focused.sh
