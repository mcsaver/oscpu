# Agent System 模块笔记

## 2026-07-28 frozen checker replay 与完整重跑门

- 系统长仿真已产生完整 raw 终端事务、空 RTL assertion、设计/仿真器/
  配置/启动产物 post-hash 时，checker-only 误判采用版本化 replay，
  不改写原 run 状态：先冻结 console/status/binding，再从该 run 的 rootfs
  提取实际 checker，并要求提取字节哈希等于 launch binding。
- legacy 与 current regex 必须对同一 SHA-bound 输入重放；同时保留一组
  benign fixture 和一组真实 fault fixture，分别证明新 checker 不误拒绝
  `printk: debug:` 且仍拒绝 `BUG:`。只从当前源码反推旧 regex 不足以绑定
  历史执行语义。
- 完整系统重跑只由四个硬件证据条件触发：production core RTL 语义变化、
  当前配置实际 elaborated RTL 变化、device/simulator 执行语义变化、或
  原 run 缺少冻结输入/终端链/post-hash。诊断观测日志变化本身不触发重跑；
  必须把判断依据写入 task-run。
- exact terminal 事件必须从 SHA-bound raw console 计数并校验顺序，不能从
  聚合摘录推断，更不能通过 seen/dedup 逻辑掩盖重复。历史 strict FAIL、
  return code 与中断 run 均原样保留，replay PASS 另建独立状态文件。
- V10F 实战使用 V1 preliminary + V2 canonical 版本，不追改已发布 PASS。
  V2 经 `prepare-rtl-task-contract` canonical
  `create → validate → render`、`fork_turns=\"none\"` 和只读反例优先审查，
  verdict 为 `APPROVED_NOT_PROMOTION_ELIGIBLE`；single-flight WSL lane
  显式交接并归还。
- reviewer 的非阻塞反例也要进入工具债务：当前 elaboration comparator
  从 A3 文件集合单向遍历，未来版本应先断言 A3/A4 generated filename set
  双向相等。该债务不用于篡改 V2，也不扩大 checker-only 结论。
- 稳定收尾顺序是：业务 replay PASS → 独立 reviewer → DB-owned
  project/module memory 发布 → 同领域 bounded recall → task-specific e2e
  → evidence index/strict guard。checker replay 不资格化 architecture 或
  PPA，长期 goal 保持 active。
- guard profile 采用 exact-path 优先：systemd strict checker、transaction
  evidence parser、三份定向单测与 incomplete-console fixture 共七个路径只映射
  `rv64-systemd-contract` 并立即返回；generic `Linux/**` 再映射
  `rv64-linux`。agent-system 自检必须同时穷举七个 checker-only 路径，并以
  `Linux/scripts/check-ubuntu-rootfs.sh` 证明 broader Linux 路径仍保持
  `rv64-linux`，避免因分类优化削弱 rootfs 验证门。
- 实战闭环：`2026-07-28-a3-printk-debug` 的 agent-system profile
  11/11 节点 PASS，`2026-07-28-rv64-a3-checker-replay` 的
  rv64-systemd-contract profile completed；八个实际路径的 strict guard
  精确要求上述两项并 PASS。全 dirty worktree guard 因任务外
  `rv64-linux`/`npc-dev` 路径缺 evidence 而保持 FAIL，记录为范围豁免，
  不能借 scoped PASS 掩盖。

## 2026-07-27 current-design replay stage-order preflight

- V10D independent final reviewer 通过 canonical
  `create → validate → render`、`fork_turns="none"` 与 exact rendered
  text 复核本地 RV64 collector/exit/currentness 链。合同 JSON SHA-256
  为 `9b44a39d41d7ba9bfaab83034962e68aa0f99cd21ae1a414577ad024a3a227a1`，
  rendered SHA-256 为
  `3a2711cdd1d25c0712f95359f99684f53b25106d4cd4e40a918d5c68a68ce4a2`；
  reviewer 只读、未写文件并显式归还唯一 WSL 工程命令 lane。
- reviewer 找到一个非 RTL 假绿入口：V10C runner 实际执行
  `control-event-index-verify`，但 `test-runner-stage-order.py` 的
  `REQUIRED_ORDER` 未列该 stage，因此静态负向 fixture 不能拒绝验证
  stage 被删除或移到 ledger 之后。
- 稳定合同现要求
  `module -> functional -> architecture -> candidate/census -> SQ-retry ->
  GAP audit -> index build -> index verify -> ledger -> currentness`。自检
  同时拒绝 candidate-before-architecture、missing-index-verify 与
  verify-after-ledger；runner 对 full/resume attempt 都无条件执行该
  preflight，不能用 resume 绕过。
- V10C attempt 13 从 currentness resume，持久化三项负向拒绝和完整
  PASS marker，再确认 design-id `c1b531…bb594` 的 15/35/0 currentness；
  standard/detailed status 均 PASS 且保留 `SERIALIZE-G1=OPEN`。该修复
  只加强本地证据 publication 顺序，不改变 RTL、断言、testbench
  oracle 或 PPA 能力。
- task-specific `agent-system` e2e
  `.github/task-runs/2026-07-27-stage-order-index-verify-revtag-v10d/`
  completed 11/11，`npc-dev` 对应 run completed 5/5；两者均完成
  DB marker publication。最终 strict guard 为 PASS，要求的两个
  profile 正是 `agent-system` 与 `npc-dev`，均命中 current evidence。
- reviewer 合同中一个可选 candidate path 写错为 evidence 子目录；
  实际 live path 是
  `npc/rv64/eval/ppa/arch-stable/full-core-current.json`。版本化 v1
  合同保留原记录，不追改或扩大其结论；后续需要直接审计时创建新
  contract version。

## 2026-07-27 RV64 long-run single-flight and reviewer provenance

- V9Z 两轮本地 RV64 RTL reviewer 均使用 `prepare-rtl-task-contract` canonical `create → validate → render`、`fork_turns="none"` 与精确 render 文本；v2 合同 SHA-256 为 `66f6519d35e690f5b93555e2abbed76ffd6c0683a584a452d86f1a29bd1b8ce2`。每轮只读节点均显式取得并归还唯一 Windows→WSL 工程命令 lane，协调状态保存在 dispatch log，不混入 module/signal/cycle 技术目标。
- 前台工具返回 timeout 只说明外层等待结束，不证明 WSL 内的仿真/构建子进程已经退出。若同一 canonical flow 仍有 live child，必须继续保持 single-flight；只有 Windows PowerShell 只读进程/证据观测确认退出后，才能启动下一次工程命令。
- 分阶段 official-test 完成但缺少 AM、benchmark 与 final aggregate publication 时，状态保持 `GAP`，不能从局部日志追认为 aggregate PASS。长流程可用一个隐藏的 `Start-Process wsl.exe` 保存 PID、stdout/stderr 与明确参数，并仅由 PowerShell 轮询；PID 退出后再核对 canonical final result、design-id 和 return code。
- 本轮规范只固化命令 lane、进程退出与证据 publication 的真实状态机，不限制 RTL 源码探索、testbench、负向 RTL 版本、断言、覆盖、实现、验证或 PPA 能力。技术叙述继续以具体本地 RV64 module/signal/transaction/cycle/EDA evidence 为主。

## 2026-07-27 task-specific bounded-focus refresh ordering

- V9Y `npc-dev` 的两个 fail-closed run 均有五个业务节点 PASS，但 overall 保持 blocked：第一次把 `v9y` 当成普通 focus term；第二次的精确领域词尚未出现在 retained module-memory index。两者都不计完成证据。
- 稳定收尾顺序为：先写 current project/module memory，再用 `github_index_db.py refresh` 增量索引这两份 memory，确认同一领域词的 `brief --focus-scope non-history` 命中独立 module chunk，最后运行 task-specific profile。最终 `.github/task-runs/2026-07-27-serialize-memory-owner-terminal-current/` 为 bounded recall 完整、5/5、exit 0。
- 该纠偏不降低 independent-focus、历史隔离或节点成功条件。strict guard 最终仅保留 `rv64-linux` 的系统终态证据 GAP；本轮没有把 V9Y 模块/功能/架构证据外推为 Linux rootfs PASS。

## 2026-07-26 bounded root-shim chunk contract

- 根 `AGENTS.md` 由一个标题和长编号列表组成；旧 `split_section_lines()` 只按 3500 字符软分块，首块估算超过 `load --max-tokens 1200`，导致 shim 已被索引但有界读取仍 fail-closed。`scripts/dev_memory/core.py` 现增加独立 1000-token chunk 上限，并在追加下一行前按现有 `estimate_tokens()` 一致判定是否换块。
- 根 shim 实测形成 972/418-token 两块。分块只在行边界发生；单行 `LOAD_ONLY_OVERSIZE` 仍保留为一个超预算 chunk，因此 200-token 负向 load 继续拒绝，不以拆分超长单行掩盖预算反例。
- `.github/task-runs/2026-07-26-default-chunk-max-tokens/` 的 `github-index` profile completed。两份更早的 blocked run 分别保留 context focus 失败和 runner 超时的真实反例，不用于完成证明。
- strict guard 当前仍缺 `agent-system` 与 `rv64-linux`：前者的真实 `three-layer-contract` 在既有大规模 Markdown 集合上报告 `active_md=9598 db_owned=7378 shims=25 live_evidence=3 live_rules=2`；后者保持 V9S systemd-strict RED。二者均显式作为豁免/GAP，不追认为 PASS；本索引修复不改变 RV64 RTL、断言、terminal transaction 或 PPA 结论。

## 2026-07-24 RV64 RTL 合同措辞与 current-design forward test

- `prepare-rtl-task-contract` 的精确 e2e anchor 已恢复，skill quick validation 通过；真实 `agent-system` forward test `.github/task-runs/2026-07-24-rtl-task-contract-response-revtag-v9r/` 在 4000-token bounded context 下 10/10 completed。2400-token 的 blocked run 保留为上下文预算反例，不追认为完成。
- `npc-dev` forward test `.github/task-runs/2026-07-24-control-event-rtl-evidence-revtag-v9r/` 为 5/5 completed；`difftest` forward test `.github/task-runs/2026-07-24-rv64-memory-functional-aggregate-revtag-v9r/` completed。`rv64-linux` current-design run `.github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/` 为 7 PASS / 1 FAIL：失败节点是 1200 秒 rootfs 有界窗口，日志进入 Linux 6.6 heap init，但未到 virtio/VFS/systemd marker。
- 主 agent 与子 agent 的技术段落以本地 RV64 module、signal、pipeline stage、transaction、cycle、testbench、EDA、evidence、PPA 开头；协调状态单独进入 task-run/contract。真实文件名、RTL 标识符、命令、assertion、compile-success negative RTL variant、unknown、反例和范围扩展请求保持原样。
- 该层是硬件领域语义与证据排序规范，不建立关键词黑名单，不扫描或自动替换合法处理器术语，不改变 tools、shell、filesystem、write paths、context、实现、验证或 PPA 能力；产品界面的外部分类结果不作为工程 gate，也不作可控性承诺。

## 2026-07-23 RV64 final-response evidence ordering

- 本地 RV64 RTL 子 agent 的初始提示继续使用 canonical `create → validate → render` 和 `fork_turns="none"`；全部设计事实来自合同列出的 RTL/spec/testbench/evidence。最终回复首段统一按“RV64 RTL 对象或本地证据文件 → 周期或编译配置 → testbench/EDA 观测 → PASS/GAP/inconclusive 范围”组织。
- 本地 JSON 证据校验出现意外接受或拒绝时，必须给出具体 schema 字段、工作区相对路径、定向单测和返回结果。V9O 的两轮真实反例分别是 mutation summary 可内嵌下游 boundary artifact，以及 architecture hard-gates result 可搬到非 canonical 路径并内嵌 ledger reference；二者均已转成 exact schema/path、递归 reference 检查和定向单测。
- 一次 reviewer 在写完 task-run report/replay fixtures 后，其最终自然语言回复在 Codex UI 展示阶段中断。稳定恢复规则是把节点记为 `review_pending`，保留合同 SHA、报告、原始证据与中断状态；不重发同一文本，不把未显示回复追认为正式 PASS，也不改变 RTL 语义。报告中的可操作反例仍须由主 agent 转成 spec、TB、RTL variant 或 fail-closed validator。
- 该叙述层不建立关键词黑名单，不扫描或替换合法 CPU 术语和真实标识符，也不减少 `workspace-files`、shell、实现、验证、PPA、负向 RTL 版本、断言、覆盖、unknowns、替代假设或 `scope_extension_request`。它提高的是本地处理器工程对象与证据的可判别性，不能保证或控制产品侧 UI 分类结果。
- task-contract audit、28 项 self-test、20 项 CLI self-test 和 skill audit 均 PASS；V9O evidence index 164 artifacts、selected validator tests 5/5 与 `check-contract` 471 assertions/13 tests 也通过。完整核仍为诚实 GAP/59 blockers/PPA UNQUALIFIED，长期目标保持 active。

## 2026-07-23 RTL review provenance finalization

- V9N 终审证明：若 `dispatch-log.md`、review contract 或其它协调记录列入 evidence `SOURCE_PATHS`，必须在最终 canonical 证据生成前冻结。reviewer 结果若在证据之后追加，即使 RTL、focused log 与变体语义均正确，live provenance 也必须判 GAP；修复动作是重放叶证据及受影响的上层 architecture aggregate，再由下游 validator 重构验证，不能只改 ledger SHA。
- canonical 子 agent 流程保持 `create → validate → render`，V2 合同 SHA 为 `de35267426484ede9e84b382cb29c107656f02fb069baaf8593965289a515315`。WSL single-flight ownership 必须用协调消息明确交接与归还；技术 prompt 原样保持本地 RV64 module/signal/transaction/cycle、RTL/spec/TB/evidence 输入和 `rg`/`sed` 只读能力，不把协调状态混写为硬件目标。
- 本轮 V2 reviewer 正是通过上述独立检查发现 freshness GAP；主 agent 冻结记录后完成 9 门 canonical 回放与 135 项 arch-stable 单测。该规则提高证据时间序完整性，不建立关键词黑名单，不改写真实 RTL 标识符，也不削减 workspace exploration、负向 RTL 源码变体、unknowns、反例、scope extension 或 PPA 分析能力。

## 2026-07-23 RV64 hardware-domain user-visible wording

- `rv64-hardware-professional` 现同时约束主 agent 用户进度、终审摘要与子 agent render：首句落到本地 RV64 module/signal/transaction、流水级/时钟周期、仿真/综合/STA 动作和生成证据。
- 协调层状态单独写入合同 JSON、dispatch log 或 task-run，不反复复制进 RTL 技术目标；真实 module/signal/TB/log/schema 标识符以及 PMP、特权级、访问异常、内存保护等处理器术语保持原样。
- 该规则是领域语义完整性层，不建立关键词黑名单，不重命名 RTL 标识符，也不改变 `workspace-files`、shell、命令、路径、上下文、负向 RTL 版本、断言、覆盖矩阵、unknowns、反例或 PPA 分析能力。
- 根 `AGENTS.md`、`.github/AGENTS.md`、`.github/copilot-instructions.md` 与 `AI_ENVIRONMENT.md` 均提供可自动发现入口；RTL 子 agent 仍使用 versioned task contract 与 Windows→WSL single-flight。

## Executable target preconditions and wording boundary (2026-07-22)

- e2e 节点的“兼容配置”必须按实际产物类型定义，并有独立正反例合同：可执行 reference、DiffTest shared object、AM image 不能只因同属 NEMU 就互换。配置边界允许业务 smoke SKIP，但配置选择器合同本身必须始终执行并 fail closed，避免错误前提被 SKIP 掩盖。
- 本地 RV64 工作继续使用已固化的 `rv64-hardware-professional` 叙述：明确 CPU 微架构、Verilog/SystemVerilog、spec、testbench、EDA、功能证据与 PPA 范围；真实 RTL 标识符和特权级/异常术语不改写。该层不建立关键词黑名单，不削减 workspace、shell、上下文或推理能力，也不承诺控制不可观测的产品侧内容分类结果。
- 若产品界面中断当前节点，恢复依据是 task-run 状态、唯一配置/RTL 哈希和已发布 evidence，而不是重复派发同一节点。子 agent 仍先消费版本化本地 RTL 任务合同；协调状态留在主 agent/task-run，技术任务只携带本地 RTL/spec/TB/evidence 输入、输出与成功条件。

## 当前状态

- 2026-07-22（V9I 字段级 RTL 合同与 current-design forward test）：**交互叙述应把硬件性质直接绑定到 module/signal/transaction/cycle，而不是依赖可能跨领域解释的简称；真实标识符、验证强度和能力分档保持不变**。canonical renderer 现自动提示 `ARADDR/ARSIZE/ARPROT`、READY/VALID 周期、2B EXEC PMP、PMEM 读取边界和 lane0/lane1 fault owner；file/module/signal/TB/log/schema 标识符原样保留。规则不建立关键词黑名单，不减少 workspace exploration、实现工具、负向 RTL 变体、断言、覆盖矩阵、unknowns、替代假设或 scope extension。task-contract 25 项 self-test、20 项 CLI self-test、wiring audit 和 skill quick validation 均 PASS；真实 V9I no-tools reviewer 合同 SHA `00a2e4db3475a6dec764404aca44095eaac88a8289dc2fae0268066b7de09991` 返回限域 PASS。共享 `arch_stable_freeze.py` 增加 IFU-ACCESS semantic validator 后，6 个直接绑定它的 CLOSED results 均按自身 canonical 动态重建；directed architecture records 则从 DI-2 根入口递归重建九门。首轮从 DI-1 启动因 DI-2 sibling inventory 尚存在而在仿真前 fail-closed，这个反例已保留；纠正后九门全 GREEN，full-core 审计为诚实 GAP/38 blockers/PPA UNQUALIFIED，且无 CLOSED evidence drift。稳定顺序：字段级合同 create→validate→render → current-design canonical → 限域独立审查 → ledger binding → shared-consumer replay → DB memory → task-specific e2e → strict guard。
- 2026-07-22（V9H shared-validator fail-closed replay）：**公共 RTL 证据验证器或 canonical `Makefile` 入口发生来源哈希变化时，应先区分“生产 RTL design_id 漂移”“仅入口来源漂移”和“既有 CLOSED 结果的验证工具绑定过期”，再选择动作**。本轮生产 `.v` RTL 未变；9 个 directed architecture records 只有 `Makefile` provenance 失配，允许在 exact-byte 重构旧 target block、唯一 allowed path、non-provenance semantic projection 不变且 pre/post hard gates 为 RED/GREEN 的条件下更新来源摘要。另一方面，FDG、XRET、memory lifecycle、IFU AXI、INSTRET 的 current result 都直接绑定公共 `arch_stable_freeze.py` 与 `Makefile`；新增 `IFU-FETCH-G2` semantic validator 后它们正确 fail-closed，不能沿用摘要重绑。主节点因此重放 5 组 canonical 本地仿真，恢复 6 个 CLOSED 条目的 current-source 绑定，109-module aggregates 与全部 compile-success RTL verification variants 均重新 PASS；最终 full-core blocker 从暂态 46 回到 40，并净关闭本轮一项。稳定规则：来源摘要重绑只适用于可重构、语义投影不变的入口 provenance；凡证据结果直接绑定已变化的验证工具，默认重跑 canonical 动态证明。两类动作及其 pre-state 必须都保留审计，不能用最终 GREEN 覆盖中间 fail-closed 反例。
- 2026-07-22（V9F e2e manifest/state 审计接线闭合）：**规范 final-state task-run 的 DB 证据集合现精确为 ordinary evidence 与唯一 canonical `run-manifest.json` 的并集，且 state traceback 会按真实 run root 读取报告**。真实收尾审计暴露两个根因：`validate_state_traceback_payload` 把裸 `run_id` 传给接收 `run_root` 的 `task_run_report_fields`，以及 `index-evidence` 只收 `/evidence/` 普通资产、却未收 observability/trace-audit 强制要求的顶层 manifest。修复后只额外允许 `.github/task-runs/<run>/run-manifest.json` 这一精确路径，`evidence-index.md` 与 manifest 的 count/bytes/kind/list 仍只聚合 ordinary assets；runtime validator 要求 ordinary 行数精确等于 manifest `asset_count`、manifest 恰一行且 kind=json、无额外路径、总行数精确为 ordinary+1。`evidence_assets.path` 是主键，排除重复路径用计数伪装集合一致的反例。`github-index` 行为 probe 覆盖双次索引幂等、manifest SHA/size 刷新、删除清理、peer-run 隔离和 `render manifest → index → validate` 顺序；`agent-system` 行为 probe 直接验证 completed report 的七态 traceback。forward-test `.github/task-runs/2026-07-22-agent-system-observability-run-manifest-revtag-v9f/`（github-index 1/1）与 `.github/task-runs/2026-07-22-agent-system-state-traceability-observability-revtag-v9f/`（agent-system 10/10）均 completed，两个 run 的 artifact/trace/state targeted audit 全部 PASS，分别为 ordinary/DB=2/3 与 12/13。独立 reviewer 在上述集合、清理、幂等和 finalization 边界内判 PASS。声明边界：该性质只适用于 manifest 已写定且完成重新索引的规范 run；历史 run 不会自动迁移，不能把一般性的 `DB count >= manifest count` 当成一致性证明。
- 2026-07-21（V9E architecture source-binding rebind）：**共享本地 RTL 验证入口文件变化时，不能只看 production RTL design_id；必须枚举每条证据的全部 source-binding section，并经更严格下游消费者 forward test**。新增独立 `check-xret-current-mode` Makefile target 后，九条 architecture gate 的动态 command/log/metric/status 与 RTL identity 均未变，但 `provenance.files` 哈希正确失配。首版 task-local repair 只更新九个 `provenance`，要求 pre-gate 仅两个 provenance check RED、每条唯一 live mismatch 为 Makefile、去除 source-binding 后 semantic projection 相同、candidate 9/9 GREEN 才原子替换；随后 arch-stable forward test 又捕获四个 optional `source_manifest` 仍绑定旧哈希。该首轮 coverage gap 原样保留，工具修正为遍历 `provenance` 与 `source_manifest`、复核旧aggregate、自身文件 live hash 和 post-gate GREEN。另以 byte-level reconstruction 删除唯一 10 行/598-byte XRET target block，精确重建旧 Makefile SHA，证明允许路径内没有无关字节变化。规则：来源重绑必须同时给出 exact allowed path、actual byte delta、non-source-binding projection、pre/post consumer 状态和未重跑动态证明的准确声明；不能用手工 JSON 改写或把首轮 GREEN 覆盖掉后续反例。子 agent 继续用 local RV64 module/signal/transaction/EDA 精确措辞、hash-bound JSON contract 和 self-contained no-tools review；这是减少领域歧义，不改变审查规则或模型推理能力。

- 2026-07-21（V9D discriminating RTL variant reconciliation）：**任务合同中计划的 RTL 验证变体必须与最终能被定向 oracle 动态区分的变体一致，并作为证据 source binding 重新生成**。FDG 首个classifier-to-gate 绑定切片虽然可编译，但全核 precise-trap owner 在 ordinary dispatch-valid 前正确截获，所选 oracle 因而不能拒绝；该候选不计入覆盖，替换为 lane1 dual-dispatch exclusion 切片。随后同步 `contract.md`/`rtl-derivation.md`，重跑 canonical builder，再更新 ledger hash；禁止让旧计划文字与实际 aggregate 分离。v1 reviewer 又以 commit-observer 非空性和 PC/tval 值敏感性两项 P1 推动证据升级为 6/6 RTL source variants + 1/1 observer probe，v2 才判 PASS；第一轮 FAIL 与被丢弃候选都保留，不能由后续 PASS 覆盖。最终 canonical replay 又发现随机 `/tmp` 编译根使同一语义日志哈希漂移；修复只把当前 `TemporaryDirectory` 精确路径替换为 `<FDG_TRANSIENT_TMP>`，保留仓库路径、编译参数、诊断、oracle marker、return code 与结果文本，并以 109 module + 7 variant/probe live-log 检查和两次完全相同 SHA 重放证明；v3 reviewer 判 PASS、无 P0/P1。聚合 parser 可同时接受仓库既有的精确 `PASS <test>` 与 `[PASS] <test>` 成功格式，但仍须拒绝任一 FAIL/ERROR marker、非零返回码、缺失/重复测试和 membership 漂移；这是兼容已冻结 testbench 输出格式，不是降低判定强度。DB-owned memory updater 必须以条目中真实存在的稳定 identity 作 exact-line upsert，并为分块回读提供足够 token budget；本轮首次幂等复跑因identity 漂移和截断回读失败；修正 exact-line/20k-token 回读并去除一个相邻字节级重复项后，下一轮三份文档全部 unchanged。所有自然语言继续显式绑定 local RV64 module/signal/path/cycle/EDA 语义，不改变真实工程动作。
- 2026-07-21（V9C task-specific e2e DB-first focus ordering）：**task slug 的领域词必须先有当前non-history 独立 focus，不能由同一旧 task-run 自证**。反例 `.github/task-runs/2026-07-21-rv64-instret-retirement-closure-revtag-v9c/` 在五个 NPC 合同节点5/5 PASS 时仍因 `no independent primary focus match` 正确保持 blocked；根因是当时 INSTRET 稳定结论尚未通过 `update-stored` 进入 module memory，且多出的 `closure` 不存在于独立 focus。`project-status` 属于 core chunk，不能单独替代独立 focus。先用官方 `update-stored` 发布`.github/memory/modules/npc.md`，再把 slug 收敛到确实存在的 `rv64 instret retirement` 后，bounded brief 命中该 module chunk 并 complete；随后 `npc-dev` 5/5、`agent-system` 10/10、`github-index` 1/1 均完成原子 publication。稳定顺序是：业务证据闭合 → DB-owned module memory 发布 → 同领域词 task-specific e2e → strict guard。该规则保留 non-history fail-closed、历史隔离和全部节点验证强度，只消除收尾顺序歧义；blocked 反例保留审计但不计为完成证据。
- 2026-07-21（v8x 子 agent 合同与 shell ownership 实战纠偏）：**审查节点超时和合同顺序错误都必须显式降级，不能靠结果内容追认 PASS**。真实 `workspace-files/read-only` reviewer 在主 agent 交出唯一 WSL shell ownership 后完成合同哈希、focused marker 与两项 mutation witness 的部分检查，但未在限定窗口内返回 verdict；主 agent 中断该节点、收回 shell ownership，并在 dispatch log 登记 `review_interrupted`，其部分观察不授予 PASS。随后一次 no-tools follow-up 虽返回 pass，却因新版 JSON 尚未先走 canonical `create -> validate -> render`，结果只能保存为 `candidate-only`。正式 v2 合同改为真正的 `prompt-supplied-self-contained`，SHA `1b1d568b5ac9e2cec6bb7033ee7233ece6d7a6f2206927effcd39303e130678f`，无 tools/shell/files/write/external access，原样派发并允许 unknown、反例、scope extension 与 inconclusive，最终仅对冻结 V8X 证据判 pass/blockers=0。稳定规则：shell-holding 节点必须有明确归还或由主 agent 可审计中断回收；任何补派均先生成新版本合同，不口头扩权、不追认 candidate；限定材料 reviewer 不冒充完整仓库审查。准确本地 RV64 RTL 术语用于消歧，能力分档、反例强度与平台审查边界保持不变。
- 2026-07-21（v8w 本地 RV64 RTL 子 agent 实战）：**硬件专业措辞、最小真实权限与强反例复核在不削弱模型能力的前提下再次形成可审计闭环**。两轮独立 reviewer 均由 `prepare-rtl-task-contract` 的 canonical `create → validate → render` 生成 versioned `workspace-files`/read-only JSON；正文明确对象为本地 RV64 Verilog/SystemVerilog 处理器，把 `kill/drop/flush/recovery/mutation` 分别限定为流水线事务失效、bridge terminal、checkpoint 恢复和 compile-success RTL 验证变异，并保留 counterexample、UNKNOWN/GAP、scope-extension 与否决晋级的结论出口。合同显式冻结 allowed files/commands、零 write paths，排除网络、账号、凭据和外部服务；Windows→WSL 工程 shell ownership 在主 agent 与 reviewer 间单一交接并显式归还。v2 reviewer 的 late-old-drop/new-head 与纯选择性 A/D write drain 缺口已转成 directed TB、guard 反例和新增 mutation，v3 合同 SHA `082356f2bf7338a69d71b8da064421e1717764dbbe642add7c2d5d3033ebf3e5` 仍保留真实 backend+bridge 双 owner 联合轨迹为 verification GAP，父 goal 保持 active。该规则不采用关键词黑名单、语义隐写或自动改写，不承诺消除平台误分类，也不以绕过平台检查为目标；它只提高本地硬件任务的对象/层级/作用域/工程目的准确性，技术能力和审查强度保持不变。证据 `.github/task-runs/2026-07-21-rv64-v8w-speculation-recovery/`。

- 2026-07-21（RV64 硬件专业措辞 v10b 实战闭环）：**canonical RTL 子任务合同现以正向本地范围声明消歧，不靠关键词黑名单、隐匿、自动改写或能力缩减**。`rv64-hardware-professional` 首段固定声明工作对象为本地 RV64 Verilog/SystemVerilog 处理器，输入/操作/产物仅限合同授权的 RTL、规格、testbench、EDA 与证据；歧义术语必须显式补足对象、抽象层级、作用域和工程目的，例如 pipeline transaction `kill/flush`、checkpoint recovery、load replay、testbench fault stimulus、compile-success RTL mutation、datapath bypass 与 privilege-level transition。JSON policy/contract 已机器化 `domain_reference`、`positive_local_scope_preamble_required`、四维上下文与 `ambiguous_terms_require_hardware_context`；该层不扫描词表、不改 RTL 标识符，也不改变 tools、shell、filesystem、context、write_paths、反例搜索、推理或结论出口。旧 e2e 文本钩子错误地把 no-tools 等同于固定自然语言句式，已改为校验真实机器权限形状 `allowed_commands=[]`、`write_paths=[]` 与“不执行工程命令或仓库读取”；generator audit、25 项 self-test、20 项 CLI self-test 均 PASS。真实 v6 mutation-reconstruction reviewer 使用 versioned 合同 SHA `68e3ce55eb21c30b80b1de162be08bcf72260affee9dd7281d600ad2e84d1b46`，只消费冻结本地 RTL 材料且不执行工程命令/仓库读取，给出限域 PASS；`agent-system` run `.github/task-runs/2026-07-21-rv64-hardware-professional-task-contract-revtag-v10b/` 10/10 completed。v10 的生成 bytecode-cache 与 v10a 的陈旧文本钩子失败包均保留，证明规则通过真实 forward-test 纠偏，而非修改报告造绿。
