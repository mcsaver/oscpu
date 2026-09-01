# Qwen NPU 宏命令、GMEM 与完成协议 ABI（DRAFT v0.1）

> **DRAFT / GAP：本文是待实现、待验证的 ABI 草案，不是 RTL、RV64 接线、llama.cpp backend 或 Qwen 推理已经完成的证据。**
>
> 本文只冻结新增的“宏 descriptor”命名空间及其功能仿真协议。`docs/` 中现有扩展 ISA/PDF 所定义的 custom opcode、TCR/TR/GR、TIU/GDMA LO/HI 位域仍是既有规范；本文没有声称这些宏 kernel ID 已由 PDF 定义，也不擅自复用或修改 PDF 中的任何指令位域。后续若由 RV64 指令提交宏 descriptor，指令位域到 descriptor IOVA 的绑定必须在单独的 CPU/NPU 集成规范和 RTL 中明确实现并验证。

## 1. 范围与强制约束

本 ABI 面向两个前端，但二者必须驱动同一套 NPU command 语义：

1. llama.cpp/ggml 动态 backend 的 Verilator 功能仿真前端；
2. `npc/rv64` 经现有扩展 ISA 提交命令的协处理器前端。

版本 0.1 只提出以下宏 kernel：

| Kernel ID | 名称 | 作用 |
|---:|---|---|
| `0x514e0001` | `GET_ROWS_Q8_0` | 从 Q8_0 权重表 gather 并反量化为 FP32 |
| `0x514e0002` | `GEMV_Q8_0_F32` | Q8_0 权重与动态 Q8_0 activation 的 batch-1 GEMV，输出 FP32 |
| `0x514e0010` | `VECTOR_F32` | FP32 elementwise、broadcast、activation 与 RoPE |
| `0x514e0011` | `REDUCE_F32` | FP32 reduction、norm 与 softmax |
| `0x514e0020` | `GDN_SCAN_F32` | 有序 Gated DeltaNet scan 与持久状态提交 |
| `0x514e0021` | `ATTN_DECODE_F32` | decode attention、RoPE、KV 更新和 online softmax |
| `0x514e0030` | `LM_HEAD_TOPK_Q8_0` | 全 vocab Q8_0 LM head 与 NPU 内 top-k/argmax |

`0x514e0000..0x514effff` 是本文**提议的 descriptor kernel namespace**，不是 RISC-V 指令编码空间。kernel ID 只能出现在本 ABI command header 中；在没有单独批准的 ISA 绑定前，禁止把它们直接解释为 PDF 中的 `opcode/funct/tsk_typ`。

所有 required 主计算必须由 Verilator 执行的 NPU 数值数据路完成。host 只允许：

- 解析模型与 tokenizer；
- 计算 shape、stride、地址、position、sequence ID 等控制标量；
- 注册 IOVA window、构造 descriptor、驱动时钟和处理握手；
- 按 GMEM 请求搬运**未经数值变换的原始字节**；
- 处理 EOS、文本流输出，以及对 NPU 返回的不超过 20 个候选执行 sampling/RNG。

host/backend/DPI 禁止执行 Q8 量化或反量化、矩阵乘、elementwise、norm、softmax、RoPE、GDN、attention、full-vocab 扫描或 top-k。禁止调用 ggml CPU kernel、BLAS 或其他 CPU 算法后伪造 NPU completion。Verilator 从 SystemVerilog 生成的模拟器代码不属于该禁令；数值语义必须能追溯到受时钟和端口约束的 NPU SV module/function。

## 2. 基本表示、端序与对齐

- 所有多字节整数和 IEEE 浮点 bit pattern 均为 little-endian。
- `u16/u32/u64` 为无符号整数；`s64` 为二补码有符号整数。
- `iova64` 是 NPU 地址空间中的 64-bit byte address，不是可直接解引用的 host pointer。
- `f16_bits` 和 `f32_bits` 分别是 IEEE-754 binary16/binary32 的原始 bit pattern。
- command header、parameter block 和 completion record 的起始 IOVA 必须至少 64-byte 对齐。
- FP32 数据地址必须至少 4-byte 对齐；Q8_0 block 地址必须至少 2-byte 对齐。
- 所有 `address + size`、`stride * count` 和 shape 乘积必须在无符号 64-bit 中无溢出；发现溢出即拒绝命令。
- `reserved` 字段在提交时必须为零。同一 major 版本内，未知 flag 或非零未知扩展字段均 fail-closed。

## 3. Command header：固定 128 bytes

每条 command 固定使用下列 128-byte header。parameter block、covered-node list 和 completion record 由 IOVA 引用，不内嵌于 header。

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 4 | `u32` | `magic` | 固定 `0x514e5055`（`QNPU`） |
| `0x04` | 2 | `u16` | `abi_major` | 本文为 `1` |
| `0x06` | 2 | `u16` | `abi_minor` | 本文为 `0` |
| `0x08` | 2 | `u16` | `header_size` | 必须为 `128` |
| `0x0a` | 2 | `u16` | `command_size` | v1.0 必须为 `128`；同 major 的扩展规则见第 13 节 |
| `0x0c` | 4 | `u32` | `kernel_id` | 第 1 节 proposed namespace 中的 kernel ID |
| `0x10` | 4 | `u32` | `flags` | 公共 command flags |
| `0x14` | 4 | `u32` | `context_id` | 隔离 KV/GDN state 和 sequence 的上下文 |
| `0x18` | 8 | `u64` | `sequence_id` | 单调或由 runtime 唯一分配的 sequence 标识 |
| `0x20` | 8 | `u64` | `producer_id` | 完整 ProducerId；completion 必须原样返回，禁止截断 |
| `0x28` | 8 | `u64` | `user_tag` | backend/CPU 的不透明 tag，completion 原样返回 |
| `0x30` | 8 | `iova64` | `param_iova` | kernel parameter block |
| `0x38` | 4 | `u32` | `param_size` | parameter block 的实际 byte 数 |
| `0x3c` | 4 | `u32` | `node_count` | 本 command 覆盖的 required ggml node 数 |
| `0x40` | 8 | `iova64` | `node_list_iova` | 按 graph 拓扑顺序排列的 `node_count` 个 `u64` node ID；`node_count=0` 时为零 |
| `0x48` | 8 | `u64` | `node_hash_lo` | covered-node hash 的低 64 bits |
| `0x50` | 8 | `u64` | `node_hash_hi` | covered-node hash 的高 64 bits |
| `0x58` | 8 | `iova64` | `completion_iova` | 可写 completion record 地址 |
| `0x60` | 4 | `u32` | `completion_size` | v1.0 必须至少为 `128` |
| `0x64` | 4 | `u32` | `capability_epoch` | backend 探测到的 NPU capability epoch；不匹配即失败 |
| `0x68` | 8 | `u64` | `deadline_cycles` | 从命令接受起的最大 NPU 周期；零表示由外层 watchdog 决定 |
| `0x70` | 8 | `u64` | `reserved0` | 必须为零 |
| `0x78` | 8 | `u64` | `reserved1` | 必须为零 |

公共 `flags`：

| Bit | 名称 | 语义 |
|---:|---|---|
| 0 | `REQUIRED` | 该 command 覆盖 required 主计算；任何不支持、执行失败或 coverage 缺失都必须使整次 graph 失败，禁止 CPU fallback |
| 1 | `FUSED` | 一条 command 覆盖多个 ggml node；必须提供完整 node list/hash |
| 2 | `RESET_STATE` | 仅允许状态 kernel 使用；请求从已定义零状态开始 |
| 3 | `COMMIT_STATE` | 状态 kernel 成功后原子发布新 state epoch |
| 4 | `PROFILE` | 请求填写 completion 的周期/字节/工作量计数；release 模式下仍不得开启 waveform/assert |
| 31:5 | — | v1.0 保留，必须为零 |

covered-node hash 冻结为：对 `node_list_iova` 指向的 little-endian `u64` 字节串计算 SHA-256，并取 digest 的前 16 bytes；按 little-endian 分别装入 `node_hash_lo/node_hash_hi`。NPU 可以原样回显该 hash；backend 必须用提交前保存的 node list/hash 做闭合审计。hash 属于控制完整性，不是模型数值运算。

## 4. 参数块公共前缀

所有 kernel parameter block 的前 8 bytes 相同：

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 2 | `u16` | `param_major` | v1 为 `1` |
| `0x02` | 2 | `u16` | `param_minor` | v1 为 `0` |
| `0x04` | 4 | `u32` | `param_size` | 必须等于 command header 的 `param_size` |

parameter block 的 kernel 类型由 command header 的 `kernel_id` 唯一决定。参数中所有 `reserved` 必须为零。

## 5. `GET_ROWS_Q8_0` parameter block：128 bytes

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 8 | — | 公共前缀 | 见第 4 节 |
| `0x08` | 8 | `iova64` | `src_q8_iova` | Q8_0 行表起始地址 |
| `0x10` | 8 | `iova64` | `row_index_iova` | row index 数组 |
| `0x18` | 8 | `iova64` | `dst_f32_iova` | FP32 输出 |
| `0x20` | 8 | `iova64` | `scratch_iova` | NPU scratch；不需要时为零 |
| `0x28` | 4 | `u32` | `row_count` | gather 行数，必须非零 |
| `0x2c` | 4 | `u32` | `elements_per_row` | 每行元素 K；必须是 32 的倍数 |
| `0x30` | 8 | `u64` | `src_row_stride_bytes` | 两个 Q8_0 行首之间的 byte stride |
| `0x38` | 8 | `u64` | `index_stride_bytes` | index 间距；必须与 index type 一致且不小于其宽度 |
| `0x40` | 8 | `u64` | `dst_row_stride_bytes` | FP32 输出行 stride |
| `0x48` | 4 | `u32` | `index_type` | `1=U32`，`2=I32`，`3=U64`；其他值拒绝 |
| `0x4c` | 4 | `u32` | `output_type` | v1 仅允许 `1=F32` |
| `0x50` | 4 | `u32` | `quant_type` | v1 仅允许 `1=Q8_0_BLOCK32` |
| `0x54` | 4 | `u32` | `kernel_flags` | v1 必须为零 |
| `0x58` | 8 | `u64` | `src_window_bytes` | 从 `src_q8_iova` 起允许读取的声明范围 |
| `0x60` | 8 | `u64` | `dst_window_bytes` | 从 `dst_f32_iova` 起允许写入的声明范围 |
| `0x68` | 24 | `u8[24]` | `reserved` | 必须为零 |

每个 index 必须在 `src_window_bytes/src_row_stride_bytes` 所描述的行数范围内。任何越界 index 都产生 terminal IOVA/range error，不允许用零行替代。

## 6. `GEMV_Q8_0_F32` parameter block：128 bytes

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 8 | — | 公共前缀 | 见第 4 节 |
| `0x08` | 8 | `iova64` | `weight_q8_iova` | Q8_0 权重矩阵，按输出行组织 |
| `0x10` | 8 | `iova64` | `activation_f32_iova` | FP32 activation |
| `0x18` | 8 | `iova64` | `output_f32_iova` | FP32 输出 |
| `0x20` | 8 | `iova64` | `scratch_iova` | NPU scratch |
| `0x28` | 8 | `iova64` | `activation_q8_cache_iova` | 可选 NPU 可写 Q8_0 activation cache；零表示只用 LMEM |
| `0x30` | 4 | `u32` | `rows_m` | 输出元素/权重行数 M，必须非零 |
| `0x34` | 4 | `u32` | `cols_k` | reduction 长度 K，必须是 32 的倍数 |
| `0x38` | 4 | `u32` | `batch_n` | v1 仅允许 `1` |
| `0x3c` | 4 | `u32` | `kernel_flags` | bit0=`CACHE_ACTIVATION_Q8`；其余为零 |
| `0x40` | 8 | `u64` | `weight_row_stride_bytes` | 每个 Q8_0 权重行的 byte stride |
| `0x48` | 8 | `u64` | `activation_batch_stride_bytes` | v1 仍须合法，batch=1 时只用于范围检查 |
| `0x50` | 8 | `u64` | `output_batch_stride_bytes` | v1 仍须合法，batch=1 时只用于范围检查 |
| `0x58` | 4 | `u32` | `scratch_bytes` | scratch 可用 byte 数 |
| `0x5c` | 2 | `u16` | `q8_block_elements` | 必须为 `32` |
| `0x5e` | 2 | `u16` | `rounding_mode` | 必须为 `1=GGML_Q8_0_REFERENCE` |
| `0x60` | 8 | `u64` | `expected_weight_bytes` | 权重可读范围/计数审计 |
| `0x68` | 8 | `u64` | `expected_activation_bytes` | activation 可读范围/计数审计 |
| `0x70` | 8 | `u64` | `expected_output_bytes` | 输出可写范围/计数审计 |
| `0x78` | 8 | `u8[8]` | `reserved` | 必须为零 |

v1 不隐式融合 bias、activation 或 residual；这些由显式 `VECTOR_F32` command 完成。这样 backend 不得因为模式不匹配而在 host 补算。

## 7. `VECTOR_F32` parameter block：128 bytes

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 8 | — | 公共前缀 | 见第 4 节 |
| `0x08` | 4 | `u32` | `vector_op` | 见下表 |
| `0x0c` | 4 | `u32` | `kernel_flags` | bit0: src1 broadcast；bit1: src2 broadcast；bit2: in-place 允许 |
| `0x10` | 8 | `iova64` | `src0_iova` | 主输入 |
| `0x18` | 8 | `iova64` | `src1_iova` | 第二输入；不用时为零 |
| `0x20` | 8 | `iova64` | `src2_iova` | 第三输入或 RoPE table；不用时为零 |
| `0x28` | 8 | `iova64` | `dst_iova` | FP32 输出 |
| `0x30` | 8 | `iova64` | `scratch_iova` | NPU scratch |
| `0x38` | 8 | `u64` | `element_count` | 每个 outer slice 的元素数 |
| `0x40` | 4 | `u32` | `outer_count` | slice 数，必须非零 |
| `0x44` | 4 | `u32` | `dtype` | v1 仅允许 `1=F32` |
| `0x48` | 8 | `s64` | `src0_stride_bytes` | outer slice stride |
| `0x50` | 8 | `s64` | `src1_stride_bytes` | outer slice stride；broadcast 时可为零 |
| `0x58` | 8 | `s64` | `src2_stride_bytes` | outer slice stride；broadcast 时可为零 |
| `0x60` | 8 | `s64` | `dst_stride_bytes` | outer slice stride |
| `0x68` | 4 | `f32_bits` | `scalar0` | op 相关 FP32 scalar |
| `0x6c` | 4 | `f32_bits` | `scalar1` | op 相关 FP32 scalar |
| `0x70` | 4 | `u32` | `scratch_bytes` | scratch 可用 byte 数 |
| `0x74` | 4 | `u32` | `rope_position` | RoPE 时为 token position；其他 op 必须为零 |
| `0x78` | 8 | `u8[8]` | `reserved` | 必须为零 |

v1 `vector_op`：`1=ADD`、`2=MUL`、`3=FMA`、`4=SCALE`、`5=RESIDUAL_ADD`、`6=SILU`、`7=SIGMOID`、`8=EXP`、`9=SOFTPLUS`、`10=RSQRT`、`11=ROPE`、`12=FILL`、`13=COPY_CONVERT_F32`。未列出的值拒绝。

RoPE 的 `src2_iova` 必须指向 NPU 可读的 FP32 sin/cos table；host 可以加载离线常量的原始字节，但禁止每 token 在 host 计算 sin/cos。

## 8. `REDUCE_F32` parameter block：128 bytes

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 8 | — | 公共前缀 | 见第 4 节 |
| `0x08` | 4 | `u32` | `reduce_op` | `1=SUM`、`2=MAX`、`3=SUMSQ`、`4=RMSNORM`、`5=L2NORM`、`6=SOFTMAX` |
| `0x0c` | 4 | `u32` | `kernel_flags` | bit0: causal mask；bit1: write normalized vector；其余为零 |
| `0x10` | 8 | `iova64` | `src_iova` | FP32 输入 |
| `0x18` | 8 | `iova64` | `aux_iova` | norm weight、mask 或零 |
| `0x20` | 8 | `iova64` | `dst_iova` | FP32 标量/向量输出 |
| `0x28` | 8 | `iova64` | `scratch_iova` | reduction scratch |
| `0x30` | 4 | `u32` | `outer_count` | reduction row 数 |
| `0x34` | 4 | `u32` | `reduce_count` | 每行 reduction 元素数 |
| `0x38` | 4 | `u32` | `inner_count` | v1 必须为 `1`；为未来轴泛化保留 |
| `0x3c` | 4 | `u32` | `dtype` | v1 仅允许 `1=F32` |
| `0x40` | 8 | `u64` | `src_outer_stride_bytes` | 输入行 stride |
| `0x48` | 8 | `u64` | `dst_outer_stride_bytes` | 输出行 stride |
| `0x50` | 8 | `u64` | `aux_outer_stride_bytes` | aux 行 stride；共享 aux 时可为零 |
| `0x58` | 4 | `f32_bits` | `epsilon` | norm epsilon；其他 op 必须为 `+0.0` |
| `0x5c` | 4 | `f32_bits` | `scale` | softmax/normalization scale；不用时为 `1.0` |
| `0x60` | 4 | `u32` | `scratch_bytes` | scratch 可用 byte 数 |
| `0x64` | 4 | `u32` | `causal_position` | causal softmax 的最大可见位置；其他 op 为零 |
| `0x68` | 24 | `u8[24]` | `reserved` | 必须为零 |

所有 reduction 按固定逻辑次序执行并使用 FP32 中间值。softmax 必须使用 FP32 `max`、`sum` 和归一化状态；至少实现 `x-max → exp → sum → reciprocal → multiply`，禁止把 exp/sum 交给 host。

## 9. `GDN_SCAN_F32` parameter block：256 bytes

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 8 | — | 公共前缀 | 见第 4 节 |
| `0x08` | 8 | `iova64` | `q_iova` | FP32 q 输入 |
| `0x10` | 8 | `iova64` | `k_iova` | FP32 k 输入 |
| `0x18` | 8 | `iova64` | `v_iova` | FP32 v 输入 |
| `0x20` | 8 | `iova64` | `beta_iova` | FP32 beta 输入 |
| `0x28` | 8 | `iova64` | `gate_iova` | FP32 gate/decay 输入 |
| `0x30` | 8 | `iova64` | `output_iova` | FP32 scan 输出 |
| `0x38` | 8 | `iova64` | `conv_state_in_iova` | FP32 depthwise-conv history |
| `0x40` | 8 | `iova64` | `conv_state_out_iova` | 成功后发布的新 conv history |
| `0x48` | 8 | `iova64` | `recurrent_state_in_iova` | FP32 GDN recurrent state |
| `0x50` | 8 | `iova64` | `recurrent_state_out_iova` | 成功后发布的新 recurrent state |
| `0x58` | 8 | `iova64` | `scratch_iova` | NPU state tile scratch |
| `0x60` | 4 | `u32` | `token_count` | decode v1 最小实现允许 `1`；不得为零 |
| `0x64` | 4 | `u32` | `head_count` | GDN head 数 |
| `0x68` | 4 | `u32` | `key_dim` | 每 head key dimension |
| `0x6c` | 4 | `u32` | `value_dim` | 每 head value dimension |
| `0x70` | 4 | `u32` | `conv_kernel_size` | depthwise conv history 长度 |
| `0x74` | 4 | `u32` | `dtype` | v1 必须为 `1=F32` |
| `0x78` | 8 | `u64` | `position` | sequence 内首 token position |
| `0x80` | 8 | `u64` | `q_token_stride_bytes` | q token stride |
| `0x88` | 8 | `u64` | `k_token_stride_bytes` | k token stride |
| `0x90` | 8 | `u64` | `v_token_stride_bytes` | v token stride |
| `0x98` | 8 | `u64` | `output_token_stride_bytes` | 输出 token stride |
| `0xa0` | 8 | `u64` | `recurrent_head_stride_bytes` | recurrent state head stride |
| `0xa8` | 8 | `u64` | `conv_head_stride_bytes` | conv state head stride |
| `0xb0` | 4 | `u32` | `scratch_bytes` | scratch 可用 byte 数 |
| `0xb4` | 4 | `u32` | `state_epoch_in` | 命令预期的 active state epoch |
| `0xb8` | 4 | `u32` | `state_epoch_out` | 成功提交后的 epoch，必须严格大于 input epoch |
| `0xbc` | 4 | `u32` | `kernel_flags` | bit0: state ping-pong；bit1: include depthwise conv；其余为零 |
| `0xc0` | 64 | `u8[64]` | `reserved` | 必须为零 |

GDN recurrent state 和 conv history 在 v1 中强制 FP32。若设置 command `RESET_STATE`，NPU 必须从语义零状态执行，而不是要求 host 计算或更新 state。若设置 `COMMIT_STATE`，completion 只能在 output/state 写入完成且新 epoch 原子发布后报告成功；发生中途错误时旧 epoch 保持 active，或将 context 标记为 poisoned 并拒绝后续命令，禁止静默使用部分更新状态。

本文尚未冻结 Qwen3.5 的具体 GDN 数学式和 tensor layout；它们必须以 pinned llama.cpp 实际 graph/operator 为实现规范补充。该项是明确 GAP，不能仅凭本参数块声称 GDN 已支持。

## 10. `ATTN_DECODE_F32` parameter block：256 bytes

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 8 | — | 公共前缀 | 见第 4 节 |
| `0x08` | 8 | `iova64` | `q_iova` | 当前 token 的 FP32 Q |
| `0x10` | 8 | `iova64` | `new_k_iova` | 当前 token 的 FP32 K |
| `0x18` | 8 | `iova64` | `new_v_iova` | 当前 token 的 FP32 V |
| `0x20` | 8 | `iova64` | `output_iova` | FP32 attention 输出 |
| `0x28` | 8 | `iova64` | `k_cache_iova` | KV K cache |
| `0x30` | 8 | `iova64` | `v_cache_iova` | KV V cache |
| `0x38` | 8 | `iova64` | `scratch_iova` | online softmax 与 tile scratch |
| `0x40` | 8 | `iova64` | `rope_table_iova` | FP32 sin/cos table；不使用 RoPE 时为零 |
| `0x48` | 8 | `u64` | `position` | 当前 token position |
| `0x50` | 4 | `u32` | `sequence_length` | 写入当前 K/V 后的可见 token 数 |
| `0x54` | 4 | `u32` | `query_head_count` | query head 数 |
| `0x58` | 4 | `u32` | `kv_head_count` | KV head 数，必须整除 query head 数 |
| `0x5c` | 4 | `u32` | `head_dim` | head dimension |
| `0x60` | 4 | `u32` | `rope_dim` | RoPE 作用维度；零表示不做 RoPE |
| `0x64` | 4 | `u32` | `cache_capacity_tokens` | KV cache 容量 |
| `0x68` | 8 | `u64` | `q_head_stride_bytes` | Q head stride |
| `0x70` | 8 | `u64` | `k_head_stride_bytes` | new K head stride |
| `0x78` | 8 | `u64` | `v_head_stride_bytes` | new V head stride |
| `0x80` | 8 | `u64` | `output_head_stride_bytes` | 输出 head stride |
| `0x88` | 8 | `u64` | `cache_token_stride_bytes` | KV cache token stride |
| `0x90` | 8 | `u64` | `cache_head_stride_bytes` | KV cache head stride |
| `0x98` | 4 | `f32_bits` | `attention_scale` | QK score scale |
| `0x9c` | 4 | `f32_bits` | `softmax_epsilon` | online softmax 防护值；正常实现可为 `+0.0` |
| `0xa0` | 4 | `u32` | `scratch_bytes` | scratch 可用 byte 数 |
| `0xa4` | 4 | `u32` | `kernel_flags` | bit0: causal；bit1: apply RoPE；bit2: commit KV；其余为零 |
| `0xa8` | 4 | `u32` | `cache_dtype` | v1 正确性配置仅允许 `1=F32` |
| `0xac` | 4 | `u32` | `arithmetic_dtype` | v1 仅允许 `1=F32` |
| `0xb0` | 80 | `u8[80]` | `reserved` | 必须为零 |

attention 必须在 NPU 内完成 QK、scale、causal mask、softmax、PV 和 GQA head 映射。online softmax 的 running max `m`、running sum `l` 和 output accumulator `o` 强制 FP32。`sequence_length=1` 可以在 RTL 内走数学等价 fast path，但仍必须写入 KV；它只证明 token-0，不能作为多 token/chat 的完成证据。

## 11. `LM_HEAD_TOPK_Q8_0` parameter block：128 bytes

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 8 | — | 公共前缀 | 见第 4 节 |
| `0x08` | 8 | `iova64` | `weight_q8_iova` | vocab×hidden Q8_0 LM-head 权重 |
| `0x10` | 8 | `iova64` | `hidden_f32_iova` | FP32 hidden vector |
| `0x18` | 8 | `iova64` | `topk_value_f32_iova` | 至少 `top_k*4` bytes 的 FP32 logits 输出 |
| `0x20` | 8 | `iova64` | `topk_index_u32_iova` | 至少 `top_k*4` bytes 的 token index 输出 |
| `0x28` | 8 | `iova64` | `scratch_iova` | activation Q8 cache 与 top-k scratch |
| `0x30` | 4 | `u32` | `vocab_size` | Qwen3.5-0.8B artifact 预期为 248320；实现仍须按字段检查 |
| `0x34` | 4 | `u32` | `hidden_size` | reduction K，必须为 32 的倍数 |
| `0x38` | 4 | `u32` | `top_k` | `1..20` |
| `0x3c` | 4 | `u32` | `kernel_flags` | bit0: greedy-only；其余为零 |
| `0x40` | 8 | `u64` | `weight_row_stride_bytes` | 每个 vocab row 的 Q8_0 stride |
| `0x48` | 8 | `u64` | `hidden_stride_bytes` | v1 必须至少为 `hidden_size*4` |
| `0x50` | 8 | `u64` | `topk_output_stride_bytes` | value/index 相邻记录的逻辑 stride，v1 必须为 4 |
| `0x58` | 4 | `u32` | `scratch_bytes` | scratch 可用 byte 数 |
| `0x5c` | 4 | `u32` | `quant_type` | v1 仅允许 `1=Q8_0_BLOCK32` |
| `0x60` | 8 | `u64` | `expected_weight_bytes` | 权重可读范围/计数审计 |
| `0x68` | 24 | `u8[24]` | `reserved` | 必须为零 |

top-k 比较规则冻结为：先按 FP32 logit 从大到小；数值相等时 token index 较小者优先。NaN 视为小于任何非 NaN；多个 NaN 之间仍按 token index 递增。NPU 必须遍历完整 vocab 并只返回不超过 20 个候选。host 不得接收完整 logits 后再做 full-vocab 扫描。任何需要全 vocab 的 repetition penalty、mask 或 logits processor 在 v1 未实现时必须禁用或使 required graph fail-closed，不能落到 CPU。

## 12. Q8_0 和 FP32 数值语义冻结

v1 `Q8_0_BLOCK32` 的每个 block 固定为 34 bytes：

| Block offset | Size | 表示 |
|---:|---:|---|
| `0x00` | 2 | IEEE binary16 little-endian scale `d` |
| `0x02` | 32 | `qs[0..31]`，每项为二补码 `int8`，无 zero-point |

反量化语义为 `x[i] = FP32(d) * FP32(qs[i])`。

`GGML_Q8_0_REFERENCE` activation 动态量化语义冻结为：

1. 对每个连续 32 元素 FP32 block 求 `amax = max(abs(x[i]))`；
2. `amax==0` 时 `d=0` 且全部 `q[i]=0`；
3. 否则以 FP32 计算 `d=amax/127`、`id=1/d`；
4. `q[i]=clamp(round_away_from_zero(x[i]*id), -127, 127)`；
5. `d` 以 IEEE binary16 round-to-nearest-even 存储；
6. block dot 先按 i=0..31 顺序形成一个精确 int32 和，再将 weight/activation 的存储 FP16 scale 转为 FP32，相乘后按 K block 地址递增顺序累加到 FP32 输出。

FP32 multiply/add 的默认 rounding 为 round-to-nearest-even。实现不得把跨 block FP32 accumulate 改成 host double，也不得通过重排归约得到未验证的不同语义。允许经过定向数值测试后在 capability 中新增其他 rounding/approximation mode，但不得静默改变 v1 mode。

GDN recurrent/conv state、norm reduction、softmax `max/sum`、attention online `m/l/o` 和 LM-head logits 强制 FP32。任何 BF16/FP16 state 或近似 SFU 都必须使用新的明确 capability/参数版本并配置误差 oracle；不能在 v1 下隐式降精度。

## 13. Completion record：固定 128 bytes

| Offset | Size | Type | 字段 | 语义 |
|---:|---:|---|---|---|
| `0x00` | 4 | `u32` | `magic` | 固定 `0x514e5043`（`QNPC`） |
| `0x04` | 2 | `u16` | `abi_major` | `1` |
| `0x06` | 2 | `u16` | `abi_minor` | `0` |
| `0x08` | 2 | `u16` | `completion_size` | `128` |
| `0x0a` | 2 | `u16` | `reserved0` | 必须为零 |
| `0x0c` | 4 | `u32` | `status` | `0=SUCCESS`；其他值为 terminal failure |
| `0x10` | 4 | `u32` | `error_class` | 第 14 节错误类别；成功时为零 |
| `0x14` | 4 | `u32` | `kernel_id` | command kernel ID 回显 |
| `0x18` | 4 | `u32` | `command_flags` | 已接受 command flags 回显 |
| `0x1c` | 4 | `u32` | `context_id` | context 回显 |
| `0x20` | 8 | `u64` | `sequence_id` | sequence 回显 |
| `0x28` | 8 | `u64` | `producer_id` | 完整 ProducerId 回显 |
| `0x30` | 8 | `u64` | `user_tag` | user tag 回显 |
| `0x38` | 4 | `u32` | `covered_node_count` | 仅 SUCCESS 时可计入闭合审计 |
| `0x3c` | 4 | `u32` | `state_epoch_out` | 状态 kernel 成功提交的 epoch；非状态 kernel 为零 |
| `0x40` | 8 | `u64` | `node_hash_lo` | 成功覆盖 node hash 回显 |
| `0x48` | 8 | `u64` | `node_hash_hi` | 成功覆盖 node hash 回显 |
| `0x50` | 8 | `u64` | `npu_cycles` | 从接受到 terminal completion 的 NPU 周期 |
| `0x58` | 8 | `u64` | `gmem_read_bytes` | 成功/失败前实际完成的 GMEM read bytes |
| `0x60` | 8 | `u64` | `gmem_write_bytes` | 成功/失败前实际完成的 GMEM write bytes |
| `0x68` | 8 | `u64` | `q8_mac_count` | 执行的 int8 MAC 数，不含失败前未执行部分 |
| `0x70` | 8 | `u64` | `vector_element_count` | vector/reduction/SFU 处理元素数 |
| `0x78` | 8 | `u64` | `state_update_count` | GDN/KV 成功写入的 state 元素数 |

completion 在 command 未完成时不得提前写入 `SUCCESS`。实现应先写计数和回显字段，最后以 release/valid 语义发布 terminal `status`。timeout、signal、GMEM error 或 Verilator异常均不得因为进程返回码为零而伪写成功。

backend/CPU 还必须维护每次 graph 的审计计数：

- `required_nodes_seen`；
- `required_nodes_assigned_to_npu`；
- `required_nodes_enqueued`；
- `required_nodes_successfully_covered`；
- `commands_accepted`、`commands_terminal_success`、`commands_terminal_failure`；
- `unsupported_required`、`cpu_fallback_attempts`；
- `coverage_missing`、`coverage_duplicate`、`coverage_hash_mismatch`；
- `rtl_failures`、`gmem_errors`、`timeout_errors`；
- 汇总 `npu_cycles/gmem_bytes/q8_macs/vector_elements/state_updates`。

## 14. 错误码分类

`status` 为非零 terminal code，`error_class` 使用下列分类；具体低级原因可在后续 minor 版本增加独立字段或日志 marker，但不得用模糊 success 代替：

| `error_class` | 名称 | 示例 |
|---:|---|---|
| 0 | `NONE` | 仅 SUCCESS |
| 1 | `ABI` | magic、major、header/command/param/completion size 错 |
| 2 | `FLAGS_RESERVED` | 未知 flag 或 nonzero reserved |
| 3 | `CAPABILITY` | kernel/epoch/模式未实现；required 时整 graph 失败 |
| 4 | `DTYPE_QUANT_LAYOUT` | dtype、Q8 block、rounding、stride、shape 不支持 |
| 5 | `IOVA_RANGE_PERMISSION` | window 未注册、越界、地址溢出或权限错误 |
| 6 | `GMEM_RESPONSE` | 总线 error、tag/last/byte-enable 协议错误 |
| 7 | `LMEM_SCRATCH` | scratch 过小、bank/layout 不可实现 |
| 8 | `STATE_SEQUENCE` | context、position、epoch、KV capacity 或 GDN state 不匹配 |
| 9 | `NUMERICAL` | 明确检测到的非法数值模式或未获支持的 NaN policy |
| 10 | `TIMEOUT` | 超过 `deadline_cycles` 或外层 watchdog |
| 11 | `INTERNAL_PROTOCOL` | command/completion/engine ready-valid 生命周期错误 |
| 12 | `COVERAGE` | node list/count/hash 不匹配、重复或缺失 |
| 13 | `FORBIDDEN_FALLBACK` | required node 被尝试交给 CPU |
| 14 | `POISONED_CONTEXT` | 先前失败留下不可安全继续的状态上下文 |

只要 command 带 `REQUIRED`，以上任一错误都必须向上返回 graph failure，禁止改写为 unsupported 后继续 CPU 执行。

## 15. IOVA window 与 GMEM 传输

backend 在提交 command 前注册 IOVA window：

`{iova_base, byte_size, permissions, window_id, generation, host_buffer_binding}`。

要求：

- 每次访问都同时检查 window generation、读写权限、下界、上界和无溢出；
- command、parameter、node list 和只读权重 window 不得被 NPU 写；completion、output 和 state-out 必须可写；
- 释放或重绑 window 必须改变 generation，旧 descriptor 随后失败；
- `iova64` 不是 raw host pointer，NPC 侧可映射到真实物理地址，Verilator 侧可映射到已注册 host buffer；
- host memory adapter 只能根据 GMEM read/write request 搬运原始 bytes。它不得检查 tensor 数值后代算，不得进行 FP/int8 转换。

功能仿真 GMEM 数据 line 提议为 512 bytes（4096 bits），配套字段至少包括：

`valid/ready, read_or_write, iova, byte_count_or_keep, tag, data[4095:0], last, error`。

Q8_0 的 34-byte block 允许跨 512-byte line，NPU 侧 block-unpack FIFO 必须正确拼接。该 512-byte line 只为降低 Verilator `eval()`/握手次数，不改变内存语义。

`npc/rv64` 集成使用 64-bit data adapter 将同一逻辑 burst 串行化为 8-byte beat，并保持地址、byte-enable、tag、last、error 和 completion 顺序等价。不得为 64-bit adapter 创建另一套数值 kernel 或由 CPU 补算。512-byte Verilator adapter 与 64-bit NPC adapter 必须通过同一命令/内存镜像的等价性测试。

## 16. Success 与 coverage 闭合

一次 graph/token 只有同时满足以下条件才可报告成功：

```text
required_nodes_seen
  == required_nodes_assigned_to_npu
  == required_nodes_enqueued
  == required_nodes_successfully_covered
```

并且：

```text
unsupported_required      == 0
cpu_fallback_attempts     == 0
coverage_missing          == 0
coverage_duplicate        == 0
coverage_hash_mismatch    == 0
commands_terminal_failure == 0
rtl_failures              == 0
gmem_errors               == 0
timeout_errors            == 0
```

只有 `status=SUCCESS`、ProducerId/sequence/context/kernel/node count/hash 全部匹配的 completion 才能增加 `required_nodes_successfully_covered`。失败 command 的部分计算、GMEM 写入或 state 更新不能计入 coverage。多个 fused command 的 node list 必须互不重叠；所有 required node 必须恰好覆盖一次。metadata-only 的 VIEW/RESHAPE 可以由 host 管理别名和 stride，但一旦发生实际 tensor 数据搬运就必须计入 NPU DMA 覆盖，不能用 host copy 隐去 required 工作。

## 17. 版本与向后兼容

- major 不匹配：无条件 `ABI` error。
- 同 major、consumer minor 大于或等于 producer minor：consumer 可接受已知最小 size；所有新增 tail bytes 必须为零，且不得改变既有字段语义。
- 同 major、producer minor 大于 consumer minor：只有 consumer 明确支持 `command_size/param_size` 的零扩展规则时才可接受，否则 fail-closed。
- `header_size < 128`、v1.0 `command_size != 128`、参数小于对应 kernel 的固定 size或 completion 小于 128，均拒绝。
- command header 的 `param_size` 必须等于参数公共前缀中的 `param_size`。
- kernel ID 与 parameter block 类型/size 必须严格匹配，禁止依靠 size 猜测 kernel。
- 未知 flag、未知 enum、非零 reserved、capability epoch 不匹配均拒绝；required command 永不降级。
- 新增 dtype、近似 SFU、F16/BF16 KV、batch GEMM 或 fused layer 必须通过新的 minor/major 和 capability 显式协商，不能改变 v1.0 语义。

## 18. 必须具备的负向测试

在任何 Qwen end-to-end PASS 之前，至少固定以下定向测试：

1. 错 magic、major、header/command/param/completion size；
2. 未知 flags、nonzero reserved、错误 capability epoch；
3. kernel ID 与 parameter block size/type 不匹配；
4. Q8 K 不是 32 的倍数、block scale 跨 512-byte line、行 stride 过短；
5. IOVA 未注册、generation 过期、读写权限错误、`address+size` 溢出；
6. scratch 过小、输出与只读权重非法 alias；
7. GDN state epoch/position 错、命令失败后旧 epoch 保持或 context 明确 poisoned；
8. attention 的 head 映射不可整除、sequence 超过 KV capacity、cache dtype 不支持；
9. `top_k=0`、`top_k=21`、相等 logit 与 NaN 的稳定 tie-break；
10. required kernel 不支持时立即失败，`cpu_fallback_attempts` 记一并使 graph 失败；
11. covered-node count/hash 错、node 重复覆盖、required node 缺失；
12. GMEM backpressure、response error、tag/last 错和 command timeout；
13. 512-byte Verilator line 与 64-bit NPC adapter 对同一内存镜像产生完全相同的输出和 completion；
14. completion buffer 只读或过小，绝不能退化成无 completion 的 success；
15. host backend 中故意启用 ggml CPU fallback 时，policy hook 必须阻止执行并报告 `FORBIDDEN_FALLBACK`。

正向证据至少应分别覆盖 Q8_0 gather、单/多 block GEMV、一个完整 FP32 MLP 子链、GDN token-0/token-1、attention seq-1/seq-2、全 vocab LM-head+top-k；单个 seq-1 fast path 不能作为 shell 对话或持久状态已完成的证据。

## 19. 当前 GAP 清单

本文没有提供以下实现证据：

- proposed kernel namespace 到现有 PDF ISA/TCR 位域的 RV64 提交绑定；
- 512-byte Verilator GMEM adapter 和 64-bit NPC adapter RTL；
- Q8_0 FP16 scale、动态 activation 量化、FP32 accumulate 数据路；
- FP32 vector/reduction/SFU、GDN、attention、top-k RTL；
- pinned Qwen3.5 graph 中 GDN/attention 的精确 tensor layout 和 op manifest；
- llama.cpp required-op scheduler hook、sampler top-k sideband和 completion coverage 审计；
- token-0/token-1 或 shell 交互的端到端 PASS；
- tokens/s 测量。

在这些 GAP 被相应 RTL/testbench/runtime 证据关闭前，本文只能作为实现接口草案，不能用作“Qwen 已在 NPU 上运行”的验收依据。
