# NEMU PyLong Systemctl-Lite Wide-Ifetch-Off Heavy

## 任务

继续推进 NEMU full Ubuntu 22.04 的 PyLong/int transient blocker [76]。在已经完成默认 fast path `systemctl-lite` 基线后，本轮用同一 stage/loops 口径关闭 `NEMU_INTERPRETER_WIDE_IFETCH`，验证 wide-ifetch slow path 是否更容易复现 PyLong/int state corruption。

## 配置

- profile 边界：NEMU-only，`scripts/agent-e2e.sh --validate-profile --profile nemu-ubuntu-profile` PASS。
- runner：`run-systemctl-lite-wide-ifetch-off-heavy.sh`。
- gate：`make -C Linux ARCH=riscv64-nemu check-nemu-python-int-preflight`。
- rootfs：full Ubuntu 22.04 rootfs + 独立 overlay。
- `NEMU_INTERPRETER_WIDE_IFETCH=0`。
- `NEMU_PYTHON_INT_STAGE_MODE=systemctl-lite`。
- `NEMU_PYTHON_INT_LOOPS=10`。
- `NEMU_PYTHON_INT_STAGE_TIMEOUT=300`。
- `NEMU_PYTHON_INT_CHECK_MAX_CYCLES=240000000000`。
- `NEMU_PYTHON_INT_CHECK_TIMEOUT=7200`。
- `NEMU_PYTHON_INT_BOOT_TIMEOUT=2400`。
- `NEMU_PYTHON_INT_POWEROFF=0`。

## 并行环境说明

启动前发现 NPC 侧仍有 `NpcSimTop` 在运行 `.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-access-trace/`。本轮不杀 NPC，保持 NEMU/NPC 开发环境隔离但可并行的要求；因此本 run 的 wall time 不作为性能基线，只用于 PyLong/int 正确性和复现率判断。

## 结果

- 结果：PASS。
- `run.rc=0`。
- `python-int-preflight-summary.tsv` 显示 `status=pass`。
- `stage_count=8`。
- `runtime.wide_ifetch=0`、`runtime.decode_cache=1`、`runtime.vaddr_host_fast=1`、`runtime.mmu_tlb=1`。
- 8 个 stage 全部 `stage_rc.*=0`：
  - `before-runtime`
  - `runtime-after-core-tools`
  - `runtime-after-systemd-files`
  - `runtime-after-systemctl-daemon-reload`
  - `runtime-after-systemctl-root-enable`
  - `runtime-after-systemctl-runtime-start`
  - `runtime-after-systemctl`
  - `after-runtime`
- `done_line=__NEMU_PYTHON_INT_PREFLIGHT_DONE__ rc=0`。
- `boot_seconds=145`、`total_seconds=371`。因启动前存在 NPC 并行长跑，该耗时只作环境参考，不作为性能基线。
- console 负向扫描未发现 `__NEMU_CHECK_FAIL__`、`Traceback`、`OverflowError`、`ValueError`、`AssertionError`。

## 结论

同口径 `systemctl-lite` 下关闭 `NEMU_INTERPRETER_WIDE_IFETCH` 的单次重型 run 未复现 [76]。这与此前 `full-lite` wide-ifetch-off 首跑曾复现、diag rerun 又 PASS 的不稳定性一致：wide-ifetch-off 可以暴露问题，但单样本 PASS 不能排除 wide-ifetch，也不能关闭 PyLong/int blocker。下一步应跑同一 `systemctl-lite` 口径的 `NEMU_VADDR_HOST_FAST=0`，或加入更贴近 CPython small-int/PyLong object 布局的 guest-side sentinel。

## 证据入库

- `index-evidence --write-index --yes`：PASS，`assets=9 runs=1 index_docs=1 stored_index_docs=1`。
- `archive-markdown ... --backup-dir .github/db-backup/task-runs --yes`：PASS，task-run Markdown retained。

## 边界

本 run 只验证 wide-ifetch-off + systemctl-lite 口径下的 PyLong/int probe 行为。即使 PASS，也不能排除 wide-ifetch 或 host-fast path；即使 FAIL，也需要结合 stage、stack 和 after-runtime 恢复情况继续定位 NEMU 指令/访存/CPython object 状态根因。
