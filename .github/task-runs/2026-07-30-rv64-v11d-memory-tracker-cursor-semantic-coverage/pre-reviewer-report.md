# V11D 独立预审

## 结论

`GAP`，且 blocker 属于验证证据缺失，不是已知 production RTL 缺陷。

## H1/H2/H3

- H1：静态支持。沿前 `live_q` 圆环扫描、lane1 对合法 lane0 claim
  的排除、最后出生 lane 推进与零出生保持的 RTL 数据流一致。
- H2：未发现合法二态 production RTL 反例；不重分类为 RTL 修复。
- H3：成立。V11C TB 使用 DUT token 构造 expected state，且只有
  `TOKEN_COUNT=4`，没有独立 expected cursor/first-second-free encoder。

## 要求的闭环

- 4/32-token assert/release；
- lane0/lane1-only、双出生、blocked lane、原子单 credit、idle/full、
  exact/bulk death、非相邻空洞与回绕；
- 关闭 `OOO_ASSERT` 后仍拒绝错误 reset、固定 scan base、错误步长/
  lane 优先级、ready 代替 fire、idle 自增、两类 lane1 排除错误和
  32-token 截短扫描；
- summary 绑定 design/source/TB/config/log/vvp/receipt；
- ledger 只晋级 `tracker-next-token-cursor`，总体保持 GAP。

合同 SHA-256：
`4f9bf8c34276eeba4a1758e4243583def7cd907e94f6ffd676646a13290c3cb9`。

