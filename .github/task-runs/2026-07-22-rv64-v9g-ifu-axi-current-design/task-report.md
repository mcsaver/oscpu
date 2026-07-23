# RV64 V9G IFU-AXI-G1 当前设计闭环报告

## 状态

- `state`: 当前设计 architecture evidence slice 已闭合；长期 RV64 OoO/PPA 目标保持 active
- `design_id`: `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`
- `classification`: architecture closure；`PPA=UNQUALIFIED`；`promotion_eligible=false`
- `debt`: `IFU-AXI-G1` P0，`CLOSED`，`current_design_bound=true`
- `production_rtl`: 本切片没有修改生产 `.v`；完整 RTL design-id 保持不变

## 根因与真实 owner/dataflow

受阻点不是已确认的生产 RTL 缺陷，而是旧证据没有完整覆盖并绑定当前设计中的 PTE A 位
更新写事务。当前 `OooFetchAxiBridge` 以寄存后的 `state_q==S_AD_UPDATE` 持有整笔写事务，
`aw_done_q` 与 `w_done_q` 分别记录 AW/W channel accepted，`ad_drop_q` 只记录旧 fetch
语义是否因 `mmu_flush_i` 被丢弃。flush 不是 AXI reset：已经建立的 write owner 必须继续
补齐 AW/W 并消费 B，只在完整 B completion 后释放事务。

写 owner 的建立边界也已冻结：若 flush 到达时旧状态仍为 `S_WALK_R`，该拍属于 PTW
read-owner 取消/排水，不能跨越 flush 新建 A-update write owner。`AxiXbar` 则分别捕获
master AW/W，并只在 exact slave B fire 后释放 `wr_active_q` 与对应 master busy owner。

## 实现者交付

生产 RTL 只读。本轮增加并固化了以下验证与证据路径：

- `tb_ooo_fetch_axi_bridge.sv` 覆盖 AW-first/W-first、first/last/all-fire、B error、
  repeated flush、payload stability、drop quiet 与非 drop fault；
- `tb_ooo_fetch_axi_bridge_xbar.sv` 覆盖 IFU B owner 释放后后续 master 的精确
  address/data/B response；
- `tb_axi_xbar.sv` 覆盖 BVALID 在 BREADY=0 下保持两拍、不得提前释放 owner，及
  AW-first/W-first；
- 证据生成器独立重建 focused marker、动态模块集合、branch-local RTL 验证变异、
  源码/变体哈希与生产源码前后稳定性；
- arch-stable validator 对 `IFU-AXI-G1` 执行同 design-id、canonical command、
  result/raw hash、focused/module/variant 和语义字段的 fail-closed 校验；
- `make -C npc/rv64 check-ifu-axi-flush-drain` 成为永久 canonical 入口。

接口合同见 `contract.md`，周期方程与 owner 推导见 `rtl-derivation.md`。

## 当前设计证据

Canonical 命令：`make -C npc/rv64 check-ifu-axi-flush-drain`。

- focused：3/3 PASS；
- 动态派生模块 aggregate：109/109 PASS；
- compile-success RTL 验证变异：18/18 编译成功且全部被指定动态 oracle 检出；
- IFU 证据构建器单元测试：8/8 PASS；
- bridge 变体 14/14，AxiXbar 变体 4/4；
- 生产 RTL source set：145 个文件，变异运行前后 byte-identical；
- 当前结果与全部证据绑定同一 design-id。

关键 SHA-256：

- IFU result：`6bd084c95b5d871fe047ef0bf6b731dc60d5392792ae14f4de98a342d7fab71c`；
- IFU raw log：`d063ae168e32af64ec7f76c0a41adc6d3f882c5fc64c768f6f328908890431`；
- ROADMAP：`b1440ea25961e11ef4367c5be7e4f7d179f8f7d516519a42d36103fbfc4efebc`；
- architecture debt ledger：`75853ae07ef9c09d562b44bbad4dbc346e01c5e157d4bf3579b2b9e1bbe3961c`。

账本 revision 为 `v9g-20260722`。`IFU-AXI-G1` 已绑定 canonical command、当前
design-id、result 与 raw log；新增语义 validator 后，MEM/MIQ、INSTRET、XRET、FDG
等既有 CLOSED 证据也均以各自 canonical 入口重新生成，没有复用失效的旧 source binding。

## 架构来源绑定与硬门

新增 Makefile/TB 证据入口使九条旧 directed architecture record 按来源哈希正确
fail closed。重绑定工具只允许两个实际漂移路径：

- `npc/rv64/Makefile`；
- `npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv`。

工具逐字节重建两个旧文件，确认 9 个 record 的 13 个 provenance section 只有来源字段
变化、非 provenance 语义投影完全相同，再重放当前 109/109 模块集合和 18/18 验证变异。
最终结果为 `manifest=UNCHANGED projection=UNCHANGED module=109/109 variants=18/18
gates=9/9 PASS`。

- `architecture-current.json`：
  `5a61c7ddb4a5d884a564b6b2594beeebb5225e794804fe692dabd978c189d52b`；
- provenance rebind audit：
  `84869411a3cb7b1c0c504a69fbc43817dbc63393cde2a1ecbfd2b1c026c05d40`；
- architecture hard-gates：
  `e51bb8486fb0f067635d0e6e3fbeda92f425c2cc7aa909297c3ada9cf3262716`，
  `DI-1..DI-5` 与 `OOO-1..OOO-4` 共 9/9 GREEN。

## Arch-stable 与 PPA 边界

最终 arch-stable 审计的 85 个单元测试、architecture audit 与 candidate verify 全部
通过，但 full-core 结果仍诚实保持 `architecture_freeze=GAP`、41 个 blocker、
`PPA=UNQUALIFIED`、`promotion_eligible=false`；`full-core-current.json` SHA-256 为
`8ee9242d1ae9c072997274118530526df6c70c2e42d54fd8dd468b18fb0f51b2`。

剩余 blocker 属于其它仍 OPEN/STALE 的架构债务、full-core holder/lifecycle census、
同 design-id functional aggregate、cohort inventory 和完整 freeze inputs。本轮没有声称
完整 ISA/Linux、200 MHz、area、timing、power 或 Pareto 晋级。

## 审查者结论

早期独立审查提出 8 项覆盖问题，其中 7 项已转化为对称同拍场景、BREADY 背压、稳定性
marker、动态 oracle 和来源重建；第 8 项经周期推导收敛为明确的 `S_WALK_R`/`S_AD_UPDATE`
owner 建立边界，而不是扩大生产 RTL 语义。

最终 no-tools 合同
`subagent-contracts/v9g-ifu-axi-final-evidence-review-v1.json` 的 SHA-256 为
`e9cff492b1b02b789c20fc2d13e1b459c6f33374403fa2dbd8f5a3230b0a0b2d`；canonical
`create → validate → render` 通过，零命令、零写路径、无外部来源。审查者给出限定性
PASS、置信度约 0.94：在合法 AXI slave、当前 design-id、非 reset 和冻结配置内，没有
发现能推翻 `IFU-AXI-G1` CLOSED 的周期级反例，也没有提出 scope extension。

审查者保留的边界是：这不是任意无限 stall 序列的形式穷尽证明；非法提前 BVALID、reset
中的 owner、多 master 公平性、其它配置和 PTE 一致性不在本 debt 范围；reviewer 没有
自行读取原始文件，其复核不能替代主 agent 的动态运行和哈希重建。完整结论见
`review-summary.md` 与 `dispatch-log.md`。

## AI 工作流与数据库收尾

所有子任务描述均显式限定为本地 RV64 Verilog/SystemVerilog 处理器 RTL、testbench、EDA
与证据产物；合同写明 JSON 路径、自身 SHA-256、允许材料、write paths、结构化
command/mode/purpose 和成功条件。该措辞用于准确表达硬件对象与权限边界，不改变任务真实
意图，也不削弱验证或模型能力。

- project/module 稳定事实仅通过 `github_index_db.py update-stored` 发布；
- bounded brief 使用 `rv64 ifu axi current design v9g`、profile `npc-dev`、
  `focus_scope=non-history`，由 DB-owned NPC memory 提供独立 focus；
- 第一次 task-specific `npc-dev` E2E 因没有独立 focus 而正确保持 blocked，原证据包
  `.github/task-runs/2026-07-22-rv64-ifu-axi-current-design-v9g/` 原样保留；
- memory 更新后，新证据包
  `.github/task-runs/2026-07-22-rv64-ifu-axi-current-design-v9g-final/` 的 5 个节点
  全部 PASS，证明修正不是手工覆盖状态；
- 主任务 136 个原始证据资产已由 `index-evidence --write-index` 建立 SHA-256、大小、
  行数、marker 和摘要索引，并写入 `evidence-index.md`；完整 payload 不进入长期 DB 文档；
- 成功 E2E run 的 artifact/trace/state targeted audit 全部 PASS，普通 evidence 6 项、
  顶层 canonical manifest 1 项，DB 计数与 manifest 精确一致；
- DB-first、Markdown coverage、Skill、policy、report、schema、artifact、trace、state
  全局审计全部 PASS；stored snapshot 为 6905 个文档；
- RTL task-contract 的 repository audit、25 项正反例 self-test 与 20 项 CLI self-test
  全部 PASS，合法 CPU architecture/RTL 词汇和按 write path 限定的实现能力保持可用；
- 全部 E2E profile 静态图验证通过；strict guard 以 `changed_paths=2163` 要求
  `agent-system`、`npc-dev`、`github-index` 三个 profile，最终 3/3 PASS。

## 明确不外推与下一步

- `IFU-AXI-G1` 只在当前 design-id 和冻结配置下 CLOSED；design-id 变化后必须重跑；
- 不外推到 full-core ARCH_STABLE、系统级功能完成或正式 PPA；
- 长期 `/goal` 继续 active；本报告只关闭 V9G 当前设计证据切片；
- 下一切片须依据当前 debt ledger 和 DB brief 选择仍为 P0 的 architecture blocker，先完成
  owner/holder/recovery 合同与证据闭环，再考虑稳定基线或局部 PPA。
