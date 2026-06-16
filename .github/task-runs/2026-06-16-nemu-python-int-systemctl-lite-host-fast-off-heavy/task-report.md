# NEMU PyLong Systemctl-Lite Host-Fast-Off Heavy

## 任务

继续推进 NEMU full Ubuntu 22.04 的 PyLong/int transient blocker [76]。在已经完成默认 fast path `systemctl-lite` 基线和 `NEMU_INTERPRETER_WIDE_IFETCH=0` 同口径 A/B 后，本轮关闭 `NEMU_VADDR_HOST_FAST`，验证 host fast vaddr path 关闭后是否仍会复现 PyLong/int state corruption。

## 配置

- profile 边界：NEMU-only，`scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu-profile` PASS。
- runner：`run-systemctl-lite-host-fast-off-heavy.sh`。
- gate：`make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight`。
- rootfs：full Ubuntu 22.04 rootfs + 独立 overlay。
- `NEMU_VADDR_HOST_FAST=0`。
- `NEMU_PYTHON_INT_STAGE_MODE=systemctl-lite`。
- `NEMU_PYTHON_INT_LOOPS=10`。
- `NEMU_PYTHON_INT_STAGE_TIMEOUT=360`。
- `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=320000000000`。
- `NEMU_PYTHON_INT_CHECK_TIMEOUT=9000`。
- `NEMU_PYTHON_INT_BOOT_TIMEOUT=3600`。
- `NEMU_PYTHON_INT_POWEROFF=0`。

## 并行环境说明

启动前发现 NPC 侧仍有 `NpcSimTop` 在运行 `.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-raw-bytes-loop/`。本轮不杀 NPC，保持 NEMU/NPC 开发环境隔离但可并行的要求；因此本 run 的 wall time 不作为性能基线，只用于 PyLong/int 正确性和复现率判断。

## 结果

- 状态：FAIL-diagnostic。
- `run.rc`：2。
- runtime flags：`runtime.wide_ifetch=1`、`runtime.decode_cache=1`、`runtime.vaddr_host_fast=0`、`runtime.mmu_tlb=1`。
- stage 结果：
  - `before-runtime:0`
  - `runtime-after-core-tools:0`
  - `runtime-after-systemd-files:0`
  - `runtime-after-systemctl-daemon-reload:0`
  - `runtime-after-systemctl-root-enable:0`
  - `runtime-after-systemctl-runtime-start:0`
  - `runtime-after-systemctl:1`
  - `after-runtime:0`
- 失败点：`runtime-after-systemctl` 的 prewarm 阶段 import `datetime` 时在 `/usr/lib/python3.10/datetime.py` 中触发 `assert abs(microseconds) < 3.1e6`，`timedelta(microseconds=1)` 断言失败。
- 恢复特征：随后 `after-runtime` 阶段同一 PyLong/int probe 恢复为 `rc=0`，最终 `__NEMU_PYTHON_INT_FOCUSED_RC__:1`、`__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=1`。
- summary 记录缺口：本 run 使用修复前的 `Linux/scripts/check-nemu-python-int-preflight.sh`，因此 `python-int-preflight-summary.tsv` 仍停在 `status=started`，没有最终 `status=fail`/`stage_rc.*`。本轮已在脚本层补 `append_summary_result()`，并用后续 e2e 与 fail-path 行为测试验证。

## 结论

`NEMU_VADDR_HOST_FAST=0` 不能消除当前 PyLong/datetime transient blocker；host-fast-off + `systemctl-lite` 仍能复现失败。该结果说明 host fast vaddr path 不是必要条件，或至少不是唯一触发条件；下一步不应把调查收窄为“只修 host fast path”，而应继续围绕 guest memory/PyLong object 状态、`datetime.timedelta` 构造路径和 systemctl runtime 阶段前后的瞬态状态做更短 reproducer。

## 证据入库

待执行 `index-evidence --write-index`、`archive-markdown`、memory 更新与 DB audit。本 run 的原始 evidence 保留在 `evidence/python-int-systemctl-lite-host-fast-off/`，其中 `rootfs-overlay.raw` 体量较大，只登记摘要，不直接塞入 memory。

## 边界

本 run 不替代完整 Ubuntu 22.04 full hard gate，不替代 NEMU performance profile 基线，也不证明 NPC UART/root shell 问题。
