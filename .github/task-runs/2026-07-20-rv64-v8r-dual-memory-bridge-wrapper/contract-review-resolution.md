# v8r/F1 合同审查处置

## 审查 provenance

- 首次 reviewer `/root/v8r_f1_contract_review` 未返回工程结论，已中断；该局部任务只记
  `review_pending/interrupted`，不把长期父目标标为 blocked。
- 重试 reviewer `/root/v8r_f1_contract_review_retry` 严格消费同一份 self-contained、no-tools
  合同；未访问 shell、文件、网络或外部服务，结论为 `gap`。
- 原始子任务合同：`subagent-contracts/v8r-dual-memory-bridge-contract-review.json`。
- 原始子任务合同 SHA-256：
  `83079bd867a5c29664d99ba55c2f83b58eb3f04ab8f8d0ffdc0a6d01a23bdb53`。

## blocker 处置

| ID | 处置 | 冻结位置 | 状态 |
| --- | --- | --- | --- |
| B1 | 明确 DMA 事件可见拍组合屏蔽 `lookup_hit_o`，沿上以最高运行期优先级清全部 valid | 主规范 §2.7.5、§5.1；task contract §3/§4 | contract-closed, execution-pending |
| B2 | 增加 wrapper carrying contract：`mmu_flush_i` 前两 bridge 必须 idle；事件拍 DTLB `!clear_i` 屏蔽旧翻译且 request READY 为 0；非法非 idle pulse 使用 assert-negative 拒绝 | 主规范 §2.7.4/§2.7.5/§5.1；task contract §3/§4 | contract-closed, execution-pending |
| B3 | valid 更新改为逐 entry 合并：local fill/store 先更新，peer 只覆盖目标 index；不同 index 同拍保留，同 index peer clear 最终获胜；DMA 才是全局外层优先级 | 主规范 §2.7.5、§3.3、§5.1；task contract §3/§4 | contract-closed, execution-pending |
| B4 | 冻结维护地址为原始 byte PA；`wstrb` 只允许相对该 PA 的规范化 `01/03/0f/ff`；两端 assertion 拒绝 zero、稀疏、lane-shifted mask；枚举全部合法 mask/offset | 主规范 §2.7.1、§2.7.5、§5.1；task contract §3/§4 | contract-closed, execution-pending |
| B5 | 不提前关闭；在 RTL、directed TB、assert-negative、mutation、checker、F0 aggregate 与同 digest hard gate 全部产生 fresh 结果前，禁止使用唯一 leaf claim | 主规范 §5.1、§6；task contract §1/§4 | open-evidence-gate |

## 反例到可执行证据映射

| 反例 | hard gate |
| --- | --- |
| C1 DMA 同拍 stale hit | direct cache 与 wrapper TB 同拍 lookup/DMA；两 lane 后续 miss |
| C2 MMU flush 同拍旧翻译 | idle 正例、非 idle assert-negative、双 DTLB 结构 checker |
| C3 peer 吞无关 fill | direct cache 的不同 index、同 index 不同 tag、同 exact line 矩阵 |
| C4 非规范 mask 漏清 | 1/2/4/8B × 全 offset 枚举；invalid-mask assert-negative |
| C5 B/lookup stale hit | wrapper 精确同拍波形/断言与 `remove_same_cycle_hit_block` mutation |
| C6 过早 maintenance | AW、W、非 terminal B backpressure 正例与 `request_time_maintenance` mutation |
| C7 killed escaped write | bridge 现有 owner authority 复用检查、定向 terminal/drop/无 RMW |
| C8 B error/NC/IO/A-D 误 RMW | 分类定向检查与 `b_ok_only_peer` mutation |
| C9 peer miss 冻结 hot hit | 双向 hit-under-peer-miss 与 `gate_lane1_ready_on_arbiter_idle` mutation |
| C10 双响应被合并 | 双真实 hit、四种 response-ready 组合与 `merge_dual_response` mutation |
| C11 cross-wire 错接 | 非对称地址/mask 双向 TB、source checker、三项 cross-wire mutation |
| C12 reset 重放/旧响应 | peer/DMA/lookup/pending-response 与同步 reset 重合矩阵 |

## 明确未扩大的范围

本次处置没有把 F1 扩成 canonical-core 集成，也不声称 same-lane hit-under-own-miss、未来双 B
同拍冲突、第二 MIQ、physical SQ query、双 WB credit、DI-5/OOO-3 GREEN 或任何正式 PPA 结论。
复审只能判断新版合同是否充分；B5 必须由后续 fresh 可执行证据关闭。
