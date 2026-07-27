# RV64 V9W pending-system canonical kind contract

## RTL 对象

- 当前本地 RV64 双发射 OoO RTL：
  `sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`。
- 类型 owner：
  `OooPendingSystemSequencer.kind_q`。
- 消费链：
  `OooPendingSystemSequencer` →
  `OooControlPlane` →
  `OooCoreTopGlue` →
  `OooFrontend` typed redirect。
- 本轮类型集合：
  `CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/FENCE/IRQ`。

## 本轮目标

1. 用单一注册 `kind_q` 取代并行类型状态，所有公开类型信号只从
   canonical kind 投影。
2. 普通 FENCE 的强 `mem_idle` 条件只消费 holder 的 `fence_o`，不在父模块
   再建立第二个 raw instruction 类型真源。
3. SFENCE/SINVAL 与 FENCE.I 的 redirect reason 消费 holder-derived commit
   pulse，不用窄 raw encoding 重解码。
4. 保留 CSR exact ProducerId lease；非 CSR 类型不得制造 ProducerId。
5. 用双 lane 正例、分层回归与 compile-success RTL 负向版本绑定当前
   design-id。

## 不变量

- `valid_o` 当且仅当 `kind_q != NONE`。
- valid holder 的八个公开类型信号 exact-one。
- 非空 holder 不接受 recapture；kind 与 payload 保持到授权 clear/death。
- CSR lease 只在 CSR dispatch birth，只能由 matching producer death 或
  backend-global reset 清除。
- 不给 terminal event 增加去重；不关闭、降级或放宽 RTL assertion。
- 本轮不把局部类型闭合外推为完整 recovery、memory-owner、Linux 终态或
  PPA 结论。

## 成功条件

- 两条 lane 的七类非 IRQ capture/hold/clear 矩阵为 14/14 PASS。
- SFENCE.VMA、SINVAL.VMA 与 FENCE.I 的 typed redirect 均出现精确 marker。
- 四个可编译 RTL 负向版本全部由预期 assertion/oracle 拒绝，且 live
  RTL source set 前后不变。
- focused、layered、module aggregate 与 canonical architecture replay
  均绑定当前 design-id 并通过。
- `SERIALIZE-G1` 保持 `OPEN`；最终声明保持
  `architecture_freeze=GAP`、`PPA=UNQUALIFIED`、
  `promotion_eligible=false`。
