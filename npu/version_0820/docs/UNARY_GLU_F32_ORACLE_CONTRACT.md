# Unary/GLU F32 纯整数 raw-bit oracle 合同

## 1. 成功边界与冻结身份

本合同冻结 profile `TENSOR_NPU_UNARY_GLU_F32_RNE_V1`。它只证明四个
Unary/GLU 标量数据流、三个 F32 child primitive 和固定 JSON/JSONL 证据可以由
整数与位操作重放；不证明 RTL、Verilator、综合、STA、PPA、Qwen 对话或 tokens/s。

该层把 AOR EXP32/LOG32 当作不可重结合的单个 child，并绑定：

- AOR profile：`AOR_AARCH64_FMA_RNE_V1`；
- AOR generator SHA-256：
  `d18d79a44940d2e7ce915b64bc6cf65383f2307d9d16ec792d6e4077c2d59e95`；
- AOR manifest canonical SHA-256：
  `4d7b403b5f835adfc4465f920a9322ddf71b7568aaf0f1790c84e0b81371f004`；
- AOR qualified vectors SHA-256：
  `e635c1ce963bb814f746dc828d715bd6cc39841f11ed8551aa7b15f128fcaa41`。

加载新 manifest、生成向量、重验向量和重验证据时都会重新计算这三个身份；任一变化
均 fail-closed。新 oracle 不修改、复制或替代 AOR 的 EXP/LOG 表、DAG 或 NaN evidence。

## 2. 输入 profile 与父事务语义

`SIGMOID`、`SOFTPLUS`、`SILU` 只消费 `src0`，要求 `src0` 是 F32 finite 或
signed zero。`SWIGLU` 同时消费 `src0` 与 `src1`，二者都必须 finite 或 signed
zero。被消费输入只要是 `±Inf`、qNaN 或 sNaN，就必须在任何 child request 前返回：

```text
status=UNSUPPORTED
output_raw32=00000000
child_count=0
commit_count=0
flags=00000
```

外部 NaN 因而不依赖 payload/sign 的 target 选择规则。内部 primitive 的 invalid 或
sNaN 结果按当前本地 `fpu-sp` 行为使用 canonical `7fc00000`；qNaN 不置 NV，sNaN
或 invalid 置 NV。内部 `±Inf` 是合法 IEEE 数据，不是 control error。有限输入引起的
SWIGLU 最终 overflow Inf 也是一次正常 `OK`、单次 commit 的结果。

flags 顺序固定为 `flags[4:0]={NV,DZ,OF,UF,NX}`。父层只对实际完成的 child flags
做 sticky OR；`NEG_LOCAL` 与 SOFTPLUS 快路径 bitcopy 不是 child，不贡献 flags。

常量：

```text
ONE    = 3f800000
TWENTY = 41a00000
NEG_LOCAL(x) = x XOR 80000000
```

## 3. 纯整数 F32 primitive

生产 oracle 的 AST gate 是闭合的正向 capability 策略，而不是局部 token 黑名单：允许的
AST node、逐条 import identity、module/object attribute 及 call origin 都由独立白名单冻结。
module namespace 或 callable 不得被捕获、别名化或经 subscript 动态调用；反射
`getattr/vars/globals/locals`、dunder namespace、间接 builtins/import、host
`float`/`complex`、true division、power、dynamic import/eval/exec/compile 均拒绝。
`json.loads` 只能是直接的 `json.loads(...)` call origin，并且必须同时安装固定 identity 的
duplicate-key、JSON real、JSON non-finite 三个 fail-closed hook；通过 `json.__dict__`、
别名或动态名字索引的间接调用一律拒绝。所有 CLI 以及 fixed unit 入口在执行语义工作前都
对磁盘上的 production source 运行同一 gate。实现和固定测试不导入
`math/cmath/decimal/fractions/numpy`，不调用 libm、DPI、ctypes 或 host FPU。

有限非零 F32 raw 解码为：

```text
normal:    (-1)^s * (0x800000|frac) * 2^(ef-150)
subnormal: (-1)^s * frac             * 2^-149
```

### 3.1 ADD32_RNE

两个有限项移到共同二进制指数，构造一个精确有符号整数和，只调用一次 F32 RNE pack。
精确抵消在 RN-even 下产生 `+0`；只有 `-0 + -0` 保留 `-0`。同号 Inf 直返，
`+Inf + -Inf` 为 canonical NaN/NV。

### 3.2 MUL32_RNE

两个有限 significand 先做精确整数乘法、指数相加，再只 pack 一次。signed zero 使用
sign XOR；`0*Inf` invalid，而 `Inf*Inf` 是 xor-signed Inf、flags 0。有限 overflow
产生 Inf/OF|NX。

### 3.3 DIV32_RNE

有限商保持为精确有理数：

```text
(Ma/Mb) * 2^(Ea-Eb)
```

对任意候选舍入网格 `G`，只用移位和 `divmod` 计算商、余数，再以
`2*remainder` 与 divisor 比较执行 retained-even RNE。没有 host real 近似，也没有
先把倒数舍入。`Inf/0` 是 signed Inf、flags 0；只有有限非零除以 zero 置 DZ；
`0/0` 与 `Inf/Inf` invalid。

### 3.4 tininess-after 的两阶段整数规则

ADD/MUL 复用已修正的 AOR `pack_f32`；DIV 的 exact-rational pack 独立实现同一规则：

1. 把 exact value 舍入到 24-bit precision，同时暂时假定 exponent range 无界；
2. 用该临时结果判断舍入后是否仍小于 minimum-normal；
3. 丢弃临时结果，从 exact value 直接舍入到最终 normal/subnormal 网格；
4. final inexact 且步骤 2 仍 tiny 才置 `UF|NX`。

因此不能从 final exponent field 反推 UF。临时 24-bit 结果仍 tiny、但最终 subnormal
网格进位到 `00800000` 时仍应 `UF|NX`。这一点与
[Berkeley SoftFloat FAQ](https://www.jhauser.us/arithmetic/SoftFloat-3/doc/SoftFloat-FAQ.html)
讨论的 tininess-after 临界情况一致。

当前本地 fixed-commit `fpu-sp` 布尔 profile 的不可删 operational regression 包括：

| primitive | operands | result | flags |
|---|---|---|---|
| MUL | `00800000 * 3f7ffffe` | `007fffff` | none |
| MUL | `00800000 * 3f7fffff` | `00800000` | UF\|NX |
| MUL | `80800000 * 3f7fffff` | `80800000` | UF\|NX |
| MUL | `00000001 * 3f000000` | `00000000` | UF\|NX |
| MUL | `Inf * -Inf` | `-Inf` | none |
| MUL | `0 * Inf` | `7fc00000` | NV |
| DIV | `Inf / 0` 与 `-Inf / 0` | signed Inf | none |
| DIV | finite / 0 | signed Inf | DZ |
| DIV | `0/0`、`Inf/Inf` | `7fc00000` | NV |
| DIV | `00800000 / 3f800001` | `007fffff` | UF\|NX |
| DIV | `00800000 / 3f7fffff` | `00800001` | NX |
| DIV | `1/3` | `3eaaaaab` | NX |

这里 special `kind` 与有限 significand 必须分开分类；Inf 的解码 magnitude 也为 0，
不得用 `magnitude==0` 代替 `kind==zero`。

## 4. 四个固定 DAG

每个列出的节点都必须 materialize 为 F32 raw，并作为一个独立 child 记录。禁止融合、
拆分、交换角色或重结合。

### 4.1 SIGMOID

```text
e = AOR_EXP32(NEG_LOCAL(src0))
d = ADD32_RNE(ONE,e)
y = DIV32_RNE(ONE,d)
```

`src0=c2c80000`（-100）时 `e=+Inf,OF|NX` 合法，`d=+Inf`，最终
`y=+0`，sticky `OF|NX`。

### 4.2 SOFTPLUS

ordered finite `src0 > 41a00000` 时直接 raw bitcopy，0 child、0 flags、1 commit。
比较是严格 `>`；`419fffff`、`41a00000`、`c1a00000` 都走：

```text
e = AOR_EXP32(src0)
d = ADD32_RNE(ONE,e)
y = AOR_LOG32(d)
```

`41a00001` 才走快路径。尤其 `41a00000` 必须留下三个 child，而不能只比较最终 raw。

### 4.3 SILU

```text
e = AOR_EXP32(NEG_LOCAL(src0))
d = ADD32_RNE(ONE,e)
y = DIV32_RNE(src0,d)
```

禁止替换成 `MUL32(src0,DIV32(ONE,d))`。`src0=c2c80000` 时内部 Inf 合法，最终
为 `-0`，sticky `OF|NX`。

### 4.4 SWIGLU

```text
e = AOR_EXP32(NEG_LOCAL(src0))
d = ADD32_RNE(ONE,e)
s = DIV32_RNE(src0,d)
y = MUL32_RNE(s,src1)
```

`src0` 是 nonlinear gate 输入，`src1` 是 linear up 输入。必须先 materialize `s`；
禁止 `(src0*src1)/d`、FMA、任意重结合或交换两个外部 source role。最终 MUL 的 signed
zero 由 materialized `s` 与 `src1` 的 sign XOR 决定。

## 5. 有界 mutation 首 witness

搜索按 manifest 中 domain list、每个 anchor 的 unsigned raw 升序、再 gate list 顺序
进行。18 个 SILU anchor 各扫描包含端点的 `±2048 raw`，去重并过滤非 finite 后共有
`69652` 个候选。SWIGLU reassociation 的完整域是这些候选与 10 个固定 gate 的
`696520` 个有序 pair；role swap 域含 4 个有序 pair。命中首 witness 即停止，GAP
则必须耗尽对应完整域。

当前纯整数 bounded audit 的首 witness：

1. `SILU_RECIPROCAL_MUL`：检查 6155 个候选后命中 `src0=3a7ff807`。
   `d=3fffe005`；strict direct DIV=`3a000c03`，mutant reciprocal=`3f000fff`
   再 MUL=`3a000c02`。两侧 sticky 都为 NX，但 final raw 不同。
2. `SWIGLU_NUMERATOR_FIRST`：检查 13 个 pair 后命中
   `src0=00000001,src1=40000000`。strict 先 DIV 得 `s=00000000`，再 MUL 得
   `00000000,UF|NX`；mutant 先 MUL 得 numerator `00000002`，再 DIV 得
   `00000001,NX`。
3. `SWIGLU_ROLE_SWAP`：第 1 个 pair `src0=3f800000,src1=40000000` 即命中。
   strict final=`3fbb26a8`；把 linear up 与 nonlinear gate 角色交换后
   final=`3fe17bea`，两侧 sticky 都为 NX。

canonical mutation audit 还绑定两侧 child count/opcode、每个 materialized stage 的
raw/flags、candidate count、完整 domain/order 和 final sticky flags。当前 3 witness、
0 GAP；若未来身份变化后重搜无命中，只能记录
`GAP_NO_WITNESS_IN_BOUNDED_DOMAIN`，不得声称等价。

## 6. 向量与 exact-byte verifier

qualified JSONL 第一行是 metadata，其后固定 60 个 case。每个 case 严格记录：

- operation、两个 source raw 及 source role recipe；
- `expected_status/expected_error/output_raw32/commit_count`；
- exact child count/order/opcode；
- 每个 child operands、materialized 名、result raw、child flags；
- AOR child 的完整内部 trace SHA-256；
- 父事务 sticky flags。

集合包含四个 op 的普通正/负与 `±0`、`±minsub`、-100 内部 Inf、SOFTPLUS 三个
阈值点与 -20、SWIGLU signed zero/source role、两个计算图 mutation witness、role-swap
witness、有限 overflow Inf，以及每个 op 的外部 `±Inf/qNaN/sNaN` preflight 拒绝。
另外两项 primitive differential 固定
`00800000*3f7fffff -> 00800000,UF|NX` 及其负号镜像。

`verify-vectors` 不只逐字段检查；它会用当前 manifest 和 generator 重建完整有序
payload，并要求输入 bytes 逐字节相等，包括 60 个 membership/order、所有 recipe、
JSON 精确类型、字段白名单和末尾换行。改 recipe、替换/删除/重排 case、未知字段、
bool 冒充 integer、JSON real、畸形 JSONL 或无末尾换行都 fail-closed。

## 7. CLI 与 evidence-v2

固定 CLI：

```text
validate-manifest
self-test
audit-mutations --output <owned tmp path>
emit-vectors --output <checked-in vector or owned tmp path>
verify-vectors --input <path>
verify-evidence --evidence <owned receipt>
```

所有错误只输出一行 canonical machine-readable FAIL JSON、rc2、无 traceback。
evidence-v2 绑定 generator、test、manifest file、vectors、contract、canonical mutation
audit 和每个最终命令 log SHA；同时重复绑定 AOR 三重 identity。命令 rc 字段的语义
明确为外部 Codex exec 的观测，log bytes 本身不能证明 parent wait status。

`verify-evidence` 重新计算所有 artifact/log SHA、manifest/vector exact payload、mutation
audit exact payload、case/test/witness/GAP 数和成功边界。每条成功 log 必须恰好等于一行
canonical JSON 加末尾换行；expected object 由当前 generator、manifest canonical/file、
vectors、audit 身份与 `60 vectors / 28 self cases / 3 witness / 0 GAP / 23 of 23 unit
without skip / 6 artifacts / 7 commands` 分命令推导。receipt 中 command identity、完整 args、
timeout、外部 rc authority 也逐字冻结。因此旧 PASS log 即使被换入且同步更新 SHA，或仅改
count/identity/marker/字段/末尾换行，仍会被 exact-payload verifier 拒绝。其自身 log
与 fixed unit-test 的两个 log SHA 只允许 bootstrap 时临时为 null；最终 receipt 必须绑定
两者，并在不使用 bootstrap 参数时再次通过。bootstrap unit 本身仍必须运行全部方法且
不得 skip。

evidence 另绑定修复前的 shadow diagnostic：旧 checker 曾接受间接 JSON callable capture、
动态 builtins lookup 与反射；该日志只证明被观察到的 pre-fix 漏洞，不是成功证据。

## 8. 未关闭范围

- 没有运行或宣称 RTL/Verilator PASS；
- 没有运行综合、STA、PPA；
- 没有运行 Qwen 模型或测量 tokens/s；
- 未提供本轮未授权上游 RTL 文件逐文件 SHA；
- 本 oracle 不扩大 AOR all-NaN target evidence 的成功范围。
