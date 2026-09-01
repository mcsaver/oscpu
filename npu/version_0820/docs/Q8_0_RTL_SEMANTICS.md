# Q8_0 RTL 数值语义契约

> **实现契约与分层证据边界。** 本文冻结 Qwen3.5-0.8B Q8_0 路径应由 RTL/Verilator 实现的数值和行布局语义。当前 RTL 已实现 int8 block dot、精确 FP16 scale 扩展、按 b10507 括号和 block 顺序执行的 FP32 scale/accumulator primitive、单个 32-word F32 activation block 的 reference Q8_0 量化器、缓存多个 activation block并按 row-major weight stream 输出逐行 F32 的 GEMV primitive，以及一个 34-byte block到32个独立F32 lane的原子dequant primitive；定向 Verilator marker 包括 `[NPU-Q8-SCALE-ACC][PASS]`、`[NPU-Q8-QUANT][PASS]`、`[NPU-Q8-GEMV][PASS]` 和 `[NPU-Q8-DEQUANT][PASS]`。`ne[]/nb[]` 行遍历、GET_ROWS Phase B、GMEM/LMEM command、ggml backend required-op 执行与 Qwen end-to-end tokens/s 仍是 GAP。

本文的数值依据固定为 llama.cpp **b10507**、commit [`95c409c13625a23da2aa37270339ce9179215a18`](https://github.com/ggml-org/llama.cpp/tree/95c409c13625a23da2aa37270339ce9179215a18)。以后上游行为变化不得静默改变本文语义；若需要兼容另一实现，必须新增显式 rounding/capability 版本。

官方永久链接：

- [`block_q8_0`、`QK8_0` 和量化函数声明](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-quants.h)
- [reference quant/dequant](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-quants.c)
- [portable generic Q8_0 dot](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/quants.c)
- [x86 优化量化/dot 路径](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/arch/x86/quants.c)
- [CPU `MUL_MAT` 的 type-trait/activation conversion 调度](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/ggml-cpu.c)
- [`ggml_tensor.ne[]/nb[]` 定义](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/include/ggml.h)

本文只摘取必要语义并使用简洁伪代码，不复制上述源码的大段实现。

## 1. 适用范围和优先级

本契约适用于：

- Q8_0 权重的 `GET_ROWS` 反量化；
- `MUL_MAT` 中 F32 activation 到 Q8_0 的动态量化；
- Q8_0×Q8_0 generic dot 和 Q8_0 权重 GEMV；
- Qwen GGUF tensor 的 `ne[]/nb[]` 行寻址；
- `tests/vectors/q8_0_reference.json` 中 `TV0/TV1` 的 RTL oracle。

command、IOVA、GMEM 和 completion 传输见 [`QWEN_NPU_COMMAND_ABI.md`](QWEN_NPU_COMMAND_ABI.md)。若该 ABI 中的概括性文字与本文更精确的 Q8_0 数值步骤冲突，以本文为 Q8_0 数值实现依据；传输、权限和 coverage 仍以 command ABI 为准。

## 2. 34-byte block 布局

`QK8_0=32`。一个标准 `block_q8_0` 固定为 **34 bytes**，无 zero-point：

| Block byte offset | Size | 类型 | 语义 |
|---:|---:|---|---|
| `0x00` | 2 | IEEE-754 binary16，little-endian | scale `d` |
| `0x02` | 32 | `int8_t qs[32]` | 32 个二补码量化值 |

因此：

```text
sizeof(block_q8_0) = 2 + 32 = 34
dequant(i)         = fp32_from_fp16(d) * fp32(qs[i])
```

约束：

- logical row length `K` 必须是 32 的倍数；
- 每行 block 数为 `K/32`；
- reference activation quantization 的输出范围是 `[-127, 127]`，但从 GGUF 读取的合法 `int8_t` 权重字节按完整 `[-128, 127]` 解码；
- scale 可以是任意有限 binary16，包括有限负数和 subnormal；reference activation quantization 自身只生成非负 scale；
- binary16 scale 的 exponent 全 1（NaN 或 ±Inf）必须按第 6 节 fail-closed。

## 3. Reference F32→Q8_0 quantization

RTL 的 `GGML_Q8_0_REFERENCE` 模式冻结为 b10507 reference 路径，而不是运行机器自动选择的 x86 fast path。

对每个连续 32 个 F32 元素的 block：

```text
require all x[i] finite

amax = 0.0f
for i = 0..31:
    amax = max(amax, abs(x[i]))

if amax == 0.0f:
    d32 = +0.0f
    id  = +0.0f
else:
    d32 = RN32(amax / 127.0f)
    id  = RN32(1.0f / d32)

d16 = FP32_TO_FP16_RNE(d32)

for i = 0..31:
    scaled = RN32(x[i] * id)
    q[i]   = roundf_away_from_zero(scaled)
    require -127 <= q[i] <= 127
```

必须注意两个常见误实现：

1. `q[i]` 使用由完整 FP32 `d32` 得到的 `id`，**不能**先把 `d32` 舍入到 FP16，再用解码后的 `d16` 反算 `id`；
2. `d16` 的 FP32→binary16 转换使用 round-to-nearest, ties-to-even；元素整数化则使用 C `roundf` 语义，即 halfway case 远离零。

`+0.0/-0.0` 全零 block 统一得到 binary16 `+0`（bits `0x0000`）和 32 个零 q byte。若有限非零输入的 `d32` 在 binary16 转换后成为零，仍保留 reference 行为：q byte 按未舍入 `d32/id` 形成，但后续反量化和 dot 使用存储的 `d16=0`。

## 4. Dequantization 舍入

对一个已验证为有限 scale 的 block：

```text
d32 = exact_fp16_to_fp32(d16)
for i = 0..31:
    y[i] = RN32(d32 * fp32(qs[i]))
```

binary16 到 binary32 的转换是精确扩展；乘法结果按 FP32 round-to-nearest, ties-to-even。不得在 host 使用 double 反量化后再把结果传给 NPU，也不得忽略 2-byte scale 把 34-byte block 当作连续 32-byte int8 数据。

## 5. x86 halfway tie 差异

b10507 的 reference quantizer 使用 `roundf`，halfway case 远离零；x86 优化路径使用向量 nearest-integer conversion/rounding 时，halfway case通常按 ties-to-even。典型边界：

| `scaled` | reference `roundf` | x86 ties-to-even |
|---:|---:|---:|
| `+0.5` | `+1` | `0` |
| `-0.5` | `-1` | `0` |
| `+2.5` | `+3` | `+2` |
| `-2.5` | `-3` | `-2` |

因此：

- RTL v1 的 normative mode 是 reference/away-from-zero；
- 与自动选择的 x86 optimized CPU 路径做 bit-exact differential 时，必须排除精确 halfway 输入，或强制 CPU oracle 调用 reference quantizer；
- halfway 专项应作为舍入模式的负向/边界测试，不能把已知模式差异误报为随机 RTL bug；
- 若未来要支持 x86 ties-to-even，必须新增显式 rounding mode/capability，不能静默替换 reference mode。

本文件的 `TV0/TV1` 都故意避开 halfway tie，不能用它们证明 tie 行为已实现。

## 6. Non-finite 输入 fail-closed

官方 reference C 路径不构成 NaN/Inf 的安全协议。本 RTL 契约在其有限数值语义之外增加 fail-closed 要求：

- quantization 的任意 F32 activation 为 NaN 或 ±Inf：整条 block/kernel 返回 numerical error；
- Q8_0 输入 block 的 binary16 scale 为 NaN 或 ±Inf：拒绝该 block/kernel；
- scale product、scaled block term 或 FP32 accumulator 产生 NaN/±Inf：返回 numerical error；
- error command 不得产生 success coverage，不得把未验证的 partial output/state 发布为有效结果；
- 若 destination 不能缓冲到最后原子提交，completion 必须标记 context/output poisoned，后续 required command 必须拒绝使用它；
- host 不得先清洗、截断或替换 non-finite 值后继续执行。

finite subnormal、有限负 scale 和 `-0.0` 按 IEEE 语义处理，不属于错误。flush-to-zero 若未来需要，必须作为不同 capability 明确协商，v1 禁止静默 FTZ/DAZ。

## 7. Portable generic Q8_0 dot 累加顺序

对两个含 `nb=K/32` 个 block 的 Q8_0 行，RTL v1 按 portable generic 路径的逻辑顺序执行，不使用跨 block reduction tree，也不在 host 累加：

```text
acc = +0.0f

for b = 0..nb-1 in increasing address order:
    sumi = int32(0)
    for i = 0..31:
        sumi += int32(x[b].qs[i]) * int32(y[b].qs[i])

    dx = exact_fp16_to_fp32(x[b].d)
    dy = exact_fp16_to_fp32(y[b].d)

    scale_product = RN32(dx * dy)
    block_term    = RN32(fp32(sumi) * scale_product)
    acc           = RN32(acc + block_term)

result = acc
```

每个 block 内的 int32 sum 是精确整数和。即使两个输入 byte 都为 `-128`，32 项乘积仍不会溢出 int32。这里的括号顺序来自 b10507 portable generic 源码中的 `sumi * (dx * dy)`：必须先把两个 scale 相乘并舍入到 FP32，再乘精确转换后的 `sumi`；不能改成 `(sumi * dx) * dy`。例如 `sumi=262175`、`dx` half bits=`0x3c01`、`dy` half bits=`0x3fff` 时，源码顺序结果为 `0x490013dc`，错误括号顺序为 `0x490013dd`。随后按 block index 递增累加；禁止默认用 host double、跨 block pairwise tree或未声明 FMA contraction改变结果。若为提高并行度采用多 accumulator/tree，必须作为不同 numerical mode验证，不能声明为本 generic reference mode。

## 8. `MUL_MAT` 的 activation F32→Q8_0 路径

Q8_0 weight 的 b10507 CPU `MUL_MAT` type trait 选择 Q8_0 作为 vector-dot partner type。对于 F32 activation，语义路径是：

```text
F32 activation row
    -> reference quantize each 32-element block to Q8_0
    -> cache/reuse the quantized activation row
    -> Q8_0(weight row) dot Q8_0(activation row)
    -> FP32 output
```

NPU 的 `GEMV_Q8_0_F32` 必须在 RTL 内完成这条路径：

- activation 每行量化一次，可缓存在 LMEM；
- 权重逐行/逐 block 从 GMEM 流入；
- 每个输出 row 使用第 7 节 generic dot；
- batch-1 decode 的整个 M×K GEMV 是一条大 command，host 不按 tile 或 block 往返；
- C++ backend/memory adapter 只能搬原始 F32 activation 和 Q8_0 weight bytes，禁止提前量化、反量化、计算 scale 或 dot；
- 不能以“数学上等价”为由直接做 Q8 weight×F32 activation 并仍声称 bit-match 此 reference Q8_0×Q8_0 路径。

完整 runtime 可以对支持的 tensor shape声明 capability；任何未支持 batch、stride、dtype 或 layout 必须 fail-closed，不能回退 CPU。

## 9. Qwen/ggml `ne[]`、`nb[]` 行布局

对标准二维 Q8_0 weight tensor：

```text
ne[0] = K                 // 每行 logical elements，最内层/reduction 维
ne[1] = M                 // 权重行/输出维
nb[0] = 34                // 相邻 Q8_0 block 的 byte 距离，不是单个 logical element
nb[1] >= (K/32) * 34      // 相邻行 byte stride，可含 padding
```

高维 batch/broadcast 继续使用 `ne[2..3]`、`nb[2..3]`。任一 weight 行 `(i1,i2,i3)` 和行内 block `b` 的地址为：

```text
row_base   = base + i1*nb[1] + i2*nb[2] + i3*nb[3]
block_addr = row_base + b*nb[0]
```

v1 标准 Q8_0 capability 要求 `nb[0]==34`、`ne[0]%32==0`，但必须尊重 `nb[1..3]`，不得假设所有行紧密相邻。GGUF tensor 之间的文件对齐/padding 也不能被误当作 row payload。

F32 activation tensor 的最内层为 K，标准 `nb[0]==4`；对于 batch-1 GEMV，NPU将一个 F32 K-vector动态量化后与 M 个 Q8_0 weight row做 dot。输出 logical dimension为 M。实际地址必须来自 descriptor 中由 ggml `ne[]/nb[]` 转换的 byte strides，不得根据 Qwen hidden size硬编码连续布局。

Qwen3.5-0.8B 的 embedding `GET_ROWS` 同样把 token index 映射到 `i1` 行，读取该行的 `ne[0]/32` 个 34-byte block并输出 `ne[0]` 个 FP32。dense projection/LM head使用同一行规则；本模型不是 MoE，v1 不因而假定或伪支持 `MUL_MAT_ID`。

必须检查：

- `ne/nb` 乘法和地址相加不溢出 64-bit；
- 每个 row/block 均落在已注册只读 IOVA window内；
- `nb[1]` 不小于本行 payload；
- 34-byte block 跨 512-byte 功能仿真 GMEM line 时拼接正确；
- view/transpose产生非标准 `nb[0]` 时，若硬件未实现该 layout则返回 unsupported，而不是按 contiguous 误读。

## 10. `TV0/TV1` 机器 oracle

机器可读 oracle 位于 [`tests/vectors/q8_0_reference.json`](../tests/vectors/q8_0_reference.json)。该文件的 `TV0/TV1` 与本文共同冻结最小正向向量；若二者不一致，测试必须失败并先修正契约/向量，禁止让 testbench自行猜测或更新 expected。

### TV0：全零 block

| 项 | 冻结值 |
|---|---|
| input | 32 个 `0.0f` |
| scale binary16 bits | `0x0000` |
| 34-byte block | 34 bytes 全 `00` |
| self-dot block int32 sum | `0` |
| self-dot FP32 result bits | `0x00000000` |

该向量验证零 scale、零量化 byte、反量化零和 generic self-dot 零，不验证 halfway rounding。

### TV1：scale=1 的有限整数 block

输入前 8 项：

```text
[-127, -64, -1, 0, 1, 63, 64, 127]
```

其后 24 项全部为 `0.0f`。

| 项 | 冻结值 |
|---|---|
| scale binary16 bits | `0x3c00`（`1.0`） |
| 34-byte block hex | `003c81c0ff00013f407f` 后接 24 bytes `00` |
| self-dot block int32 sum | `44421` |
| self-dot FP32 result bits | `0x472d8500` |

其中 `0x81/0xc0/0xff/0x00/0x01/0x3f/0x40/0x7f` 分别是前 8 个 `int8` q byte。scale 为 1，因此 dequant 后精确恢复这 8 个整数和 24 个零；self-dot 为：

```text
(-127)^2 + (-64)^2 + (-1)^2 + 0^2
+ 1^2 + 63^2 + 64^2 + 127^2 = 44421
```

TV1 也避开 halfway tie，只验证 34-byte 布局、符号扩展、int32 dot、scale=1 的 FP32 累加和输出 bit pattern。

## 11. 最小验证门

在宣称 `GET_ROWS_Q8_0` 或 `GEMV_Q8_0_F32` 可用前，至少需要：

1. RTL block pack/unpack 对 TV0/TV1 的 34 bytes逐字节一致；
2. reference quantizer产生 TV0/TV1 指定 scale和 q byte；
3. dequantizer的每个 FP32输出与 oracle一致；
4. dot primitive的 `sumi` 分别为 0 和 44421；
5. 加入 FP16 scale和FP32累加后，self-dot输出分别为 `0x00000000`、`0x472d8500`；
6. 至少一个 multi-block向量验证 block地址递增累加顺序；
7. halfway输入分别检查 reference away-from-zero 与 x86 ties-to-even的预期差异；
8. activation NaN/Inf、weight scale NaN/Inf和FP32溢出的 fail-closed负向测试；
9. 34-byte block跨512-byte GMEM line，以及带padding的 `nb[1]` 行布局；
10. backend required-op审计证明量化、scale和dot没有由CPU/DPI代算。

当前可以报告的范围是 **dot + FP16 scale decode + generic FP32 block accumulator + reference activation quantizer + multi-block stream GEMV primitive PASS**。其中：

- `TensorNpuQ8ReferenceQuantizer` 以 raw FP32 stream 接收恰好 32 项，TV0/TV1 byte-exact；另有独立 halfway 向量证明 RMM away-from-zero；
- `d32` 非零但存储后的 `d16` 下溢为零时，q byte 仍由完整 FP32 `d32/id` 生成；
- activation NaN/Inf、scale pack overflow、reciprocal overflow、子运算数值异常、RMM 越界和三类 watchdog 均 fail-closed，且成功前不发布 partial block；
- `TensorNpuQ8StreamGemv` 已覆盖 `M=2/B=2` raw-bit oracle、完整 signed int8、result backpressure、provisional-row poison、reset cancel 和 watchdog；额外反例验证非最后一个 weight block 的 child error terminal 必须在 `WEIGHT_STREAM` 当拍被父 FSM 捕获，不能退化成 stall timeout；
- `TensorNpuQ8DequantBlock` 对 `+1/-2` scale、half subnormal、negative zero和raw `-128`逐lane raw-bit一致；所有32个乘法先进入原子buffer，只有全块成功后才按0..31发布，后期child error不会泄漏早期lane；
- 统一回归 marker 为 `[NPU-REGRESSION][PASS] tests=16 assertions=off waveform=off optimization=O3`，量化器 marker 为 `[NPU-Q8-QUANT][PASS] success=5 error=8 tv0_tv1=bit_exact ties=RMM-away scale_half_zero=unrounded-d atomic=1 reset=child-cancel timeout_defaults=48/16/512 no_host_fp=1`，stream marker 包含 `early_child_terminal=caught`，dequant marker为 `[NPU-Q8-DEQUANT][PASS]`。

这仍不等于 `GET_ROWS_Q8_0` 或完整 `GGML_OP_MUL_MAT`：stream primitive 虽已缓存 multi-block activation 并逐行消费 weight，但尚未实现 `ne/nb` 地址遍历、真实 GGUF row stride、34-byte block 跨 GMEM line、DMA/LMEM 接线、command completion 或 backend 调度。只有这些层级全部通过且 backend required-op audit 证明没有 CPU/DPI 代算后，才能报告相应算子的 PASS；在此之前 Qwen 一 token与 tokens/s 仍是 GAP。
