# OoO Fetch Packet Decode

## 1. 需求

`OooFetchPacketDecode` 负责把 fetch response 中的两个 32-bit word 解释成前端可消费的两个指令槽：

- 支持 RV64C：slot0 可为 16-bit compressed 或 32-bit instruction。
- slot1 根据 slot0 长度从 `inst0[31:16]` 或 `inst1[15:0]` 开始取指。
- 当 slot1 是跨 word 的 32-bit 指令时，低 16 位来自 `inst0[31:16]`，高 16 位来自 `inst1[15:0]`。
- 输出 slot0/slot1 的 PC、next PC、解压后的 32-bit 指令、response code 和 packet next PC。
- 输出每个 slot 是否为 control-stop instruction，用于父模块判断 response 是否应该停止继续顺序取指。

本模块只描述 fetch packet 的组合解码事实，不做 dispatch、trap、flush、redirect、FIFO 或 outstanding 状态更新。

## 2. 协议

输入：

- `rsp_pc_i` 是 response slot0 的 PC。
- `rsp_inst0_i` 是从 `rsp_pc_i` 对应 fetch word 返回的 32-bit 数据。
- `rsp_inst1_i` 是下一 fetch word 返回的 32-bit 数据。
- `rsp_resp0_i/rsp_resp1_i` 是两个 word 对应的 fetch response code，`2'b00` 表示正常。

输出：

- `dec0_*_o` 描述 slot0。
- `dec1_*_o` 描述 slot1。
- `packet_next_pc_o == dec1_next_pc_o`。
- `dec*_control_stop_o` 在对应 slot response 非零，或解压后 opcode 是 branch/JAL/JALR/system 时为 1。

slot1 response 选择：

- slot1 完全落在 `rsp_inst0_i` 内部时，`dec1_resp_o = rsp_resp0_i`。
- slot1 需要 `rsp_inst1_i` 任意半字时，`dec1_resp_o = rsp_resp1_i`。

## 3. 状态机

本模块无状态、无寄存器、无 ready/valid。所有输出必须由输入纯组合决定。

## 4. 不变量

- 不改变 `OooRvcDecompressor` 的 RVC 展开规则。
- 不产生 illegal/trap 判定；reserved/illegal 指令仍交给后续 decode。
- 不读取或修改 `next_fetch_pc`、FIFO、branch prefetch、RAS、CSR 或 ROB 状态。
- 对同一 fetch response，输出必须与原 `OooAluFetchCore` 内联半字拼接逻辑等价。

## 5. 数据通路

1. 取 `rsp_inst0_i[15:0]` 为 slot0 halfword。
2. 若 slot0 halfword 低两位不是 `2'b11`，slot0 长度为 2 字节并经 `OooRvcDecompressor` 展开；否则 slot0 是 `rsp_inst0_i`，长度为 4 字节。
3. slot1 起始 halfword 为：
   - slot0 compressed：`rsp_inst0_i[31:16]`
   - slot0 uncompressed：`rsp_inst1_i[15:0]`
4. 若 slot1 compressed，slot1 经 `OooRvcDecompressor` 展开；否则按 slot0 长度选择 32-bit 拼接源。
5. PC/next PC 由 slot 长度顺序累加，packet next PC 等于 slot1 next PC。
