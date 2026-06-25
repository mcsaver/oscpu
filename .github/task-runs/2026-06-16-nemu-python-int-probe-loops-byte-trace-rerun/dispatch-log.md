# Dispatch Log

## 2026-06-21

- 确认 `doctor --fail-on-drift` 当前 `blocking_drift=0`，历史 manual log/旧 shim 不作为本轮 blocker。
- 修改 PyLong probe：新增 `validate_loop_count()`、`PROBE_LOOPS_*`、`PYLONG_PROBE_LOOPS_PREPARSE_*`。
- 跑 host smoke：`python3 Linux/tools/nemu-python-int-preflight.py --mode int10-create --tag host-smoke --loops 2/20` PASS。
- 跑静态验证：
  - `python3 -m py_compile Linux/tools/nemu-python-int-preflight.py` PASS。
  - `bash -n Linux/scripts/check-nemu-python-int-preflight.sh scripts/e2e/modules/nemu.sh` PASS。
  - `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j2` PASS。
  - `scripts/agent-e2e.sh --profile nemu-dev --task-slug 2026-06-16-nemu-probe-loops-guard-contract-rerun --stop-on-fail` PASS。
  - `scripts/agent-e2e.sh --profile nemu-dev --task-slug 2026-06-16-nemu-probe-loops-preparse-contract --stop-on-fail` PASS。
- 跑 heavy diagnostics：
  - `probe-loops-byte-trace-rerun` FAIL，抓到 `PROBE_LOOPS` 对象 `ob_size` 损坏。
  - `probe-loops-preparse-byte-trace-rerun` FAIL，证明 literal `20` 正常，`int("20")` 返回的新对象坏。
- 修复 trace 盲点：
  - 新增 `vaddr-write-value-trace`，serial value marker 同时 arm vaddr/paddr value trace。
  - summary 增加 `runtime.vaddr_write_value_trace`。
  - `scripts/agent-e2e.sh --profile nemu-dev --task-slug 2026-06-16-nemu-vaddr-value-trace-contract --stop-on-fail` PASS。
  - 修正 value trace 为 user-only，避免 kernel/S-mode 写入噪声。
- 后续 heavy diagnostics：
  - `vaddr-value-trace-rerun` PASS，接线可运行但初版噪声大。
  - `vaddr-value-user-trace-rerun` PASS，user-only trace 可运行。
  - `vaddr-value-exact-trace-rerun` PASS，精确坏值 trace 可运行但该样本未复现 PyLong failure。
- 2026-06-21 继续本轮修复：
  - 新增 `Linux/tools/nemu-python-int-trace-correlate.py`，自动关联失败对象
    `ob_size` vaddr/paddr 与 `vaddr-write-value-trace`。
  - `vaddr-value-exact-trace-rerun-2` PASS，summary `status=pass`，correlate
    输出 `TARGETS=0 VALUE_HITS=2 TARGET_HITS=0`。
  - `vaddr-value-byte-trace-rerun-2` FAIL，`runtime-after-identity` stage rc=1；
    correlate 输出失败对象 `0x3f89dfc4d0`、`ob_size vaddr=0x3f89dfc4e0`、
    `paddr=0x857e84e0`，`VALUE_HITS=12217 TARGET_HITS=0`。
  - 修复 `serial_port_flush_tx()` marker 处理顺序，避免 NEMU Log 插入
    Python marker 行；同步 `nemu-dev` 合同。
  - 验证：`py_compile` PASS，`bash -n` PASS，NEMU build PASS，
    `scripts/agent-e2e.sh --profile nemu-dev --task-slug 2026-06-21-nemu-trace-correlate-contract-rerun --stop-on-fail` PASS。
