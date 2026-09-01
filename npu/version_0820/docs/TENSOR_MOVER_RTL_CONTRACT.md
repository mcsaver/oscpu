# Tensor mover RTL contract

> **Phase A：CPY / CONT / CONCAT0。** 本合同冻结 Qwen3.5-0.8B 单 token
> 主文本图首先需要的 stride-gather/pack 数据搬运切片。它不实现
> `SET_ROWS`、KV root swap、GGML scheduler、UNARY、GDN 或 attention；Phase A
> PASS 只能证明这里列出的三个 mover family。只允许 Verilator 功能仿真，
> 禁止综合、STA、PPA、DPI、host 代算、assert 和 waveform。

## 1. 固定图边界

固定 llama.cpp b10507 commit
`95c409c13625a23da2aa37270339ce9179215a18`、Qwen3.5-0.8B、
`T=1,B=1,n_ubatch=1,n_seq_max=1` 时，Phase A 覆盖：

- `M_CPY_F32_PACK_STATE`：18 个 non-empty convolution state copy、18 个
  non-empty GDN state copy，以及36个 empty CPY 图节点；source logical order
  pack 到 contiguous transaction-shadow destination。
- `M_CONT_PACK_F32`：gate pack 与 no-FA attention output pack。
- `M_CONT_PACK_F16`：仅 `AUTO -> FA rejected` 且 V-cache 仍为未转置布局时的
  V gather/pack。
- `M_CONCAT0_F32`：18 个 recurrent convolution history/current concat，固定
  concat dimension 0。

图变体决定 CONT 个数，但不改变本模块的单命令语义。`SET_ROWS` 与同-token
KV read-your-writes 留给 Phase B。CPU/DPI 不得补做上述 required mover。

## 2. Module 与命令端口

```text
module TensorNpuTensorMover
  parameter STALL_TIMEOUT_CYCLES = 512
  parameter COMMAND_TIMEOUT_CYCLES = 1048576

  clk_i / synchronous active-high rst_i
  start_i / ready_o / busy_o
  opcode_i[1:0]
    0 = M_CPY_F32_PACK_STATE
    1 = M_CONT_PACK_F32
    2 = M_CONT_PACK_F16
    3 = M_CONCAT0_F32

  gmem_floor_i[63:0], gmem_limit_i[63:0]       // limit exclusive

  src0_region_base_i[63:0], src0_region_size_i[63:0]
  src0_view_off_i[63:0]
  src0_ne0_i..src0_ne3_i[31:0]
  src0_nb0_i..src0_nb3_i[63:0]

  src1_region_base_i[63:0], src1_region_size_i[63:0]
  src1_view_off_i[63:0]
  src1_ne0_i..src1_ne3_i[31:0]
  src1_nb0_i..src1_nb3_i[63:0]

  dst_region_base_i[63:0], dst_region_size_i[63:0]
  dst_view_off_i[63:0]

  held 64-bit single-outstanding GMEM request/response interface

  done_o / error_o / error_code_o[4:0]
  elements_done_o[63:0]
  bytes_moved_o[63:0]             // logical destination bytes, counted once
  gmem_read_beats_o[63:0]
  gmem_write_beats_o[63:0]
  writes_accepted_o[63:0]
  active_cycles_o[63:0]
```

`src1_*` 只在 CONCAT0 使用。destination 始终按 logical flat index contiguous
写入：

```text
dst_addr(q) = dst_region_base + dst_view_off + q*element_bytes
```

Phase A destination 必须是 transaction-private scratch 或 inactive shadow。
本模块不修改 active root、不产生 root commit，也不承诺清除失败事务留下的
shadow bytes。只有 `done_o` 才使父级获得 commit eligibility；`error_o`、reset
或 timeout 后父级必须丢弃该 destination generation。`writes_accepted_o` 让父级
审计 partial-shadow side effect，但它从不表示 architectural commit。

## 3. 精确 logical mapping

对 source descriptor 的坐标 `(i0,i1,i2,i3)`：

```text
src_addr = region_base + view_off
         + i0*nb0 + i1*nb1 + i2*nb2 + i3*nb3
q = i0 + ne0*(i1 + ne1*(i2 + ne2*i3))
```

### 3.1 CPY_F32 / CONT_F32 / CONT_F16

每个 logical element 的 raw 4B 或2B从 source gather，并写到 destination 的
contiguous `q`。same-type copy 必须逐 bit 保留 NaN payload、signed zero、Inf
和 subnormal；模块不做浮点运算或转换。CPY 与 CONT 使用相同 datapath，但保留
不同 opcode 供 manifest/权限审计。

CPY 允许任一 `ne[d]==0`。empty CPY 必须合法地恰好 retire 一次，GMEM read、
write、bytes、elements 均为0，并允许 `view_off==region_size`；不得 dereference。
CONT 的任一零维度均 fail-closed 为 header/shape error。

### 3.2 CONCAT0_F32

只支持 F32、`dim=0`。两个 source 的 `ne1/ne2/ne3` 必须完全相同且全部维度
非零；destination shape 隐式为：

```text
[src0.ne0 + src1.ne0, src0.ne1, src0.ne2, src0.ne3]
```

对 destination 坐标：若 `i0<src0.ne0`，从 src0 同坐标 gather；否则从 src1
的 `(i0-src0.ne0,i1,i2,i3)` gather。必须逐 row 拼接，禁止实现成
`src0 entire backing || src1 entire backing`。

## 4. Preflight 与地址安全

任何 GMEM request 前必须完成全部 header/address preflight，使用至少128-bit
中间值；任一失败时 read/write request count 必须为0。

非空 source 的访问上界：

```text
last_byte_exclusive = view_off
                    + sum((ne[d]-1)*nb[d])
                    + element_bytes
```

必须同时满足：

- opcode 对应的 element bytes 正确；所有 source stride 是 element-bytes 的
  非零整数倍；
- total element count 在 `1..2^32-1`；所有乘加无128-bit溢出且最后可表示为
  64-bit address；
- `last_byte_exclusive <= region_size`；
- 每个可能发出的 aligned 8B read beat 完整落在 source region 与
  `[gmem_floor,gmem_limit)` 内；
- destination contiguous end 不超过 destination region 与 GMEM window；
- destination element address 满足2B/4B自然对齐；aligned write beat 落在
  GMEM window；只有目标 byte lanes 的 `wstrb` 可置1；
- 每个非空 source 的 conservative byte span 与 destination contiguous span
  不重叠；CONCAT 的两个 source 都必须检查；
- CONCAT 的 `ne0` 加法、shape product 和 destination byte count 均不溢出。

empty CPY 不形成访问集合，只要求 source/destination `view_off<=region_size`、
region base/offset 加法可表示为64-bit，且 window/header 合法；不执行 overlap、
stride beat 或最后字节 dereference。

不支持的 opcode/dtype/shape/stride/overlap 一律显式 error，禁止隐式 CPU
fallback 或截断地址。

## 5. GMEM 事务、FSM 与 timeout drain

每个 element 严格执行：

```text
READ_REQ -> READ_WAIT -> capture selected 2B/4B
         -> WRITE_REQ -> WRITE_WAIT -> advance logical coordinate
```

- request 只在 `valid&&ready` 被接受；`valid&&!ready` 时 write/read/address/data/
  strobe 逐 bit 稳定；任意时刻最多一个 outstanding request；
- response 只在相应 WAIT/DRAIN state 给予一个 credit；read data 只在成功的
  matching response 被采样；write response 的 rdata 忽略；
- 只有 write response 成功后才增加 `elements_done/bytes_moved`；read/write beat
  在各自 request handshake 计数；`writes_accepted` 在 write request handshake
  计数；
- busy `start_i` 不采样、不覆盖 resident descriptor；
- terminal `done_o` 或 `error_o` 各为单拍，下一拍回 IDLE；
- reset 优先取消命令、request valid 与未提交 completion，deassert 后不得出现
  stale terminal；已接受的外部 write 可能留在 shadow，但不能变成 active root。

watchdog 优先级固定为：

```text
reset > internal corruption/domain fatal > command timeout
      > stall timeout > normal progress
```

REQ state 在 timeout hit 当拍必须撤销 request valid，防止 same-cycle late ready
接受已失去 completion eligibility 的新 transaction。WAIT state 中 request 已被
接受后，timeout **不得**直接回 IDLE/ERROR；必须锁存 timeout cause，进入唯一
`GMEM_DRAIN`，保持 response credit，冻结 coordinate/result counters，直到 matching
response 到达再输出 error。late `gmem_rsp_error_i` 覆盖 timeout cause 为
GMEM-response error。drain 完成后无需 reset 即可接受新命令，且迟到 response
不得污染下一命令。

## 6. Error code

```text
0  NONE
1  HEADER / unsupported opcode
2  SHAPE
3  STRIDE_OR_ALIGNMENT
4  SOURCE_BOUNDS
5  DESTINATION_BOUNDS
6  OVERLAP
7  GMEM_RESPONSE
8  STALL_TIMEOUT
9  COMMAND_TIMEOUT
10 INTERNAL_STATE
```

错误优先级必须确定；同一命令不得因组合 `if` 顺序漂移。response-error override
只适用于已接受 request 的 WAIT/DRAIN transaction。

## 7. Directed raw-byte oracle

TB 使用确定性 8B GMEM 模型，不使用 DPI/host 数值代算。至少覆盖：

1. **Strided CPY F32**：

   ```text
   src.ne=[3,2,1,1], src.nb=[4,16,32,32], view_off=4
   selected raw words:
     00000000,80000000,7fc12345,3f800000,ff800000,00000001
   expected contiguous destination bytes:
     00 00 00 00 | 00 00 00 80 | 45 23 c1 7f |
     00 00 80 3f | 00 00 80 ff | 01 00 00 00
   ```

2. **Gate CONT F32**：source 每 head 为 `[q0,q1,g0,g1]`，
   `ne=[2,2,1,1], nb=[4,16,32,32], view_off=8`；expected packed raw words
   `3f000000,bf000000,7fc12345,80000000`。
3. **Permuted CONT F16**：小型 `ne=[3,2,2,1]` 且 `nb0` 大于 `nb1`，验证
   logical i0-fast gather、2B lane select、跨8B边界和 contiguous pack。
4. **CONCAT0 F32**：

   ```text
   A.ne=[3,2], B.ne=[1,2]
   A rows=[01020304,11121314,21222324]
          [31323334,41424344,51525354]
   B rows=[a1a2a3a4] [b1b2b3b4]
   expected=[Arow0,Brow0,Arow1,Brow1]
   ```

5. **Qwen empty CPY homolog**：含 `ne1=0`、`view_off==region_size`，精确
   零 beat/零 bytes/零 elements、canary/root generation 不变。
6. request ready backpressure 下 payload稳定；response delay；single-outstanding；
   write strobe 不能修改邻接 canary。
7. read error、write error、READ_WAIT timeout、WRITE_WAIT timeout、late response
   error override；每例在不 reset 下运行下一条 clean command，证明 drain recovery。
8. busy start ignored；mid-command reset cancellation；deassert 后 clean recovery。
9. wrong opcode/shape/stride、128-bit overflow、source/destination bounds、read-beat
   overfetch、destination alignment、source/destination overlap，且全部 zero request。
10. command/stall timeout 与 request ready 同拍，证明 timeout 优先且 request 未被
    接受。

固定 marker：`[NPU-TENSOR-MOVER][PASS]`。INFO 至少给出每个正向 case 的
elements/bytes/read-beats/write-beats，以及 negative/drain/recovery 数量。

## 8. Verilator 与 PASS/GAP

唯一固定功能配置：

```text
verilator --binary --timing --sv -O3 -Wall -Wno-fatal
C++: -O3 -DNDEBUG -march=native
assertions=off, waveform=off
Mdir/log/TMPDIR/cache 全部位于项目 tmp/
```

PASS 要求新增 RTL/TB 零 warning/error、build/run rc=0、精确 marker、无 wave
产物，并保留首次反例与 root-cause 修正记录。仍为 GAP：SET_ROWS、F32→F16
转换、KV overlay/root atomic commit、graph manifest/command ABI、LMEM/DMA 集成、
backend `supports_op`、Qwen 整图、shell 对话和 tokens/s；禁止把 Phase A PASS
外推为这些功能 PASS。

## 9. Phase A 当前证据

截至 2026-08-21，`rtl/TensorNpuTensorMover.v` 与
`tests/tb_tensor_mover.sv` 已按机器合同
`tmp/contracts/tensor_mover_phase_a_v1.json`（SHA-256
`6459a1cc171523ac4876e72c586bb66eecc023862f2dfed8da3a3b7a945cfc37`）
落盘。定向 build/run 返回0，`tmp/logs/tensor-mover/run.log` 精确命中
`[NPU-TENSOR-MOVER][PASS]`；5个正向、22个负向、14个 preflight、4个
accepted-response drain、9个无 reset recovery 均已动态执行，观测最大
outstanding 为1。最终新增 RTL/TB 零 warning/error 且无 waveform。

该 test 已作为独立 filelist 纳入 `scripts/run_npu_regression.sh`。一次固定
aggregate build/run 返回0，末行精确为
`[NPU-REGRESSION][PASS] tests=26 assertions=off waveform=off optimization=O3`；
全部 aggregate build/run log 的 warning/error/FAIL 扫描及 waveform 文件扫描
均为零匹配。

首次反例保留在 `tmp/logs/tensor-mover/build-first.log` 与
`run-first.log`：前者是 TB 地址索引位宽诊断；后者是 transaction conservation
oracle 未计入一次 reset-cancelled accepted request。修正后的守恒式为
`accepted_requests == responses + reset_cancelled_requests`，未改变 RTL GMEM
事务语义。

`opcode_i[1:0]` 的4个二进制码点在 Phase A 全部定义，因此二态 Verilator 没有
可编码的 unknown-opcode 动态负向值；RTL `default` 仍 fail-closed，但不能把
X/Z 激励当作可靠功能证据。若未来需要版本/保留 opcode，ABI 必须扩宽或单独
增加 version/validity 字段并新增动态负向测试。
