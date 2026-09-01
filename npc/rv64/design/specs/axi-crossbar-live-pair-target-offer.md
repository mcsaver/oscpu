# AxiCrossbar live complete-pair target VALID-only offer

## 目标时序

当前 retained 写路径：

```text
C0  master AW/W fire -> holder Q
C1  holder grant -> target AW/W；edge 建立 active/owner/sent
C2  registered target B -> master
```

本候选仅改变 live 完整写对：

```text
C0  master AW/W fire，同时向唯一 inactive target 呈现 AW/W
    edge 原子建立 active/owner/payload/sent，并消除该 pair 的 holder 残留
C1  registered active + dual-sent 授权 target B 回 master
```

既有 held-grant offer 保留，作为 partial pair、active target、older holder、contention、unknown 与所有
非资格路径的 fallback。

## Eligibility 与选择

`live_pair[m]` 只在同一 master 的 AW/W 同拍均以既有本地 READY 真实 fire 时成立：

```text
m_awready[m] = !wr_aw_hold_q[m] && !wr_master_busy_q[m]
m_wready[m]  = !wr_w_hold_q[m]  && !wr_master_busy_q[m]
live_pair[m] = m_awvalid[m] && m_awready[m]
            && m_wvalid[m]  && m_wready[m]
```

direct eligibility 还要求 reset inactive、control/target/RR 已知、target edge-old inactive、全局没有
更老完整 holder，且该 target 精确只有一个 live pair。两个 live pair 指向同 target 时 live path
action-quiet，两笔都进入 holder，下一拍由既有 RR held-grant选择；不同 target 可各自选择一个 owner。
target READY 不参与 eligibility 或 owner选择。

## 原子 sequential handoff

每个 selected live target 的 C0 edge 必须同时：

- 置 `wr_active_q[target]`；
- 锁存唯一 `wr_owner_q` 与 live AW address/size/ID、W data/strb；
- 分别以 direct AW/W fire 播种 `wr_aw_sent_q/wr_w_sent_q`；
- 置 selected master busy，并按一次真实 target acquisition 更新 RR；
- 覆盖 generic input capture，令 selected master 的 AW/W holder 都保持为 0。

selected live offer 与同 target held-grant offer必须互斥。同一 master不得在多个 target取得 owner；B
terminal 前 busy不得释放。若 selected pair 在 holder 中残留，B 后会重复真实写，因此 residual holder
是 hard failure。

## READY 四象限

| C0 target READY | C0 sent seed | C1 行为 |
|---|---|---|
| `11` | AW=1, W=1 | AW/W 静默，只等待或路由 B |
| `10` | AW=1, W=0 | 只从 registered payload 重发 W |
| `01` | AW=0, W=1 | 只从 registered payload 重发 AW |
| `00` | AW=0, W=0 | 从 registered payload 重发 AW/W |

accepted channel不得重复；live master payload在 C0 后变化或 poison 不得影响 retry。

## B authority 与 DAG

live offer 拍绝不 route B：`m_bvalid=0`、`s_bready=0`。B 继续严格要求 edge-old registered
`wr_active_q && wr_aw_sent_q && wr_w_sent_q && known owner`。partial path 即使在某拍补齐最后一个
channel，也只能在 sent 位注册后的下一拍消费 B。

允许的组合 DAG：

```text
bridge registered payload -> arbiter IDLE winner -> lane adapter align/shift
 -> crossbar local READY/live selection -> target AW/W VALID/payload

target READY -> direct channel fire D -> registered sent Q
```

实现中还必须保持组合过程隔离：master `AWREADY/WREADY` 由一个只读取 holder/busy Q 的独立
组合过程驱动；`m_bvalid/m_bresp/m_bid/s_bready` 由另一个只读取 registered
active/owner/dual-sent Q、target B 输入与 master BREADY 的组合过程驱动。读取 live AW/W 输入并
生成 target AW/W offer 的请求组合过程不得再驱动这两组输出。该隔离不增加寄存器或协议拍，只切断
工具 procedural scheduling 对无真实逻辑依赖输出产生的假组合边。

禁止 target READY 反向进入 master READY、live eligibility、target decode、RR/owner selection 或 B
route。该 forward cone 明显变长；lint 无组合环不能替代 mapped STA，PPA 在 fresh mapped 证据前固定
为 `UNQUALIFIED`。

## 必测不变量

- `XL-I1`：live offer只来自同拍双 channel fire与唯一 inactive target owner；reset/unknown fail closed。
- `XL-I2`：C0 target payload逐位等于 selected live master；C1 partial retry逐位等于 registered payload。
- `XL-I3`：READY `11/10/01/00` 的 sent seed与后续 retry精确逐 channel守恒。
- `XL-I4`：C0 early B不可见；registered owner+dual-sent前任何 B action quiet。
- `XL-I5`：selected live owner无 residual holder，AW/W/B exactly once。
- `XL-I6`：older complete holder优先；同 target live contention退回 holder/RR；不同 target owner彼此独立。
- `XL-I7`：B stall下 active/owner/payload/ID/RESP稳定，busy只在真实 B terminal释放。
- `XL-I8`：AW-first、W-first、active target与非法/unknown source继续走原 holder/held-grant路径。

本候选只优化 transport latency，不改变 store retirement、precise access fault、flush后 escaped write
drain、A/D update、cache maintenance或 memory ordering。
