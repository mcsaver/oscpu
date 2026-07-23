# V9N 不可撤回物理写 owner 下一拍驻留合同

## 本地工程范围

工作对象是本地 RV64 Verilog/SystemVerilog 双发射 OoO 核。当前切片只处理
`OooStoreQueue` plain STORE 与 `OooIntBackend` AMO physical-write transaction
在 request fire 之后、exact terminal 接受之前的 holder 驻留和 full ProducerId
一致性；不改变 AXI ABI、访存并发宽度、缓存策略或 PPA 拓扑。

## 架构需求

对 edge-old 状态满足以下任一前件：

1. SQ entry 为 `valid && request_sent && !terminal`；
2. AMO singleton 为 `mem_pending && mem_amo && mem_amo_write_sent`；

若该拍没有接受对应 exact terminal，则下一拍必须仍存在同一 holder，并保持
`ProducerId`、owner token、MMU epoch 与 request-sent 状态。hard reset 可以结束该
期待；branch/checkpoint/global flush、ROB 早 done、SQ 非 terminal release 或 holder
同沿清除均不能结束它。

## 接口契约冻结

- request fire：只把 STORE `request_sent` 或 AMO `write_sent` 置位，不产生 terminal。
- terminal：STORE 仅由 exact SQ terminal hit；AMO 仅由 exact final response
  `completion_fire`。AW/W/request-ready、flush 或 commit intent 均不是 terminal。
- release：STORE 仅在 terminal head 与 exact ROB owner 同时满足时释放；AMO singleton
  仅在 exact final response fire 后清除。
- owner identity：驻留期间 full ProducerId、ROB index、owner token、MMU epoch 不变。
- 同拍优先级：`reset > exact terminal > 保持`；flush 不得越过已发物理写 owner。

## 声明边界

本合同只补强 `STORE-BRESP-G1` 的 STORE/AMO 已发物理写 holder 生命周期证据。
即使本切片通过，full-core ARCH_STABLE、完整 producer-holder census 与 PPA promotion
仍由各自门禁裁决。
