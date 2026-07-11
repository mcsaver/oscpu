# 任务报告

## 基本信息

- `task_id`: 2026-07-11-rv64-ooo-code-first-architecture-audit
- `trace_id`: manual:2026-07-11-rv64-ooo-code-first-architecture-audit
- `task_slug`: rv64-ooo-code-first-architecture-audit
- `graph_template`: code-first-independent-review
- `profile`: none（strict guard 判定 `required_profiles=0`）
- `graph_mode`: dynamic
- `status`: completed
- `owner`: root + rv64_frontend_blind + rv64_backend_blind + rv64_topology_blind
- `started_at`: 2026-07-11（重启任务）
- `updated_at`: 2026-07-11 15:47:58 +0800

## 任务目标

- `source_request`: 不依赖现有设计 Markdown，先从当前 RV64 OoO RTL 重建真实拓扑、优缺点与实现边界，再与 Markdown 逐项对照并找出过时结论。
- `goal`: 形成可复核、不会因上下文压缩丢失的代码优先架构审计证据包。
- `scope`: `npc/rv64` 当前 core、frontend、backend、memory、control、bus、SoC 接线，以及对应设计文档、回归和 STA 产物。
- `non_goals`: 不修改 DUT RTL；不把 dated snapshot 重写成 current；不声明未执行的完整 ISA 证明、Linux gate 或物理签核。

## 阶段隔离

1. 阶段一：三个独立 reviewer 明确禁止读取 RV64 设计 Markdown，仅检查 RTL、构建配置与非 Markdown 产物。
2. 阶段一冻结：写入 `PHASE1_FROZEN.txt` 后，代码结论不可被后读文档静默改写。
3. 定向验证：六组局部/跨模块 RTL testbench，不修改 DUT。
4. 阶段二：按 active/normative、snapshot、plan、history、DB memory 生命周期对照文档。
5. 复核：实现者给证据，审查者主动降级整链静态推断、不可达模块反例和非 signoff PPA 数字。

## 节点概览

| 节点 | 负责者 | 状态 | 输出/证据 |
|---|---|---|---|
| `global-topology-blind` | rv64_topology_blind | PASS | `00_global_topology_blind.txt`、`PHASE1_FROZEN.txt` |
| `frontend-blind` | rv64_frontend_blind | PASS | `01_frontend_blind.txt` |
| `backend-blind` | rv64_backend_blind | PASS | `02_backend_blind.txt` |
| `memory-control-blind` | root + prior frozen evidence | PASS | `03_memory_control_blind.txt` |
| `directed-rtl-tests` | root | PASS | 六组 testbench；脚本 exit 0 |
| `document-lifecycle-compare` | 三个 reviewer + root | PASS | `04_DOCUMENT_COMPARISON.txt` |
| `architecture-synthesis` | root | PASS | `05_FINAL_ARCHITECTURE_ASSESSMENT.txt` |
| `db-memory-persist` | root | PASS | project-status + modules/npc stored update/readback |
| `strict-guard` | root | PASS | DB-first audit PASS；strict guard PASS，required_profiles=0 |

## 当前主要结论

- 当前核是真正的小窗口 RV64 OoO：双 dispatch/双 commit、ROB16、int/FP rename/PRF/IQ、双 completion、SQ/MIQ、Sv39/PMP、M/S/U 控制闭环。
- 真实并行度不均匀：FP 单发、memory 单 request、IFU 单 outstanding、长运算/PTW/SQ drain 多为单在飞。
- 结构强项是状态闭环和功能广度；性能/PPA 限制集中在 fetch packet、next-PC 回环、IQ 全扫描、多口 FF PRF、阻塞式 memory hierarchy。
- 已用定向检查复现 FP trap-dispatch、xRET current-mode、page-end C fault 归属、IFU A-update flush、MIQ flush+pop；MIQ full+pop 仅为当前整核不可达的潜伏模块合同。
- 文档最大漂移是把 2026-07-03 snapshot 继续作为 current authority；active specs 还遗漏 arch_trap、xRET、minstret、IFU A-update 等跨模块合同。

## 关键产物

- `audit_index`: `audit-results/2026-07-11-rv64-ooo-blind/INDEX.txt`
- `frozen_baseline`: `audit-results/2026-07-11-rv64-ooo-blind/PHASE1_FROZEN.txt`
- `document_comparison`: `audit-results/2026-07-11-rv64-ooo-blind/04_DOCUMENT_COMPARISON.txt`
- `final_assessment`: `audit-results/2026-07-11-rv64-ooo-blind/05_FINAL_ARCHITECTURE_ASSESSMENT.txt`
- `directed_runner`: `audit-results/2026-07-11-rv64-ooo-blind/run_phase1_directed.sh`
- `evidence_index`: `.github/task-runs/2026-07-11-rv64-ooo-code-first-architecture-audit/evidence-index.md`

## 阻塞与剩余工作

- `blockers`: 无。
- `remaining`: 无必需收尾工作；本任务只交付审计，不含 RTL 修复。

## 证据边界

- 当前 `.config` 未开启 Difftest，既有回归不覆盖所有保留编码与交叠时序。
- 部分结论只有局部动态 + 整链静态证据；报告没有把它们升级成完整 NpcCoreTop 程序复现。
- OpenSTA 宏模型/ideal clock 条件不具备 post-route signoff 精度。
- 本任务没有修改 DUT，因此不声称“修复完成”。

## 收尾结论

- `final_result`: 代码优先架构审计、文档对照、六组定向检查、DB memory、DB-first audit 与 strict guard 均完成。
- `review_result`: 报告已把局部动态、整链静态、不可达模块反例、历史快照和非 signoff STA 分级；没有发现需要撤回的整体结论。
