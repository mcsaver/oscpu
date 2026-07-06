# 文档生命周期协议（doc-lifecycle）

> **适用范围**：工作区内全部工程文档（`design/` 规范与计划、各级 README、`.github/memory/**`）。
> **目标**：文档不是只增不减的沉积层——每份文档有类型、有状态、有归宿；agent 系统必须能
> **动态推进**文档生命周期（创建→活跃→漂移校正→归档），而不是只维护固定几份 memory 文件。
> **由来**：2026-07-03 rv64 全 RTL 重读实践固化（task-run `2026-07-03-rv64-rtl-reread-audit/`：
> 85 份文档逐审 = 6 CURRENT / 67 校正 / 12 归档，本协议是该次实践的规则化）。

---

## 1. 文档类型分类（写文档时先定类型，类型决定生命周期）

| 类型 | 例子 | 生命周期规则 |
| --- | --- | --- |
| **normative（规范/宪法）** | `design/arch/ooo-core-architecture.md`、`SPEC-TEMPLATE.md` | 长活。分两层：normative 层（原则/契约）只在"修宪"时改；【现状】层必须随重大代码改动同步（版本号递增并注明同步依据） |
| **spec（模块规范）** | `design/specs/ooo-*.md` | 随模块共存亡：模块删除→ORPHAN 归档；模块被证死（编译期常量/结构性不可达）→**留在原位**加 ⚠️ 死硅注记（见 §2）；描述漂移→就地校正 |
| **plan（实施计划/迁移步骤）** | `*-implementation-plan.md`、decompose/迁移文档 | **天生短命**。对应工作落地或放弃的**同一个任务内**必须归档（SUPERSEDED）；未完成部分先登记到接管文档（宪法 backlog / ROADMAP / known-issues）再归档 |
| **snapshot（时点快照）** | `EVAL-REPORT-*.md`、`rtl-ground-truth-*.md` | 新快照产生即取代旧快照：旧的归档，索引/引用改指新的 |
| **index（索引/导览）** | 各级 `README.md`、`specs/README.md` | 长活。任何归档/新增/改名操作的同一个任务内必须同步索引 |
| **memory（工程记忆）** | `.github/memory/**` | 按 `memory-protocol.instructions.md`；known-issues 条目解决后移入"已解决"节，不删除 |
| **task-run（证据链）** | `.github/task-runs/**` | 只增不改，天然归档态；是其他文档归档时的"原始证据"锚 |

新建文档时：plan/snapshot 类**在文档头部自带预期归宿**（如"本计划落地后归档至 `history/`"），
避免后人猜测其时效性。

## 1.5 依赖方向铁律（长命文档禁止依赖短命文档）

文档按生命周期分两层：
- **常驻层（长命，伴随工作区一直进化）**：normative 宪法、index 索引、memory、instructions（本类规则文件）。
- **任务层（短命，任务完成即归档进 `history/`）**：plan、snapshot、task-run；spec 亦随模块共存亡、可 ORPHAN 归档。

**依赖只能「任务层 → 常驻层」，绝不能反向。** spec/plan/task-run 可以引用"遵守某 instructions / 见某 memory"；
但 **instructions / normative 层 / index / memory 绝不能"详见某 spec §x / 见某 task-run 的证据/推导"**——被依赖的
短命文档一归档，长命文档即留悬空引用（§3 悬空清零是补救，方向性违规则是从源头制造它）。**纳入完成判定钩子**（§4）。

**落地要求**：
- **常驻层文档必须自包含**：所需知识**内联写进自身**，而非指向会归档的 spec/task-run。任务完成时，
  spec 里值得长期保留的知识应**提炼进常驻层**（instructions/memory），而不是让常驻层挂"详见 spec"的指针——
  这正是"知识从任务层沉淀到常驻层"的应有动作。
- **区分「依赖」与「动作指令」**：常驻规则里写"把 X 回写到 `design/specs/<模块>.md` / 记录到 `task-runs/<pattern>`"
  是**指向目录约定的动作指令**（要你去维护那些文档），不是**依赖**某份归档件的内容——后者才违规。
- **反例（2026-07-06 实犯已改）**：把 `interface-contract-first.instructions.md`（常驻）写成"详细论证见某 spec §5 /
  对应某 spec §4.1"——该 spec 任务完成后会归档，指针即悬空。改法=把该 spec 里值得常驻的规则/踩坑**提炼内联**，删所有 spec 指针。
  （注：本条反例本身也只点常驻的 instructions 名、不点会归档的 spec 名——即本铁律自洽。）

## 2. 状态模型与标准注记

```
ACTIVE ──漂移──▶ ACTIVE(已校正) ──模块判死──▶ ACTIVE+⚠️死硅注记 ──模块删除──▶ ARCHIVED(ORPHAN)
   │                                                    plan 落地/快照被取代──▶ ARCHIVED(SUPERSEDED)
   └──内容被更好文档整体取代────────────────────────────────────────────▶ ARCHIVED(SUPERSEDED)
```

**死硅注记格式**（模块仍编译实例化但功能被证死时，spec 不归档、标题下加一行）：

```markdown
> ⚠️ **状态(YYYY-MM-DD RTL 重读)**：〈一句话死因+证据 file:line〉；拆除计划见〈宪法/backlog 位置〉。下文保留其设计语义描述。
```

**归档不等于删除**：归档件仍是历史证据，但**不再描述现状**；任何 agent 引用归档件时必须注明"(已归档)"。

## 3. 归档执行手续（每次归档都走全套，缺一不可）

1. `git mv <文件> <就近 history/ 目录>`——归档区惯例：`design/specs/history/`、`design/arch/history/`；
   新目录需自带 README 说明规约。
2. 在该 `history/README.md` 归档表**登记一行**：`| 文件 | 类别(SUPERSEDED/ORPHAN/OUTDATED) | 归档原因 | 现状参考 |`。
   "现状参考"必填——指向取代它的文档或代码真源。
3. **全仓悬空引用清零**（本协议的硬性 gate，2026-07-03 实测 12 份归档产生 10 处悬空引用）：

   ```bash
   # 对每个被移动的 <name>.md，在文档树中查未更新的旧路径引用：
   grep -rn --include="*.md" "<name>\.md" <文档根目录> | grep -v "history/"
   ```

   命中处改为 `history/<name>.md` 并加"(已归档)"。
4. 同步上级索引（`specs/README.md` 等）。
5. 若归档由某次审计触发，审计证据固化进 `.github/task-runs/<日期-任务名>/`。

## 4. 状态迁移触发点（何时**必须**推进生命周期——纳入完成判定钩子）

在声明任务"完成"前，逐项核对本次改动是否命中以下触发点；命中而未处置 = 任务未完成：

- **删除了模块/文件** → 对应 spec 同刀 ORPHAN 归档。
- **编译期常量或结构改动把某机制判死/复活** → 对应 spec 同刀加/摘 ⚠️ 注记。
- **implementation-plan 对应的工作落地或裁决放弃** → 同刀归档,未完成部分先移交。
- **产生了新的时点快照/评估报告** → 旧快照同刀归档。
- **改动触碰指令形态/数据对象/状态 owner/flush·redirect/pending**（宪法维护约定）→ 先改宪法【现状】层再动代码。
- **大规模改动后文档可信度存疑、或用户要求"重读/释放文档"** → 跑 §5 的全量审计工作流。
- **本次给常驻层文档（instructions/宪法/index/memory）加了内容** → 核对未引入「常驻→任务层」反向依赖（§1.5 铁律）：
  该内容里若出现"详见某 spec §x / 见某 task-run 证据"，改为**内联提炼**；只保留指向常驻层或目录约定的引用。
- 常规小改 → 至少校正直接相关 spec 的漂移句子（最小 diff,不重写结构）。

## 5. 可执行工具

- **全量审计工作流（Claude Code）**：`.claude/workflows/doc-lifecycle-audit.js`，
  调用 `Workflow({name: "doc-lifecycle-audit", args: {roots: [...], truth: [...]}})`。
  三阶段：盘点(动态发现文档并按子系统分组) → 并行审计(对照代码真源逐份判定
  CURRENT/DRIFT_FIXED/ARCHIVE 并就地校正) → 汇总(归档建议交主控执行 §3 手续)。
  `truth` 可传现成审计报告/真相基线加速；不传则审计 agent 直接读代码验证。
- **其他 agent 生态**：无 Workflow 工具时,按 §1-§4 手动执行同等流程（分组→对照代码→判定→
  校正/归档建议→§3 手续），产物同样固化 task-run。
- **悬空引用检查**：§3 第 3 步的 grep 模式；任何归档/改名后必跑。

## 6. 当前登记状态（随每次全量审计更新本节）

- **最近一次全量审计**：2026-07-03 两轮——第一轮 85 份（task-run
  `2026-07-03-rv64-rtl-reread-audit/`：6 CURRENT/67 校正/12 归档）；第二轮为
  doc-lifecycle-audit 工作流首次验证运行，86 份（62 CURRENT/16 校正/8 归档，
  抓到第一轮漏改的宪法 §2 表并归档 `design/study/` 整目录，
  结果 `verify-run-results.json` 固化于同一 task-run）。
- **权威现状快照**：`npc/rv64/design/arch/rtl-ground-truth-2026-07-03.md`。
- **归档区**：`npc/rv64/design/specs/history/`（15 份）、`npc/rv64/design/arch/history/`（3 份）、
  `npc/rv64/design/history/`（目录级：`study/` 8 份）。
- **待处置队列**：死硅物理拆除对应的 spec 摘除（随宪法 §8.3 B4 清理执行）。
