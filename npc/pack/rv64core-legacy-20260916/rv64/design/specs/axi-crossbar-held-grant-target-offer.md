# AxiCrossbar held-grant target VALID-only offer

## 状态变换

旧写路径：

```text
master fire -> holder Q -> grant cycle(target quiet)
            -> active/owner Q -> target AW/W offer -> registered B route
```

本候选：

```text
master fire -> holder Q -> grant cycle(target AW/W offer)
            -> active/owner Q + sent-by-fire -> retry missing channel / wait B
```

direct source 是完整 holder Q，不是 live master；所以 AW/W 的配对、target decode与 ID 在 offer 前均已
注册。target READY不参与 master READY、grant或 owner选择，只在 grant edge写 per-channel sent D。
direct target在该拍不 route B；其他 target/master 已经由 registered owner授权的并行 B不受影响。

## 四象限

| target READY | grant edge sent | 下一拍 target 行为 |
|---|---|---|
| `11` | AW=1, W=1 | 两通道静默，等待 B |
| `10` | AW=1, W=0 | 只重发 W |
| `01` | AW=0, W=1 | 只重发 AW |
| `00` | AW=0, W=0 | 以注册 payload重发 AW/W |

grant拍绝不 route B。B visibility仍只由 registered active+双 sent授权；这既避免 ownerless terminal，
也允许合法 target 在 BREADY=0时保持早到 BVALID，待下一拍精确 owner建立后再消费。

## 不变量

- `XG-I1`：每个 direct target只能对应一个 existing grant与一个 selected complete holder。
- `XG-I2`：direct AW/W payload逐位等于 selected holder；partial stall后 registered retry仍相等。
- `XG-I3`：grant edge的 sent位逐 channel等价于 direct VALID&&READY fire。
- `XG-I4`：master READY公式不依赖 target READY/BVALID，禁止 READY组合环。
- `XG-I5`：任何 BVALID/BREADY路由都要求 registered active、owner与双 sent。
- `XG-I6`：selected master holder只在 owner原子建立时清除，busy只在真实 B terminal释放。
- `XG-I7`：reset期间新增 target direct offer静默；不完整 holder、active target与
  malformed/unknown grant action-quiet。其他输出沿用既有 crossbar reset合同。

本候选只优化 transport latency，不改变 store retirement、BRESP精确异常、split beat聚合、flush后 escaped
write drain或任何 memory ordering语义。
