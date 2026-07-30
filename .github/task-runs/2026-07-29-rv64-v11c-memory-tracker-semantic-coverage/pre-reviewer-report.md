# V11C 只读预审

结论：`memory-tracker-producer-map` 的合法二态 RTL 路径无已知反例，
`memory-tracker-live-set` 静态代数无已知反例，但旧验证不足以闭合。

主要反例：

- `assign live_mask_o = live_q` 改成常零时，旧 TB 不读取 `live_mask`，
  可能继续 PASS；
- 旧 same-edge death/rebirth 使用相同 PID，被 ProducerId guard 阻断，
  不能独立证明 dying token 不参与本沿 scan；
- V8L 的 9 个 current mutation 均不直接切断 tracker map/live-set；
- 有效 tuple 与 live state 的 X-known 缺确定 oracle。

要求的最小闭合动作均已在 attempt-2 实现；`tracker-next-token-cursor`
必须保持 GAP。
