# V9H IFU-FETCH-G2 独立覆盖审查与纠偏

## 首轮裁决

独立 no-tools RTL 审查在仅有 12 行 F=2/4/6 矩阵时给出 `GAP`（置信度 0.90）。该结论是
验证证据缺口，不是生产 RTL 缺陷。审查指出：F=0 ABI 未覆盖、response 反压期间未主动呈现
另一请求、tail-zero 可能依赖复位初值、fault 后缺少接收后静默窗口、成功控制未证明内部
AR/fill/SRAM 观察点非真空，以及观测等价的 slot1 owner 变体不能计作有效杀伤。

## 已执行纠偏

- 增加真实第一页 invalid-PTE `F=0` bridge 路径和直接 decoder `F=0` 路径；验证全零 raw
  packet、两槽 page fault/NOP、精确 tval、零 instruction-data AR、零 fill/write、两拍反压和
  两拍接收后静默。
- 每个 F=2/4/6 fault response 在 `valid && !ready` 时主动呈现不同低位的对齐请求；逐拍证明
  `fetch_req_ready=0`，并证明 raw/resp/split 全元组稳定。
- 先完成逐 halfword 非零且互异的 8B 成功 packet，再无复位执行 F=2 fault；删除 scratch
  清零的可编译 RTL 变体会泄漏上一事务 tail，并被动态 oracle 拒绝。
- 成功控制事务实际观察到 4 次 instruction-data AR、1 次 packet-cache fill、1 次有效 SRAM
  写；fault 行从 frontier 关闭事件持续观察到 response 接收后两拍，逐拍检查 AR offer、fill
  和 SRAM write。
- `F_ref` 由 `4096 - pc[11:0]` 独立计算，不使用 DUT split、decoded fault 或 DUT helper。
- 将固定 4B slot1 起点这一合法 fault 元组上的观测等价变体移出杀伤集合，改为错误固定 2B
  起点的可区分反例；首轮 10/13 与中间 13/13 结果保留为审计轨迹。
- 最终 16 个 current-source RTL 变体均编译成功并由指定语义 marker 拒绝；bridge 与 decoder
  各 8 个，覆盖 frontier 保存、live/saved owner、stall release、stale/lane provenance、AR
  cutoff、partial cache fill、F=0、range 边界、slot 长度 owner 与 NOP 净化。

## 保持的边界

本轮只裁决 fetch bridge 到 packet decoder 的 page-fault byte provenance。PMP/RRESP、完整
physical footprint、lane1 下游 capture、fault-tval FIFO/trap lifecycle、PTW write PMP、
full-core architecture freeze 与正式 PPA 均仍由独立 debt/gate 裁决。
