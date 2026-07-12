# 派发日志

## 基本信息

- `task_id`: 2026-07-12-rv64-ifu-axi-g1-flush-drain
- `graph_template`: contract-first bugfix + bridge/xbar integration
- `log_policy`: append-only

---

### [2026-07-12 21:30 +0800] `recall-map` - PASS

- `owner_agent`: root + ifu_axi_rtl_review + ifu_axi_test_plan + ifu_axi_contract_review。
- `action`: DB brief 后读取 interface-contract-first、fetch bridge spec、flush contract，逆向
  `OooFetchAxiBridge` AW/W/B 状态与 `AxiXbar` hold/owner/release 数据流。
- `outputs`: 根因是 flush 把“语义可丢”错误等价成“事务可撤”；xbar 在 master-side 已接收
  channel 后会持有直至 B，必须由 bridge 持续补齐并消费。
- `handoff_to`: freeze-contract, bridge-red, xbar-red。

### [2026-07-12 21:31 +0800] `freeze-contract` - PASS

- `owner_agent`: root。
- `action`: 在 task-report 先冻结六类合同、reset/flush/write-completion 全序与同拍 corner。
- `outputs`: sticky drop + 保持 AW/W accepted/payload + consume B 后 IDLE；无 drop 的正常路径不变。
- `handoff_to`: bridge-red, xbar-red。

### [2026-07-12 21:42 +0800] `bridge-red` - PASS

- `owner_agent`: root。
- `action`: 在 official fetch bridge TB 加 AW-first、W-first、stall/repeated-flush、flush+B、
  dropped BRESP error 与 non-drop B error 矩阵，保持 RTL 未改后运行 bundled iverilog。
- `outputs`: 编译成功；新合同精确 22 fail。owner/accepted/payload/valid/BREADY 均被旧 flush
  分支清除，既有用例未报失败。
- `handoff_to`: xbar-red, implement-drain。

### [2026-07-12 21:45 +0800] `xbar-red` - PASS

- `owner_agent`: root + ifu_axi_test_plan。
- `action`: 新增 M0=真实 bridge、M1=合成后一写、S0=可控 slave 的集成 TB；先让 IFU
  AW/W 到 slave、延迟 B、flush，再排队 M1 并送 IFU B。
- `outputs`: 编译成功；旧 RTL `s_bready=0`、xbar IFU owner 不释放、M1 八拍内不到 slave，
  精确 3 fail。证明不是 bridge 内部状态假说，而是确定的系统级进展失败。
- `handoff_to`: implement-drain。

### [2026-07-12 21:47 +0800] `implement-drain` - PASS

- `owner_agent`: root。
- `action`: 拆开 reset/mmu flush；在 `S_AD_UPDATE` 增加 sticky `ad_drop_q`，保留 payload 与
  AW/W accepted 位，以 accepted-next 承认同拍 fire，完整消费 B 后再按 drop/normal 分流。
- `outputs`: 22 个 bridge RED 与 3 个 bridge+xbar RED 转 GREEN；non-drop B OK/error 原路径
  保持，drop BRESP 不再形成旧 fetch fault；module suite 增至 88。
- `handoff_to`: assert-nonvacuity, regression。

### [2026-07-12 21:48 +0800] `assert-nonvacuity` - PASS

- `owner_agent`: root + ifu_axi_rtl_review。
- `action`: 新增外部 AXI port shadow，覆盖 AW/W stall hold、pending valid、accepted 不重发、
  owner/BREADY、B order、drop quiet 与 drop completion；用独立负 TB 逐条故意违约。
- `outputs`: 12 类 marker 全命中且到达 `NEG-PROBES-DONE`；contract ratchet 38→50。审查发现
  shadow completion 首版复用生产 completion 的 common-mode 风险，随后改为只消费 shadow
  seen 与 raw port fire，并把 valid hold 判定收紧为 X-safe。
- `handoff_to`: current-source final validation。

### [2026-07-12 21:49 +0800] `module-regression-baseline` - PASS

- `owner_agent`: root。
- `action`: bundled Icarus 14.0 运行全部 module testbench。
- `outputs`: 88/88；bridge 与 bridge+xbar 均 `[RESULT] PASS`。该证据早于 21:58 assertion-only
  review 修订，作为功能 FSM 基线有效，但不能替代 current-source closure rerun。
- `handoff_to`: core-regress, current-source final validation。

### [2026-07-12 21:52 +0800] `core-regress-baseline` - PASS

- `owner_agent`: root。
- `action`: 当前 Difftest-OFF 配置运行 NPC build、AM cpu-tests 与 official p-mode suites。
- `outputs`: build PASS、AM 59/59、official 153/153、overall_rc=0；未覆盖 Difftest 与
  privileged rv64mi/rv64si。该 run 同样早于 assertion-only review 修订。
- `handoff_to`: current-source final validation, record-review。

### [2026-07-12 22:03 +0800] `record-review` - RUNNING

- `owner_agent`: root + ifu_axi_rtl_review + ifu_axi_test_plan + ifu_axi_contract_review。
- `action`: 对齐 active fetch/flush specs、ROADMAP/ground truth、task-run 与 reviewer 反例；
  审查 assertion 同盲、xbar 层次假绿、Difftest/privileged 覆盖和 200 MHz 越级结论。
- `outputs`: RTL 与 test-plan 当前均 `NO BLOCKER`；设计文档只关闭 IFU-AXI-G1 并保留其他
  blocker。current-source gates、fresh profile/evidence index、DB memory 与 strict guard 待完成。
- `handoff_to`: current-source final validation, profile/guard；parent goal 保持 active。

### [2026-07-12 22:06 +0800] `current-source-final-validation` - PASS

- `owner_agent`: root + ifu_axi_final_gates。
- `action`: 对 21:58 assertion-only 修订后的源码重新编译 focused、module、lint；同步运行
  contract/style、无 clean NPC rebuild 与独立 assertion-negative marker check。
- `outputs`: focused 2/2、module 88/88、contract 50/50、style、Verilator 5.051 lint、build
  全 rc=0；11 NEG-CASE 覆盖 12 诊断并到达 `NEG-PROBES-DONE`。
- `evidence`: `evidence/final-focused/`、`evidence/final-module-test/`、`evidence/final-gates/`、
  `evidence/final-negative/`、`evidence/final-validation-summary.txt`。
- `handoff_to`: record-review。

### [2026-07-12 22:15 +0800] `record-review` - PASS

- `owner_agent`: root + ifu_axi_rtl_review + ifu_axi_test_plan + ifu_axi_contract_review。
- `action`: 更新 active docs 与 DB-backed project/NPC/known-issues memory；索引 816 个 raw
  evidence asset；运行 fresh `npc-dev`、DB-first/Markdown/doctor/artifact audits 与 strict guard。
- `outputs`: reviewers `NO BLOCKER`；npc-dev 5/5；四项 DB/artifact 检查与 strict guard PASS；
  IFU-AXI-G1 CLOSED，IFU-FETCH-G2/PTW-PMP-G1 和 200 MHz parent 目标保持开放。
- `evidence`: 同级 `evidence-index.md`、`evidence/strict-guard.log`、sibling
  `2026-07-12-rv64-ifu-axi-g1-flush-drain-npc-final-2/`。首次 profile 后因 task-run
  尾部格式修订触发 freshness fail-closed，故以 `-2` replay 作为最终 guard 真源。
- `next_step`: 提交独立 slice，继续 IFU-FETCH-G2。
