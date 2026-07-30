# 派发日志

## 基本信息

- `task_id`: `rv64core-study-manual-20260728`
- `task_slug`: `rv64core-study-manual`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-07-28] `recall` - `completed`

- `owner_agent`: `/root`
- `trigger`: 用户要求建立覆盖全部 `vsrc` 文件的 RV64 Core 学习讲义。
- `depends_on`: 无。
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、DB-backed project/NPC/known-issues memory、`AI_ENVIRONMENT.md`、文档生命周期与 memory 协议。
- `task_contract`: 不适用。
- `access_boundary`: `read-only`
- `action`: 读取工程规则和当前 RV64 稳定合同；早期 bounded brief 因缺少独立 focus 命中而 fail-closed，转为直接读取 canonical 文件和 stored memory；memory 发布后以 `本地 RV64 RTL 合同`、`profile=npc`、`focus-scope=non-history` 重新召回成功。
- `outputs`: 当前架构与文档生命周期约束。
- `evidence`: 早期 `brief` 明确返回 `recall_status=failed`；所需正文由 filesystem/DB stored load 补读；收尾 `brief` 返回 `ok=true`、`recall_status=complete`、`2637/3200 tokens`。
- `handoff_to`: `source-inventory`
- `next_step`: 建立源码与实例层次清册。
- `notes`: 收尾成功召回使用当前非历史 focus；没有把失败召回伪装为成功。

### [2026-07-28] `source-inventory` - `completed`

- `owner_agent`: `/root`
- `trigger`: `recall` 完成。
- `depends_on`: `recall`
- `inputs`: `npc/rv64/vsrc/**`、`npc/rv64/vsrc/filelist.mk`
- `task_contract`: 不适用。
- `access_boundary`: `read-only`
- `action`: 用 `rg --files` 计得 150 个文件、145 个 HDL/头文件；按目录和 module 声明建立全集。
- `outputs`: 待落入讲义文件地图。
- `evidence`: 终端输出 `vsrc files: 150`、`Verilog files: 145`。
- `handoff_to`: `manual-design`
- `next_step`: 绑定每个文件的 parent/状态/章节。
- `notes`: `README.md`、`filelist.mk` 和事实头文件也属于用户要求的“每个文件”，不得从覆盖分母排除。

### [2026-07-28] `hierarchy-elaboration` - `completed`

- `owner_agent`: `/root`
- `trigger`: 需要排除历史文档对双内存桥实例状态的漂移。
- `depends_on`: `source-inventory`
- `inputs`: 当前 `RTL_CORE_SRCS`、顶层 `NpcTop`
- `task_contract`: 不适用。
- `access_boundary`: `read-only`
- `action`: 使用 Verilator 5.020 `--xml-only --top-module NpcTop` 展开当前层次。
- `outputs`: `/tmp/rv64-study-npctop.xml`
- `evidence`: XML 明确显示 `NpcCoreTop.u_ooo_dual_mem_bridge`、双 `OooMemAxiBridge`、双 DTLB/D-cache、`OooCoreTopGlue` 五类子系统实例。
- `handoff_to`: `manual-design`
- `next_step`: 用当前层次而非旧注释编写讲义。
- `notes`: XML 为临时分析产物，不作为长期源文件；最终事实将内联到常驻讲义和 task-run 摘要。

### [2026-07-28] `sim-hierarchy-and-inventory` - `completed`

- `owner_agent`: `/root`
- `trigger`: 需要区分生产、仿真、focused checker、catalog/header/doc。
- `depends_on`: `hierarchy-elaboration`
- `inputs`: 当前 `RTL_CORE_SRCS`、`NpcSimTop`、两个 Verilator XML。
- `task_contract`: 不适用。
- `access_boundary`: `read-only`
- `action`: 用 Verilator 5.020 展开 `NpcSimTop`，并运行 `extract_vsrc_inventory.py` 合并两个根。
- `outputs`: 150 行文件清册。
- `evidence`: `124 NpcTop-reachable + 6 simulation-only + 3 focused-checker + 3 catalog-only + 9 header/include + 5 document/build = 150`。
- `handoff_to`: `manual-write`
- `next_step`: 将状态与职责写入第 11 章。
- `notes`: XML/TSV 位于 `/tmp`，不是长期交付；讲义和工具保留可重建方法。

### [2026-07-28] `frontend-decode-static-review` - `completed-gap`

- `owner_agent`: `/root/frontend_decode_review`
- `trigger`: 独立校准 response→FIFO→dispatch/redirect 边沿。
- `depends_on`: `hierarchy-elaboration`
- `inputs`: 合同允许的 frontend/decode/common/pipeline/FPC/define 与架构文档。
- `task_contract`: `.github/task-runs/2026-07-28-rv64core-study-manual/subagent-contracts/frontend-decode-study-review.json`
- `contract_sha256`: `e6a580a5cd99e6cd1784e1cc667a1dff76f4242d525676f9c2db52c90749209c`
- `access_boundary`: `read-only`
- `action`: 逐文件复核 cache-hit C0/C1/C2、4-packet FIFO、双槽 facts、BPU/RAS、redirect 与结构性死路径。
- `outputs`: 中文逐文件职责、时相、反例和 WaveDrom 场景。
- `evidence`: 当前无 response→dispatch bypass、无 full+pop look-through；生产 DecodeStage=2，OOO_ASSERT reference=2；redirect 沿上写 PC、下一拍 request。
- `handoff_to`: `/root`
- `next_step`: 校正第 2、3、10、11 章。
- `notes`: 未运行 TB/仿真/综合/STA，动态结论保持 GAP；shell ownership 已归还且无在途命令。

### [2026-07-28] `backend-fp-retire-static-review` - `completed-gap`

- `owner_agent`: `/root/backend_fp_retire_review`
- `trigger`: 独立校准双发 rename、整数/FP 完成和 ROB 双退休。
- `depends_on`: `hierarchy-elaboration`
- `inputs`: 合同允许的 rename/scheduling/regread/execute/writeback/decode/pipeline/define 与架构文档。
- `task_contract`: `.github/task-runs/2026-07-28-rv64core-study-manual/subagent-contracts/backend-fp-retire-study-review.json`
- `contract_sha256`: `3d227e10331e502016abd66486951e52ab7f186807d5549322e6a570372ee0ff`
- `access_boundary`: `read-only`
- `action`: 复核 Decode→dispatch 组合融合、IQ/PRF/EX、ProducerId、FP done FIFO/formal-WB、ROB WB→commit 与 walk。
- `outputs`: 状态 owner 表、整数/FP 周期链和反例。
- `evidence`: dispatch 后普通 ALU 至少跨 3 个后续上升沿更新架构 GPR；FP raw 结果先 PRF/wake→done FIFO→formal FPWB→ROB→commit；ROB 无 WB→commit 同拍旁路。
- `handoff_to`: `/root`
- `next_step`: 校正第 3、4、5、7、10、11 章。
- `notes`: 静态结构高置信；动态 ISA/PPA/STA 保持 GAP；shell ownership 已归还且无在途命令。

### [2026-07-28] `memory-control-integration-static-review` - `completed-gap`

- `owner_agent`: `/root/memory_control_integration_review`
- `trigger`: 独立校准 LSU/MMU/D-cache/AXI、控制面、SoC 和仿真边界。
- `depends_on`: `hierarchy-elaboration`
- `inputs`: 合同允许的 memory/cache/control/core/bus/sim/debug/sram 与架构文档。
- `task_contract`: `.github/task-runs/2026-07-28-rv64core-study-manual/subagent-contracts/memory-control-integration-study-review.json`
- `contract_sha256`: `a11d86b01487f1632a866404259c507a4f1e94e99e6b3b299a55ccab03317904`
- `access_boundary`: `read-only`
- `action`: 复核双 memory bridge、SQ/LQ/MIQ/owner、PMP/PMA/TLB、D-cache、control drain、Xbar/device/DPI。
- `outputs`: 逐文件周期事实、反例和 12 类 WaveDrom 建议。
- `evidence`: Store 只在 SQ/ROB 双头部 launch 并等 B terminal 后释放；flush 不取消已发 AXI；FENCE 额外等 mem_idle；Xbar R 有 registered response slice。
- `handoff_to`: `/root`
- `next_step`: 校正第 6–12 章。
- `notes`: 未运行 TB/综合/STA；静态拓扑高置信，动态结果保持 GAP；shell ownership 已归还且无在途命令。

### [2026-07-28] `manual-write-and-coverage` - `completed`

- `owner_agent`: `/root`
- `trigger`: 三路静态复核完成并返回反例。
- `depends_on`: `frontend-decode-static-review`、`backend-fp-retire-static-review`、`memory-control-integration-static-review`
- `inputs`: 当前 RTL、实例清册、三路 reviewer 结果。
- `task_contract`: 不适用。
- `access_boundary`: `write docs/task-run only`
- `action`: 新建 `docs/rv64core/study/` 00–12 章、README、逐文件地图、覆盖与 inventory 工具；同步修正旧 Store/FP/ROB/FIFO 文档模型。
- `outputs`: 14 个 Markdown、2 个 Python 工具；Markdown 当前总计 4335 行。
- `evidence`: `audit_vsrc_coverage.py` 输出 `markdown_files=14`、`vsrc_files=150`、`covered_vsrc_files=150`、`wavedrom_blocks=37`、`PASS`；两个工具 `py_compile` 返回 0。
- `handoff_to`: `final-adversarial-review`
- `next_step`: 处理最终反例并冻结。
- `notes`: 没有修改 `npc/rv64/vsrc/**`；静态讲义审计不外推 RTL 功能/综合/STA/PPA PASS。

### [2026-07-28] `final-adversarial-review` - `completed-gap`

- `owner_agent`: `/root/final_manual_adversarial_review`
- `trigger`: 实现者材料和机械门已冻结到首轮 PASS。
- `depends_on`: `manual-write-and-coverage`
- `inputs`: 全讲义、当前 vsrc、架构文档与审计工具。
- `task_contract`: `.github/task-runs/2026-07-28-rv64core-study-manual/subagent-contracts/final-study-manual-adversarial-review.json`
- `contract_sha256`: `d9f655b52e78084f84c6779a7e63896057214784d626dacadbfad74b964a7b6f`
- `access_boundary`: `read-only`
- `action`: 按 P0/P1/P2 对抗式查找拓扑、周期、覆盖假绿和越级结论；逐项复核 Decode→dispatch、FP done FIFO→formal WB、Store B terminal、ROB WB→commit、redirect 与双 memory arbiter。
- `outputs`: 0 个 P0、2 个 P1、2 个 P2；四项均已在讲义或审计工具中修正。
- `evidence`: IFU redirect 改为 `discard_fetch_rsp_q` 消费旧响应但禁止入 FIFO；Store 改为 SQ/ROB 双头 launch→AW/W→B terminal；branch resolve 改为控制/恢复事件并绑定 EX0 formal WB；文件审计改为只解析 marker 内 150 个结构化 atlas row，校验每路径恰好一次、身份标签和 124/6/3/3/9/5 精确计数。
- `handoff_to`: `/root`
- `next_step`: 重跑审计、发布 memory、执行 strict guard。
- `notes`: reviewer 使用隔离合同与唯一 WSL shell ownership；未运行动态 TB/综合/STA/PPA，因此动态范围保持 GAP。

### [2026-07-28] `record-and-final-gates` - `completed`

- `owner_agent`: `/root`
- `trigger`: 最终 reviewer 发现已全部修正。
- `depends_on`: `final-adversarial-review`
- `inputs`: 修订后讲义、覆盖工具、task-run staging memory。
- `task_contract`: 不适用。
- `access_boundary`: `write docs/task-run/memory only`
- `action`: 重跑结构化文件覆盖、WaveDrom JSON、本地链接和 Python 编译门；按 full-content 协议发布 project/NPC stored memory；验证定向 load 与成功 bounded brief；运行 strict guard。
- `outputs`: 完整讲义、可重复审计工具、当前架构 memory 和闭环任务证据。
- `evidence`: 审计输出 `markdown_files=14`、`vsrc_files=150`、`atlas_rows=150`、`covered_vsrc_files=150`、`wavedrom_blocks=37`、`PASS`；两个工具 `py_compile` 返回 0；最终 stored update 分别为 `45638 bytes/22 chunks` 与 `43585 bytes/54 chunks`；bounded brief `ok=true`；strict guard `PASS`。
- `handoff_to`: 用户。
- `next_step`: 从 `docs/rv64core/study/README.md` 开始学习，按章节实验把静态合同升级为波形证据。
- `notes`: production RTL 未修改；不把旧 profile evidence 或静态文档审计外推成新的 RTL 功能/PPA 结论。
