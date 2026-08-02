# Literal RV64 CONTROL-EVENT evidence dispatch only. Keep this file free of
# includes, variables, conditionals and generated rules.
.PHONY: check-control-event-sq-retry
check-control-event-sq-retry:
	@bash ../../.github/task-runs/2026-08-01-rv64-v11x-control-event-v9r-compact-rebind/run-focused.sh

.PHONY: check-control-event-current
check-control-event-current:
	@bash ../../.github/task-runs/2026-08-01-rv64-v11x-control-event-v9r-compact-rebind/run-control-event-current.sh
