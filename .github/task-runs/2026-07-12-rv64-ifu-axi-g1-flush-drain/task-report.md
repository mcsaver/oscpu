# RV64 IFU-AXI-G1：A-update flush-drain 事务所有权修复

## 基本信息

- `task_id`: 2026-07-12-rv64-ifu-axi-g1-flush-drain
- `task_slug`: rv64-ifu-axi-g1-flush-drain
- `graph_template`: contract-first bugfix + bridge/xbar integration
- `graph_mode`: static+dynamic
- `profile`: npc-dev
- `status`: completed
- `owner`: root + ifu_axi_rtl_review + ifu_axi_test_plan + ifu_axi_contract_review
- `started_at`: 2026-07-12 21:30:00 +0800
- `updated_at`: 2026-07-12 22:15:00 +0800

## 目标与范围

- `source_request`: 持续优化架构，直到完整功能与 200 MHz 同时闭合。
- `slice_goal`: 关闭 IFU-AXI-G1，使 `OooFetchAxiBridge` 在 `mmu_flush_i` 命中已经呈现的
  Svadu A-bit 写回时，不撤回 AW/W，不丢 B owner；完整排空事务后只丢弃旧取指语义。
- `scope`: `OooFetchAxiBridge`、模块 TB、bridge+xbar 集成 TB、Makefile、两份合同 spec、
  contract ratchet 与任务证据；不顺带处理 IFU-FETCH-G2 或 PTW-PMP-G1。
- `dirty boundary`: 用户已有 dirty 文件 `OooFrontend.v`、`OooAdUpdateChecker.sv`、
  `NpcSimTop.sv`、`build/linux-logs/npc-linux.log` 与 `.superpowers/` 全部排除实现与 staging。

## 根因裁决

- `S_AD_UPDATE` 同时呈现独立 AW/W；`aw_done_q/w_done_q` 分别记录 master-side fire。
- 修复前 `rst || mmu_flush_i` 共用清零分支：flush 无条件回 `S_IDLE`、清 accepted bit、撤
  AW/W/BREADY。若 xbar 已 hold 任一 channel 或已经把写事务分配给 slave，master owner 被遗弃。
- A-bit 写回的架构语义确实可被 flush 丢弃，但 AXI valid/owner 不可撤销；正确修复层是把
  “旧取指语义 drop”与“已呈现总线事务 drain”分离，而不是让 xbar 猜测/abort。
- `RED-BRIDGE` 的 22 个合同失败与 `RED-XBAR` 的 3 个系统进展失败共同确认该根因；失败
  不是 testbench 层次 deposit 的局部假象，而是 xbar owner 无法释放、后一 master 无法到达
  slave 的确定后果。

## 接口契约冻结（SPEC §2）

### ① 握手协议

- `S_AD_UPDATE` 一旦可见，AWVALID/WVALID 已被呈现；各通道在 fire 前必须持续 valid，
  且 AWADDR、WDATA/WSTRB/WLAST 整拍稳定。AW/W 可任意顺序、任意拍独立 fire。
- `aw_done_q`、`w_done_q` 分别是本事务对应 channel 已 fire 的单一真源；已 fire 通道不得重发。
- 只有 `AW accepted && W accepted && BVALID && BREADY` 才完成写事务；BREADY 在排水期间保持 1。

### ② 反压 / stall

- AW 或 W 被反压只冻结该通道 valid+payload，不阻止另一通道独立前进。
- `S_AD_UPDATE`/flush-drain 期间 `fetch_req_ready_o=0`、`fetch_rsp_valid_o=0`、ARVALID=0；
  不接受新取指、不产生新读事务，也不把旧响应交付给前端。
- xbar/slave 可任意延迟缺失 channel 或 B；桥必须无限期保持 owner，不能用超时回 IDLE。

### ③ flush/reset 清除与保持、同拍优先级

- 全序：`rst > mmu_flush(drop semantics) > write completion outcome > normal re-walk/fault`。
- `rst` 代表全总线共同复位，可清状态并回 IDLE。
- 非 `S_AD_UPDATE` 的 `mmu_flush_i` 维持既有行为：未发事务清语义；已发读进 `S_DRAIN`
  或与同拍 R 一起完成。
- `S_AD_UPDATE` 的 `mmu_flush_i` 必须保持 PTE 地址/数据、`aw_done_q/w_done_q`，并设置 sticky
  drop；同拍 AW/W fire 仍记账。未完成时留在写排水 owner。
- 当 flush 与最后 channel/B 同拍时，事务完成但 drop 胜出：直接回 IDLE，不 re-walk、
  不返回 BRESP 派生的 fetch fault。重复 flush 幂等，sticky drop 不得被清。
- 无 flush/drop 时，B=OK 维持原 re-walk；B!=OK 维持原 access-fault 归属。

### ④ 异常序

- flush 前若 B error 已完成且未被 drop，按原规则形成当前请求的 instruction access fault。
- 一旦 drop sticky，后到或同拍的 BRESP 仅用于关闭总线事务，不再产生旧请求的架构异常。
- 本切片不改变精确异常的 ROB/commit 边界。

### ⑤ 访存序 / AXI owner

- A-bit 写回对单个 PTE 是单 beat 8B 写；其 AW/W/B 属于同一个不可拆分 owner。
- flush 不得让 xbar 的 `wr_aw_hold_q/wr_w_hold_q/wr_active_q/wr_master_busy_q` 悬空；桥消费
  B 后 xbar 必须释放 owner，随后另一个 master 的写能够取得 grant 并完成。
- 本切片只修 owner 生命周期；PTE WRITE PMP 检查由 PTW-PMP-G1 独立关闭。

### ⑥ 投机恢复 / 单一真源

- `ad_drop_q` 是“当前 A-update 完成后丢弃旧取指语义”的唯一真源；不得从
  当拍 `mmu_flush_i` 临时重推而丢失 repeated-flush/延迟 B 状态。
- `aw_done_q/w_done_q` 继续是 channel accepted 真源；PTE payload 继续由锁存 walk context
  与 `ad_pte_q` 持有，排水期不得被一般 flush 清零。

## RED 与验收门禁

- `RED-BRIDGE`: AW-first 后 flush，缺失 WVALID 与 BREADY 必须仍保持；旧 RTL 应精确失败。
- `RED-XBAR`: IFU AW/W 被 xbar 接收、slave B 延迟期间 flush；旧 RTL 撤 BREADY，xbar owner
  不释放，后续 LSU write 无法完成。
- `GREEN matrix`: AW-first、W-first、AW/W both+B delayed、flush 与最后 channel 同拍、flush 与 B
  同拍、repeated flush、payload stall stability、正常 A-update/B-error 路径不回退。
- `contract`: 至少落地 AXI valid/payload stall 稳定与 sticky-drop 排水的立即断言，并逐条做
  故意违约非真空探针；`make -C npc/rv64 check-contract` ratchet 不回退。
- `regression`: focused bridge、bridge+xbar、module 全量、lint/style/contract、clean build、AM、
  official riscv-tests；Difftest/privileged 若配置不可用必须明示。
- `parent goal`: 本切片只关闭一个功能 blocker，不宣称完整功能或 200 MHz。

## 实现结果

- reset 与 `mmu_flush_i` 已拆分；新增 sticky `ad_drop_q`，只作废旧 fetch 语义，不清
  `S_AD_UPDATE` 的 PTE payload 或 `aw_done_q/w_done_q`。
- completion 使用 `accepted_next = done_q || fire`；flush 与最后 AW/W/B 同拍时仍承认
  channel fire，完成后由 `ad_drop_q || mmu_flush_i` 选择无声回 IDLE。
- 无 drop 路径保持原义：B=OK re-walk，B error 形成 instruction access fault；drop 路径
  消费 B 后不发 response、不发 AR、不解释 BRESP。
- 新增 12 个 `` `OOO_ASSERT `` 条件；协议 shadow 只由外部 port valid/fire 建 owner，completion
  不复用生产 `aw_done_q/w_done_q/ifu_ad_write_complete_w`，避免 checker 与实现同盲。
- official bridge TB 增加 AW-first、W-first、反压+重复 flush、`flush+last-W+B`、`flush+B`、
  dropped B error 与 non-drop B error；新增 bridge+xbar TB 验证 IFU B handshake、owner 释放及
  后一 master 的精确 AWADDR/WDATA/B 路由。module suite 由 87 增至 88。

## 已有证据

- `evidence/red-summary.txt`：旧 RTL focused bridge 精确 22 fail；bridge+xbar 精确 3 fail。
- `evidence/module-test/summary.txt`：Icarus 14.0 module 88/88；其中 bridge 与 bridge+xbar
  原 RED 用例均 PASS。
- `evidence/assert-negative-summary.txt`：12 个立即断言的故意违约 marker 全部命中，
  `NEG-PROBES-DONE` 到达；contract baseline 从 38 ratchet 到 50。
- `evidence/core-regress/20260712-215009-1744303/`：NPC build PASS、AM 59/59、official
  p-mode build/run 153/153、`overall_rc=0`。当前 `.config` 为 Difftest OFF；本轮未包含
  privileged rv64mi/rv64si。
- `evidence/final-focused/` 与 `evidence/final-module-test/`：21:58 assertion-only review 修订后
  重新编译当前源码，focused bridge/bridge+xbar 2/2、module 88/88 PASS。
- `evidence/final-gates/`：contract 50/50、RTL style、bundled Verilator 5.051 lint 与无 clean
  NPC rebuild 全部 rc=0；`evidence/final-negative/` 的 compile/sim/marker check 均 rc=0，
  11 个 NEG-CASE 精确覆盖 12 条断言诊断并到达 `NEG-PROBES-DONE`。
- 新鲜度边界：21:52 core run 与最终功能 FSM 相同，但早于 assertion-only shadow 修订；因此
  只用于 AM/official 功能覆盖，最终断言源码由 current-source focused/module/lint 单独闭合。

## 设计文档审查

- active fetch spec 已冻结端口、owner、寄存器与同拍竞争表，并将 IFU-AXI-G1 标为 CLOSED；
  flush contract 已同步 E11/铁律②/UC-E，且保留 AMO/LR/SC nokill 的 UC-D 不确定性。
- ROADMAP、ground truth、completion design 与索引文档均只关闭本合同；IFU-FETCH-G2、
  PTW-PMP-G1、MIQ-G1、INSTRET-G1 等仍开放，5 ns 时序也仍远离 200 MHz。
- 文档中的 module/core 数字均带 Difftest OFF、privileged 未重跑边界；不得把本切片解释为
  “完整功能”或“200 MHz”完成。

## 实现者 / 审查者对抗

- `implementer`: sticky-drop drain、accepted-next completion、bridge+xbar progress 与 12 条立即
  断言均已实现；旧 RTL 的 22+3 RED 已在已存 module 证据中转 GREEN。
- `reviewer`: 先后检查 valid 撤回、同拍 flush+B、重复 flush、B error 越级交付、xbar owner
  假绿与断言同盲；发现 shadow completion 首版复用了生产 completion 后已修正，最终 RTL 与
  test-plan 独立审查均给出 `NO BLOCKER`。
- `closure`: current-source focused/module/lint/style/contract/build 与 assertion-negative 全绿；
  fresh `npc-dev` 5/5、816 个 raw asset 的 DB evidence index、DB-backed memory、DB-first/
  Markdown/artifact audits 与 strict guard 全部 PASS。reviewer 无剩余 blocker。

## 当前裁决

- `slice_result`: **IFU-AXI-G1 CLOSED**；root cause、old-RTL 22+3 RED、总线 owner 修复、
  非真空断言、current-source gates、核心功能回归、memory/profile/guard 全部闭合。
- `parent_goal`: **active**。完整功能仍有明确 blocker，且本切片没有新增 200 MHz STA 证据。
- `next`: 完成本切片的新鲜 profile/guard/证据索引后，继续 IFU-FETCH-G2，再处理 PTW-PMP-G1；
  功能合同闭合后才进入 mandatory repipeline/STA 主线。
