# RV64 OoO 核 · 设计与优化工作区导航

本目录是 RV64 乱序核的**设计/规范/优化**入口。配套评估与综合工具在 `../eval/`、`../vivado/`。
新会话/新人从这里恢复上下文。

## 目录结构
| 路径 | 内容 |
| --- | --- |
| `arch/ooo-core-architecture.md` | **微架构宪法**（normative 顶层）：指令生命周期、标准 uop/event 字段、状态 owner 表、副作用/flush/redirect 宪法、pending 退出计划。是 B2/B3/B4/B-LSQ 的父规范 |
| `arch/history/b2-branch-spec-redirect.md`(已归档) | **B2 规范**：多级分支投机 + 统一 redirect，拆 branch/jump pending。评审定 B(ROB-walk) 基线 + C 快照 Phase-2；含共享地基/拆除清单/验证计划 |
| `arch/rtl-ground-truth-2026-07-11.md` | **CURRENT RTL snapshot**：真实拓扑、能力边界、开放合同、验证与 PPA 证据范围 |
| `arch/history/rtl-ground-truth-2026-07-03.md`(已归档) | 2026-07-03 时点快照；仅供历史追溯，不再裁决当前 RTL |
| `arch/ROADMAP.md` | **主干**：已验证状态、架构深度再评估、优先级 backlog、专业化工作流、时序 track |
| `arch/mem-lsq.md` | LSQ / load 侧访存解耦规范（部分落地：SQ+store→load 前递已实现，load 多 outstanding 未做） |
| `arch/timing-dispatch-issue-path.md` | dispatch→issue 关键路径时序规范（FP FMA 流水化后 dispatch 链复为封顶） |
| `arch/SPEC-TEMPLATE.md` | 规范模板（spec 先行/状态机优先/图文并茂） |
| `arch/history/mem-store-decouple.md`(已归档) | B1 访存 store 写回解耦规范（已实现） |
| `specs/*.md` | 逐模块 active 规范；已完成计划与 orphan spec 见 `specs/history/`。核心规范包括 `ooo-muldiv-unit`、`pmp-checker`、`ooo-mem-axi-bridge-fsm`、`ooo-fetch-axi-bridge`、`ooo-rename-alloc`、`ooo-rob`、`ooo-csrfile`、`ooo-int-issue-queue` |
| `literature/` | 体系结构文献笔记 |
| `history/study/`(已归档) | 早期学习笔记(npc/single 复制品,原件活在 `npc/single/design/study/`) |
| `../eval/` | 统一评估系统（三 gate + CPI 画像，自校验）；详见 `../eval/README.md` |
| `../vivado/` | Vivado OOC 综合/时序分析（按模块+内存看门狗，抗 WSL 崩溃）；详见 `../vivado/README.md` |

## 专业化工作流（每轮迭代）
RECALL(读 ROADMAP+spec+记忆) → SPEC(动 RTL 前先写/更新规范) → IMPL(状态机优先) →
EVAL(`eval/npc-eval.sh --all` 三 gate 全绿 + CPI 对比) → DECIDE(负优化撤回) → RECORD+COMMIT。

## 当前一句话状态（2026-07-12）

当前核是双 dispatch/双 commit、ROB16、int/FP 独立 rename+IQ 的小窗口 RV64 OoO；
branch/FP/store 已进入正式 OoO 主路径，system/trap 默认仍走 pending+drain。fetch redirect PC
已由年龄律 arbiter 单源化，但 IFU 单 outstanding、LSU 单请求、无 LQ/MSHR/coherence。
`FDG-G1` trap-dispatch、`XRET-G1` current-mode、`MEM-ISSUE-G1`、IFU A-update flush-drain 与
IFU-FETCH-G2 page-fault provenance 合同已关闭；精确 IFU physical access、branch 后 lane1
fetch-fault owner、faulting-portion `mtval/stval`、PTE-write PMP、MIQ ghost 与 `minstret` 等合同
仍开放。本切片新鲜功能基线为 module 89/89、AM 59/59、official 177/177（当前配置 Difftest
OFF）；5 ns target-driven STA 仍远未达到 200 MHz（current WNS `-9.99ns` / TNS
`-121006.91ns`）。当前实现与证据边界见 `arch/rtl-ground-truth-2026-07-11.md`，优先级见
`arch/ROADMAP.md`。

## 长期记忆
跨会话事实/经验在 `.github/memory/modules/npc.md` 与 `.github/memory/project-status.md`。
