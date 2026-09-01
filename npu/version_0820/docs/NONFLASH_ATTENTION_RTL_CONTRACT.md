# Qwen3.5 非 Flash Attention RTL 合同

> **架构与验证合同草案。** 本文冻结 Qwen3.5-0.8B 在关闭 `FLASH_ATTN`、单 token/单 sequence 时的 KQ→softmax→VP 数据布局、mask、GQA 映射和 fail-closed 边界。它不是现有 RTL PASS；一般 softmax 数值采用显式误差合同，不冒充跨 ISA 的 llama.cpp raw-bit oracle。禁止 CPU/DPI 主计算、综合、STA 与 PPA。

固定输入：

```text
llama.cpp = b10507
commit    = 95c409c13625a23da2aa37270339ce9179215a18
model     = models/Qwen3.5-0.8B-Q8_0.gguf
model sha = 37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f
```

验收 profile 固定：

```text
--flash-attn off
-c 256
-b 1
-ub 1
type_k = F16
type_v = F16
kv_unified = false
```

`LLAMA_NPU_REQUIRED=1` 还必须在首次 reserve 前固定：

```text
flash_attn=false
auto_fa=false
fused_gdn_ar=false
fused_gdn_ch=false
auto_fgdn=false
```

固定源码：

- [Qwen full-attention graph](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/src/models/qwen35.cpp#L230-L301)
- [non-FA `build_attn_mha`](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/src/llama-graph.cpp#L2335-L2455)
- [KV cache view/stride](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/src/llama-kv-cache.cpp#L1156-L1201)
- [KV padded length](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/src/llama-kv-cache.cpp#L1142-L1153)
- [mask generation](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/src/llama-kv-cache.cpp#L1432-L1555)
- [CPU softmax order](https://github.com/ggml-org/llama.cpp/blob/95c409c13625a23da2aa37270339ce9179215a18/ggml/src/ggml-cpu/ops.cpp#L5092-L5190)

## 1. 固定 shape 与 stride

本模型 full-attention 参数：

```text
D   = 256
Hq  = 8
Hkv = 2
T   = 1
S   = 1
C   = 256
L   = 256
scale = 1/sqrt(D) = 1/16 = F32 0x3d800000
```

在 `-c 256` profile 下，KV cache physical capacity和每次图的 padded visible length均为256。未来增大 context时，L仍按256对齐；不得把“已生成token数”直接当L。

主要 tensor：

| 阶段 | dtype | `ne[0..3]` | `nb[0..3]` bytes |
|---|---|---|---|
| Qcur | F32 | `[256,8,1,1]` | `[4,1024,8192,8192]` |
| K cache view | F16 | `[256,2,256,1]` | `[2,512,1024,262144]` |
| V transposed cache view | F16 | `[256,2,256,1]` logical `[L,Hkv,D]` | `[2,131072,512,262144]` |
| Qp | F32 | `[256,1,8,1]` | `[4,8192,1024,8192]` |
| Kp | F16 | `[256,256,2,1]` | `[2,1024,512,262144]` |
| Vp | F16 | `[256,256,2,1]` | `[2,512,131072,262144]` |
| KQ/P | F32 | `[256,1,8,1]` | `[4,1024,1024,8192]` |
| VP | F32 | `[256,1,8,1]` | `[4,1024,1024,8192]` |
| pre-gate output | F32 | `[2048,1,1,1]` | `[4,8192,8192,8192]` |

GQA mapping固定为：

```text
kv_head = query_head >> 2
Q heads 0..3 -> KV head 0
Q heads 4..7 -> KV head 1
```

错误的 `query_head % 2` 必须由 directed TB 检出。

## 2. Mask 合同

T=1 mask为F32 `[L,1,1,1]`，只接受两个canonical raw值：

```text
keep = +0.0 = 0x00000000
drop = -Inf = 0xff800000
```

drop条件包括empty、异sequence和causal future。padding cell由mask屏蔽；有效cell不保证是连续前缀，因此RTL必须消费完整bitmap/mask，不得只接受valid_count。

命令preflight必须确认：

- 恰好L=256项；
- 每项仅为keep/drop canonical值；
- 至少一个keep；
- 所有Q/K/V accepted-domain数据finite；
- 地址/stride/size计算无64-bit溢出。

## 3. NPU 数值 profile

ggml图只固定K/V为F16、Q/P为F32；不同backend对dot、exp和reduction顺序不一致。v1显式选择可复现的NPU profile：

1. Q在KQ dot前由 `TensorNpuFp32ToFp16` RNE一次；
2. K、V、Q16、P16均按binary16 raw解析并精确扩为F32；
3. dot的MAC lane数、局部reduction顺序和跨beat累加顺序必须由实现合同另行固定；
4. KQ结果为F32；随后独立执行 `RN32(KQ * 1/16)`；
5. drop lane在已验证输入finite后直接写logit `-Inf`，不执行可能产生 `Inf+(-Inf)` 的运算；
6. 每head先完整求max，再完整求exp/sum，再求一次reciprocal并逐项乘；
7. P在VP dot前RNE到F16；
8. 最终2048个F32输出先进入shadow buffer，整命令成功后才原子提交。

softmax拓扑：

```text
scaled[j] = RN32(KQ[j] * 0x3d800000)
masked[j] = keep ? scaled[j] : -Inf
maxv      = max over j=0..255
e[j]      = EXP_PROFILE(RN32(masked[j] - maxv))
sum       = SUM_PROFILE(e[0..255])
recip     = RECIP_PROFILE(sum)
p32[j]    = RN32(e[j] * recip)
p16[j]    = FP32_TO_FP16_RNE(p32[j])
```

`EXP_PROFILE`、`SUM_PROFILE` 和 `RECIP_PROFILE` 尚未冻结具体实现；一般finite向量不能宣称与任意CPU/GPU backend逐bit一致。

## 4. 最小事务/FSM

推荐时分复用切片：

```text
IDLE
 -> VALIDATE_HEADER_MASK_AND_CLASSES
 -> Q_FP32_TO_FP16
 -> KQ_DOT(head=0..7, cell=0..255, d=0..255)
 -> SCALE_MASK_MAX
 -> EXP_SUM
 -> RECIP_NORMALIZE_AND_P16
 -> VP_DOT(head=0..7, d=0..255, cell=0..255)
 -> ATOMIC_COMMIT
 -> DONE
any fault -> ERROR
```

最小存储：

- 一个head的256×32-bit logit/exp scratch；
- 256×16-bit P16 scratch，可与前一buffer分bank复用；
- 2048×32-bit output shadow；
- Q16 8×256或按head转换的buffer；
- command epoch、child watchdog和sticky error。

所有 child request-valid在ready前保持；response只由匹配epoch消费。reset取消resident transaction，busy start无副作用。任何ERROR都不得发布partial output。

## 5. Bit-exact directed oracle

以下向量不依赖一般exp近似，只使用 `exp(0)=1`、drop概率0和二次幂reciprocal：

### ONE_VISIBLE

```text
Q=0, K=0
mask[0]=keep, mask[1..255]=drop
V[kv, d0, cell0]=+1h
V[kv, d1, cell0]=-2h

P[0] = F32 +1, P16=0x3c00
P[1..255] = F32 +0, P16=0x0000
Y[d0]=0x3f800000
Y[d1]=0xc0000000
```

### TWO_EQUAL_VISIBLE

```text
Q=0, K=0
mask[0]=mask[1]=keep, others=drop
P[0]=P[1]=F32 0.5, P16=0x3800
若两个V cell的d0均为+1h，则Y[d0]=0x3f800000
```

### GQA_HEAD_MAP

```text
single visible cell
V[kv0,d0,cell0]=+1h
V[kv1,d0,cell0]=-1h

heads0..3 output d0 = 0x3f800000
heads4..7 output d0 = 0xbf800000
```

### SCALE_STAGE

```text
Q一个lane=F32 +16 -> Q16 0x4c00
对应K lane=F16 +1
dot F32=0x41800000
scale后logit F32=0x3f800000
```

### fail-closed

- ALL_MASKED：ERROR，不复制release C路径的NaN传播；
- Q/K/V任一Inf或qNaN：ERROR；
- mask非canonical：ERROR；
- exp/sum/reciprocal/dot任一nonfinite或child flags：ERROR；
- reset、stage watchdog、output backpressure、busy start和epoch mismatch均需定向覆盖。

## 6. 一般 finite 数值误差合同

一般attention不能在未冻结实现前写死raw-bit oracle。未来选择exp/dot/reciprocal后，必须用离线固定raw向量和独立整数/高精度reference建立：

```text
exp error:     ULP_exp 或 max relative error
probability:   max |Prtl-Pref| 与 |sum(P)-1|
output:        |Yrtl-Yref| <= atol_y + rtol_y * sum_j |V_j*P_j|
```

阈值只能由已选primitive的定向/随机验证统计产生，不能在实现前虚构。TB运行时禁止host `real/shortreal`、DPI或libm `expf`；所有oracle预先冻结为项目内raw hex/JSON。

## 7. 规模与当前 GAP

每个token、每层full-attention的两次dot共有：

```text
2 * Hq * L * D = 2 * 8 * 256 * 256 = 1,048,576 multiply terms
softmax exp = Hq * L = 2048
```

Qwen主干有6个full-attention层。当前GAP：F16 dot engine、FP32 max/sub、exp profile、softmax sum/reciprocal、attention scratch/atomic output、KV cache DMA/stride、ROPE、command/backend与Qwen token均未实现；没有可信cycle/tokens/s、综合、STA或PPA结论。
