# RV64 layered-system cleanup receipt

- retained current L2 cache: `.github/runtime-artifacts/rv64-mini-system-current/artifacts`
- retained current L3 cache: `.github/runtime-artifacts/rv64-lightweight-linux-current/artifacts`
- retained formal L2 result: `.github/task-runs/2026-08-05-rv64-v15b-l2-mini-system-all-a9`
- retained formal L3 result: `.github/task-runs/2026-08-05-rv64-v15c-l3-lightweight-linux-all-a3`
- removed regenerated L3 build probe: `.github/runtime-artifacts/rv64-lightweight-linux-build-probe` (123 MiB)
- removed migrated replay probes: `.github/runtime-artifacts/rv64-l2-checker-replay-probe`, `.github/runtime-artifacts/rv64-l3-checker-replay-probe`
- removed transient diagnostic xtrace: `.github/runtime-artifacts/rv64-v15c-static-diagnostics/test-agent-flow-xtrace.log`
- recovery: removed items were runtime-only and can be rebuilt; formal task-run results and current identity-bound caches were not removed
