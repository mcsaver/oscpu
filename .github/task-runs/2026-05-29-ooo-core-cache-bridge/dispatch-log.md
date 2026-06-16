# Dispatch Log

## 基本信息

- `task_id`: `2026-05-29-ooo-core-cache-bridge`
- `task_slug`: `ooo-core-cache-bridge`
- `graph_template`: `npc-sim-regression`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-29 14:05] `baseline` - `completed`

- `owner_agent`: Codex
- `trigger`: core-top 分离后全量 CPU-test 正确但 CPI 高。
- `depends_on`: `.github/AGENTS.md`、NPC memory/instructions 已读取；`2026-05-29-ooo-core-top-split` 已完成。
- `inputs`: `/tmp/ysyx-ooo-full-cputests-coretop.tsv`, `cpu-tests add`
- `action`: 确认真实 IFU/LSU 总线桥成为主要新瓶颈。
- `outputs`: 优化方向限定为 core 内 bridge/cache，不回退仿真直连。
- `evidence`: `add cycles=4012 commits=839 CPI=4.782`; full weighted CPI `4.690321`。
- `handoff_to`: `packet-icache`
- `next_step`: 优先消除重复 packet fetch miss。
- `notes`: 正确性优先，所有优化必须继续跑 CPU-test 全量。

### [2026-05-29 14:25] `packet-icache` - `completed`

- `owner_agent`: Codex
- `trigger`: fetch bridge 每次 request 都串行读 `PC` 和 `PC+4`。
- `depends_on`: `baseline`
- `inputs`: `OooFetchAxiBridge`
- `action`: 增加 128-entry direct-mapped packet I-cache；hit 下一拍 `S_RESP` 返回，`S_RESP` 可同拍接下一请求；store write fire 触发 packet overlap invalidate。
- `outputs`: `npc/single/vsrc/core/NpcCoreTop.v`
- `evidence`: `cpu-tests add` 降到 `cycles=1259 commits=839 CPI=1.501`; `fence-i` PASS。
- `handoff_to`: `word-dcache`
- `next_step`: 处理 load miss 串行等待。
- `notes`: 只缓存两个 word 都 OKAY 的 packet，payload array 仅由 valid bit 保护。

### [2026-05-29 14:45] `word-dcache` - `completed`

- `owner_agent`: Codex
- `trigger`: packet I-cache 后 add 仍有大量 LSU read miss。
- `depends_on`: `packet-icache`
- `inputs`: `OooMemAxiBridge`
- `action`: 增加 128-entry PMEM word D-cache；load hit 一拍响应，miss 填充；store write-through，hit 按 `wstrb` merge，full-word store miss 分配。
- `outputs`: `npc/single/vsrc/core/NpcCoreTop.v`
- `evidence`: `cpu-tests add` 降到 `cycles=998 commits=839 CPI=1.190`。
- `handoff_to`: `sim-stats`
- `next_step`: 加 cache event 统计确认 hit/miss。
- `notes`: MMIO/非 PMEM 不缓存，store 仍必须到 LSU bus。

### [2026-05-29 14:55] `sim-stats` - `completed`

- `owner_agent`: Codex
- `trigger`: 需要给下一轮优化提供每类 cache miss 数据。
- `depends_on`: `packet-icache`, `word-dcache`
- `inputs`: `NpcSimTop.sv`, bridge internal event wires
- `action`: 在 `NPC_OOO_ALU_EXPERIMENT` 下让仿真 cache 统计层次化观察 `u_core.u_ooo_fetch_bridge` 和 `u_core.u_ooo_mem_bridge`。
- `outputs`: 运行结束打印 OoO bridge icache/dcache access/hit/miss。
- `evidence`: `add`: `icache access=511 hit=471 miss=40`; `dcache load access=146 hit=64 miss=82`。
- `handoff_to`: `regression`
- `next_step`: 跑全量 CPU-test。
- `notes`: 统计是仿真观测，不进入 core ABI。

### [2026-05-29 15:05] `regression` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 优化完成且代表测试通过。
- `depends_on`: `sim-stats`
- `inputs`: `npc/single/build/NpcSimTop`, `am-kernels/tests/cpu-tests/build/*-riscv32-npc.bin`
- `action`: 重新构建 OoO 实验模式，跑 `add` 冒烟并执行 CPU-test 全量，收集每个测试 CPI。
- `outputs`: `/tmp/ysyx-ooo-full-cputests-idcache-final.tsv`
- `evidence`: `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4` PASS；CPU-test `40/40 PASS`; total `cycles=76597 commits=78676 weighted_cpi=0.973575`。
- `handoff_to`: `memory-update`
- `next_step`: 更新 memory 与 task report。
- `notes`: Difftest 当前配置未启用；本轮以全量 CPU-test GOOD TRAP 闭合正确性。

### [2026-05-29 15:25] `capacity-sweep` - `completed`

- `owner_agent`: Codex
- `trigger`: 128-entry bridge cache 后全量 CPI 仍为 `0.973575`。
- `depends_on`: `regression`
- `inputs`: `OooFetchAxiBridge`, `OooMemAxiBridge`, `/tmp/ysyx-ooo-cache-profile.tsv`
- `action`: 扫描 1024-entry 与 2048-entry direct-mapped bridge cache，并尝试 fetch miss 时 `pc+4` packet 预填。
- `outputs`: 保留 1024-entry；撤回 2048-entry 与 `pc+4` prefill。
- `evidence`: 1024-entry CPU-test `40/40 PASS`, weighted CPI `0.912113`; 2048-entry weighted CPI `0.912050`; prefill weighted CPI `0.929679`，虽 I-miss 降到 `1538` 但周期退化。
- `handoff_to`: `module-split`
- `next_step`: 按用户源码组织要求拆分 bridge module。
- `notes`: 后续预取不能串在 demand response 前面，应考虑后台预取或多 outstanding。

### [2026-05-29 15:35] `module-split` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户指出最好一个 module 一个源文件。
- `depends_on`: `capacity-sweep`
- `inputs`: `NpcCoreTop.v`
- `action`: 将 `OooFetchAxiBridge`、`OooMemAxiBridge` 从 `NpcCoreTop.v` 拆到独立源文件，并更新 `vsrc/filelist.mk`。
- `outputs`: `npc/single/vsrc/core/OooFetchAxiBridge.v`, `npc/single/vsrc/core/OooMemAxiBridge.v`
- `evidence`: `rg -n "^module |^endmodule"` 确认三个文件各仅一个 module；OoO build PASS；CPU-test 全量 `40/40 PASS`, weighted CPI `0.912113`。
- `handoff_to`: `next-optimization`
- `next_step`: 继续围绕非阻塞 line cache、LSQ/multi-outstanding 或控制流投机推进到 `CPI=0.5`。
- `notes`: 拆分只改变源码组织，不改变桥接协议。

### [2026-05-29 15:45] `optimization-flow-hardening` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求优化不能只看 `add`，必须全量优先并选择三类代表样本，同时固化一个 module 一个源文件规则。
- `depends_on`: `module-split`
- `inputs`: `/tmp/ysyx-ooo-full-cputests-split-1024cache.tsv`, `.github/AGENTS.md`, `.github/copilot-instructions.md`
- `action`: 新增 NPC 性能优化流程 instruction，并把全量 CPU-test 优先、三样本分析、module 单文件规则挂入本地工程流程；解析当前全量结果选代表样本。
- `outputs`: `.github/instructions/npc-optimization-workflow.instructions.md`, `.github/copilot-instructions.md`, `.github/AGENTS.md`, memory/task-report 更新。
- `evidence`: 当前 1024-cache 全量 weighted CPI `0.912113`; `highest_cpi=dummy`, `lowest_cpi=prime`, `near_average_cpi=leap-year`。
- `handoff_to`: `next-optimization`
- `next_step`: 后续所有性能 A/B 按该流程跑全量并分析三类样本。
- `notes`: `add` 仅保留为冒烟/历史对比，不再作为优化有效性依据。

### [2026-05-29 16:10] `dside-prefetch-negative` - `reverted`

- `owner_agent`: Codex
- `trigger`: 需要在全量优先流程下探索 1024-cache 后的下一项 CPI 优化。
- `depends_on`: `optimization-flow-hardening`
- `inputs`: `OooMemAxiBridge`, 三类代表样本与 high-excess 样本。
- `action`: 试验 D-cache idle/background next-word prefetch。
- `outputs`: 改动撤回。
- `evidence`: 短样本 `dummy/prime/leap-year/recursion/bubble-sort` 曾有改善，但 CPU-test 全量在 `bubble-sort` BAD TRAP。
- `handoff_to`: `same-cycle-ar`
- `next_step`: 避免隐式后台读事务；转向不增加事务的 demand miss 时序优化。
- `notes`: 该反例证明局部 CPI 下降不能替代全量正确性。

### [2026-05-29 16:30] `same-cycle-ar` - `completed`

- `owner_agent`: Codex
- `trigger`: 1024-entry bridge cache 后，demand miss 仍多付出一拍地址状态延迟。
- `depends_on`: `dside-prefetch-negative`
- `inputs`: `OooFetchAxiBridge`, `OooMemAxiBridge`, CPU-test 全量。
- `action`: 对 fetch 和 load read miss 增加 request fire 同拍发 `AR` 路径；只提前当前 demand read，不新增 prefetch 或第二 outstanding。
- `outputs`: 保留同周期 demand miss AR。
- `evidence`: OoO build PASS；CPU-test 全量 `40/40 PASS`, `cycles=68487 commits=78682 weighted_cpi=0.870428`, TSV `/tmp/ysyx-ooo-full-cputests-samecycle-ar.tsv`。
- `handoff_to`: `next-optimization`
- `next_step`: 基于最新全量结果同时分析 `dummy/prime/leap-year` 与 high-excess 样本，优先补 issue/retire/control/memory stall 统计。
- `notes`: 最新三类代表样本：`highest_cpi=dummy`, `lowest_cpi=prime`, `near_average_cpi=leap-year`。
