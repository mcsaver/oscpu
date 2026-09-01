# Qwen F32→F16 SET_ROWS RTL contract

> **Mover Phase B。** 本合同只冻结 Qwen3.5-0.8B 单 token、显式
> `flash_attn=disabled`、F16 KV-cache 的12个 `GGML_OP_SET_ROWS` 节点：6个
> native K row write 与6个物理转置 V scalar-row scatter。它不实现通用 GGML
> SET_ROWS、active-root swap、attention read、Phase A CPY/CONT/CONCAT、UNARY、
> GDN 或整图调度。只允许 Verilator 功能仿真，禁止综合、STA、PPA、DPI、
> host 浮点、assert 与 waveform。

## 1. 固定图语义

固定 llama.cpp b10507 commit
`95c409c13625a23da2aa37270339ce9179215a18`、Qwen3.5-0.8B、
`T=1,B=1,n_ubatch=1,n_seq_max=1`，启动时显式关闭 flash attention 后：

- 每个 full-attention 层的 current K/V 都是512个 F32 元素
  (`head_dim=256, n_head_kv=2`)；
- K cache 是 F16 `[512,C]`，写 profile `NATIVE_K`：一个 I64 index `p`，把512个
  F32 转为 F16 后写 row `p`；
- V cache 物理转置，SET_ROWS view 为 F16 `[1,512*C]`，写 profile
  `TRANSPOSED_V`：512个 I64 indices，必须逐项等于 `j*C+p`，把第 j 个 F32
  转为 F16 后写 scalar row `j*C+p`；
- `C` 是运行时 cache capacity，`p<C` 是当前 physical slot。不能用逻辑 token
  position 替代 p。

本模块写 destination shadow/COW backing。父级只有在同 token 的所有 mover 与
compute 都成功后才交换 active root。当前 token 的 attention 读必须通过外部
overlay 看到 shadow 中的新 K/V；本模块本身不实现 overlay 或 COMMIT。

## 2. Module 与事务端口

```text
module TensorNpuSetRowsEngine
  parameter VALUE_ELEMENTS = 512
  parameter STALL_TIMEOUT_CYCLES = 512
  parameter COMMAND_TIMEOUT_CYCLES = 1048576

  clk_i / synchronous active-high rst_i
  start_i / ready_o / busy_o
  profile_i
    0 = NATIVE_K
    1 = TRANSPOSED_V
  cache_capacity_i[31:0] = C
  physical_slot_i[31:0]  = p

  gmem_floor_i[63:0], gmem_limit_i[63:0]       // limit exclusive

  values_region_base_i[63:0], values_region_size_i[63:0]
  values_view_off_i[63:0]                       // 512 contiguous F32
  indices_region_base_i[63:0], indices_region_size_i[63:0]
  indices_view_off_i[63:0]                      // 1 or512 contiguous I64
  dst_region_base_i[63:0], dst_region_size_i[63:0]
  dst_view_off_i[63:0]                          // F16 shadow backing

  held 64-bit single-outstanding GMEM request/response interface

  done_o / error_o / error_code_o[4:0]
  indices_validated_o[31:0]
  values_validated_o[31:0]
  writes_completed_o[31:0]
  bytes_written_o[31:0]                         // semantic F16 bytes
  gmem_read_beats_o[31:0]
  gmem_write_beats_o[31:0]
  writes_accepted_o[31:0]
  active_cycles_o[63:0]
```

`VALUE_ELEMENTS` 的 production/default 值固定512。TB 不得通过缩小参数替代
Qwen canonical cardinality；必须实际执行512-value native 与512-index
transposed 命令。

destination 必须是 transaction-private shadow/COW region。`done_o` 只表示这条
SET_ROWS 命令的所有512个 write response 已成功、父级可把本节点记入 completion
bitmap；不表示 token root 已提交。`error_o` 或 reset 后父级丢弃 shadow generation。

## 3. 三阶段全命令验证

任何 destination write 前必须依序完成：

```text
STATIC_PREFLIGHT
  -> INDEX_SCAN (读取并验证全部 I64 payload)
  -> VALUE_SCAN (读取全部 F32、finite/overflow 检查、RNE 转 F16并缓存)
  -> WRITE_SHADOW (使用已缓存 index/value 执行全部写)
```

内部允许：

```text
index_buffer[0:511] : 64 bit
half_buffer[0:511]  : 16 bit
```

数组 data bits 不要求 reset；只有 current command 的 validated counters 使 entry
可读。若 index/value scan 失败，`writes_accepted_o==0` 且 destination/root
canary 必须逐 bit 不变。

### 3.1 Static preflight

使用至少128-bit中间值，在首个 GMEM request 前证明：

- `C>=1`、`p<C`；production `VALUE_ELEMENTS==512`；
- values 是从 `base+view_off` 起连续 `512*4=2048` bytes；
- NATIVE_K indices 是1个 I64；TRANSPOSED_V indices 是512个连续 I64；
- destination 最大 semantic byte：

  ```text
  NATIVE_K:
    dst_rel_end = view_off + ((p*512 + 511)*2) + 2
  TRANSPOSED_V:
    dst_rel_end = view_off + (((511*C + p)*1)*2) + 2
  ```

- 所有 region base+size、view/span、`j*C+p`、byte乘加和绝对地址均不溢出；
- 每个 aligned 8B source/index read beat 完整落在对应 region 与
  `[gmem_floor,gmem_limit)`；
- 每个 aligned destination write beat 落在 GMEM window，semantic target byte落在
  destination region，F16 target自然对齐，wstrb只覆盖目标2 bytes；
- values span、indices span 与 destination conservative span 两两不重叠；
- profile 所需 index count 确定且不允许空命令。

任一 static preflight error 必须零 GMEM request。

### 3.2 Index scan

I64 payload 按 little-endian读取并逐项匹配：

```text
NATIVE_K:     index[0] == zero_extend_64(p)
TRANSPOSED_V: index[j] == zero_extend_64(j*C+p), j=0..511
```

不接受负数、越界、duplicate 或其他排列。由于预期序列结构性唯一，逐项 exact
compare 同时证明 range 与 uniqueness。全部 index 成功前不得读 values 或写
destination。

### 3.3 Value scan 与转换 profile

values 按 element index `j=0..511` 从连续 F32 backing 读取。实例化现有
`TensorNpuFp32ToFp16` 组合转换器，冻结 `FINITE_ONLY_RNE_V1`：

- finite F32 用 round-to-nearest ties-to-even 转 F16；gradual subnormal、±0保号；
- 输入 NaN/Inf (`finite_o=0`) fail-closed；
- 有限 F32 舍入到 half Inf (`overflow_o=1`) fail-closed；
- `inexact_o` 是合法审计信息，不导致 error；
- 只有全部512个 value 都成功后才进入 WRITE_SHADOW。

因此本 profile 不声称复现不同 CPU vector path 的 NaN payload。Qwen 健康执行若
产生非有限或 half overflow，整 token 失败，禁止 CPU fallback。

## 4. Destination mapping 与 write 原子边界

对缓存后的 `half_buffer[j]`：

```text
NATIVE_K:
  row_index = index_buffer[0] = p
  dst_elem  = row_index*512 + j

TRANSPOSED_V:
  row_index = index_buffer[j] = j*C+p
  dst_elem  = row_index

dst_addr = dst_region_base + dst_view_off + dst_elem*2
```

每个 write 使用 aligned 8B request，`wdata` 把16-bit half移到目标 lane，`wstrb`
只置相应两位。accepted write 可以先改变 shadow memory；write response error/
timeout/reset 后这些字节没有 architectural eligibility，父级必须丢弃整个 shadow
generation。active-root canary 始终不得改变。

`writes_completed/bytes_written` 只在成功 write response 后增加；read/write beat
在各自 request handshake 计数；`writes_accepted` 在 write request handshake 计数。

## 5. GMEM FSM、backpressure 与 timeout drain

建议显式 FSM：

```text
IDLE -> STATIC_PREFLIGHT
 -> INDEX_PREP -> INDEX_REQ -> INDEX_WAIT        (1 or512)
 -> VALUE_PREP -> VALUE_REQ -> VALUE_WAIT        (512)
 -> WRITE_PREP -> WRITE_REQ -> WRITE_WAIT        (512)
 -> DONE / ERROR
accepted WAIT timeout -> GMEM_DRAIN -> ERROR
```

- request 只在 `valid&&ready` 接受，`valid&&!ready` 时 type/address/data/strobe 逐 bit
  稳定；任意时刻最多一个 outstanding；response credit 只在 matching WAIT/DRAIN；
- busy start不采样；terminal单拍，下一拍回IDLE；
- watchdog优先级固定：

  ```text
  reset > internal/domain/conversion fatal > command timeout
        > stall timeout > normal progress
  ```

- REQ timeout hit 当拍撤销 valid，防止 same-cycle late ready；
- WAIT 中已接受 request 后，timeout锁存 cause并进入唯一 DRAIN，持续 response
  credit，冻结 scan/write/result counters；matching late response 后才 terminal；
- late `gmem_rsp_error_i` 覆盖 timeout cause为 GMEM-response error；
- drain结束无需 reset 即可运行 clean command，迟到 response不得污染下一命令；
- synchronous reset取消 resident command与completion资格；系统 bus model必须在同一
  reset域取消 accepted pending response，deassert 后不得出现 stale completion。

## 6. Error code

```text
0  NONE
1  HEADER / unsupported production parameter
2  PROFILE_OR_SHAPE
3  ALIGNMENT
4  VALUES_BOUNDS
5  INDICES_BOUNDS
6  DESTINATION_BOUNDS
7  OVERLAP
8  INDEX_PAYLOAD
9  VALUE_NONFINITE_OR_OVERFLOW
10 GMEM_RESPONSE
11 STALL_TIMEOUT
12 COMMAND_TIMEOUT
13 INTERNAL_STATE
```

static error顺序固定为 HEADER→PROFILE/SHAPE→ALIGNMENT→VALUES→INDICES→DEST→
OVERLAP；动态 index/value domain error高于 watchdog；response error覆盖 timeout。

## 7. Directed raw-bit / memory oracle

TB 使用确定性 little-endian byte GMEM，不使用 `real/shortreal`、DPI 或 host FPU。
至少覆盖：

1. **NATIVE_K canonical**：`C=8,p=3`，1个 index `3`，512个 F32；检查
   destination row3的512个 F16、未写 row/canary保持、counts=
   `indices1/values512/writes512/bytes1024`。
2. **TRANSPOSED_V canonical**：`C=8,p=3`，512个 indices `j*8+3`；检查每个
   `dst[j*8+3]` 与 source j 对应、其他 scalar row/canary保持、counts=
   `indices512/values512/writes512/bytes1024`。
3. raw conversion directed lanes至少包含：

   ```text
   F32 3f800000 -> F16 3c00   (+1)
   F32 c0000000 -> F16 c000   (-2)
   F32 3f000000 -> F16 3800   (+0.5)
   F32 477fe000 -> F16 7bff   (65504)
   F32 3f801000 -> F16 3c00   (halfway retained-even)
   F32 3f803000 -> F16 3c02   (halfway increment-to-even)
   F32 33800000 -> F16 0001   (half min subnormal)
   F32 80000000 -> F16 8000   (-0)
   ```

4. wrong native index、任一 transposed index次序/值错误、negative I64 raw、duplicate
   同构错误，且全部 zero destination write；
5. qNaN、sNaN、±Inf、finite half overflow，均在 value scan fail、zero write；
6. static profile/C/p、128-bit overflow、values/indices/destination bounds、aligned
   read overfetch、write beat window、alignment、三类 overlap，且全部 zero request；
7. request backpressure payload稳定、response delay、single outstanding；
8. index-read/value-read/write response error；INDEX/VALUE/WRITE WAIT 的 stall或
   command timeout drain、late-error override，每例无 reset clean recovery；
9. busy start ignored、mid-index/mid-value/mid-write reset取消、deassert clean recovery；
10. active-root canary始终不变；partial shadow在失败后不得被误报done/commit。

固定 marker：`[NPU-SET-ROWS][PASS]`。INFO 至少报告两个 canonical profile精确
cardinality、negative/preflight/domain/drain/recovery/reset 数量与
`max_outstanding=1`。

## 8. Verilator 与 PASS/GAP

固定功能配置：

```text
verilator --binary --timing --sv -O3 -Wall -Wno-fatal
C++: -O3 -DNDEBUG -march=native
assertions=off, waveform=off
Mdir/log/TMPDIR/cache 全部位于项目 tmp/
```

PASS 要求新增 RTL/TB 零 warning/error、build/run rc=0、精确 marker、无 wave，
保留首次反例/root-cause。仍为 GAP：通用 outer-plane/modulo SET_ROWS、F16/other
value types、active-root COW/overlay/commit、graph manifest/command ABI、attention
cache read、backend `supports_op`、Qwen整图、shell对话、tokens/s，以及全部
综合/STA/PPA。Phase B PASS不得外推为这些功能 PASS。

### 8.1 2026-08-21 Verilator 功能证据

本合同对应的生产基数 RTL/TB 已完成定向与总回归验证：

- 定向 `verilator --binary --timing --sv -O3 -Wall -Wno-fatal`，host C++
  `-O3 -DNDEBUG -march=native`，build/run 均 `rc=0`；
- `tmp/logs/set-rows-engine/run.log` 精确一个独立行
  `[NPU-SET-ROWS][PASS]`，canonical 实际执行 NATIVE_K 的512 values/512 writes
  与 TRANSPOSED_V 的512 indices/512 values/512 writes；
- `bash scripts/run_npu_regression.sh` 在加入本模块后 `rc=0`，最终 marker 为
  `[NPU-REGRESSION][PASS] tests=27 assertions=off waveform=off optimization=O3`；
- `tmp/logs/npu-regression/` 的 build/run 日志中 `%Warning`、`%Error` 与
  `[NPU-*][FAIL]` 均零匹配；`tmp/build/npu-regression/` 与对应日志树中
  `.vcd/.fst/.lxt/.lxt2/.wlf/.fsdb` 零文件；
- 未运行综合、STA 或 PPA。

固定证据 SHA-256：

```text
6376c612beb1e7409bc63dcfaf9bd0515c2bc7374f7d78e39236e17b88baaf34  rtl/TensorNpuSetRowsEngine.v
2e98e1230564690c3c0103a2e23b34ed84beb68a32082fb698abe71d789fd898  tests/tb_set_rows_engine.sv
96e5489803db073698c368c5d209f219f4498b4a3c86beae5611d07076b25c13  tmp/logs/set-rows-engine/build.log
a0d4374a27eddb9583d7b58d9ee02dc6e48ef9b4634e668034696a98a0cbba03  tmp/logs/set-rows-engine/run.log
f9393e82637ccedbc967a02a316ac3d25b8f00e0225c3de222f19299e4842e87  tmp/logs/npu-regression/tb_set_rows_engine.build.log
0899cc2aa122fd709133ea40d0efc19a6b332b51e2c14957f847029ca14d9eca  tmp/logs/npu-regression/tb_set_rows_engine.run.log
```

首次定向构建保留的唯一反例是 TB 遗留未使用 `ROOT_BASE` localparam；删除该
无功能别名后，以新的 TB identity 完成上述零 warning 的固定 build/run。此 PASS
只覆盖 Phase B 模块及其 shadow 写资格，不改变本节列出的系统级 GAP。
