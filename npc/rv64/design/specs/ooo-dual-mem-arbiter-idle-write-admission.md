# OooDualMemAxiArbiter IDLE write admission v1

## 目标与版本边界

`dual-mem-arbiter-idle-write-admission-v1` 只删除 shared miss arbiter 在已经完成合法 request census、
RR 已唯一选出 write owner 后，仍需先注册 owner、下一拍才向 lane adapter展示 AW/W 的固定空拍。
它重签旧 F0 的“IDLE 全 quiet”边界，但不改变 read、B terminal、bridge owner/maintenance、
adapter或 crossbar合同。实现同时对 `OooMemAxiBridge.write_irrevocably_presented_w` 做等价代数化简，
删除被 registered write-state/VALID 项严格吸收的 `aw_fire_w/w_fire_w`，避免冗余 READY 依赖经
peer maintenance 与另一 lane cache lookup 反向闭环；这不是新的权限语义。

当前 canonical 路径为：

```text
OooMemAxiBridge lane0/1 registered AXI
  -> OooDualMemAxiArbiter
  -> OooLsuAxiLaneAdapter
  -> AxiCrossbar
```

本候选只在第一条边界增加 write-only direct admission。旧源码注释中“未实例化”的描述不再适用；
当前实例是 `NpcTop.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter`。

## Eligibility 与组合行为

唯一 direct eligibility 为：

```text
!rst
&& state_q == S_IDLE
&& capture_valid_w
&& capture_write_w
&& capture_owner_w is exactly 0 or 1
```

用显式二态 `case` 选择 `capture_owner_w`。unknown owner/type、illegal dual-type、无 request、read
winner 或 reset 一律不产生 direct AW/W/READY；不得用 Verilog X-optimistic `if/else` 把 unknown
owner偏向任一 lane。

对合法 write winner：

- downstream AW/W VALID与所有 payload逐位来自该 winner 的 live lane输入；
- AWREADY与WREADY分别从 downstream返回且只回给 winner；非 winner所有 request READY为0；
- AW/W channel独立，`direct_aw_fire` 与 `direct_w_fire` 只由各自 VALID/READY决定；
- AR、R、B在 direct capture拍保持静默，尤其 `d_axi_bready=0`、两个 lane `bvalid=0`；
- READY只用于本拍 channel fire与沿上 sent/seen seed，不参与 owner/RR重选或 response授权。

read winner继续使用原 registered时序：IDLE拍没有 ARVALID/ARREADY，沿上锁 owner/type，下一拍
进入 `S_READ_ADDR`。

## 跨 bridge READY / maintenance DAG

bridge 的“write 已不可撤回”事实固定为：

```text
write_escaped_q
|| (((state_q == S_WRITE_REQ) || (state_q == S_AD_UPDATE))
    && (lsu_axi_awvalid_o || lsu_axi_wvalid_o))
```

不得把 `aw_fire_w`、`w_fire_w` 或任一 downstream READY重新并入该谓词。因为 bridge 的 AW/W
VALID只可能由上述 registered write state产生，fire项已被 `write-state && VALID` 严格吸收；
保留它们只会形成非法的
`arbiter READY -> bridge fire -> peer maintenance -> peer cache hit -> peer ARVALID -> arbiter census`
回边。stalled VALID首拍仍立即建立不可撤回/kill-maintenance authority；fire后的后续拍由
`write_escaped_q`保持，B terminal与exact-owner authorization不变。

## 沿上状态与 exactly-once

合法 direct write capture沿必须原子执行：

```text
owner_q    <- capture_owner_w
is_write_q <- 1
aw_seen_q  <- direct_aw_fire
w_seen_q   <- direct_w_fire
state_q    <- (direct_aw_fire && direct_w_fire)
              ? S_WRITE_RESP : S_WRITE_DATA
```

因此 READY四象限的下一拍状态为：

| downstream READY / 实际 fire | 下一拍 | seen | 后续行为 |
|---|---|---|---|
| `11` / AW+W | `S_WRITE_RESP` | `11` | 只等待 registered owner的B |
| `10` / AW only | `S_WRITE_DATA` | `10` | 只重发W |
| `01` / W only | `S_WRITE_DATA` | `01` | 只重发AW |
| `00` / none | `S_WRITE_DATA` | `00` | 对锁定owner重发AW+W |

source若为 AW-only或W-only，同样只接受已呈现channel并进入 `S_WRITE_DATA` 等待另一channel。
已 fire channel永不重复 VALID/fire；未 fire channel的 upstream `valid&&!ready` payload必须跨
direct→registered边界逐位稳定。arbiter不新增 payload寄存器，稳定性继续由选中 bridge 的 AXI
hold合同与锁定 `owner_q`共同承担。

## Owner、B、RR与恢复

- direct拍的临时选择真源是既有 `capture_owner_w`；沿后所有 transaction owner事实仍只来自
  `owner_q`。
- B只允许在 registered `S_WRITE_RESP` 中路由给 `owner_q`，且 AW/W都已经完成；不得使用
  direct fire的 next-state组合授权 B。
- B backpressure期间 owner/is_write/state/BRESP保持，唯一 B terminal 后才回 `S_IDLE`。
- `rr_q` 仍只在 R/B terminal更新；capture、AW fire或W fire均不得更新公平起点。
- 双 lane竞争时只有 RR winner获得 READY；另一 lane保持 request，不能发生跨 lane AW/W配对。
- arbiter没有普通 flush输入。上游一旦展示并被接受的 write不可取消，仍由 bridge drain/drop合同
  处理；同步全系统 reset是唯一共同放弃在途 transaction的边界。
- reset组合观察期所有 handshake输出静默，沿上恢复既有冷启动状态。

## Assertions 与 directed evidence

`OOO_ASSERT` 至少锁定：

1. direct eligibility、owner精确已知、source/payload与 winner READY映射；
2. non-owner isolation在 direct拍使用 effective capture owner，registered拍使用 `owner_q`；
3. direct fire到下一拍 owner/is_write/state/seen逐位精确；
4. read IDLE仍静默，direct拍无 R/B route；
5. 已 seen channel不重复、未 seen channel stall payload稳定；
6. owner只在 exact R/B terminal后释放，RR terminal-only；
7. illegal/unknown/reset全部 fail closed。

focused TB必须覆盖 source `11/10/01`，downstream READY `11/10/01/00`，两 lane write竞争、
read/write竞争、RR lane0/lane1、AW-first、W-first、direct后 poison live payload、B长反压、read仍
registered、reset phase matrix与 illegal dual-type negative。

## 性能与 PPA声明

资格化在 current predecessor上测得 CoreMark 144,201次、Dhrystone 600,000次 strict机会。功能
候选以 ROI 4,667,639 / 7,891,545为 exact predecessor；两项不得回归，且 Dhrystone
`cycle_memory_request_axi_write_request` 必须严格低于 1,270,001。

候选新增/拉长的组合锥为：

```text
bridge registered VALID/payload
  -> arbiter request census/RR owner mux
  -> adapter legality/align/data+strb shift
  -> crossbar input holder D
```

adapter upstream READY是本地 holder/state；bridge中冗余的 READY→maintenance边已按上节切断，
且 full-top stats-on/off Verilator lint必须保持无 `UNOPTFLAT`。这只证明组合DAG闭合；在 fresh
same-identity mapped synthesis/STA/area/power前固定 `PPA=UNQUALIFIED`、
`promotion_eligible=false`。若功能、CPI或后续 timing不合格，只回退 IDLE write direct输出、
direct seen/state seed、配套断言/TB及本候选要求的等价DAG化简；不回退 adapter、SQ fusion或
crossbar retained候选。
