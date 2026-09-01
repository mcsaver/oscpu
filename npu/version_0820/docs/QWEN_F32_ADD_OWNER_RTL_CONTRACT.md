# Qwen canonical F32 ADD[16] production-owner RTL contract

> **QWEN-F32-ADD-OWNER-v1 / topology freeze。** 本合同冻结本地
> `TensorNpuCoprocessor`、计划新增的 `TensorNpuVectorF32Adapter` 与既有
> `TensorNpuF32TensorAlu` 之间的一条最小 production transaction：解析后的
> `VECTOR_F32/ADD/F32/[16,1,1,1]` macro command 由 top 唯一接收，经 64-bit
> external GMEM 读取两个 64-byte source、逐元素执行 raw-bit FP32 ADD，并向第三个
> 64-byte window 写回结果；terminal completion 在 consumer ready 前保持。
>
> 本文是写 RTL 前的阶段 1、2a--2e 冻结，不是实现或 PASS 证据。合同 JSON 为
> `tmp/contracts/qwen-f32-add-owner-v1.json`，SHA-256 为
> `c42fc734d11c971209249f7ef7762e7cc96f2e2eb17929bc771a0e1e98ea4b23`；该哈希
> 只绑定 JSON，不绑定本文、RTL、C++、testbench 或 runner evidence。

## 0. 冻结事实与术语

- canonical manifest identity 为
  `49138fb42ef50df1cfc90a6460702e88466ac28c2b4d0c02af907f218fa2f474`，包含
  `1711 = 959 compute + 120 mover + 632 metadata` nodes；F32 `ADD` 共 84 个，
  其中 18 个满足 `src0/src1/dst=f32`、`ne=[16,1,1,1]`、
  `nb=[4,64,64,64]`。
- 当前 production `TensorNpuCoprocessor` 只有 legacy command owner；`u_dma` 是
  唯一 external GMEM owner。`TensorNpuF32TensorAlu` 已存在，但尚未进入 production
  top hierarchy；`TensorNpuVectorF32Adapter` 尚不存在。
- 本文中的 **macro owner** 是 top 内由一次 `macro_cmd_valid_i &&
  macro_cmd_ready_o` 建立并保持到 terminal completion handshake 的 transaction
  生命周期，不是新的 RISC-V opcode，也不改写既有 LO/HI custom instruction ABI。
- 本文中的 **byte adapter** 是 C++/Verilator 侧 64-bit GMEM memory adapter：它只按
  RTL request/response 搬运 little-endian raw bytes、检查已注册 IOVA window，并驱动
  时钟/握手；禁止使用 host FP、GGML CPU kernel 或其它 tensor arithmetic 形成结果。
- `TensorNpuF32TensorAlu` 的 ABI-local 编码为 `opcode_i=0` 表示 ADD、
  `dtype_i=0` 表示 F32；macro ABI 的对应编码是 `vector_op=1`、`dtype=1`。adapter
  必须显式转换，禁止把两套 enum 直接短接。

## 1. 阶段 1：需求冻结

### 1.1 功能目标

1. `TensorNpuCoprocessor` 增加一个与 legacy command 并列、但在任一周期互斥接受的
   parsed macro command port；top 是 legacy/macro admission、GMEM owner 与 held
   completion 的唯一仲裁点。
2. `TensorNpuVectorF32Adapter` 只接受 §1.2 的 exact v1 predicate。predicate 不匹配时
   产生 terminal failure，`TensorNpuF32TensorAlu.start_i` 次数、GMEM traffic 与成功
   coverage 均为零。
3. predicate 匹配时，adapter 把 macro vector descriptor 降为既有 F32 tensor ALU 的
   resident descriptor：`ADD/F32/profile0`、三组 `ne=[16,1,1,1]`、
   `nb=[4,64,64,64]`、两个 read-only source region 与一个 write destination region。
4. 算术必须来自 `TensorNpuF32TensorAlu -> TensorNpuFp32AddMul` 的 clocked RTL path。
   外部 memory adapter 对每个 accepted GMEM request 只搬运 unchanged raw bytes。
5. top 在 macro terminal 时锁存 success/failure、完整 transaction identity、coverage
   identity 与计数；`completion_valid_o && !completion_ready_i` 时整个 completion
   payload 逐 bit 保持。
6. backend 只对 exact GGML node predicate 宣告 arithmetic support；只有 matching
   RTL success completion 才增加 `executed_by_verilator` 与 required coverage。
   未实现 required node 继续 fail-closed，禁止 CPU fallback。

### 1.2 Exact v1 predicate

以下条件必须全部成立；“相近” shape、stride、flag 或 alias 均不属于本 capability：

| 类别 | exact 条件 |
|---|---|
| ABI envelope | C++ parser 已验证 128-byte command/parameter block 的 magic、major/minor、size、reserved 与零扩展规则，并令 `macro_abi_valid_i=1` |
| command | `kernel_id=32'h514e0010`、`command_flags=REQUIRED|PROFILE=32'h00000011`、`capability_epoch=32'h00000001`、`deadline_cycles=0` |
| coverage | `node_count=1`；node ID list/hash 由 backend 提交前冻结，top 只 resident echo count 与两个 64-bit hash words |
| vector op | `vector_op=1 (ADD)`、`vector_flags=0`、`dtype=1 (F32)`、`element_count=16`、`outer_count=1` |
| addresses | 虽然公共 ABI 仅要求 FP32 地址至少 4-byte aligned，本 v1 capability 进一步要求 `src0_iova/src1_iova/dst_iova` 均 8-byte aligned 且互不相等；`src2_iova=0`、`scratch_iova=0`。这是 64-bit bus + 精确 64-byte window 的必要条件，不能只由 runner 选址隐式满足 |
| stride | `src0_stride_bytes=64`、`src1_stride_bytes=64`、`src2_stride_bytes=0`、`dst_stride_bytes=64` |
| scalar/tail | `scalar0=+0`、`scalar1=+0`、`scratch_bytes=0`、`rope_position=0` |
| registered windows | 三个 generation 均有效；src0/src1 含 read permission，dst 含 write permission；每个 window 精确 64 bytes、`iova==window_base`，`base+64` 无溢出且三者半开区间互不 overlap |
| GGML predicate | `op=GGML_OP_ADD`；src0/src1/dst 均 `GGML_TYPE_F32`；每个 tensor 的 `ne=[16,1,1,1]`、`nb=[4,64,64,64]`；无 broadcast、in-place、view offset 或 host-side conversion |

`deadline_cycles=0` 表示 v1 不实现动态 per-command deadline；bounded timeout 由
`TensorNpuF32TensorAlu` 固定 `STALL_TIMEOUT_CYCLES`、`CHILD_TIMEOUT_CYCLES` 与
`COMMAND_TIMEOUT_CYCLES` 提供。任何非零 deadline 在本 wedge 以 CAPABILITY failure
拒绝，不得静默忽略。

capability epoch 的唯一 RTL 配置源冻结为 `TensorNpuCoprocessor` 的 32-bit parameter：

```verilog
parameter [31:0] MACRO_CAPABILITY_EPOCH = 32'h00000001
```

top 实例化 adapter 时用
`.MACRO_CAPABILITY_EPOCH(MACRO_CAPABILITY_EPOCH)` 原值下传；adapter 使用同名 32-bit
parameter 比较 `macro_capability_epoch_i`，不得另建可漂移 localparam。C++ ABI 侧以
`constexpr uint32_t kMacroCapabilityEpoch = 0x00000001u` 构造 command 并驱动该 input；
runner build 必须同时审计 RTL parameter default 与 C++ constant 均为 1。未来 epoch 变化
必须同一修改同时更新两侧并使旧 source/config receipt 失效，不能只改 command input。

### 1.3 Top-level macro command interface

既有 legacy ports 与语义保持不变。`TensorNpuCoprocessor` 增加以下 parsed input；全部
属于 `clk` 时钟域并由同步高有效 `rst` 取消：

| signal | width | 生产者 / 语义 |
|---|---:|---|
| `macro_cmd_valid_i`, `macro_cmd_ready_o` | 1 | top-level valid/ready admission；只在 handshake 捕获 |
| `macro_abi_valid_i` | 1 | C++ parser 已闭合 header/parameter envelope；0 必须 fail-closed，不能启动 F32 engine |
| `macro_kernel_id_i`, `macro_command_flags_i`, `macro_context_id_i` | 32 each | command identity 与 flags |
| `macro_capability_epoch_i` | 32 | 必须等于 top/adapter parameter `MACRO_CAPABILITY_EPOCH=32'h00000001` |
| `macro_sequence_id_i`, `macro_producer_id_i`, `macro_user_tag_i` | 64 each | completion 原样回显；ProducerId 禁止截断为 legacy `PID_W` |
| `macro_node_count_i` | 32 | v1 必须为 1 |
| `macro_node_hash_lo_i`, `macro_node_hash_hi_i` | 64 each | covered-node SHA-256 前 16 bytes 的两个 little-endian words |
| `macro_deadline_cycles_i` | 64 | v1 只接受 0 |
| `macro_vector_op_i`, `macro_vector_flags_i`, `macro_outer_count_i`, `macro_dtype_i` | 32 each | parsed VECTOR_F32 fields |
| `macro_src0_iova_i`, `macro_src1_iova_i`, `macro_src2_iova_i`, `macro_dst_iova_i`, `macro_scratch_iova_i` | 64 each | parsed IOVA，不是 host pointer |
| `macro_element_count_i` | 64 | v1 必须为 16 |
| `macro_src0_stride_i`, `macro_src1_stride_i`, `macro_src2_stride_i`, `macro_dst_stride_i` | 64 each | signed ABI stride 的 raw two's-complement bits |
| `macro_scalar0_i`, `macro_scalar1_i`, `macro_scratch_bytes_i`, `macro_rope_position_i` | 32 each | v1 全零 |
| `macro_src0_window_base_i/size_i`, `macro_src1_window_base_i/size_i`, `macro_dst_window_base_i/size_i` | 64 each | runner 已解析的注册 window grant |
| `macro_src0_window_perm_i`, `macro_src1_window_perm_i`, `macro_dst_window_perm_i` | 2 each | bit0=read、bit1=write |
| `macro_windows_generation_valid_i` | 1 | 三个 IOVA binding generation 均与 command 提交时一致 |

`macro_abi_valid_i` 与 window grant 是 host control proof，不授权 host 计算 tensor；RTL
仍独立检查 kernel/vector exact predicate、地址算术、permission 与 overlap。外部 GMEM
bridge 对每次实际 request 再检查 window，形成第二道 fail-closed boundary。

### 1.4 Completion interface 与计数

既有 `completion_valid_o/ready_i` 是 legacy 与 macro 共用的唯一 terminal channel；新增
`completion_is_macro_o` 和下列 macro-only payload。legacy completion 时这些字段必须
全部为零，不能泄漏上一条 macro resident 值：

| payload | width | success/failure 语义 |
|---|---:|---|
| `completion_macro_status_o`, `completion_macro_error_class_o` | 32 each | success 均为 0；failure status=`{24'd0, completion_error_code_o}`，class 采用 command ABI §14 |
| `completion_macro_kernel_id_o`, `completion_macro_command_flags_o`, `completion_macro_context_id_o` | 32 each | accepted command 原样回显 |
| `completion_macro_sequence_id_o`, `completion_macro_producer_id_o`, `completion_macro_user_tag_o` | 64 each | accepted command 原样回显 |
| `completion_macro_covered_node_count_o` | 32 | resident count 回显；只有 success 且全 identity match 才可计 coverage |
| `completion_macro_node_hash_lo_o`, `completion_macro_node_hash_hi_o` | 64 each | resident hash 回显；failure 不具 coverage eligibility |
| `completion_macro_npu_cycles_o` | 64 | 从 top 接受 macro 后到 adapter terminal 的周期数 |
| `completion_macro_gmem_read_bytes_o` | 64 | matching、无 error 的 64-bit read response 数乘 8 |
| `completion_macro_gmem_write_bytes_o` | 64 | matching、无 error 的 write response 对应 strobe popcount；本 wedge 每成功元素为 4 |
| `completion_macro_q8_mac_count_o` | 64 | v1 恒为 0 |
| `completion_macro_vector_element_count_o` | 64 | 成功 write response 后完成的元素数；完整 success 必须为 16 |
| `completion_macro_state_update_count_o` | 64 | v1 恒为 0 |

top 还增加持久诊断计数 `macro_command_count_o`、`macro_f32_start_count_o` 与
`macro_completion_count_o`。它们分别只在 macro admission、F32 child start handshake、
macro terminal success handshake 处增加，用于证明 unknown-kernel 没有伪启动、success
恰好一次启动/完成；reset 清零，失败不能增加 `macro_completion_count_o`。

`completion_error_o/completion_error_code_o` 对 macro 仍提供 top-level condensed error，
并与 ABI error class 同拍锁存。计划在 `tensor_npu_defs.vh` 的既有 0--12 之后使用：

| condensed code | value | ABI `error_class` |
|---|---:|---:|
| `NPU_ERR_MACRO_ABI` | 13 | 1 ABI |
| `NPU_ERR_MACRO_CAPABILITY` | 14 | 3 CAPABILITY |
| `NPU_ERR_MACRO_LAYOUT` | 15 | 4 DTYPE_QUANT_LAYOUT |
| `NPU_ERR_MACRO_IOVA` | 16 | 5 IOVA_RANGE_PERMISSION |
| `NPU_ERR_MACRO_TIMEOUT` | 17 | 10 TIMEOUT |
| `NPU_ERR_MACRO_PROTOCOL` | 18 | 11 INTERNAL_PROTOCOL |

Runtime `gmem_rsp_error_i` 继续使用既有 `NPU_ERR_GMEM_RESPONSE`，并映射 ABI class 6。

`completion_macro_status_o` 的确定编码冻结为：success 是 `32'h00000000`；failure 是
8-bit condensed `completion_error_code_o` 的零扩展，即
`{24'd0, completion_error_code_o}`。因此所有 failure status 必须是 1--255，禁止输出
`completion_error_o=1 && completion_error_code_o=0`；若内部出现该矛盾，强制改写为
`NPU_ERR_MACRO_PROTOCOL=8'd18` / ABI class 11。status 不是另一套自由枚举，C++ 不得再
重映射或压缩。

`TensorNpuF32TensorAlu.error_code_o` 0--12 到 macro completion 的映射逐项冻结如下。
“理论不可达”表示 fixed descriptor 与 adapter preflight 正常时不应发生；若真实 RTL
仍产生该 code，必须按表形成 failure 并留下 marker，绝不能追认为 success：

| F32 engine code | F32 含义 | condensed top code | ABI `error_class` | 可达性 / fail-closed 解释 |
|---:|---|---|---:|---|
| 0 | `ERR_NONE` | success 时 0；若伴随 `error_o` 则 `NPU_ERR_MACRO_PROTOCOL` (18) | success 0；矛盾时 11 | 只允许与 `done_o` success 同现；error+NONE 或 done+error 是 protocol failure |
| 1 | `ERR_HEADER_PROFILE` | `NPU_ERR_MACRO_PROTOCOL` (18) | 11 | 理论不可达：adapter 固定 opcode/dtype/profile/reserved/op_params；出现即 lowering corruption |
| 2 | `ERR_SHAPE_BROADCAST` | `NPU_ERR_MACRO_PROTOCOL` (18) | 11 | 理论不可达：adapter 固定三组 `ne=[16,1,1,1]`；出现即 lowering corruption |
| 3 | `ERR_STRIDE_ALIGNMENT` | `NPU_ERR_MACRO_PROTOCOL` (18) | 11 | 理论不可达：adapter 固定 `nb=[4,64,64,64]` 且已验 alignment |
| 4 | `ERR_SOURCE_BOUNDS` | `NPU_ERR_MACRO_IOVA` (16) | 5 | 理论不可达但按 IOVA failure 收口；F32 start 已发生，coverage仍为0 |
| 5 | `ERR_DEST_BOUNDS` | `NPU_ERR_MACRO_IOVA` (16) | 5 | 理论不可达但按 IOVA failure 收口；destination无 commit eligibility |
| 6 | `ERR_OVERLAP` | `NPU_ERR_MACRO_IOVA` (16) | 5 | 理论不可达但按 IOVA failure 收口；三 window exact-disjoint 检查失配 |
| 7 | `ERR_GMEM_RESPONSE` | 既有 `NPU_ERR_GMEM_RESPONSE` (10) | 6 | runtime window generation/permission/error response |
| 8 | `ERR_STALL_TIMEOUT` | `NPU_ERR_MACRO_TIMEOUT` (17) | 10 | REQ 或 GMEM response phase timeout |
| 9 | `ERR_COMMAND_TIMEOUT` | `NPU_ERR_MACRO_TIMEOUT` (17) | 10 | F32 command watchdog |
| 10 | `ERR_CHILD_PROTOCOL` | `NPU_ERR_MACRO_PROTOCOL` (18) | 11 | FP child ghost/wrong-owner/credit fault |
| 11 | `ERR_CHILD_TIMEOUT` | `NPU_ERR_MACRO_TIMEOUT` (17) | 10 | FP child request/response timeout；accepted child先由F32 drain收口 |
| 12 | `ERR_INTERNAL_STATE` | `NPU_ERR_MACRO_PROTOCOL` (18) | 11 | illegal F32 state/owner invariant failure |

adapter 同拍观察 `done_o && error_o`、未知 code、或 terminal 时仍有 GMEM accounting
outstanding，也一律覆盖为 `NPU_ERR_MACRO_PROTOCOL` / class 11。该覆盖优先于表中的
普通映射，防止矛盾 terminal 假绿。

### 1.5 Completion record 的 C++ 序列化边界

RTL top 只产生 §1.4 表中的 parsed completion payload；它不输出也不写入完整 128-byte
completion record，不直接访问 `completion_iova`。C++ runner 在观察并 handshake 掉 held
RTL completion 后，负责按 `QWEN_NPU_COMMAND_ABI.md` §13 以 little-endian 序列化：

- `magic=32'h514e5043`、`abi_major=1`、`abi_minor=0`、`completion_size=128`、
  `reserved0=0`；
- status/error class与 top payload逐 bit一致；identity、coverage、cycles/bytes/elements
  只复制 top frozen outputs；`state_epoch_out/q8_mac_count/state_update_count` 使用 top
  已冻结的零输出；
- completion window 必须已注册、可写且至少128 bytes。runner 先写其余字段，最后以
  release/publication 语义写 terminal status；window错误不得形成无record success。

C++ 只能做 record framing/byte serialization，不能修改 status/class、补造 identity/counter
或根据 tensor raw bytes推断 success。因此下文“completion ABI字段闭合”仅指 RTL输出表中
字段 + C++固定 framing 的组合，不表示 top 自己生成完整 record。

### 1.6 周期、复位与性能边界

- top 与 adapter 均为单 transaction、多周期、非流水实现；macro outstanding 最大为 1。
- F32 engine 逐元素串行：每个元素固定执行 src0 read、src1 read、一个 F32 ADD child、
  一个 4-byte-strobed destination write。合同不承诺背靠背 macro 吞吐。
- 64-bit GMEM read 没有 byte-enable，读取一个 F32 仍传输 aligned 8-byte beat；因此完整
  ADD[16] 的成功审计预期是 32 个 read responses = 256 read bytes、16 个 write
  responses = 64 write bytes、16 vector elements。raw tensor payload 本身仍各为 64 bytes。
- `rst` 优先于 admission、owner、timeout 与 completion；reset 取消 resident macro、
  adapter/F32 engine state、GMEM credit 和未接受 completion，复位后禁止发布 stale terminal。
- 失败 completion 被 consumer 接受后沿用既有 sticky `ST_ERROR_HOLD`，直到
  `error_clear_i`；error clear 不能把失败改成 success，也不能重发旧 completion。
- functional-simulation byte adapter 的固定响应界为
  `B_rsp=16` cycles：request 在边沿 `t` fire 后，首次 response valid 必须在
  `t+1..t+16` 之一出现；禁止同边沿 response。首次 valid 后
  `{gmem_rsp_valid_i,gmem_rsp_rdata_i,gmem_rsp_error_i}` 必须逐 bit保持，直到 selected
  owner 的 `gmem_rsp_valid_i&&gmem_rsp_ready_o` handshake。
- `B_rsp` 约束 accepted request 到首次 response valid；正常 WAIT/DRAIN owner 必须持续
  提供 response credit，故无 reset/fatal collision 时 handshake 也在该界内。若接入环境
  无法保证 `B_rsp=16` 或 response-held semantics，则“accepted request 可 bounded
  terminal”仍是 GAP：F32 accepted-owner `ST_DRAIN` 本身没有第二个 watchdog，不能用第一
  次 timeout 外推 drain 最终一定结束。

### 1.7 明确 out-of-scope / GAP

- 不实现 `VECTOR_F32` 的 MUL/FMA/SCALE/activation/RoPE/broadcast/in-place，也不实现
  其它 kernel、dtype、shape 或 stride。
- 不实现 descriptor namespace 到 PDF custom opcode/TCR/TR/GR 的 RV64 instruction binding；
  macro port 是 Verilator/backend 功能仿真的 production top interface。
- 不修改 `TensorNpuF32TensorAlu`、`TensorNpuFp32AddMul` 或 third-party FPU 数值语义；
  不新增 host FP oracle。
- 不实现 512-byte GMEM line、LMEM cache、multi-outstanding、tag reorder 或 speculative
  completion；本 wedge 只使用现有 64-bit single-outstanding semantics。
- 本文不证明 backend、RTL、raw oracle、Verilator build/run、综合、STA 或 PPA PASS。
  即使后续一条 directed node 通过，也只关闭一个最小 transaction；其余 1078 个
  compute/mover nodes 继续标为 GAP，不得外推完整 Qwen、token-0 或 tokens/s。

## 2. 阶段 2a：协议规则

### 2.1 Admission 与 resident command

1. clean `ST_IDLE` 的固定优先级为 legacy command > macro command > descriptor/debug
   access。为保持已有软件时序，`cmd_ready_o` 维持 legacy admission；
   `macro_cmd_ready_o` 只在 clean idle、无 legacy `cmd_valid_i` 时为 1。
2. 定义 `legacy_fire=cmd_valid_i&&cmd_ready_o`、
   `macro_fire=macro_cmd_valid_i&&macro_cmd_ready_o`；任一周期二者之和不得大于 1。
   legacy 与 macro 同时 valid 时只接受 legacy，macro producer 必须保持 valid/payload
   直到后续 ready，禁止丢弃或双采样。
3. macro payload 只在 `macro_fire` 锁存进 top resident registers。进入非 IDLE 后，
   pin-level payload 变化不得覆盖 resident identity、descriptor、window grant 或 counters。
4. `desc_write_ready_o` 与 `host_lmem_ready_o` 在 macro valid/admitted/active 期间均为 0；
   macro path 不读写 LMEM。

### 2.2 Top-to-adapter handshake

- top 在 `TOP_MACRO_START` 保持 `adapter_start_valid` 与全部 resident payload；只有
  `adapter_start_valid && adapter_start_ready` 才建立 adapter owner，并进入
  `TOP_MACRO_RUN`。
- adapter 在 `AD_IDLE` 采样一次 payload，随后 `AD_CHECK` 依固定优先级检查：

  ```text
  ABI envelope -> kernel/capability/deadline -> vector layout/tail
               -> IOVA generation/permission/alignment/overflow/overlap
  ```

- preflight failure 直接进入 `AD_ERROR`；不得产生 F32 start、GMEM request 或 success
  coverage。exact success 才进入 `AD_ENGINE_START`。
- `AD_ENGINE_START` 在 `TensorNpuF32TensorAlu.ready_o=1` 时发出且只发出一次
  `start_i` handshake；F32 start 之前 resident ALU descriptor 已稳定。

### 2.3 Single external GMEM owner

top 用 state-driven mux 唯一选择 external GMEM owner：

```text
TOP_DMA_RUN   -> u_dma
TOP_MACRO_RUN -> u_vector_f32_adapter -> u_f32_tensor_alu
all others    -> no request owner
```

- 只有 selected owner 看见 `gmem_req_ready_i` 与
  `gmem_rsp_valid_i/rdata_i/error_i`；non-owner 的 ready/response-valid 输入强制为 0。
- external `gmem_rsp_ready_o` 只来自 selected owner；无 owner 时为 0。state 只能在该
  owner terminal 且其内部 outstanding 已清零后离开 RUN，response 不得被另一 owner
  credit。
- public request 只在 `valid&&ready` 接受；`valid&&!ready` 时
  在 watchdog 命中前 `{valid,write,addr,wdata,wstrb}` 逐 bit 保持。REQ watchdog 命中
  当拍允许组合撤销 `valid`，即取消尚未 accepted 的 request；payload在取消边沿前仍稳定，
  same-cycle late ready 因 gated valid=0 不得形成 fire。任一时刻 top external
  outstanding 最大为 1；该可取消 REQ 是本合同的显式例外，不宣称普通 irrevocable
  ready-valid。
- read address 为 8-byte aligned，返回全部 64 raw bits；F32 lane 由既有 ALU 选择。
  write strobe 只允许 `8'h0f` 或 `8'hf0`，memory adapter 仅更新对应四个 raw bytes。
- memory adapter 每个 accepted request 产生恰好一个 response；request fire 同周期禁止
  response valid/fire，首次 response valid latency 固定为 `1..B_rsp`、`B_rsp=16`。
  response valid/data/error 一旦出现必须 held until ready。地址、generation 或 permission
  二次检查失败时返回 `gmem_rsp_error_i=1`，不得代算或静默丢弃。

### 2.4 Adapter-to-F32-engine protocol

- adapter 对 F32 engine 使用 ready/start + single-cycle done/error；F32 engine 只在
  `start_i&&ready_o` 捕获固定 descriptor。
- engine 的 held GMEM request/owner/drain、child ADD request/response、watchdog 与
  write eligibility 继续服从 `F32_TENSOR_ALU_RTL_CONTRACT.md`；adapter 不旁路其
  preflight、owner 或 timeout。
- adapter 在 GMEM request fire 时寄存 `{write,wstrb}`，仅在 matching、无 error
  response fire 时增加 byte counters；同一 response 不得双计入。
- engine `done_o` 只有在 16 个 destination write responses 成功后才映射 macro
  success；`error_o` 映射 terminal failure。engine arithmetic flags 可用于日志，
  不改变 FP32 raw result，也不把 IEEE flag 当 transaction error。
- adapter 对 F32 child 的同步 reset 定义为：`AD_IDLE`、`AD_CHECK`、`AD_DONE`、
  `AD_ERROR` 全周期置 1；进入 `AD_ENGINE_START` 后置 0，并在整个
  `AD_ENGINE_START/AD_ENGINE_RUN` 保持释放。F32 start fire 只能发生在 reset 已释放一个
  完整组合周期后的 `AD_ENGINE_START` closing edge。进入 `AD_DONE/AD_ERROR` 后 reset
  至少保持一个完整周期，清空 engine residue。
- F32 Moore terminal 在 `AD_ENGINE_RUN` 周期被 adapter 于边沿 `E_f32` 采样并进入
  `AD_DONE/AD_ERROR`；adapter terminal valid 随后保持恰好一个完整周期。仍处于
  `ST_MACRO_RUN` 的 top 在该周期 closing edge `E_top` 锁存 payload并进入
  `ST_COMPLETE`；adapter 同一 `E_top` 回到 `AD_IDLE`。下一周期 top 才对外拉高 held
  `completion_valid_o`。因此 one-cycle adapter terminal不会因 top backpressure丢失，
  adapter不等待 backend ready。

### 2.5 Completion hold 与 coverage eligibility

1. adapter terminal 只允许 top 锁存一次 completion。top 同拍冻结 resident identity、
   status/class、cycles/bytes/elements，并进入 `ST_COMPLETE`。
2. `completion_valid_o && !completion_ready_i` 时，legacy 与 macro payload、
   `completion_is_macro_o`、error/status/class 和所有 counters 必须稳定。
3. macro success 必须同时满足：exact preflight、F32 start exactly one、F32 done、
   no adapter/GMEM error、`vector_element_count=16`、read bytes=256、write bytes=64、
   top resident identity 未变化。
4. backend 只有在 `status=SUCCESS` 且 kernel/context/sequence/full producer/user tag/
   node count/hash 全部等于提交快照时，才令
   `executed_by_verilator += 1` 与 `required_nodes_successfully_covered += 1`。
5. failure 可以回显 submitted node count/hash 便于诊断，但没有 coverage eligibility；
   `executed_by_verilator`、required covered 与 `macro_completion_count_o` 均不得增加。
6. legacy completion 的 macro-only payload 组合置零；macro completion 的 legacy
   `completion_producer_id_o` 等窄 identity 不能冒充 full macro ProducerId。

### 2.6 Timeout、错误优先级与恢复

逐拍优先级冻结为：

```text
rst
  > top/adapter illegal state or wrong-owner response
  > GMEM response error
  > F32 command/phase/child timeout
  > exact-predicate rejection
  > normal progress
```

- unknown kernel/epoch/nonzero deadline：CAPABILITY terminal；F32 start=0、GMEM
  read/write bytes=0、vector elements=0。
- invalid/out-of-range/overlap/permission window：IOVA terminal；F32 start=0、
  destination commit=0。若 RTL preflight 后 host window 二次检查发现 generation 漂移，
  以 GMEM_RESPONSE terminal，仍不得 success。
- timeout test 将 public `gmem_req_ready_i` 持续拉低。F32 REQ watchdog 当拍撤销 valid，
  adapter 映射为 TIMEOUT terminal；无 accepted request、无 destination byte、无残留
  process。accepted transaction timeout/drain 仍由既有 F32 engine 完成后才能 terminal。
- accepted GMEM response 若未在 `B_rsp=16` 内首次 valid，memory integration 已违约；
  F32 可能先命中 WAIT timeout并进入 `ST_DRAIN`，但 drain没有二次 timeout。此时 runner
  必须 fail-closed为 environment/protocol GAP并停止宣称 bounded RTL completion，不能靠
  无界等待或 host伪造 response terminal。
- wrong-owner/ghost response 或 adapter/top illegal state 映射 INTERNAL_PROTOCOL；若
  selected child 内已有 accepted owner，必须先完成既有 owner-tagged drain，禁止直接
  重分配 GMEM。
- error completion handshake 后 top 进入 sticky `ST_ERROR_HOLD`；`error_clear_i` 才
  恢复 clean IDLE。clean retry 不依赖 global reset，但旧 completion/GMEM response 不得
  被新 transaction 接纳。

### 2.7 Backend 与 byte adapter 边界

- `npu_device_supports_op` 与 `graph_compute` 使用同一个 exact GGML predicate；support
  query 不能比实际 lowering 更宽。
- metadata node 可以由 host 管理 shape/view；本任务的 ADD data movement/arithmetic
  必须进入 macro RTL。任何 predicate mismatch 的 required node 立即增加
  `unsupported_required` 并返回 graph failure，禁止执行 GGML CPU kernel。
- command/parameter parser、node hash、IOVA registration 与 completion serialization
  是 host control 工作；结果 tensor 的 64 raw bytes只能由 RTL GMEM writes 形成。
- completion serialization 只添加固定 magic/version/size/reserved framing并复制 held RTL
  payload，详细边界见 §1.5；C++ 不得生成另一套 success/status oracle。
- 固定 oracle 使用 compile-time raw `uint32_t` bit patterns；禁止 C++ float expression、
  `ggml_compute_forward_*`、BLAS 或读回后重算 expected result。

## 3. 阶段 2b：状态机

### 3.1 `TensorNpuCoprocessor` top FSM

在现有状态上新增 `ST_MACRO_START` 与 `ST_MACRO_RUN`；legacy 边保持原语义：

| top state | owner / 输出 | 正常转移 |
|---|---|---|
| `ST_IDLE` | clean admission；无 GMEM owner | legacy fire -> `ST_DECODE`; macro fire -> `ST_MACRO_START` |
| `ST_DECODE` | legacy decoder/config | 既有 cfg/sync/MM2/DMA/error 边 |
| `ST_TIU_RUN` | `u_mm2`，只占 LMEM | done/error -> `ST_COMPLETE` |
| `ST_DMA_RUN` | `u_dma`，唯一 GMEM owner | done/error -> `ST_COMPLETE` |
| `ST_MACRO_START` | top resident macro；adapter start held | adapter start fire -> `ST_MACRO_RUN` |
| `ST_MACRO_RUN` | `u_vector_f32_adapter`，唯一 GMEM owner | adapter done/error -> `ST_COMPLETE` |
| `ST_COMPLETE` | held legacy/macro completion | ready handshake + success -> `ST_IDLE`; error -> `ST_ERROR_HOLD` |
| `ST_ERROR_HOLD` | sticky fail-closed；无 GMEM owner | `error_clear_i` -> `ST_IDLE` |

`ST_MACRO_START` 不允许 GMEM request；adapter 不 ready 的 stall 由 top macro command
watch counter 诊断，但正常 reset 后 adapter 必须 ready。非法 top state 形成
INTERNAL_STATE error completion，且不得选中 DMA 或 adapter GMEM owner。

### 3.2 `TensorNpuVectorF32Adapter` FSM

| adapter state | 输出 / owner | 正常转移 |
|---|---|---|
| `AD_IDLE` | `start_ready_o=1`；F32 child held reset | start fire -> `AD_CHECK` |
| `AD_CHECK` | zero GMEM/F32 start；exact predicate combinational preflight | ABI/capability/layout/IOVA reject -> `AD_ERROR`; exact -> `AD_ENGINE_START` |
| `AD_ENGINE_START` | child reset释放；fixed resident ALU descriptor；held `f32_start_valid` | F32 start fire -> `AD_ENGINE_RUN` |
| `AD_ENGINE_RUN` | F32 child owns adapter GMEM；account matching responses | F32 done -> `AD_DONE`; F32 error -> `AD_ERROR` |
| `AD_DONE` | one-full-cycle success terminal；child同步reset=1 | closing edge由top采样，同时 -> `AD_IDLE` |
| `AD_ERROR` | one-full-cycle failure terminal；child同步reset=1 | closing edge由top采样，同时 -> `AD_IDLE` |

`AD_CHECK` 错误优先级按 §2.2；`AD_ENGINE_RUN` 中 F32 error mapping 按 §2.6。
adapter 不新增 DRAIN state，因为 accepted GMEM/ADD child 的 drain 已在
`TensorNpuF32TensorAlu.ST_DRAIN` 内完成；adapter 在 child terminal 前不得提前报错。

## 4. 阶段 2c：不变量

| ID | 触发 / 表达式 | 违反后果 |
|---|---|---|
| O1 | `legacy_fire + macro_fire <= 1`；legacy/macro/descriptor/debug admission 同拍互斥 | 双 command owner |
| O2 | macro payload 只在 `macro_fire` 更新；从 accept 到 completion handshake resident identity/descriptor/window 不变 | identity 或地址串单 |
| O3 | `adapter_start_fire` 每条 admitted macro 至多一次；`f32_start_fire` 只在 exact predicate success 且每条至多一次 | unsupported work 被执行或重复计算 |
| O4 | `ST_DMA_RUN` 与 `ST_MACRO_RUN` 互斥；public GMEM mux 任一周期最多一个 request/response-credit owner | GMEM owner corruption |
| O5 | non-owner 永远看不到 public ready/response-valid/data/error；无 owner 时 `gmem_rsp_ready_o=0` | response 被错误 engine 采纳 |
| O6 | public `valid&&!ready` 在 REQ watchdog取消边沿前 valid/payload stable；watchdog edge可令valid变0，same-cycle late ready不得fire | raw-byte address/data corruption或取消后误接受 |
| O7 | external outstanding ∈ `{0,1}`；accepted requests = matching responses + reset-cancelled，离开 RUN 时 outstanding=0 | orphan response / 跨 command credit |
| O8 | unknown kernel/epoch/deadline：F32 starts=0、GMEM bytes=0、elements=0、success completion=0 | capability 假绿 |
| O9 | ABI/layout/IOVA preflight rejection 均发生在首个 F32 start/GMEM request 前 | 非资格访问或 destination side effect |
| O10 | canonical success 的 F32 start=1、read responses=32、write responses=16、elements=16 | transaction cardinality mismatch |
| O11 | read byte counter只在 matching non-error read response增加8；write byte counter只在 matching non-error write response增加 `popcount(wstrb)` | completion 伪报 traffic |
| O12 | host memory adapter只复制 request 指定 raw bytes；host tensor op count恒为0 | host 代算 |
| O13 | completion valid backpressure期间 `is_macro/error/status/class/identity/count/hash/counters` 全部稳定 | held completion corruption |
| O14 | macro full ProducerId 64 bits原样回显；禁止通过 legacy `PID_W` 路径截断后比较 | wrong producer completion |
| O15 | failure completion无 coverage eligibility；只有 all-identity-match success 可增加 executed/covered各1 | partial/error 被计为完成 |
| O16 | legacy completion所有 macro-only字段为0；macro completion不能复用上一条 legacy identity | cross-protocol stale payload |
| O17 | timeout 或 error 后 destination success bytes不增加；accepted owner必须 drain 后 terminal | partial write 被提交或 orphan owner |
| O18 | reset清空 top/adapter/F32 resident owner和 completion valid；reset 后无 stale request/terminal | reset 后幽灵事务 |
| O19 | src0/src1/dst 三个 `[base,base+64)` window 两两不 overlap且权限正确；所有 64-bit 加法无溢出 | alias 或越界破坏 |
| O20 | unsupported required GGML node never invokes CPU kernel；`cpu_fallback_attempts=0`、`host_tensor_ops=0` | fail-open graph execution |
| O21 | successful completion identity match之前 `executed_by_verilator` 不变；每个 required node最多覆盖一次 | duplicate/mismatched coverage |
| O22 | top 只有在 adapter terminal且其 GMEM outstanding=0时进入 `ST_COMPLETE` | completion 领先 memory lifecycle |
| O23 | request在边沿t fire后无same-cycle response；首次response valid必须在t+1..t+16，随后valid/data/error held until ready | ownerless response、unbounded integration或payload漂移 |
| O24 | adapter child reset只在`AD_ENGINE_START/RUN`释放；`AD_DONE/ERROR` terminal保持一整周期并由top closing edge采样 | child residue或one-cycle terminal丢失 |

O1--O11、O13--O19、O22--O24 由 RTL immediate assertion 与 directed scoreboard 组合覆盖；
O12、O20、O21 由 runner source audit、backend unit test、completion matcher 与 counters
覆盖。文本不变量本身不是 PASS 证据。

## 5. 阶段 2d：数据通路约束

### 5.1 Resident capture 与 exact preflight

- top 为 §1.3 全部 macro command/window/identity 字段设置 resident registers，只在
  `macro_fire` 更新；adapter 再在 start fire 捕获自身 resident snapshot。两层 resident
  的目的是隔离 public pin backpressure 与 engine lifetime，不允许组合直通 host payload
  到运行中 F32 address path。
- exact predicate 比较使用显式组合网络。`base+64` 采用 65-bit/128-bit 中间值检查
  overflow；三个半开区间用 widened end 比较。任何检查失败都在 `AD_CHECK` 终止。
- `gmem_floor` 取三个 window base 的 unsigned minimum，`gmem_limit` 取三个
  `base+64` 的 unsigned maximum；每个 source/destination 独立 region bound 仍传给 F32
  engine，因此 floor/limit 间的空洞不授权访问。

### 5.2 Macro-to-resident-F32 lowering

exact predicate 通过后，adapter 对 `TensorNpuF32TensorAlu` 固定驱动：

```text
opcode_i      = 3'd0              // ALU-local ADD
dtype_i       = 2'd0              // ALU-local F32
profile_i     = 4'd0              // RNE/gradual/tininess-after/qNaN+
reserved_i    = 32'd0
op_params_i   = 64'd0

src0: region_base=src0_window_base, region_size=64, view_off=0
src1: region_base=src1_window_base, region_size=64, view_off=0
dst : region_base=dst_window_base,  region_size=64, view_off=0

src0.ne = src1.ne = dst.ne = [16,1,1,1]
src0.nb = src1.nb = dst.nb = [4,64,64,64]
gmem_floor = min(src0_base,src1_base,dst_base)
gmem_limit = max(src0_base+64,src1_base+64,dst_base+64)
```

没有 broadcast mux、scalar mux、op mux 或 host result injection。每个 element 的唯一
数值 path 是 aligned GMEM read0 -> lane select -> aligned GMEM read1 -> lane select ->
`TensorNpuFp32AddMul(op_mul=0)` -> raw result -> aligned write-data/strobe。

### 5.3 GMEM mux 与 byte accounting

- top public GMEM mux 的 select 只来自 registered `state_q`，不用 request valid 自仲裁；
  `u_dma` 与 adapter 各有完整 `{valid,write,addr,wdata,wstrb,ready,rsp}` internal bundle。
- request direction/strobe 在 adapter request fire 时进入一个 single-outstanding accounting
  register；matching response fire 后清零。response error 记录 failure，不计 completed
  byte；write popcount 仅需显式 case 覆盖合法 `0f/f0`，不能用大 function 隐藏 owner。
- byte adapter response不可与request fire同拍；accepted edge后的1--16周期首次拉高
  response valid，并保持 payload直到ready。RTL accounting owner因此必定先在request edge
  建立，下一拍以后才可能消费 response，消除 fire+ownerless response 歧义。
- 64-bit external read 会读到相邻 F32 word，但 F32 engine只选择 address[2] 对应 lane；
  destination write strobe保证另一个 lane raw bytes不变。

### 5.4 Completion data path

- top 的 parsed completion registers 是 legacy/macro 共用的唯一 RTL producer；terminal 时以
  `completion_is_macro_q` 选择 payload，之后只在 completion handshake 或 reset 更新。
- macro identity 直接来自 top resident q；status/class来自 adapter terminal mapping；
  `npu_cycles` 来自 top macro cycle counter，bytes/elements来自 adapter accounting/F32
  terminal snapshot；q8/state counters组合常零。
- backend matcher 保存 submit snapshot并逐字段比较，不从 mutable GGML tensor 重建
  identity。只有匹配后的 success 才更新 audit counters。
- 128-byte record 的 magic/version/size/reserved和completion-window publication由C++按
  §1.5完成；它们不是top output，也不属于RTL completion holder的可变字段。

### 5.5 候选 critical paths 与打拍边界

- 新增组合候选路径：macro exact comparisons + widened window end/overlap -> adapter
  next-state；该路径只在 `AD_CHECK`，不在 GMEM request ready 返回路径。
- public GMEM request path是 selected child registered payload -> top owner mux -> output；
  `gmem_req_ready_i` 只经 owner gate返回 selected child。禁止把 exact predicate或 completion
  matcher串入 ready critical path。
- 数值 critical path仍位于既有 `TensorNpuFp32AddMul`；F32 tensor ALU 的 preflight
  span/bounds与 modulo/stride path不因固定 adapter descriptor增加新组合级。本阶段不作
  综合、STA 或 PPA 声明。

## 6. 阶段 2e：RTL 级电路 topology（九项冻结）

1. **Module 边界与接口协议**
   - `TensorNpuCoprocessor`：单 `clk`、同步高有效 `rst`；既有 legacy command、
     descriptor/debug LMEM、held completion 与 64-bit GMEM ports保持；新增 §1.3 parsed
     macro valid/ready 与 §1.4 macro completion/counter ports；top parameter
     `MACRO_CAPABILITY_EPOCH=32'h00000001` 原值传给adapter。
   - `TensorNpuVectorF32Adapter`：单 `clk_i/rst_i`；top-to-adapter start/ready resident
     descriptor；adapter-to-F32 start/ready + done/error；64-bit held GMEM valid/ready；
     one-cycle terminal result。全部同一时钟域，无 CDC。
   - public completion是唯一 held channel；adapter/F32 terminal不直接暴露给 backend。

2. **所有状态寄存器**
   - top：扩展 `state_q`，新增全部 macro identity/descriptor/window resident q、
     `completion_is_macro_q`、macro status/class/payload q、macro cycle q，以及 persistent
     macro accept/F32-start/success counters；均由 top 唯一
     `always @(posedge clk)` 更新，reset为0/`ST_IDLE`。
   - adapter：`adapter_state_q`、resident predicate/window fields、GMEM accounting
     outstanding/direction/strobe、read/write byte q、terminal code/class q 与 F32 start
     cardinality q；均由唯一 `always @(posedge clk_i)` 更新，reset为0/`AD_IDLE`。
   - 既有 `TensorNpuF32TensorAlu` state/descriptor/walker/owner/drain/counters不修改。

3. **所有主要组合逻辑块**
   - top admission priority decode、legacy/macro completion output decode、DMA/adapter
     GMEM owner mux与non-owner input gates。
   - adapter exact ABI/capability/layout/window predicate、widened min/max/end/overlap、
     fixed F32 descriptor wiring、F32 error-to-ABI mapping、GMEM response accounting decode。
   - 所有 `always @(*)` 先给默认值；不推 latch，不用 `always_comb`。

4. **FSM 状态与状态转移**
   - top 精确采用 §3.1 八态；adapter 精确采用 §3.2 六态。两者都是 Moore terminal +
     valid/ready handshake transition。
   - top/adapter非法态均 fail-closed；已有 accepted F32 owner时由 child `ST_DRAIN`
     收口后才允许 adapter terminal，不新增旁路 terminal edge。

5. **Pipeline stage 与 valid/ready 流向**
   - 无 macro 多命令 pipeline。寄存边界为 public macro accept -> top resident ->
     adapter resident/preflight -> F32 resident -> GMEM/FP child逐元素 -> adapter terminal
     snapshot -> top held completion。
   - backpressure点为 public macro ready、adapter start ready、F32 start ready、GMEM
     request/response ready和public completion ready；每一级 resident valid在消费前保持。
     GMEM REQ valid只有在watchdog取消边沿可在未fire时撤销；response禁止same-cycle并按
     `B_rsp=16`/held-until-ready合同返回。

6. **Flush/stall/kill/reset 优先级**
   - 本接口无独立 flush/kill；同步 `rst` 是唯一取消，优先级最高。
   - 运行优先级固定 `reset > illegal/wrong-owner > GMEM error > timeout > predicate
     rejection > normal`。GMEM request stall在watchdog edge前由child held valid处理，
     watchdog edge可取消unaccepted request；completion stall由top holder处理。sticky error
     clear只在 `ST_ERROR_HOLD` 生效，不能与 active owner竞争。

7. **资源复制或共享**
   - `u_dma` 与 `u_vector_f32_adapter` 共享唯一 public 64-bit GMEM port；top `state_q`
     提供显式 mux select、request enable、ready/response gate。没有组合 valid arbitration。
   - adapter独占一个既有 `TensorNpuF32TensorAlu` instance；该 engine再独占一个
     `TensorNpuFp32AddMul`。16个元素串行复用同一 FP32 add与GMEM port，不复制16份算术。
   - legacy `u_mm2`/LMEM结构保持；macro不共享或占用LMEM。

8. **可能的 critical path**
   - adapter preflight：enum/flag比较 -> 65/128-bit window end -> overlap/permission ->
     next-state；只在独立 CHECK cycle。
   - top traffic：child registered GMEM payload -> 2:1 owner mux -> public port，以及 public
     ready -> owner gate -> child；不得串入 descriptor comparison。
   - arithmetic：既有 FP32 child unpack/align/add/normalize/round；本合同不改变且不声称
     STA/PPA。completion identity comparator位于 C++ backend，不进入 RTL critical path。

9. **Function 与显式硬件划分**
   - top/adapter FSM、admission、owner mux、valid/ready、timeout/error mapping、completion
     hold必须写成显式 `always @(posedge ...)` / `always @(*)` / `assign` 网络，禁止 function。
   - 只允许小型纯组合 helper（例如 8-bit strobe popcount或无溢出比较）；window
     arbitration、permission与overlap仍显式可见。production `.v` 使用 Verilog-2001，
     不使用 `logic/always_ff/always_comb`。
   - C++ raw-byte read/write helper只做 bounds/permission/memcpy式 byte movement；不得包含
     float、tensor loop或oracle computation。

## 7. Topology 自审与阶段边界

### 7.1 自审结论

- **端口闭合**：macro command 的 ABI control、full identity、exact vector fields 与
  IOVA grant均有明确生产者；capability epoch固定为32'h1且top parameter/C++ constant同值；
  RTL completion具备ABI所需parsed identity、coverage和计数，legacy completion有明确零化
  规则，完整record framing明确由C++序列化。
- **owner 闭合**：legacy优先 admission避免 simultaneous-valid deadlock；top state而非
  request valid选择 DMA/adapter，non-owner response被物理 gate，外部GMEM仍唯一 outstanding。
- **复位/优先级闭合**：top、adapter与F32 engine共享同步 reset；accepted child transaction
  只由既有 owner-tagged drain收口；error completion仍走原有 held/sticky生命周期。
- **数据面闭合**：macro ABI enum到F32 engine enum显式转换；三个64-byte window降为
  固定 resident descriptor；host只搬 raw bytes，结果只能来自既有 FP32 RTL child。
- **coverage闭合**：submitted identity在top resident后原样回显；backend必须在 success和
  全字段匹配后才增加 executed/covered；failure、metadata与unsupported node均无资格。
- **timeout闭合**：v1明确拒绝动态 deadline，固定 child watchdog提供 bounded terminal；
  ready-low timeout在首个accepted request前结束，无destination commit或残留owner；
  accepted request的bounded terminal明确依赖byte adapter `B_rsp=16`与held response合同，
  不再从无二次watchdog的`ST_DRAIN`越级外推。

### 7.2 已知未知项、反例与替代解释

- `macro_abi_valid_i` 是解析后 control proof；完整 malformed header/parameter 的拒绝证据
  必须由 C++ parser定向测试提供，不能由本 RTL predicate外推。若要求 RTL直接解析128-byte
  blocks，需要新增 port/路径合同，属于 scope extension。
- v1 completion read bytes按实际64-bit bus response计为256，而不是两个tensor的128
  semantic bytes；write bytes按有效strobe计为64。若消费者把两者都定义为semantic bytes，
  必须先修订 ABI计数语义，不能在runner中临时改口径。
- 公共 command ABI 允许一般 FP32 IOVA 只做 4-byte alignment；本 wedge 的 capability
  明确更窄并要求三个 64-byte window base 全部 8-byte aligned。若 base 为
  `4 mod 8`，首/末 64-bit read beat会触及精确 window 外的相邻4 bytes，因此 backend
  support/lowering、adapter preflight与byte-adapter注册必须一致拒绝，不能先宣告support
  再依靠child或memory bridge失败。
- 同拍出现 legacy与macro valid时采用 legacy priority，不是协议错误。替代设计“both-valid
  均不ready”会形成可持续死锁，“macro priority”会改变既有legacy可接受时序，因此不采用。
- adapter不自建 drain；若后续在adapter层增加其自身accepted transaction或动态 cancel，必须
  新增 owner-tagged drain state，不能继续沿用当前六态解释。
- 若其它集成环境不能证明accepted response在1--16 cycles出现并held until ready，bounded
  completion保持GAP；延长runner wall-clock或等待`ST_DRAIN`不构成硬件证明。
- 18个 canonical manifest nodes 具有相同静态 predicate，但本任务冻结的成功 evidence只是一条
  `node_count=1` directed transaction。未逐节点闭合的其它实例不能因 shape相同自动提升为
  full-manifest PASS。

### 7.3 写 RTL 前门槛

本文九项 topology 自审通过，可作为后续阶段 3 的候选输入；当前仍停在 topology freeze。
只有 primary agent 明确确认后，才能创建/修改 `TensorNpuVectorF32Adapter.v`、
`TensorNpuCoprocessor.v` 或 `tensor_npu_defs.vh`。后续 RTL 必须逐条映射 O1--O24，
并以一次冻结的 O3/no-assert/no-trace Verilator build/run、positive raw-bit oracle、
unknown-kernel/out-of-range/timeout 三个独立负向配置和 fail-closed receipt 提供真实证据。

## 8. v8 semantic-permission repair 与 exact-warning census 冻结

本节冻结 `qwen-f32-add-owner-v8`。v6 已消费唯一一次 fresh build identity，Verilator
generation、model make 与 backend make 均成功，但在正式 elaboration membership 和
binary invocation 之前由 warning gate 于 `direct-build-evidence-audit` fail-closed。
v6 的 `run.status` 固定为
`FAIL rc=1 stage=direct-build-evidence-audit evidence_complete=0 cleanup_rc=0`；v8 不重跑、
不修改、也不追认该 identity。v7 因首个 material 路径 `ENOENT` 而零写入、零 preflight、
零 build，是不可续跑的历史 GAP。v8 以独立 preflight 和新的唯一 build identity继续。

### 8.1 阶段 1：需求与接口边界

1. v6 Verilator primary diagnostics 证明 `TensorNpuVectorF32Adapter` 的三个 resident
   permission register 保存了永不参与 admission 的位：`src0_window_perm_q[1]`、
   `src1_window_perm_q[1]` 与 `dst_window_perm_q[0]`。根因是 resident state 宽于实际
   permission 语义，不是缺少消费者。
2. 将上述三个 2-bit resident register 分别替换为 1-bit
   `src0_window_readable_q`、`src1_window_readable_q` 和
   `dst_window_writable_q`。同步 reset 写 `1'b0`；`start_fire_w` 分别捕获外部
   `src0_window_perm_i[0]`、`src1_window_perm_i[0]` 与
   `dst_window_perm_i[1]`；`iova_reject_w` 只消费这三个语义 bit。
3. 外部 `src0_window_perm_i/src1_window_perm_i/dst_window_perm_i` 仍为 2 bits，
   `TensorNpuCoprocessor` 的 resident command 与 C++ command driver 均不变。source 的
   write permission 和 destination 的 read permission 对本 exact ADD capability 没有
   授权语义，因此不进入 adapter transaction state。
4. `AD_IDLE/CHECK/ENGINE_START/ENGINE_RUN/DONE/ERROR`、F32 descriptor、GMEM owner、
   byte accounting、terminal mapping、assertion与全部 public port保持不变。禁止 dummy
   reduction、lint directive、path/category waiver或新增无语义 consumer。
5. 唯一 v8 elaboration 使用
   `verilator --cc -O3 -Wall -Wno-fatal --no-assert --no-trace`、model `make -j1`、
   task-scoped backend `make -j1`。同一 binary 依次运行 unknown-kernel、
   out-of-range/4-mod-8、request-ready-low 和 production；只有 production 可获得
   success commit/coverage。
6. v8 只修改本节、`TensorNpuVectorF32Adapter.v` 和自包含 runner。top、F32 child、
   FPU-SP、runtime/backend及其它 production RTL 必须由 source identity 证明字节不变。

### 8.2 阶段 2a：permission 与 evidence 协议

- permission pin 只有在 `start_valid_i && start_ready_o` 时被采样。capture 后三个
  semantic bit 在整个 resident transaction 内保持，pin-level未消费位变化不能改变
  `AD_CHECK` 或 F32 address path。
- preflight 等价式冻结为：

  ```text
  readable0 = src0_window_perm_i[0]
  readable1 = src1_window_perm_i[0]
  writable  = dst_window_perm_i[1]
  permission_reject = !readable0 || !readable1 || !writable
  ```

  该式与 v6 对实际消费位的判定逐 bit等价；`2'b11` source、`2'b11` destination仍
  可按相关 bit通过，`2'b10` source或`2'b01` destination仍必须在首个 F32 start/GMEM
  request前拒绝。
- v8 runner 的 preflight 必须在 build root 不存在且 `build_count=0` 时完成：绑定 v6
  immutable FAIL、v7零动作GAP、v8 contract/material、runner、全部 production source、
  tool、两个 pinned GGML DSO与 task-scoped `backend.mk`；运行通用 task-run-status 单测、
  runner EXIT/signal/cleanup probe、warning comparator self-test与membership comparator
  mutation。preflight只允许对Verilator执行`--getenv/--version`只读tool-identity查询；不得
  执行RTL elaboration/generation、make或binary。
- Verilator warning 只从 `%Warning-CATEGORY: path:line:column:` primary row解析，并规范化为
  `CATEGORY<TAB>repo-relative-path<TAB>line<TAB>column`。actual multiset 必须精确等于
  本节 §8.6 的25行；missing、extra、duplicate、path substitution、line substitution、
  category substitution与class collision均调用同一 comparator且必须被拒绝。
- model-make/backend-make、新 top/adapter/runtime source及 generated C++ 的 warning/error
  count必须为0。允许的25行不是 generic Verilator flag，也不是 path-only waiver；任何额外、
  缺失、重复、换行号、换路径或换 category都使唯一 build FAIL。
- execute 必须先复核 preflight artifact hashes与 source/tool/DSO identity，再将
  `build_count` 从0单调写为1。首个非预期非零立即保留 stage/rc/FAIL，不编辑、不重跑。

### 8.3 阶段 2b：状态机

production adapter 不新增状态或转移：

```text
AD_IDLE --start_fire/capture three semantic bits--> AD_CHECK
AD_CHECK --ABI/capability/layout/permission+IOVA reject--> AD_ERROR
AD_CHECK --exact predicate--> AD_ENGINE_START -> AD_ENGINE_RUN
AD_ENGINE_RUN --F32 done/error with no accounting owner--> AD_DONE/AD_ERROR
AD_DONE/AD_ERROR --> AD_IDLE
rst_i --> AD_IDLE and all three semantic bits = 0
```

permission register 不具备独立 FSM；其唯一更新使能为 reset 或 `AD_IDLE && start_fire_w`。
busy pin变化没有 capture enable，不能覆盖 resident permission。F32 accepted owner 的 drain、
terminal和clean retry仍完全由既有 engine/adapter/top状态边闭合。

### 8.4 阶段 2c：不变量

| ID | 触发 / 表达式 | 违反后果 |
|---|---|---|
| V8P1 | public permission ABI 始终为三个2-bit input；top/runtime无接口变化 | ABI/source identity漂移 |
| V8P2 | capture后 `readable0==src0_perm[0]`、`readable1==src1_perm[0]`、`writable==dst_perm[1]` | permission误授权或误拒绝 |
| V8P3 | source write bit与destination read bit不进入resident state或任何 success predicate | 无语义状态/新源码warning |
| V8P4 | busy transaction期间三个semantic q保持；reset后均为0 | pin串扰或stale grant |
| V8P5 | permission reject在F32 start与GMEM traffic前terminal；失败coverage/commit为0 | 未授权访问 |
| V8P6 | production success仍恰好1次F32 start、32 read responses、16 write responses、16 elements | 功能cardinality漂移 |
| V8P7 | Verilator actual warning multiset精确为§8.6的25行；其它build diagnostics为0 | 新警告被掩盖或legacy边界漂移 |
| V8P8 | actual `S` rows精确为21 design + 1 control + 1 tool且四类互斥 | elaboration输入身份不明 |
| V8P9 | preflight build_count=0且build root absent；execute只允许0→1一次 | 重跑污染证据身份 |
| V8P10 | 任何signal、early EXIT、cleanup failure或证据未闭合均不得写PASS | 长跑假绿 |

V8P2--V8P5 由结构性 bit-select/register网络与 source audit闭合；V8P6由 production raw-bit
transaction；V8P7--V8P10由同一自包含 runner 的 comparator、negative fixtures、status
helper与receipt闭合。文本不变量不单独构成PASS。

### 8.5 阶段 2d：数据通路约束

- permission path固定为三个外部2-bit pins -> 三个固定 bit-select -> start-fire enable的
  1-bit寄存器 -> `iova_reject_w` 三个反相项。没有宽 mux、reduction、function、额外 port或
  permission sideband。
- window base/size/end/overlap、`gmem_floor/limit`、fixed F32 descriptor、child ADD与
  GMEM accounting数据路均不变；三个semantic bit只位于独立 `AD_CHECK` permission path，
  不进入GMEM ready critical path或FP32 arithmetic critical path。
- source/tool identity在preflight与execute前后重算。third-party FPU-SP和
  `TensorNpuFp32AddMul.v`必须字节不变；25行diagnostic通过 exact location/class census
  单独分类，不能改动源文件去“清零”既有冻结边界。
- actual membership从 raw `VTensorNpuCoprocessor__verFiles.dat` 的 `S` rows取得；21个
  ordered design输入、`/usr/share/verilator/include/verilated_std.sv` control和
  `/usr/bin/verilator_bin` tool canonicalize后形成互斥 exact union。

### 8.6 immutable 25-row legacy warning census

规范化 row精确如下；顺序不授予集合外diagnostic，多重性仍必须逐行精确为1：

```text
IMPORTSTAR	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv	1	16
IMPORTSTAR	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv	2	15
IMPORTSTAR	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv	1	16
IMPORTSTAR	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv	2	15
IMPORTSTAR	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_rnd.sv	1	15
UNUSEDPARAM	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv	25	31
UNUSEDPARAM	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv	130	28
UNUSEDPARAM	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv	373	41
UNUSEDPARAM	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_wire.sv	458	36
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv	27	9
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_128.sv	28	9
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_ext.sv	7	28
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/float/fp_fma.sv	9	28
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv	25	9
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_64.sv	26	9
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv	23	9
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_32.sv	24	9
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv	21	9
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_16.sv	22	9
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv	19	9
UNUSEDSIGNAL	npu/version_0820/third_party/fpu-sp/verilog/src/lzc/lzc_8.sv	20	9
UNOPTFLAT	npu/version_0820/rtl/TensorNpuFp32AddMul.v	41	31
UNOPTFLAT	npu/version_0820/rtl/TensorNpuFp32AddMul.v	43	31
UNOPTFLAT	npu/version_0820/rtl/TensorNpuFp32AddMul.v	45	31
UNOPTFLAT	npu/version_0820/rtl/TensorNpuFp32AddMul.v	47	32
```

### 8.7 阶段 2e：RTL/evidence topology（九项）

1. **module边界与协议**：`TensorNpuVectorF32Adapter` 的 clk/reset、start/ready、外部
   2-bit permission pins、GMEM、terminal ports全部不变；v8 runner是独立preflight/execute
   evidence入口，不成为production module。
2. **状态寄存器**：仅以三个1-bit semantic q替换三个2-bit q；reset为0，更新块仍是唯一
   `always @(posedge clk_i)`，正常enable仅 `start_fire_w`。其它resident/FSM/accounting
   register不变。
3. **组合逻辑**：`iova_reject_w` 直接读取三个semantic q；window widened-end、overlap、
   lowering、error mapping和owner accounting组合块不变。所有组合网络无latch。
4. **FSM**：仍为§8.3六态；permission repair不新增状态、边、terminal或drain。
5. **pipeline/valid-ready**：public macro -> top resident -> adapter start capture -> CHECK ->
   F32 resident -> GMEM/FP child -> adapter terminal -> top held completion保持；permission只在
   adapter capture边界打拍，无新backpressure。
6. **reset/stall/kill优先级**：无flush/kill；同步reset最高，随后既有protocol/GMEM error/
   timeout/predicate/normal优先级。permission bit不产生异步取消或stall。
7. **资源复制/共享**：三个semantic bit是控制状态，不复制算术、GMEM port或F32 child；唯一
   external GMEM owner mux及16元素串行ADD资源共享不变。
8. **critical path**：permission path从2-bit pin的固定select到1-bit q，再到CHECK比较；比原
   2-bit q的单bit选择不增加组合深度。候选最长路径仍是window preflight与既有FP32 child；
   本轮不声明STA/PPA。
9. **function与显式硬件**：permission capture/reset和CHECK判断保持显式时序/assign网络，
   不用function、loop、dummy reduction或lint waiver。warning/membership comparator只存在于
   runner Python here-doc，不进入综合网表。

Topology自审：外部ABI、capture时点、reset值、permission truth table、FSM、owner与critical
path均自洽；三个未消费bit从resident硬件中删除但不改变任何被授权的transaction行为。允许进入
阶段3，只实施三个semantic register、对应reset/capture/consumer改名以及v8 evidence runner。

### 8.8 判定边界、反例与未知项

- production正向必须由真实 `ggml_backend_graph_compute` 触发 raw ADD[16]，并观测
  required `seen=assigned=enqueued=covered=executed=1`、
  `cpu_fallback_attempts=host_tensor_ops=0`、GMEM read/write/elements=`256/64/16`、
  128-byte completion identity与四周期held稳定。
- unknown kernel、4-mod-8/out-of-range IOVA、request-ready-low timeout分别在其声明class
  受控失败，成功coverage/output commit为0，并以同一binary clean recovery。
- 反例：若任一permission无关bit仍被resident保存，Verilator应产生新的adapter warning或
  source audit拒绝旧register；若相关bit接错，negative permission truth table或production
  start/traffic cardinality必须失败。generic warning suppression不是替代方案。
- 替代解释“保留2-bit q以便未来读写复用”不成立：当前exact capability只冻结两个source读和
  destination写；未来若增加in-place/读改写必须版本化扩展permission contract与测试，不能让当前
  无语义state长期驻留。
- `unknowns`：v8未执行综合/STA/PPA，25行UNOPTFLAT只作为冻结Verilator保守诊断，不证明独立
  FPU-SP数值正确性；accepted GMEM bounded terminal仍依赖`B_rsp=16`环境合同。
- `scope_extension_request`：无。当前合同路径足以完成semantic repair、preflight与唯一build。
- 即使v8全部通过，也只把同一predicate的18个canonical F32 ADD[16] nodes纳入本slice；其余
  1078 required compute/mover nodes、真实Qwen shell chat、strict system-level
  `cpu_fallback=0`、anti-hang integration与tokens/s继续为GAP。

## 9. v10 exact least-privilege permission repair 与 mode4 killer

本节冻结 `qwen-f32-add-owner-v10`。v9 在唯一 fresh
`--cc -O3 -Wall -Wno-fatal --no-assert --no-trace` build 的
`direct-build-evidence-audit` 首错处 fail-closed；25 条冻结 legacy warning 全部存在，
唯一额外项是 `TensorNpuVectorF32Adapter.v:51:24`、`:54:24`、`:57:24` 的三条
`UNUSEDSIGNAL`。它们分别对应 source permission 的 write bit 与 destination
permission 的 read bit。v9 的 `run.status`、Verilator log 与 raw `__verFiles.dat`
SHA-256 固定为
`1edbc5331002f76fdbb85eccdc8c5c5e010c027ef8920e9d77f0d04be761d240`、
`a9eac867db75b66ccfcc943e9c3b8d644d3ed8ab866ac2becf830744b1b9bd39`、
`28c227957e9d7e3a38d3d3d0987034ea6ed58b97194a69ee4f5c70b1c4378e14`；
v10 不重跑、不修改、也不追认该 build。合同 JSON 为
`tmp/contracts/qwen-f32-add-owner-v10.json`，SHA-256 为
`acf6ed5ce6626ee46ba9b344faa685a6366f1b50adab032fec9ac7084fe03bd6`；该哈希
只绑定 JSON，不绑定本文、RTL、runtime 或 evidence。

### 9.1 阶段 1：需求与接口边界

1. canonical F32 ADD[16] capability 的 permission 必须是 exact least privilege：
   `src0_window_perm_i==2'b01`、`src1_window_perm_i==2'b01`、
   `dst_window_perm_i==2'b10`。三个 2-bit public port 及 top ABI 保持不变。
2. adapter 只在 `start_fire_w` 捕获三个 full-equality predicate：
   `src0_window_permission_ok_q`、`src1_window_permission_ok_q` 与
   `dst_window_permission_ok_q`。同步 reset 全部清零；任一为 0 时在首个 F32 start、
   GMEM request 与 destination commit 前返回 `NPU_ERR_MACRO_IOVA` / ABI class 5。
3. 64 组 permission 组合中只接受 `(01,01,10)`。source/destination 的 RW `11`、
   missing `00`、方向互换以及任一额外权限均拒绝；禁止 dummy reduction、diagnostic-only
   consumer、Verilator lint directive、generic warning flag 或 path-only waiver。
4. self-test ABI 追加数值保持向后兼容的 mode4 `overpermission`；0--3 的数值与语义不变。
   mode4 仅把 src0 permission 改为 `11`，其余 descriptor、window 与 identity 全部合法，
   必须受控 IOVA 拒绝且 F32/GMEM/result work 为零、failure 恰好一次、held completion 与
   clean recovery 有效。
5. adapter 六态 FSM、F32 descriptor、owner、timeout、address/size/alignment/overlap、
   arithmetic datapath、completion layout 与 audit v1/v2 structure 均不变。top、F32 child、
   third-party FPU-SP、综合、STA、PPA、其余 kernel 与完整 Qwen graph 不在本修复范围。
6. v10 runner 以独立 fresh log/compiler/build root 实现 preflight/execute 两阶段：preflight
   证明 build count 为 0、build root 不存在、64-row permission truth table、五 mode source/
   parser、warning 与 membership comparator 负向闭包；显式 continuation 后才允许唯一 build
   和同一 binary 的四负一正配置。

### 9.2 阶段 2a：permission、runtime 与 evidence 协议

- `start_valid_i && start_ready_o` 是 permission 的唯一 capture enable。捕获表达式逐字冻结为：

  ```text
  src0_permission_ok = (src0_window_perm_i == 2'b01)
  src1_permission_ok = (src1_window_perm_i == 2'b01)
  dst_permission_ok  = (dst_window_perm_i  == 2'b10)
  permission_reject  = !src0_permission_ok || !src1_permission_ok ||
                       !dst_permission_ok
  ```

  full equality 使三个 public input 的全部六个 bit 都具有 admission 语义；busy 时 pin-level
  permission 变化没有更新 enable，不能改变 resident transaction。
- `AD_CHECK` 的 `ABI -> capability -> layout -> IOVA` 优先级不变。permission mismatch 属于
  IOVA predicate，在 F32 reset 仍 asserted 且 GMEM owner 尚未建立时进入 `AD_ERROR`。
- positive、unknown-kernel、out-of-range 与 request-ready-low mode 均驱动 `01/01/10`；
  `overpermission=4` 驱动 `11/01/10`。mode4 的其它 descriptor 字段必须与 positive 相同，
  从而把 dynamic killer 精确归因于 source0 overpermission。
- mode4 terminal 必须是 status/error code 16、error class 5、F32 start=0、GMEM request/
  response/read/write=0、vector elements/result bytes=0、success=0、failure=1；identity/framing、
  四周期 held stability 与 error-clear 后 recovery 均为 1。
- preflight 的 permission truth-table audit 必须枚举 64 组输入并只接受一组；runtime source
  audit 必须闭合 header constant、C++ enum、backend upper bound、submission permission、
  mode switch、CLI parser/name/negative oracle以及 unknown CLI mutation。warning comparator 的
  missing/extra/duplicate/path/line/category/class-collision 与 membership comparator 的
  missing/extra/substitution/class-collision必须继续被同一 production comparator拒绝。
- execute 先复核 immutable preflight receipt 与 source/tool/DSO identity，再将 build count
  唯一地从 0 写为 1。首个非预期非零立即留下 FAIL/stage/rc，禁止编辑或重跑该 identity。

### 9.3 阶段 2b：状态机

production adapter 不新增状态、owner 或转移：

```text
AD_IDLE --start_fire/capture three exact-equality bits--> AD_CHECK
AD_CHECK --permission mismatch among other IOVA predicates--> AD_ERROR(IOVA)
AD_CHECK --all exact predicates--> AD_ENGINE_START -> AD_ENGINE_RUN
AD_ENGINE_RUN --F32 done/error after accounting owner clears--> AD_DONE/AD_ERROR
AD_DONE/AD_ERROR --> AD_IDLE
rst_i --> AD_IDLE and all permission_ok bits = 0
```

`permission_ok_q` 没有独立 FSM；它们只在 reset 或 `AD_IDLE && start_fire_w` 更新。
mode4 在 `AD_CHECK` 直接结束，因此不能进入 F32 accepted-owner drain。其它 timeout/drain、
terminal 与 clean retry 状态边保持既有合同。

### 9.4 阶段 2c：不变量

| ID | 触发 / 表达式 | 违反后果 |
|---|---|---|
| V10P1 | public permission ABI 始终为三个 2-bit input，0--3 mode 数值不变 | ABI 漂移 |
| V10P2 | `src0_permission_ok_q` 当且仅当 captured src0 为 `01` | source 误授权/误拒绝 |
| V10P3 | `src1_permission_ok_q` 当且仅当 captured src1 为 `01` | source 误授权/误拒绝 |
| V10P4 | `dst_permission_ok_q` 当且仅当 captured dst 为 `10` | destination 误授权/误拒绝 |
| V10P5 | 64-row truth table 的 accepted set 精确为 `{01/01/10}` | least-privilege 漂移 |
| V10P6 | capture 后三 bit 在 resident transaction 内保持；reset 后全零 | pin 串扰或 stale grant |
| V10P7 | permission reject 在 F32 start/GMEM traffic 前 terminal，失败 coverage/commit 为零 | 未授权访问 |
| V10P8 | mode4 只改变 src0 `01->11`，terminal 精确为 status16/class5 | killer 归因不明或 class 漂移 |
| V10P9 | production success仍为1次F32 start、32 read responses、16 write responses、16 elements | 正向 cardinality 漂移 |
| V10P10 | actual warning multiset精确为冻结25行；新源码/generated C++/make error-warning为0 | warning 假绿 |
| V10P11 | actual `S` rows精确为21 design + 1 control + 1 tool，四类互斥 | elaboration身份不明 |
| V10P12 | build count只允许0->1；signal/early EXIT/cleanup或证据缺失不得写PASS | 长跑假绿 |

V10P2--V10P7 由 full-equality register网络、64-row source audit与 mode4 dynamic killer共同
闭合；V10P8--V10P12 由同一 binary 的五配置、warning/membership comparator、status helper
和 final receipt闭合。文本不变量本身不是 PASS 证据。

### 9.5 阶段 2d：数据通路约束

- permission path固定为三个 2-bit input -> 三个 2-bit equality comparator ->
  `start_fire_w` enable 的三个 1-bit q -> `iova_reject_w` 三项反相 OR。不存在未消费 bit、
  宽 resident permission register、dummy reduction、function 或 sideband。
- window base/size/end/overlap、`gmem_floor/limit`、fixed F32 descriptor、FP32 child 与 GMEM
  accounting不变。permission comparator只进入独立 `AD_CHECK`，不进入 GMEM ready path、
  FP32 numerical path或completion holder critical path。
- runtime `macro_submission` 显式保存三路 2-bit permission；default为 `01/01/10`，mode4
  构造时只覆盖 src0为`11`，`drive_submission` 不再散落 magic numeric permission。
- 预计新增最长路径仅为 2-bit equality -> resident bit（capture edge）和 resident bit ->
  IOVA reject -> next-state；既有 window widened comparison与 F32 add仍是更长候选。本轮不
  运行或声明 STA/PPA。

### 9.6 阶段 2e：RTL/runtime/evidence topology（九项）

1. **module边界与协议**：`TensorNpuVectorF32Adapter` 的 clk/reset、start/ready、三路
   2-bit permission、GMEM与terminal port不变；runtime self-test proc/version/result layout
   不变，只扩展 enum value 4；v10 runner不进入production hierarchy。
2. **状态寄存器**：以三个1-bit `*_permission_ok_q`替换 v8 的 readable/writable q；reset为0，
   唯一正常更新enable仍是`start_fire_w`。runtime `macro_submission` 新增三路permission字段，
   不是clocked RTL state。
3. **组合逻辑**：capture RHS使用三个full equality，`iova_reject_w`只消费三个ok q；window、
   lowering、mapping与accounting网络不变。C++ mode switch明确产生五个mode。
4. **FSM**：adapter仍为六态，top与F32 child状态机不变；overpermission走CHECK->ERROR，
   不新增drain或旁路terminal。
5. **pipeline/valid-ready**：public macro -> top resident -> adapter capture/CHECK -> F32 ->
   GMEM/FP child -> adapter terminal -> top held completion不变；permission只在既有capture边界打拍。
6. **reset/stall/kill优先级**：同步reset最高，随后既有protocol/GMEM error/timeout/predicate/
   normal优先级；permission错误不产生异步kill，mode4通过普通fail-closed terminal恢复。
7. **资源复制/共享**：三个2-bit comparator和三个1-bit resident control不复制GMEM、F32 child
   或算术资源；唯一GMEM owner和16元素串行ADD共享不变。
8. **critical path**：新增permission equality只在CHECK admission path；traffic ready与
   arithmetic path不变。warning/membership/runtime parser audit只存在runner Python，不进入网表。
9. **function与显式硬件**：permission capture/reset与reject保持显式时序/assign网络；禁止
   function/loop/dummy consumer/lint waiver。C++ helper只做raw byte、framing与mode control，不做FP。

Topology自审：三路full equality覆盖全部六个public permission bit；capture/reset/忙态保持、
CHECK拒绝、F32/GMEM零副作用、mode4 expected terminal及既有owner/timeout/held completion均自洽。
允许进入阶段3，只实施adapter三项 exact predicate、runtime mode4、本文与v10 evidence runner。

### 9.7 判定边界、反例与未知项

- 反例：若仍使用单 bit-select，则 source `11` 或 destination `11` 会错误通过；64-row audit和
  mode4必须检出。若用dummy reduction消费多余bit，truth table可能不变但source audit必须因缺少
  full-equality capture而拒绝。
- 替代解释“RW是更强权限所以应接受”不采用：本 capability 的安全合同是exact least privilege，
  descriptor权限同时表达调用方意图；过授权本身属于 IOVA policy violation，而不是可忽略超集。
- `unknowns`：本轮不执行综合/STA/PPA或独立FPU-SP数值证明；accepted GMEM bounded terminal仍依赖
  `B_rsp=16`与held response环境合同。
- `scope_extension_request`：无；当前合同列出的 RTL/runtime/docs/evidence 路径足以闭合本修复。
- 即使v10最终PASS，也只覆盖相同predicate的18个canonical F32 ADD[16] nodes；其余1078个
  required compute/mover nodes、strict full-graph `cpu_fallback=0`、Qwen shell chat、anti-hang
  integration与tokens/s继续为GAP。
