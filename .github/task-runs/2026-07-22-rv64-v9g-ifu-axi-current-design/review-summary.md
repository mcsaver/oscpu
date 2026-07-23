# V9G IFU-AXI-G1 独立终审摘要

## 裁决

限定材料 reviewer 判定 **PASS**：在合法 AXI slave 合同、当前
`design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`、
非 reset 路径及冻结 RTL/TB 配置内，没有发现能推翻 IFU-AXI-G1 当前设计 CLOSED 的
周期级反例。`scope_extension_request` 为无，置信度约 0.94。

终审合同：

- JSON：`subagent-contracts/v9g-ifu-axi-final-evidence-review-v1.json`；
- SHA-256：`e9cff492b1b02b789c20fc2d13e1b459c6f33374403fa2dbd8f5a3230b0a0b2d`；
- canonical `create → validate → render` 通过；
- `self-contained-no-tools`，无命令、无写路径、无外部来源。

## 接受依据

- write owner 只在寄存后的 `state_q==S_AD_UPDATE` 建立；旧 `S_WALK_R` 的 flush
  由 PTW read-owner 取消/排水处理，不能同拍新建 A-update write owner；
- `aw_accepted_next`/`w_accepted_next` 纳入当拍 fire，`effective_drop` 纳入当拍
  `mmu_flush_i`；
- focused 3/3 覆盖 first/last/all-fire、both-done+B-error、repeated flush、
  payload stability、drop quiet 及通用 AxiXbar 两拍 BREADY 背压；
- 18/18 branch-local compile-success RTL verification variants 均被指定动态 oracle
  拒绝，排除了 accepted-next、旧 done-only completion、drop/BRESP 优先级、BVALID
  提前释放和 AW/W 同拍错误依赖等共同盲点；
- module aggregate 109/109、证据单测 8/8、生产 RTL 哈希前后相同；
- 两个 architecture source 漂移路径旧哈希精确重建，非 provenance 语义投影不变，
  directed architecture gates 9/9 GREEN。

## 残余边界

- 本结论是结构检查、定向动态验证、mutation 和 aggregate 的组合，不是任意无限 stall
  序列的形式化穷尽证明；
- 非法提前 BVALID、reset 中 owner 处理、多 master 公平性、零气泡 handoff、其它配置和
  PTE 一致性的更广问题不属于 IFU-AXI-G1；
- reviewer 按合同没有独立读取原始产物；其 PASS 只作为已执行 fail-closed 证据链的第二遍
  逻辑复核，不替代主 agent 的动态运行和哈希重建；
- full-core `ARCH_STABLE=GAP`、41 blockers、`PPA=UNQUALIFIED`、
  `promotion_eligible=false` 保持不变，不得外推为全核完成或 PPA 改善。
