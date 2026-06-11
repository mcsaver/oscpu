# Task Report

## 基本信息

- `task_id`: 2026-06-02-rv64-ubuntu-shell-abortfix
- `task_slug`: rv64-ubuntu-shell-abortfix
- `graph_template`: `rv64-ubuntu-probe-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: Codex
- `started_at`: 2026-06-02
- `updated_at`: 2026-06-02

## 任务目标

- `source_request`: 使用用户的 RV64 core，根据项目记忆继续启动完成 Ubuntu 22.04；遇到 SRET/Sv39/RVC/return 预测相关问题必须先修 bug，不能靠跳过用例或关闭 direct RAS 跑通。
- `goal`: 在保留 focused 覆盖和 direct RAS return fast path 的前提下，让 NPC/Verilator 跑到 Ubuntu 22.04 initramfs 内官方 `/bin/sh -c` marker。
- `scope`: `npc/rv64` OoO LSU AXI bridge flush/abort 语义、相关 testbench、Ubuntu shell initramfs gate、项目 memory/task-run 记录。

## 选图说明

- `selected_template`: `rv64-ubuntu-probe-loop`
- `why_this_graph`: 本轮直接处理 Linux/Ubuntu 长链启动卡点，并以 guest-watch marker 作为验收，而不是只看局部 smoke。
- `dynamic_nodes_added`: `lsu-read-abort-contract`、`ubuntu-shell-clean-gate`
- `why_dynamic_nodes_were_needed`: 卡点来自 bridge/xbar flush response ownership，不是既有 agent 图里的单一 ISA focused gate；同时需要一次干净长跑证明修复已越过 `/init` 和 `/bin/sh -c`。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| reproduce-contract | rv64-linux | completed | Ubuntu shell timeout history, SRET/Sv39/RAS smokes | read flush-abort root cause | `OooMemAxiBridge` waited for R after xbar could cancel read |
| rtl-fix | verilator-tapeout | completed | bridge FSM and xbar abort contract | read/page-walk flush releases locally; write drain unchanged | `npc/rv64/vsrc/core/OooMemAxiBridge.v` |
| focused-tests | rv64-linux | completed | updated bridge testbench | in-flight read flush-abort covered | `tb_ooo_mem_axi_bridge` PASS |
| regression | rv64-linux | completed | current rv64 build | focused 5/5 PASS, SRET/Sv39/RAS smokes GOOD TRAP | logs under `/tmp/codex-rv64-clean-regress` and tool output |
| ubuntu-shell-clean-gate | rv64-linux | completed | OpenSBI + Linux Image + shell initramfs | `[ysyx-sh] /bin/sh -c marker` matched | `npc/rv64/env/logs/codex-shell-clean-3000m/console.log` |

## RTL 推导摘要

- `requirements`: flush 后的读事务不得阻塞后续 trap/redirect；写事务不得因为 flush 丢失外部副作用；direct RAS 不能作为 workaround 关闭。
- `protocol`: `NpcAxiBus/AxiLiteXbar` 的 read abort 可以在 slave AR 尚未发出前取消 master-accepted read；若 slave AR 已发出，则 xbar 可 drop 后续 R。读/page-walk flush 后没有外部副作用，bridge 不再拥有 post-flush R。
- `fsm`: `S_WALK_R/S_READ_DATA` 遇 `flush_i` 直接进入 `S_IDLE` 并清 `drop_rsp_q`；非 flush 的遗留 read response 仍按原路径消费；AW/W/B 写路径保持 drain。
- `invariants`: read flush releases; write flush drains; no CPU response after flush; next CPU request can fire after abort; D-cache store update happens only after successful B.

## 关键产物

- `artifacts`:
  - `npc/rv64/vsrc/core/OooMemAxiBridge.v`
  - `npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv`
  - `npc/rv64/env/logs/codex-shell-clean-3000m/console.log`
  - `npc/rv64/env/logs/codex-shell-clean-3000m/npc.log`
- `logs_or_traces`:
  - `/tmp/codex-rv64-clean-regress/logs/tb_ooo_mem_axi_bridge.log`
  - `/tmp/codex-rv64-clean-regress/logs/tb_ooo_sv39_boot.log`
  - `/tmp/codex-rv64-clean-regress/logs/tb_ooo_priv_system.log`
  - `/tmp/codex-rv64-clean-regress/logs/tb_ooo_fetch_axi_bridge.log`
  - `/tmp/codex-rv64-clean-regress/logs/tb_ooo_fetch_trap_gate.log`
- `linked_memory_updates`:
  - `.github/memory/project-status.md`
  - `.github/memory/modules/npc.md`
  - `.github/memory/known-issues.md`

## 验证记录

- `make -B -C npc/rv64 -j1`: PASS.
- focused module regression: `tb_ooo_mem_axi_bridge/tb_ooo_sv39_boot/tb_ooo_priv_system/tb_ooo_fetch_axi_bridge/tb_ooo_fetch_trap_gate` 5/5 PASS.
- smoke regression: `smoke-jal-link smoke-branch-raw smoke-sret-user smoke-sret-user-pagefault smoke-sret-user-sv39 smoke-sret-restore smoke-ras-trap-boundary` 全部 GOOD TRAP.
- Ubuntu shell gate: `[ysyx-init] Ubuntu 22.04 initramfs reached`、`PRETTY_NAME="Ubuntu 22.04.5 LTS"`、`[ysyx-sh] /bin/sh -c marker`，`GUEST EXPECT MATCH`，`cycles=991670090`，`commits=481347843`，`CPI=2.060`，`simulation frequency=150957 inst/s`.
- `git diff --check`: PASS.

## 当前阻塞点

- `blockers`: 本轮目标无阻塞；initramfs 内官方 `/bin/sh -c` gate 已闭合。
- `missing_dependencies`: rootfs/virtio-blk、Linux-visible framebuffer/display、多源设备栈、UART RX/TTY 交互、完整 FP fflags/dynamic rounding 与最终 PPA 仍未作为本轮目标声明通过。
- `risk_assessment`: 如果后续引入多 outstanding 或 response queue，必须重新证明 flush 后 response ownership，不可复用“master AR fire 必有 R”的旧假设。

## 下一步建议

1. 进入 `rv64-ubuntu-rootfs-loop`，优先补 virtio-blk/rootfs mount 需要的设备和 DTB 契约。
2. 进入 `linux-display-loop` 前先明确 Linux-visible framebuffer/DRM/virtio-gpu 选型，不把当前 VGA/SDL host stub 当作 Linux display。
3. 若继续优化 CPI，先做 line-based cache 或 response queue 的所有权证明，再跑 Ubuntu 窗口 A/B。

## 模板升级候选

- `repeated_dynamic_subgraph`: bridge/xbar flush ownership audit + focused abort test + clean Ubuntu guest-watch.
- `should_promote_to_static_template`: 是。
- `reason`: Linux 长链启动中 flush/orphan response 是高复发风险，后续多 outstanding/LSQ/cache line fill 都会再次碰到同类 contract。

## 收尾结论

- `final_result`: NPC RV64 已在 direct RAS 开启、SRET/Sv39/RVC focused 不跳过的条件下跑通 Ubuntu 22.04 shell initramfs `/bin/sh -c` marker。
- `evidence_summary`: focused 5/5 PASS；SRET/Sv39/RAS smokes GOOD TRAP；clean Ubuntu shell gate `GUEST EXPECT MATCH`，`cycles=991670090/commits=481347843/CPI=2.060`。
- `notes`: 本轮修复的是 read flush-abort ownership bug；rootfs/virtio/display 仍是独立后续 gate。
