# V11E independent final review

## RTL 对象与配置

- 对象：`OooRob.slot_generation_q`。
- production RTL：
  `npc/rv64/vsrc/writeback/OooRob.v`，
  SHA-256
  `bbb68a2a819bb8bfb005adfb8f2659e8037ea6280d9dc338415395aeab62c561`。
- 独立 testbench：
  `npc/rv64/testbench/tests/tb_ooo_rob.sv`，
  SHA-256
  `6c5881089fc1437d40f15532279dde1e0c8b1359d4bd5c47ff03b4886a87f4f5`。
- 配置：16-slot ROB，`PRODUCER_GEN_W=1/4`，assert/release。
- final-review contract SHA-256：
  `75fe8f31bbada20668b8da84d9085cf378b4e0ac7dad1dd6d752e48aa1d13aad`。

## Testbench / EDA 观测

- canonical attempt-3 baseline 4/4 PASS。
- 17 个 compile-success RTL variants 在两种 generation width 下形成
  34 个独立仿真镜像；所有变体编译均关闭 `OOO_ASSERT`，34/34 由
  `[V11E-SLOT-GEN-ORACLE][FAIL]` 拒绝。
- 独立 model 只由 stimulus 与沿前 generation/valid/done/head/tail/count/
  recovery 状态推导 expected，并在每个 posedge 比较全部 16 个 slot；
  expected carrier 不复用 DUT ProducerId。
- attempt-1 的 `walk-carrier-zero-generation/g1` 假绿与 attempt-2 的
  `recovery-resets-generation/g1` 假绿原样保留。attempt-3 采用
  slot4 generation=0、slot3 generation=1 的同一 recovery pair 后，
  两类错误均在定向 cycle 被拒绝。
- 146-file RTL pre/post snapshot 均为
  `665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca`；
  normal regression marker 为 `[PASS] tb_ooo_rob`。
- ARCH_STABLE 为 51/53 expected GAP，marker：
  `v11e_new_failures=0`。

## 裁决

- `blocker=0`。
- bounded APPROVE：只批准 semantic ledger 的
  `rob-slot-generation` 单元由 GAP 晋级 PASS。
- V11D→V11E ledger 精确差分只新增
  `v11e-rob-slot-generation-current-closure`，总计从
  6 PASS / 38 GAP 变为 7 PASS / 37 GAP。
- 不批准 global holder collision fence、global no-live-reuse、whole
  architecture、system、synthesis、STA、power 或 PPA。
- `GEN_W=1` 有限回绕仍依赖外部 holder collision fence。
- `scope_extension_request=none`，置信度高。

终审节点未修改文件，全部只读命令已停止，唯一 WSL shell ownership 已归还。
