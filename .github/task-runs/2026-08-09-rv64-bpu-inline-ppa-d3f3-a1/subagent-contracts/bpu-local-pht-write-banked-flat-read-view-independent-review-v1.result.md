# BPU write-banked / flat-read-view independent review v1

RV64 RTL 结论｜对象=`OooBranchLocalPht/OooBranchLocalPhtBank`、`gate-summary.json` 与 architecture registry｜周期/配置=双路 lookup 0-cycle、bank-local update S1→S2、f5f2/5.0 ns flat-read-view config｜TB/EDA 观测=child/parent rc0、12/12 compile-success mutation 拒绝、registry 19 tests及render/check rc0；综合/STA未运行｜范围=PASS

## 裁决

`RETAIN`。授权且仅授权一次使用全新 run-id 执行：

- design-id：`sha256:f5f2a00a34a25262f9913abda384a197f751afc94cf424e896c7414a65b92eb8`
- configuration：`mapped-5ns-bpu-local-pht-write-banked-flat-read-view-inline-v1`
- period：5.0 ns
- runner：`npc/rv64/eval/ppa/run-traceable-mapped-current.sh`

该授权不代表 PPA PASS；Top40、WNS/TNS、面积及功耗收益仍为 UNKNOWN。

## RTL 独立核对

- `valid_view_o[row]=valid_q[row]`，wrapper 接到 `flat_valid_view_w[bank*256+:256]`，完整索引 `{bank,row}` 对应 `flat_valid_view_w[bank*256+row]`。
- counter 位基址为 `2*256*bank+2*row = 2*(bank*256+row)`，等价于 `flat_counter_view_w[2*index+:2]`。
- 两路输出分别直接使用 `lookup0_idx_i`、`lookup1_idx_i`，无寄存级、仲裁或地址复用，保持同/异 bank、同/异 row 双路 0-cycle lookup。
- wrapper 无 local-PHT `reg`、`always @(posedge clk)`、公共 `counter_train` 或 variable-write owner。16 个 generate bank 各自唯一拥有 256 个 `valid_q/counter_q` entry 及 S1 payload/S2 write。
- `update_valid_i && update_bank_w==THIS_BANK` 构成唯一 bank 选择；`update_old_ctr_w`、`counter_train`、`upd_*_q` 均在 bank 内。
- 非阻塞赋值保持 S1 读取沿前 Q、旧 pending S2 同沿写回，因此 read-before-write 和连续同 entry RAW no-forward 保持。
- `rst || clear_i` 优先清 `valid_q/upd_valid_q`；parent 仍直接送出 update，mispredict 依据 actual outcome 训练且无 restore 输入。

## Mutation 与 sealed gate

12 个保存的 mutant SHA 与 `mutation-evidence.json` 一致，实际 diff 分别覆盖 lane1 地址复用、bank/row 交换、lookup 加拍、公共 4096-entry write owner、counter wrap、update 早/晚拍、RAW forwarding、clear pending、same-bank arbitration、mispredict suppress/restore。每项 `compile_succeeded=true`、`driver_rc=2`、预期 marker 恰好一次、`[RESULT] FAIL` 恰好一次、无 `[RESULT] PASS`；12 份 raw-log SHA 全部一致。

产品源哈希：

- child：`3ea207a6e61569d10ffc388b989fb1ca75a1c9d31d6267591e2db0453a2f72a9`
- parent：`f56cf84f2d54917300a4dbcebe052568f2b50a12f049de531ccaf0d50b983fb4`

七项 gate rc 均为 0，`gate-summary.json` artifact SHA 全部复算一致。`registry-check` 的 `structural=PASS product=GAP` 是正确 fail-closed，不能提升为 physical closure。

## Registry/PPA 投影

- 新候选固定为 `development/UNMEASURED/GAP/canonical=false`，唯一 next action 为 `RUN_TRACEABLE_MAPPED_CURRENT_ONCE`。
- 冻结 b279 summary SHA `fc752a73...62d802` 一致；execution 为 PASS，但实验 verdict 保持 `ROLLBACK/GAP/RETAIN_NONCANONICAL`。
- b279 binding design-id 与 live f5f2 不同，`ARCHITECTURE.md` 正确投影 `GAP_STALE_DESIGN`。
- 新配置投影三个 placeholder macro、inline predictor/child/bank 及 keep-hierarchy 集合。
- runner 强制显式 configuration/design-id，并在末端重绑 source、parameters、STA manifest、raw synth census 与 production manifest。

## 边界

- Counterexamples：未发现阻断一次 PPA 的承重反例。
- Unknowns：无新 elaboration、mapped、STA、Top40、area 或 qualified-power；flat 4096-entry read mux可能改善、持平或恶化。
- Alternative hypotheses：旧 b279 面积回退可能同时来自 bank-local read mux、S1复制、hierarchy或 mapping。
- Exactly-once：首次 invocation 后授权视为已消费；无预登记机器异常或新身份不得重复同一 design/config。
- Scope extension：无。
- Confidence：RTL packing/owner/周期语义和 registry stale 绑定为高；focused evidence为高但非形式完备；PPA收益为无。

合同 JSON SHA-256：`4274b398cceb505275d0d43b87b68890f336ac87421a803de48cf8d77478e7fe`。独立节点未重跑测试、仿真、综合、STA或 parser。
