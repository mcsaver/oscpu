# V9H IFU-FETCH-G2 当前设计证据合同

## 工程范围

工作对象是授权的本地 RV64 Verilog/SystemVerilog 双发射 OoO 处理器工程。操作只覆盖本地
RTL、规格、testbench、Icarus/Verilator 等 EDA 工具与生成证据；不使用网络、远程主机、
账号、凭据或第三方服务。

本切片只重新裁决 `IFU-FETCH-G2`：跨 4KiB 页的 fetch packet 必须把首个失败 halfword
offset 作为 byte-range provenance 交给唯一 RVC length owner，再映射为 slot0/slot1 page-fault
response。生产 RTL 仅在当前设计动态证据证明合同不成立时才允许修改。

## 当前 ABI 与 owner

| 合同 | 冻结内容 |
| --- | --- |
| transaction | `OooFetchAxiBridge` 持有请求、successful prefix、fault suffix 与 frontier `F`；`OooFetchPacketDecode` 是唯一 C/32 长度 owner |
| response ABI | success 为 `(resp0=OK, resp1=OK, split=4)`；fault 为 `(resp0=OK, resp1=cause, split=F)`，`F∈{0,2,4,6}` |
| byte range | slot 的半开区间 `[start,start+len)` 完全位于 F 前则 OK；触及 fault suffix 则消费 `resp1` |
| invalid data | prefix 未成功时不得读取其长度；完整 instruction range fault 时输出 NOP，fault tail 不得影响指令分类或 slot 长度 |
| handshake | provenance 与 `fetch_rsp_valid/ready` 同 owner；stall 时 PC/raw packet/resp/split 全部稳定，flush 丢弃旧 response 时同时丢弃 provenance |
| timing | 不新增 response→request 组合 owner；不复制 RVC 解压；本切片不以验证重绑声明 PPA 改善 |

## 定向矩阵

- `PC=page+0xFFA`，F=6：C+C、C+32、32+C 两槽均 OK；32+32 仅 slot1 page fault。
- `PC=page+0xFFC`，F=4：C+C 两槽 OK；C+32、32+C、32+32 的 slot1 page fault。
- `PC=page+0xFFE`，F=2：C 开头时 slot0 OK/slot1 page fault；32 开头时 slot0 与
  无架构 owner 的 slot1 均 fault。
- fault tail 分别伪装成 C/32/semihost-like raw bits，不能改变有效 prefix、slot PC/length、
  response 或 faulted instruction NOP 净化。
- page-fault transaction 的 raw prefix、frontier、无年轻 instruction AR、无 cache fill/SRAM
  write 必须有非真空动态 marker。
- compile-success RTL 验证变异必须分别切断 frontier 保存、decoder range 比较、prefix 优先级、
  slot1 owner 与 full-range NOP 净化，并由指定动态 oracle 拒绝。

## 明确边界

- 本 debt 只覆盖 second-page page-fault byte provenance；PMP/RRESP、exact-halfword physical
  footprint、lane1 downstream capture 和 PTW write PMP 属于各自独立合同。
- `fault_tval` 当前虽由同一 split 计算，但其 FIFO/trap lifecycle 不由本切片重新关闭。
- 通过只允许把 `IFU-FETCH-G2` 在当前 design-id 下从 `STALE_EVIDENCE` 重新绑定为
  `CLOSED`。full-core architecture freeze 与 PPA promotion 状态不得由本结果推导。
