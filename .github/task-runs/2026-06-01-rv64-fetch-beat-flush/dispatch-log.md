# Dispatch log

## 任务分解

1. 读取项目 agent/memory/instructions，确认本轮必须遵循 RTL workflow、先定位 root cause、最后更新 memory/task-run。
2. 对 RV64 IFU/LSU/front-end CPI 热点做局部画像，选择低风险入口：先减少 IFU packet miss 的 `PC`/`PC+4` 串行读。
3. 修改 `OooFetchAxiBridge` demand miss 协议，用一个 64-bit beat 填两条指令；同步更新 Sv39 boot testbench 的 mock memory。
4. 运行 focused Sv39/priv/mem bridge 回归，定位 faster IFU 暴露的 precise trap flush 问题。
5. 修复 `OooAluFetchCore` 中 commit exception 同拍仍允许年轻 stop/drain/dispatch 捕获的问题。
6. 运行 focused SV、RV64 build、全量 `riscv64-npc` cpu-tests，并与上一轮 direct RAS 日志做 A/B。
7. 固化 task-run、module memory、known issue 与 project status。

## Root cause notes

- 取指侧 root cause: 现有 packet fetch 本来每个 packet 需要两条 32-bit 指令，但 demand miss 路径仍把 `PC` 与 `PC+4` 拆成两个串行 AXI-Lite read；在分页后 ITLB/bridge 命中改善后，这个串行读成为更明显的固定 miss 成本。
- flush 侧 root cause: faster IFU 让同拍事件更紧凑后，`csr_trap_mem_valid_w` 触发 commit exception 的同一时钟，后续 stop/drain/dispatch capture 逻辑仍可能运行，导致更年轻 fetch fault/JALR 状态覆盖精确异常快照。修复后 commit exception 成为同拍屏障，trap flush 保持到 backend drained。

## 验证证据

- Focused SV 3/3 PASS: `tb_ooo_sv39_boot tb_ooo_mem_axi_bridge tb_ooo_priv_system`
- `make -C npc/rv64 -j1`: PASS
- `riscv64-npc` cpu-tests: 56/56 PASS
- A/B: total cycles `183747 -> 175112`，weighted CPI `1.237970 -> 1.179793`

## 后续建议

- 完整 line-based I-cache/D-cache：优先从可控的 I-cache multi-word line fill 或 D-cache physical line fill 做起，配套 hit/miss 统计和 old/new log A/B。
- AXI-Lite 多 outstanding/xbar 并行化：需要先定义 response ownership 和 flush/orphan response 协议，避免复发旧 memory response ownership 问题。
- 非 return JALR target prediction：`recursion` 的剩余 jump wait 已不是 RAS return 缺口，下一步应面向函数指针/indirect call 的 BTB 或 selective squash。
