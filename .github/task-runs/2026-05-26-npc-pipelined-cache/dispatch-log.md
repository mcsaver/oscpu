# Dispatch Log: NPC Pipelined Cache Hit Path

- `task_id`: `2026-05-26-npc-pipelined-cache`
- `date`: `2026-05-26`
- `owner`: `Codex`

## Nodes

### recall

- `status`: completed
- `inputs`: `.github/AGENTS.md`, `.github/copilot-instructions.md`, project memory, NPC module memory, NPC study notes, RTL workflow instructions
- `action`: 确认当前 cache 已严格同步 SRAM，瓶颈来自 blocking cache FSM 和 IfStage 单 pending 请求。
- `evidence`: `rg`/`nl` 检查 `Sram1Rw/Sram2R1W`、`ICache`、`DCache`、`IfStage`、`MemoryStageControl`。

### derive

- `status`: completed
- `action`: 按 RTL 四段式推导需求、协议、状态机、不变量和数据通路。
- `outputs`: 采用 hit fast path + response holding；ICache/IfStage 支持 response 同拍发下一预测 PC；DCache load hit 支持背靠背，store hit 受 1RW data SRAM 限制。

### implement-single

- `status`: completed
- `action`: 修改 `npc/single` 的 `ICache`、`DCache`、`IfStage`；新增 cache 背靠背 hit test。
- `outputs`: single lint PASS；ICache/DCache 专项 PASS；模块 27/27 PASS；pipe/stage pipe PASS。
- `notes`: 首版 IfStage 组合出 next request 时触发 Verilator `UNOPTFLAT`，已改成只基于 late response 的 pipeline issue，避开 same-cycle response 兼容路径组合环。

### implement-soc

- `status`: completed
- `action`: 同步 `npc/soc` 复制版 cache/frontend 改动，保留 SoC ICache MROM cacheable 特例。
- `outputs`: soc lint/testbench/pipe/build/soc-lint/soc/soc-run 均 PASS。

### benchmark

- `status`: completed
- `action`: 跑 CoreMark 量化 CPI。
- `evidence`: CoreMark PASS，`cycles=427772874`、`commits=303899791`、`CPI=1.408`、ICache miss `30850`、DCache miss `70`、writeback `240`。
- `notes`: CPI 未回到组合读时期的约 `1.17`，主要因为当前 core 仍对每个 DCache hit load/store 在 MEM 等一次 response；继续优化应从 EX 阶段提前发 DCache 请求或 MEM hit latency hiding 入手。

### record

- `status`: completed
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md` 与本 task-run。
