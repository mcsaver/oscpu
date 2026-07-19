# S2-Q1A MMU epoch owner abort-priority 合同

## 裁决与范围

本切片只把 `OooMmuEpochOwner` 从 Q1 的“无取消三态 leaf”推进为可消费上层 shared registered
abort event 的 source-catalog leaf。它没有 live instantiate，也没有产生 identity mismatch、连接 CsrFile
reservation、打开 ROB permit 或执行 context apply。因此允许状态是：

> **Q1A abort-priority source-catalog GREEN / live integration RED**

不允许把它写成 Q2 active、共享 reservation 已原子取消、full identity 已安全、dynamic epoch 已接通，
或任何 Linux、频率、面积、功耗结论。

## 精确方程与优先级

```verilog
capture_block = abort_valid || abort_rearm || state != UNLOCKED || request_valid
request_ready = shape_valid && state == UNLOCKED && cause_nonzero
                && !abort_valid && !abort_rearm
grant_valid   = state == COMMIT && !abort_valid
request_fire  = request_valid && request_ready
grant_fire    = grant_valid && grant_ready
```

唯一时序优先级：

```text
reset > abort > grant/current-state transition > hold
```

abort 展示拍已经组合屏蔽 request/grant 两个 handshake 并维持 capture block；该沿把 state、held cause、
held payload 清零，不写 `mmu_epoch_q`，并把 `abort_rearm_q` 置为当拍 `request_valid`。所以 `abort+request`、
`abort+grant_ready`、`abort+backpressured-grant` 都没有可见 fire，下一拍 owner 已清且 epoch 与
abort edge 前一致。abort 后若旧 request 连续保持 valid，rearm 会继续令 ready=0；只有观察到 valid-low
edge 后才重新开放；abort 拍没有 request envelope 时则无需凭空增加一个 rearm bubble。

## 六类合同

| 类别 | Q1A 规则 |
| --- | --- |
| handshake | 无 abort 时保持原 request/grant ready-valid；abort 拍两路 fire 均为 0；valid-low 前不重收被取消 envelope |
| stall | abort 自身只封新 capture，不参与 quiet；已发 memory transport 仍由上层 drain |
| flush/kill | leaf 不读 raw flush；上层必须先把 mismatch/flush 归一为唯一 registered event |
| exception order | leaf 不选 head；active wrapper 必须只给 matching live head 生成 request/abort |
| memory order | 原 `mem_context_quiet && owner_live_empty` grant 前提不变；abort 不冒充 quiet |
| recovery truth | held bundle/epoch 仍是 leaf 真源；shared abort producer 与 CsrFile 同拍广播尚未实现 |

## 原子边界与未闭合项

本 leaf 关闭的是 `P0-Q1-ABORT-PRIORITY` 的 leaf consumer 半边：同拍效果屏蔽、时序清理、epoch
不前进、assertion/mutation 一致。整个 P0 仍未关闭，原因是 active wrapper 还必须同时做到：

1. `identity_valid && full_identity_match` 的 mismatch producer；
2. mismatch 检出拍立即以 `kill_now` gate grant/apply，随后只产生一个 registered shared abort；leaf
   只能证明 event 到达拍，不能替代这个前一拍窗口；
3. 同一个 event 同拍清 Q1 held owner 与 CsrFile reservation；
4. producer 必须在 abort 后撤销旧 valid；leaf 的 rearm 会在 valid-low 前 fail closed，之后的新 valid
   才能表示重新按当前 head/full-id 资格化的 envelope；
5. late IFU/memory ack 由带 generation 的 tombstone/drain 协议吞掉。

这些条件不可用本 leaf 的 focused GREEN 替代。

## 机器验证义务

- release/assert 正向各一次，必须同时出现旧 Q1 与新 Q1A 唯一 PASS marker；
- 5 个 assertion-negative 分别命中 zero-cause、request drift、quiet drop、illegal state、abort leak；
- 13 个 mutation 必须替换恰好一次、编译/展开成功，再由指定动态 oracle 唯一杀死，其中 rearm
  mutation 必须被 continuous-valid 反例杀死；
- 静态合同必须证明 `mmu_epoch_q` 只有 reset 与 grant-fire 两个时序写点，并证明该 leaf 在 production
  RTL 中没有实例引用；前者锁住 epoch 单一写者，后者锁住本结论只是 source-catalog；
- release/assert Verilator lint、RTL style、Yosys、static contract 全通过；
- 共享 module aggregate、全 RTL style、全 contract 另行通过；
- strict lint/default build 的既有 RED 必须现场复跑并与 pre-snapshot 115-warning 归一化签名比较。

`mem_context_quiet && owner_live_empty` 被定义为当前 transaction 的 sticky/irrevocable completion，
不是可回落的瞬时 empty level。进入 COMMIT 后回落由命名 assertion-negative 拒绝。`capture_block` 只
封另一条 admission，禁止回灌本 request producer，否则会形成组合环。
