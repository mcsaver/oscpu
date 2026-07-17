# S2-G1 effective-kill 与写逃逸维护伴随裁决

> 状态：`active companion ruling / implementation_RED`。
>
> 本文件不修改或替代 hash-bound 架构/PPA 合同、typed memory ABI、
> `s2-g1-exact-owner-provenance-{completion-definition,rtl-derivation,errata}.md`
> 或 R4-P0A/R3.6 基线。它只收敛实现审查中发现的同拍歧义；在 focused
> positive、assert-negative、source binding 与 wrapper 集成全部 GREEN 前，S2-G1
> 仍为 RED，且不构成 architecture-feasible seed。

## 1. 需求与边界

1. MIQ 的 registered `head_killed` 只表示过去沿已经落账的 kill；本拍 selective
   kill 或 global flush 必须通过 `head_effective_killed` 立即压住 WB、PRF/wakeup、
   SQ fill/terminal、device release 与其它架构副作用。
2. exact response 与 effective kill 同拍仍须 drain transport、exact-pop MIQ，并产生
   恰一次 tagged terminal；kill 只取消副作用，不能取消 accounting。
3. global flush 可在已验证 LOAD/ATOMIC 的 HW A/D write 已逃逸后清除 MIQ。迟到 B
   仍须执行 invalidate-only coherence maintenance；它不得执行 DTLB/read fill、RMW
   data update、WB、SQ 或 architectural fault。
4. 普通 identity mismatch 不能借 `cpu_kill` 或 `expected_effective_killed` 裸旁路获得
   cache maintenance 权限。STORE DRAIN 是 nokill owner，始终走当前 exact MIQ head，
   不使用 killed-write 例外。
5. AMO read terminal 后到 write request fire 前仍是同一 live ATOMIC owner；restore/flush
   清除此 inter-phase state 时必须产生 tagged terminal，不能用“head-only”证明其不可达。

## 2. 协议与同拍优先级

### 2.1 response/effective-kill

```text
transport_fire = response_valid && response_ready
identity_match = kind/token/epoch exact
miq_pop = transport_fire && identity_match
terminal = miq_pop
architectural_side_effect = miq_pop && !head_effective_killed
```

- `response_ready` 可因 effective kill 免占 WB credit，但不得依赖 identity equality。
- `head_effective_killed` 覆盖 registered kill、同拍 ROB-age kill、global flush；
  `head_killed` 不再授权或禁止任何 response side effect。
- device `cancel` 优先于 `release`；同拍 effective kill 时不得呈现新的 device AR。

### 2.2 killed write coherence authority

只允许在 kill 边沿 MIQ edge-old head仍可见且 exact 时锁存一次：

```text
capture = active_expected_identity_match
       && expected_effective_killed
       && tracker_exact
       && sticky_verified
       && write_has_externally_escaped
```

之后真实 B terminal 的 cache maintenance 资格为：

```text
invalidate = real_B && tracker_exact && sticky_verified
          && (current_expected_exact || killed_write_authority)
rmw_update = real_B_OK && current_expected_exact && !effective_kill
```

`killed_write_authority` 只允许 invalidate，不允许 fill/RMW/WB/fault；新 active owner
accept、reset 或该事务 B terminal 清除。identity/sticky/tracker 漂移必须 assertion-fatal。
尚未逃逸的可取消 owner不得取得该权限。

### 2.3 AMO inter-phase cancel

AMO read response若进入write phase，不是逻辑 terminal；token继续由 registered
`mem_pending` tuple拥有。`checkpoint_restore`/global flush 在 write request fire 之前清除
该状态时，terminal queue lane5必须捕获该 exact ATOMIC tuple。restore拍所有 request-valid/
fire必须为0，禁止 bridge station 已收请求而 MIQ flush吞掉push。若 read response与restore
同拍，restore优先且旧 MIQ response/drop accounting负责恰一次终止，不得同时创建write phase。

## 3. terminal queue 与 SQ release 事件代数

`OooMemOwnerTerminalCollector` 是本 checkpoint 的 32-token pending terminal queue；
名称强调其 accounting-only 职责，不另建重复 module。六个 ingress 固定为：

| lane | source | STORE 可能性 | 释放规则 |
| --- | --- | --- | --- |
| 0 | exact response terminal | killed PROBE可为STORE；DRAIN B不进本 lane | LOAD/ATOMIC或killed PROBE进入queue |
| 1 | bridge active/drop0 | killable PROBE可为STORE | queue 延迟 tagged free |
| 2 | bridge station/drop1 | 未advance PROBE可为STORE；nokill DRAIN禁止drop | queue 延迟 tagged free |
| 3 | reservation local cancel | 显式排除STORE | LOAD/ATOMIC进入queue；STORE由SQ release |
| 4 | buffer local cancel | 显式排除STORE | LOAD进入queue；STORE由SQ release |
| 5 | AMO inter-phase cancel | ATOMIC | write尚未fire且restore/flush清pending时queue free |

raw SQ release 必须排除：queue `pending_mask`、本拍六路 ingress mask、edge-old
MIQ/bridge/reservation/buffer residency 与本拍 request-fire residency。只有同拍精确
authority-end 可覆盖 residency 抑制；它不能覆盖 pending/ingress 抑制。由此 STORE
probe drop 与 SQ squash同拍时，SQ entry可删除但token只由queue释放一次；DRAIN B只
标SQ terminal，token继续由最终SQ release释放一次。

## 4. 状态机、不变量与拓扑

- MIQ状态不变：exact response pop与flush/kill accounting同沿发生；副作用资格单独使用
  effective-kill，不能把pop改成kill-dependent。
- bridge killed-write authority是单bit sticky state；不改变AXI FSM，也不进入ready/valid。
  它只到D-cache B-terminal invalidate enable。
- terminal queue保持32bit pending + 两个registered dequeue slot；新allocation与terminal
  不得是同一逻辑owner，同沿free不得被allocator复用。

必须成立：

1. exact response + effective kill -> one pop, one terminal, zero architectural side effects；
2. successful PROBE + same-cycle kill -> no SQ fill/WB，STORE token最终free恰一次；
3. killed LOAD -> no WB/PRF/wakeup，terminal恰一次；
4. DRAIN B -> one formal store terminal、no collector free；SQ release后token恰一次free；
5. write-maintenance exception不得由mismatched current MIQ owner创建；
6. exact killed escaped A/D write的真实B必须invalidate-only；未逃逸kill不得维护；
7. AMO inter-phase cancel产生一次terminal，restore拍无request/MIQ双射破坏；
8. 所有equality只资格side effect/assertion，不进入response ready或AXI hold路径。

## 5. focused 退出门槛

- selective kill+LOAD response、selective kill+successful PROBE response、global flush+response；
- transport exact-pop与terminal count各恰一次，WB/SQ fill/device release为零；
- exact killed escaped A/D write迟到B产生一次invalidate-only；
- A!=MIQ-B + kill、未逃逸kill、tracker/sticky漂移均不维护且各有单marker negative；
- AMO read→write inter-phase restore cancel与restore/request-fire negative；
- source manifest绑定RTL、TB、runner、本addendum与既有erratum。

本 addendum 不授权 Linux、综合、STA、PPA 或架构晋级。
