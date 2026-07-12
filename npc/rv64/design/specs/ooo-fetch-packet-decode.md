# OoO Fetch Packet Decode

## 1. 需求

`OooFetchPacketDecode` 负责把 fetch response 的 8B raw packet 与 byte-segment provenance
解释成前端可消费的两个指令槽：

- 支持 RV64C：slot0 可为 16-bit compressed 或 32-bit instruction。
- slot1 根据 slot0 长度从 `inst0[31:16]` 或 `inst1[15:0]` 开始取指。
- 当 slot1 是跨 word 的 32-bit 指令时，低 16 位来自 `inst0[31:16]`，高 16 位来自 `inst1[15:0]`。
- 输出 slot0/slot1 的 PC、next PC、解压后的 32-bit 指令、response code 和 packet next PC。
- 输出每个 slot 是否为 control-stop instruction，用于父模块判断 response 是否应该停止继续顺序取指。
- 本模块是唯一 RVC length owner：bridge 只提供 raw bytes、两个 segment response 与 split，
  不得在上游复制 compressed decode。

本模块只描述 fetch packet 的组合解码事实，不做 dispatch、trap、flush、redirect、FIFO 或 outstanding 状态更新。

## 2. 协议

输入：

- `rsp_pc_i` 是 response slot0 的 PC。
- `rsp_inst0_i` 是从 `rsp_pc_i` 对应 fetch word 返回的 32-bit 数据。
- `rsp_inst1_i` 是下一 fetch word 返回的 32-bit 数据。
- 完整成功/cache response 固定为 `(resp0=OK, resp1=OK, split=4)`。
- fault response 使用 successful-prefix/fault-suffix ABI：首个失败 halfword offset 为
  `F∈{0,2,4,6}` 时，`resp0=OK`、`resp1=cause`、`rsp_resp0_bytes_i=F`。因此 split=0
  是合法且必要的 first-halfword fault 编码；bridge 不再把 resp0/resp1 固定解释成两个 4B word。
- `2'b00` 表示对应 byte range 正常。decoder 是唯一把 byte-range provenance 归一为
  per-slot response 的 owner。

输出：

- `dec0_*_o` 描述 slot0。
- `dec1_*_o` 描述 slot1。
- `packet_next_pc_o == dec1_next_pc_o`。
- `dec*_control_stop_o` 在对应 slot response 非零，或解压后 opcode 是 branch/JAL/JALR/system 时为 1。

slot response 选择：

- 对 slot 的半开区间 `[start,start+len)`，完全落在 split 之前时选 resp0；触及 split
  之后的 fault suffix 时选 resp1。该规则同时兼容历史 G2 segment 表达与当前 G1
  successful-prefix/fault-suffix 表达。
- prefix 所在 segment fault 时不得读取 prefix 长度；使用安全 C.NOP 形状提供确定的组合 PC，
  response fault 仍胜出。
- slot0 fault 后 slot1 没有架构 owner，`dec1_resp_o` 继承 slot0 fault。
- 完整指令区间 response 非 OK 时，`dec*_inst_o` 必须净化为 `32'h0000_0013`。仅净化
  fault prefix 不够：32-bit prefix 可位于成功 segment，而 upper half 来自 fault segment；
  原始 tail 可能伪造 semihost peer 或其它旁路分类。

## 3. 状态机

本模块无状态、无寄存器、无 ready/valid。所有输出必须由输入纯组合决定。

## 4. 不变量

- 不改变 `OooRvcDecompressor` 的 RVC 展开规则。
- 不产生 illegal/trap 判定；reserved/illegal 指令仍交给后续 decode。
- 不读取或修改 `next_fetch_pc`、FIFO、branch prefetch、RAS、CSR 或 ROB 状态。
- 对同一 fetch response，输出必须与原 `OooAluFetchCore` 内联半字拼接逻辑等价。
- response provenance 只在本模块归一一次；decoder 后只剩 per-slot response，split 不进入 FIFO。

## 5. 数据通路

1. 先计算 slot0 prefix `[0,2)` 的 segment response；只有 OK 才读取
   `rsp_inst0_i[15:0]`，否则用安全 C.NOP prefix。
2. 若有效 slot0 halfword 低两位不是 `2'b11`，slot0 长度为 2 字节并经
   `OooRvcDecompressor` 展开；否则长度为 4 字节。再对完整 `[0,L0)` 映射 response。
3. slot1 起始 halfword 为：
   - slot0 compressed：`rsp_inst0_i[31:16]`
   - slot0 uncompressed：`rsp_inst1_i[15:0]`
4. 先检查 slot1 prefix `[L0,L0+2)`；仅在 slot0 完整 range 与 slot1 prefix 都 OK 时
   读取长度。若 slot1 compressed，经 `OooRvcDecompressor` 展开；否则按 slot0 长度选择
   32-bit 拼接源，并对 `[L0,L0+L1)` 映射 response。
5. 完整 effective response fault 时输出 NOP；PC/next PC 仍按安全/有效 prefix 长度顺序累加，
   packet next PC 等于 slot1 next PC。

## 6. IFU-FETCH-G2 / IFU-ACCESS-G1 证据与边界（2026-07-13）

- 旧 RTL 真实 Sv39 两页三级 walk 的 B=2/4/6 × C/32 共 12 行矩阵精确 4 RED，8 个控制行通过。
- current-source page matrix 12/12，decoder/Glue/trap focused 5/5，module 89/89。
- split=4 的 C.EBREAK + faulted upper half 精确拼成 `32'h40705013`，输出仍净化 NOP，
  证明 response 对 invalid tail 与 semihost peer 非干扰。
- IFU-ACCESS-G1 把 bridge raw ABI 收敛为 success=`(OK,OK,4)`、fault=`(OK,cause,F)`，
  permanent matrix 覆盖 F=0/2/4/6、PMP 与 RRESP fault、4/6/8B 实际 packet footprint；
  decoder 对 split=0 及 slot0/slot1 owner 均有动态检查。
- IFU-ACCESS-G1 已关闭物理窄读/PMP/RRESP 与 lane1 fault owner；faulting portion
  `mtval/stval` 仍属独立 IFU-TVAL-G1，不能由 response owner 证据越级关闭。
