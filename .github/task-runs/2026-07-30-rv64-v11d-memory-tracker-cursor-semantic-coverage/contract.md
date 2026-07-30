# V11D `OooMemOwnerTracker.next_token_q` 语义覆盖合同

## 本轮分类

- 初始分类：`verification`。
- 唯一技术目标：为 production `OooMemOwnerTracker.next_token_q` 建立当前
  source-bound、可证伪且不依赖 DUT 返回 token 作为参考答案的周期级语义证据。
- 重分类条件：若定向 testbench 在合法二态输入下给出 production RTL 反例，
  本轮立即改列 `production RTL fix`，先补根因与接口合同，再做最小修复。

## 当前事实

- production tracker：
  `npc/rv64/vsrc/memory/OooMemOwnerTracker.v`
- 当前 production tracker SHA-256：
  `fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8`
- V11C 已闭合 `memory-tracker-producer-map` 与
  `memory-tracker-live-set`，明确未闭合 `tracker-next-token-cursor`。
- A3 的系统终端事务和 checker replay 已闭合；本轮不改变 production
  core RTL、elaborated RTL、设备模型或 simulator 语义时，不触发完整系统重跑。

## 竞争假设

- H1（RTL 正确、证据缺口）：游标从沿前 `live_q` 开始扫描，返回圆环顺序中
  第一/第二个空闲 token；游标只由真正出生的最后一路推进到其 token 后一项。
- H2（RTL 反例）：lane1-only、双出生、原子单 credit、blocked lane、回绕、
  满表/同沿死亡或 production `TOKEN_COUNT=32` 中至少一条轨迹违反 H1。
- H3（假绿）：testbench 读取 `alloc*_token_o` 后再构造 expected token，
  或只观察 live-count/map，使游标错误仍可 PASS。

## 结论边界

本轮最多晋级 census 单元 `tracker-next-token-cursor` 的单个 production
`OooMemOwnerTracker` 实例。不得外推其它 holder、global no-live-reuse、
whole architecture、系统事务、综合、STA、功耗或 PPA。

