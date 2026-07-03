# RV64 OoO 核 · 设计与优化工作区导航

本目录是 RV64 乱序核的**设计/规范/优化**入口。配套评估与综合工具在 `../eval/`、`../vivado/`。
新会话/新人从这里恢复上下文。

## 目录结构
| 路径 | 内容 |
| --- | --- |
| `arch/ooo-core-architecture.md` | **微架构宪法**（normative 顶层）：指令生命周期、标准 uop/event 字段、状态 owner 表、副作用/flush/redirect 宪法、pending 退出计划。是 B2/B3/B4/B-LSQ 的父规范 |
| `arch/history/b2-branch-spec-redirect.md`(已归档) | **B2 规范**：多级分支投机 + 统一 redirect，拆 branch/jump pending。评审定 B(ROB-walk) 基线 + C 快照 Phase-2；含共享地基/拆除清单/验证计划 |
| `arch/rtl-ground-truth-2026-07-03.md` | **RTL 重读真相基线**（权威现状快照）：能力/缺口/死硅普查，与旧文档冲突时以其证据为准 |
| `arch/ROADMAP.md` | **主干**：已验证状态、架构深度再评估、优先级 backlog、专业化工作流、时序 track |
| `arch/mem-lsq.md` | LSQ / load 侧访存解耦规范（部分落地：SQ+store→load 前递已实现，load 多 outstanding 未做） |
| `arch/timing-dispatch-issue-path.md` | dispatch→issue 关键路径时序规范（FP FMA 流水化后 dispatch 链复为封顶） |
| `arch/SPEC-TEMPLATE.md` | 规范模板（spec 先行/状态机优先/图文并茂） |
| `arch/history/mem-store-decouple.md`(已归档) | B1 访存 store 写回解耦规范（已实现） |
| `specs/*.md` | 逐模块规范（66 份；另 15 份已归档至 `specs/history/`）。核心模块专业规范：`ooo-muldiv-unit`、`pmp-checker`、`ooo-mem-axi-bridge-fsm`、`ooo-fetch-axi-bridge`、`ooo-rename-alloc`、`ooo-rob`、`ooo-csrfile`、`ooo-int-issue-queue` |
| `literature/` | 体系结构文献笔记 |
| `history/study/`(已归档) | 早期学习笔记(npc/single 复制品,原件活在 `npc/single/design/study/`) |
| `../eval/` | 统一评估系统（三 gate + CPI 画像，自校验）；详见 `../eval/README.md` |
| `../vivado/` | Vivado OOC 综合/时序分析（按模块+内存看门狗，抗 WSL 崩溃）；详见 `../vivado/README.md` |

## 专业化工作流（每轮迭代）
RECALL(读 ROADMAP+spec+记忆) → SPEC(动 RTL 前先写/更新规范) → IMPL(状态机优先) →
EVAL(`eval/npc-eval.sh --all` 三 gate 全绿 + CPI 对比) → DECIDE(负优化撤回) → RECORD+COMMIT。

## 当前一句话状态（2026-07-03）
全 RTL 从零重读真相基线已固化（`arch/rtl-ground-truth-2026-07-03.md`，与旧文档冲突时以其为准）：
域 B 只剩 system/trap/IRQ 类，分支（F2 真预测+ROB-walk）、FP 真乱序簇、load/store/AMO（SQ+MIQ）
已迁回域 A，pending branch/jump/mem/FP 四通道证死（拆除计划见宪法 §8.3）。功能面 AM cpu-tests
56/56、riscv-tests 十套件+privileged 全绿、ACT4 I/M/Sv 族全 PASS、CoreMark difftest 全绿
（F2 落地后 +18.3%）；时序封顶复归 `OooDispatchBackend`（39 逻辑级；FP FMA 已流水化 173→31 级）。
详细历程见 `arch/ROADMAP.md` 与 `.github/task-runs/2026-06-28-npc-rv64-ooo-perf-opt/campaign-report.md`。

## 长期记忆
跨会话事实/经验在 `.github/memory/modules/npc.md` 与 `.github/memory/project-status.md`。
