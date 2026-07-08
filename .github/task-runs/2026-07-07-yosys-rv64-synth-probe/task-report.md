# 2026-07-07 Yosys RV64 Synthesis Probe

## 目标

在暂停 Ubuntu/rootfs 启动前，先确认当前 RV64 NPC 是否已经能用 Yosys 产出一版综合结果，并把不能进入 STA-ready 标准单元网表的阻塞点收敛到可继续优化的对象。

## 变更

- 下载并使用本地 `oss-cad-suite`，Yosys 版本为 `0.66+197`；`npc/rv64 syn-check-env` 已通过。
- `yosys-sta` 增加 `VERILOG_INCLUDE_DIRS`，解决 RV64 RTL 读取 `define.v` 的 include 失败。
- `yosys-sta` 增加 `SYNTH_FLATTEN`、`SYNTH_SHARE`、`SYNTH_STOP_AFTER_COARSE`、`SYNTH_PUBLIC_AUTONAME` 开关。
- `npc/rv64/Makefile` 的 `syn/sta` 路径透传上述开关；RV64 默认采用 hierarchy + no-share，避免全顶首次综合被 flatten 与 SAT sharing 放大。

## 成功证据

全顶 `NpcTop` 已能完成 Yosys frontend/coarse generic synthesis：

```sh
make -C npc/rv64 syn STA_CLK_FREQ_MHZ=100 STA_SYNTH_STOP_AFTER_COARSE=1
```

产物：

- `npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v`
- `npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v.il`
- `npc/rv64/build/sta/NpcTop-100MHz/NpcTop.netlist.v.json`
- `npc/rv64/build/sta/NpcTop-100MHz/synth_check.txt`
- `npc/rv64/build/sta/NpcTop-100MHz/synth_stat.txt`

关键证据：

- `synth_check.txt`: `Found and reported 0 problems.`
- `NpcTop.netlist.v`: `248825` 行，约 `8.2M`
- `NpcTop.netlist.v.il`: `726310` 行，约 `45M`
- `NpcTop.netlist.v.json`: 约 `89M`
- `NpcTop.netlist.v` sha256: `d08c22037150f7e8489726363a1b9ef26e3fe0805df0e2bf894928986ebc3e4c`

证据目录：

- `.github/task-runs/2026-07-07-yosys-rv64-synth-probe/evidence/syn-100mhz/synth_check.coarse.txt`
- `.github/task-runs/2026-07-07-yosys-rv64-synth-probe/evidence/syn-100mhz/synth_stat.coarse.txt`
- `.github/task-runs/2026-07-07-yosys-rv64-synth-probe/evidence/syn-100mhz/NpcTop-100MHz.coarse.files.txt`
- `.github/task-runs/2026-07-07-yosys-rv64-synth-probe/evidence/syn-100mhz/NpcTop-100MHz.coarse.sha256`
- `.github/task-runs/2026-07-07-yosys-rv64-synth-probe/evidence/syn-100mhz/make-syn-coarse.markers.log`

## 未闭合边界

这还不是 STA-ready 标准单元网表。

- 全顶 `NpcTop` full stdcell synthesis 在 `900s` 窗口内未完成；当前首要热点是 `OooFetchPacketCache.v:129` 的 4096-bit `valid_next_r[invalidate_idx]` 动态写，fine/simplemap 阶段展开为巨量 mux/shift。
- `PmpChecker` 单模块 full stdcell smoke 也未在 `600s` 内完成。关闭 public `autoname` 后，它越过了早期长命名点，但在 ABC 抽取/映射阶段被 timeout 终止，说明 PMP/NAPOT 范围比较本身也是独立综合热点。

对应证据：

- `make-syn-hier-noshare2.timeout-tail.log`
- `make-syn-hier-noshare2.timeout-markers.log`
- `make-syn-pmpchecker-gate-noautoname.tail.log`
- `make-syn-pmpchecker-gate-noautoname.markers.log`

## 实现者交付

已交付一版可复现的全顶 `NpcTop` Yosys coarse generic netlist，且 `check` 为 0 problems；综合入口不再手工拼参数，直接从 `npc/rv64` 执行 `make syn` 并按开关控制即可。

## 收尾验证

- `git diff --check` PASS。
- `bash -n scripts/e2e/modules/npc.sh scripts/e2e/modules/toolchain.sh` PASS。
- `make -C npc/rv64 syn-check-env` PASS。
- `scripts/agent-e2e.sh --profile yosys-sta --task-slug yosys-rv64-synth-probe-yosys-sta --stop-on-fail` PASS。
- `scripts/agent-e2e.sh --profile npc-dev --task-slug yosys-rv64-synth-probe-npc-dev --stop-on-fail` PASS（第二次 run：`2026-07-07-yosys-rv64-synth-probe-npc-dev-2`）。
- `scripts/agent-e2e.sh --profile agent-system --task-slug yosys-rv64-synth-probe-agent-system --stop-on-fail` PASS（第二次 run：`2026-07-07-yosys-rv64-synth-probe-agent-system-2`）。
- `scripts/agent-e2e.sh --guard --guard-mode strict` PASS。

## 审查者结论

不能把本轮结论升级为“已经可以 STA/时序签核”。当前只证明 RV64 RTL 的 Yosys frontend/coarse synthesis 可通过；full stdcell/STA 前必须先优化两个工具不友好热点：fetch packet cache 的动态位写结构，以及 `PmpChecker` 的 NAPOT/TOR 展开逻辑或映射策略。

## 下一步

1. 先重写 `OooFetchPacketCache` 的 valid 位更新结构，避免整条 4096-bit 向量动态索引写在 Yosys fine pass 中爆炸。
2. 再对 `PmpChecker` 做 OOC 综合优化：将 per-entry lower/upper/cover 计算拆成更可共享的结构，或在 STA 前用局部参数/生成块减少重复函数展开。
3. 两个热点过门级 smoke 后，再恢复 `NpcTop` full stdcell synthesis，并随后进入 iEDA STA。
