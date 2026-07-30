# V11D 游标周期推导

## 1. 需求

`OooMemOwnerTracker` 必须在双发射内存 owner 出生时给出稳定、无重复且可回绕的
token。`next_token_q` 只是 allocator cursor，不是 owner holder；它不得授权
writeback、redirect 或 memory side effect，但其选择错误会破坏 token 分配公平性
和双 lane 顺序。

## 2. 协议规则

设沿前状态为 `live_q` 与 `cursor_q`：

1. lane0 从 `cursor_q` 开始按模 `TOKEN_COUNT` 顺序选第一个沿前 FREE token。
2. lane1 使用同一沿前集合；仅当 lane0 形成合法 claim 时排除 lane0 候选，
   然后选择第一个剩余 FREE token。
3. 非原子请求各 lane 按自身 valid/ready 出生；lane0 被 PID/kind 条件阻塞时，
   lane1 不得被迫跳过 lane0 未取得的 token。
4. 原子双 lane 只有两路均 valid+ready 时才同时出生；单 credit 时零出生。
5. tagged free 与 STORE release 只改变沿后 live-set，同沿 allocator 不得借用
   dying token。
6. 若 lane1 出生，下一游标为 `alloc1_token+1`；否则若 lane0 出生，为
   `alloc0_token+1`；否则保持。加法按 `TOKEN_W` 自然回绕。

## 3. 状态转移

| 本沿出生 | `cursor_d` |
| --- | --- |
| lane0=0, lane1=0 | `cursor_q` |
| lane0=1, lane1=0 | `lane0_token + 1` |
| lane0=0, lane1=1 | `lane1_token + 1` |
| lane0=1, lane1=1 | `lane1_token + 1` |

reset 后 `cursor_q=0`。状态模型必须根据 stimulus、沿前 expected live/PID
集合和协议规则独立计算 ready/token/fire；不得先读取 DUT token 再生成 expected。

## 4. 不变量

- 所有出生 token 均来自沿前 FREE 集合。
- 同沿双出生 token 不同，且顺序等于从 expected cursor 开始的第一/第二 FREE。
- 零出生时 cursor 保持，包括 idle、满表、PID 阻塞和原子单 credit。
- 同沿死亡不影响本沿 token 选择；下一沿才允许扫描到释放 token。
- cursor 回绕后仍扫描完整 token 空间；`TOKEN_COUNT=4` 与 production
  `TOKEN_COUNT=32` 都必须覆盖。
- 禁用 production `OOO_ASSERT` 后，独立 testbench 仍能拒绝游标 RTL 变体。

## 5. 数据通路与观测

- 输入：两路 allocation valid/kind/epoch/ProducerId、atomic-pair、
  两路 exact free 与 STORE release mask。
- 独立模型：expected live bitmap、expected ProducerId live-set、
  expected cursor、圆环 first/second-free encoder。
- 黑盒观测：`alloc0_ready_o/alloc0_token_o`、
  `alloc1_ready_o/alloc1_token_o` 及沿后 live-set。
- 直接状态观测只可作为补充诊断，不得替代黑盒 token 序列和 mutation
  sensitivity。

## 6. 最小定向轨迹

1. reset→lane0-only→lane1-only→idle hold；
2. 非原子双出生，空洞相邻与不相邻；
3. lane0 PID blocked、lane1-only 取得第一 FREE；
4. 单 FREE：非原子 lane0-only 出生与原子双 lane 零出生；
5. 满表 + exact/bulk death：同沿不复用、下一沿从保持的 cursor 扫描；
6. 尾部双出生跨 `TOKEN_COUNT-1→0` 回绕；
7. production `TOKEN_COUNT=32` 全环扫描和非零空洞；
8. 编译成功游标变体：固定 scan base、错误 reset、错误 advance 步长、
   错误 lane 优先级、ready 代替 fire、零出生自增、lane1 未排除 lane0、
   截短 production 扫描。

