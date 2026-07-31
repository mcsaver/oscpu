# 规范：OooLsuAxiLaneAdapter（逻辑 byte window → 标准 AXI lane/split）

> 模块：`vsrc/memory/OooLsuAxiLaneAdapter.v`。状态：**T4I 已实施并验证**。
> 本规范关闭 `OooMemAxiBridge` 历史 exact-address/low-window 扩展与当前 NpcTop
> 64-bit AXI slave ABI 之间的语义缺口。

## 1. 目的与范围

LSU/MIQ/SQ 内部把一次 1/2/4/8-byte 访问表示成：精确起始地址、低位连续 `wdata/wstrb`，
read response 也从 bit0 开始。这是适合前递与 cache 窗口的逻辑 ABI，但不是 64-bit AXI 的
byte-lane ABI。特别是旧实现的 `addr=...5,size=4` single beat 跨越 lane7，只有仿真 DPI 的
私有 low-window 扩展才能工作。

本 adapter 位于 `NpcCoreTop` 的 `OooMemAxiBridge` 与对外 LSU AXI master 端口之间：

- 上游保持逻辑 low-window ABI，避免把拆分状态混入 Sv39/PTW/PMP/PMA FSM；
- 下游只产生标准 64-bit AXI single-beat lane 布局；
- 自然对齐访问保持一笔；任意非自然对齐访问拆为按地址递增的 byte 微事务；
- 多笔 read 重组为一个上游 R，多笔 write 聚合为一个上游 B。

模块不做地址翻译、权限/PMA、cache、store retirement 或异常 cause 选择。跨 4KiB plain
访问已在后端按既有策略形成 address-misaligned exception；PMP/PMA 在 adapter 前按完整 byte
range 授权，故微事务不会合法地跨页或跨静态 region。

## 2. 接口契约

端口分 `u_*`（上游 bridge 逻辑 ABI）与 `d_*`（下游标准 AXI ABI）。两侧均为 64-bit、
single-beat、无 burst；ID/LEN/BURST/PROT 由 `NpcCoreTop` 直通既有常量，adapter 只拥有
ADDR/SIZE/DATA/STRB 与五通道握手。

| 通道 | 上游语义 | 下游语义 | owner / 背压 |
| --- | --- | --- | --- |
| AR | `u_araddr` 是逻辑首 byte；`u_arsize`=log2(nbytes) | single 时原 addr/size；split 时 `addr+i,size=BYTE` | AR fire 后 adapter 持有事务，直到上游 R fire |
| R | `u_rdata[8*nbytes-1:0]` 从 bit0 连续 | slave 按 `d_araddr[2:0]` 返回物理 lanes | adapter 吞每个下游 R；只呈现一个聚合上游 R |
| AW/W | 地址精确；有效数据/strb 从 lane0 连续，AW/W 可任意先后 | single 时 data/strb 左移到地址 lane；split 时 one-hot byte lane | 任一上游 AW/W fire 后写 owner 已建立，不允许 read 越过 |
| B | 一次逻辑 write 只回一个 B | 每个微写都必须收 B | 保留首个非-OKAY，全部微写 drain 后聚合为错误 B |

`u_arready` 只依赖 adapter 寄存状态，不依赖 `d_arready`；`u_awready/u_wready` 同理，禁止
ready/valid 组合环。任一写半通道已收、写微序列在飞或上游 B 未消费时，read admission 为 0；
任一 read 在飞或上游 R 未消费时，write admission 为 0。这一保守全序与桥侧
“所有 store 等聚合 B”契约配合，防止后续 bus-miss read 在 split write 的全部
物理 beat 完成前越过。

典型 misaligned read（4B @ offset6）：

```text
u: AR(addr=A+6,size=4) fire ------------------------------- R(data=b3..b0) fire
d:   AR(A+6,B) R(b0@lane6) AR(A+7,B) R(b1@lane7)
     AR(A+8,B) R(b2@lane0) AR(A+9,B) R(b3@lane1)
```

典型 split write 的 AW/W 可以分别 stalled；每一笔都满足：

```text
d_AWVALID/payload ─────────── until AWREADY
d_WVALID/payload  ───── until WREADY
                    both fire/owned -> wait B -> next byte
```

### reset / flush 谁清谁保持

adapter 没有 flush/redirect 端口，这是有意的 owner 边界：

| 事件 | 清除 | 必须保持 |
| --- | --- | --- |
| `rst` | 全部 hold/FSM/聚合 response | 无 |
| bridge flush，尚未 `u_*` fire | bridge 可撤销请求 | adapter 无 owner |
| bridge flush，任一 `u_AR` 或 `u_AW/u_W` 已 fire | 无 | 已接收 payload、全部下游 VALID、微事务进度，直到聚合 R/B；bridge 自己 drain/drop |

同拍优先级：`rst` > 已有下游 response/微事务推进 > 已有上游聚合 response handshake > 新上游
admission。首版不做 response-consume + new-request look-through，避免 payload owner 混拍。

## 3. 状态与时序模型

### 3.1 Read FSM

```text
R_IDLE --u_AR.fire(valid size)--> R_AR --d_AR.fire--> R_DATA --d_R.fire--+
   | invalid size -> R_RESP(error)                                      |
   +<--------------------------- u_R.fire ----------------------- R_RESP<+
                                      split&&!last -> R_AR(next byte)
```

- `R_IDLE`：只在没有任何 write owner 时接收；锁存 base/size，结果清零；
- `R_AR`：single 呈现原 addr/size；split 呈现 `base+byte_idx,size=0`，stall 全字段冻结；
- `R_DATA`：持续 `d_rready=1`。single 从地址 lane 右移到 bit0；split 只抽取当前 byte；
- `R_RESP`：锁存聚合 data/resp，直到 `u_rready`。

若地址按 `nbytes` 自然对齐则 single；否则逐 byte split。`ARSIZE>3` fail closed，不发下游 AR。

### 3.2 Write FSM

```text
W_COLLECT --AW/W 均已收--> W_SEND --AW&&W 均完成--> W_B --B.fire--+
     ^                         | AW/W 独立 hold                        |
     +<----------- u_B.fire -- W_RESP <-------------------------------+
                         split&&!last -> W_SEND(next byte)
```

- `W_COLLECT`：独立锁存 AW 与 W；收下任一半通道即建立 write owner；
- `W_SEND`：分别跟踪 `aw_done/w_done`，两者完成前 payload 不变；
- `W_B`：收对应 B，首个非-OKAY 粘滞保留；若仍有 byte，继续下一个 beat；
- `W_RESP`：只向上游呈现一次聚合 B。

`AWSIZE` 是权威宽度；`wstrb` 必须精确等于该 size 的 low contiguous mask。
地址按 `AWSIZE` 自然对齐时 single，data/strb 左移由 `STRB_W` 推导的 lane；
非自然对齐且获得 split 授权时，每个 byte 使用 `AWSIZE=0`、
`AWADDR=base+index`、one-hot lane。size 超出总线宽度、空/稀疏/超宽 `wstrb`
或禁止 split 的 misaligned 请求均 fail closed，不发下游通道。

## 4. 不变量

- **LSA-I1 标准 lane**：每笔下游 write 的有效 lane 必须落在其地址/size 允许范围；split 时
  恰好 one-hot 且 `AWSIZE=0`。
- **LSA-I2 精确覆盖**：成功逻辑事务恰好访问原 `[base,base+nbytes)`，不多读/多写相邻设备 byte。
- **LSA-I3 聚合唯一**：一次上游 AR 只产生一次上游 R；一对上游 AW/W 只产生一次 B。
- **LSA-I4 stalled hold**：任一 `d_*VALID&&!READY` 的 VALID 与全部 payload 次拍冻结。
- **LSA-I5 owner 不被 flush 撤销**：adapter 无 flush 输入；reset 外已接收事务必到聚合 response。
- **LSA-I6 write→read 物理顺序**：存在 AW half/W half/微写/待消费 B 时，不接收新 read。
- **LSA-I7 无组合环**：所有上游 ready 来自本地 FF/FSM，下游 ready 不反传到同拍上游 ready。

LSA-I1/I3/I4/I6 必须落 `OOO_ASSERT` 立即断言，并用 mutation-negative 证明非真空。

## 5. 关键路径与时序考量

上游 admission 与下游 ready 之间用寄存状态切断；地址加一、lane shift 与 byte select 只驱动
已注册的下游 payload，不进入 backend/translation/cache hit 控制锥。自然对齐 miss/store 多一拍
adapter capture；D-cache hit 不经过 adapter。misaligned 最多 8 笔，属于正确性慢路。

## 6. 验证计划

- 模块 TB：aligned B/H/W/D read/write 的 lane+size；15 组合法自然 lane；
  SH@7/SW@6/SD@1 逐 byte split；AW-first/W-first/同拍、AR/AW/W stall、R/B backpressure、
  粘滞 error、稀疏/zero WSTRB 拒绝、write 阻止 read；
- bridge TB：cacheable line read 保持 aligned 8B+fill；uncacheable read 改 exact addr/原 size+no fill；
  Sv39 leaf 同合同；misaligned PMEM store 不走早期 B decouple；
- bus/device TB：AxiCrossbar 的 AWSIZE owner/hold；UART/CLINT/PLIC 标准 lane；
- NpcTop/NpcSimTop：AxiDpiSlave data read/write lane、virtio AR/AWSIZE 实际消费；
- end-to-end：misaligned load/store、ma_data、virtio/UART/CLINT/PLIC、official 177、AM、CoreMark。

实施阶段定向证据：adapter TB PASS；bridge wait-B PASS；xbar AWSIZE owner/stall
PASS；UART/CLINT/PLIC 4/4 PASS；real DPI lane+guard suite PASS；完整 module **100/100** PASS。
系统软件、fresh STA 与冻结网表证据由对应 task-run 收口，不在本段预支。

## 7. 风险与回退

- misaligned MMIO/PTE 不获得 split 授权，adapter 本地返回 DECERR 且不发下游，
  因而不会为了对齐而扩大设备 read/write side effect。aligned MMIO 始终只发一笔。
- plain store 的设备动态 B error 由 T4N late-B owner 精确接收；adapter 只负责聚合 split B，
  backend/SQ 保持 ROB owner 到该聚合 terminal，见 `ooo-store-bresp-precise-terminal.md`。
- 若性能回退超预算，允许给 aligned single 增加经证明无组合环的 bypass；不得回退 lane/split 语义。

## 8. 变更记录

- 2026-07-14（T4I contract）：冻结 logical-window/standard-lane 边界、byte split FSM、flush owner、
  store-read ordering 与验证矩阵。
- 2026-07-14（T4I implementation）：RTL、顶层连接、AWSIZE owner 及 device/DPI lane
  已落地；所有 store 改为等聚合 B；按 `STRB_W` 派生 lane 并拒绝超 bus size。
- 2026-07-14（T4N）：聚合 B 成为 plain-store ROB terminal，SLVERR/DECERR 精确归属。
