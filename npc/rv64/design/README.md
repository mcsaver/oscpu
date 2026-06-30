# RV64 OoO 核 · 设计与优化工作区导航

本目录是 RV64 乱序核的**设计/规范/优化**入口。配套评估与综合工具在 `../eval/`、`../vivado/`。
新会话/新人从这里恢复上下文。

## 目录结构
| 路径 | 内容 |
| --- | --- |
| `arch/ooo-core-architecture.md` | **微架构宪法**（normative 顶层）：指令生命周期、标准 uop/event 字段、状态 owner 表、副作用/flush/redirect 宪法、pending 退出计划。是 B2/B3/B4/B-LSQ 的父规范 |
| `arch/b2-branch-spec-redirect.md` | **B2 规范**：多级分支投机 + 统一 redirect，拆 branch/jump pending。评审定 B(ROB-walk) 基线 + C 快照 Phase-2；含共享地基/拆除清单/验证计划 |
| `arch/ROADMAP.md` | **主干**：已验证状态、架构深度再评估、优先级 backlog、专业化工作流、时序 track |
| `arch/SPEC-TEMPLATE.md` | 规范模板（spec 先行/状态机优先/图文并茂） |
| `arch/mem-store-decouple.md` | B1 访存 store 写回解耦规范（已实现） |
| `specs/*.md` | 逐模块规范（71 份）。本轮新增核心模块：`ooo-muldiv-unit`、`pmp-checker`、`ooo-mem-axi-bridge-fsm`、`ooo-fetch-axi-bridge`、`ooo-rename-alloc`、`ooo-rob`、`ooo-csrfile`、`ooo-int-issue-queue` |
| `literature/` | 体系结构文献笔记 |
| `study/` | 早期学习笔记 |
| `../eval/` | 统一评估系统（三 gate + CPI 画像，自校验）；详见 `../eval/README.md` |
| `../vivado/` | Vivado OOC 综合/时序分析（按模块+内存看门狗，抗 WSL 崩溃）；详见 `../vivado/README.md` |

## 专业化工作流（每轮迭代）
RECALL(读 ROADMAP+spec+记忆) → SPEC(动 RTL 前先写/更新规范) → IMPL(状态机优先) →
EVAL(`eval/npc-eval.sh --all` 三 gate 全绿 + CPI 对比) → DECIDE(负优化撤回) → RECORD+COMMIT。

## 当前一句话状态（2026-06-28）
功能 56/56、riscv-tests 271/0、模块 112/112 全绿；AM 加权 CPI 1.26（自基线 −66%）；
时序 Fmax 由 `OooDispatchBackend` 单拍 rename/alloc/IQ 链（39 逻辑级）唯一封顶。
详细历程见 `arch/ROADMAP.md` 与 `.github/task-runs/2026-06-28-npc-rv64-ooo-perf-opt/campaign-report.md`。

## 长期记忆
跨会话事实/经验在 `.github/memory/modules/npc.md` 与 `.github/memory/project-status.md`。
