# AOR EXP32/LOG32 纯整数 source-replay oracle 合同

## 1. 范围与状态

本合同冻结项目内 `scripts/aor_f32_oracle.py` 的行为。该工具只重放 Arm
optimized-routines 标量 `expf`/`logf` 的固定逐操作图，不调用宿主 libm，也不把宿主
算术结果当作 oracle。

- profile：`AOR_AARCH64_FMA_RNE_V1`
- flags profile：`AOR_STEP_STICKY_V1`
- 上游 commit：`67126040cf80f956676fbf473c2d9bebdb475283`
- manifest schema：`aor-f32-exp-log-manifest-v1`
- manifest 状态：`DRAFT_BLOCKED_ON_NAN_CODEGEN_EVIDENCE`
- manifest：`tests/vectors/aor_f32_manifest.json`
- 固定向量：`tests/vectors/aor_f32_vectors.jsonl`

本交付是 Python source-replay oracle 及测试数据，不是 RTL、Verilator、Qwen 端到端或
性能验收结论，也不执行综合、STA 或 PPA。

## 2. 许可与来源边界

算法、表项和常量派生自 Arm optimized-routines 固定 commit 的：

- `math/expf.c`
- `math/exp2f_data.c`
- `math/logf.c`
- `math/logf_data.c`

manifest 明确选择上游双许可证中的 MIT 路径。实际分发源码或其实质派生物时，仍须在
项目的第三方通知中保留相应版权、MIT 许可正文、固定 commit 与上述来源路径。本合同
没有补猜上游发布包哈希。当前工作区未 vendoring 固定 commit 的一手文件，因此
`expf.c`、`exp2f_data.c`、`logf.c`、`logf_data.c`、`math_config.h`、`math_errf.c` 的
逐文件 SHA256 均是明确的 `GAP_SOURCE_FILES_NOT_VENDORED_NO_LOCAL_CONTENT_SHA256`，
不是已验证或可由 commit 字符串推导的 hash。

## 3. 不变量

### 3.1 数据表示

有限输入解码为 `sign, magnitude, exponent`，数学值为
`(-1)^sign * magnitude * 2^exponent`。零单独保留符号；Inf/NaN 在进入有限整数路径前
分类。`normalize_dyadic` 只用整数移除 magnitude 的二进制尾零。

唯一 RN-even pack 先选择格式允许的舍入网格，再依据 remainder、half 和 retained LSB
作一次舍入。格式参数如下：

| 格式 | precision | emin | emax | 最小网格 |
|---|---:|---:|---:|---:|
| binary32 | 24 | -126 | 127 | -149 |
| binary64 | 53 | -1022 | 1023 | -1074 |

tininess-after 不能用最终 encoding 是否为 zero/subnormal 代替。按照
[Berkeley SoftFloat FAQ 的 underflow-threshold 说明](https://www.jhauser.us/arithmetic/SoftFloat-3/doc/SoftFloat-FAQ.html)，
必须先把 exact dyadic 按目标 precision 做一次“暂时假定 exponent range 无界”的 RN-even
舍入；若这个非零暂时结果的绝对值严格小于 `2^emin`，则检测到 tiny。随后最终 encoding
仍须从原 exact dyadic 直接舍入到有限 exponent/subnormal 网格，禁止把暂时结果再次舍入。
最终舍入 inexact 且暂时结果 tiny 时置 `UF|NX`，所以最终 raw 即使进位到 minimum normal 也
可能带 `UF|NX`；若暂时 precision 舍入已经进位到 `2^emin`，同样的 minimum-normal 最终 raw
则只带 `NX`。官方 FAQ 的 F64 `0x380fffffe1000000` → F32 `0x00800000, UF|NX` 正是前一种
情况。RN-even 溢出仍置 `OF|NX`。

### 3.2 基础操作

- F64 ADD/SUB：两个精确有符号整数在共同指数对齐，相加后只 pack 一次。
- F64 MUL：精确 magnitude 乘积与指数和只 pack 一次。
- F64 fused-mulAdd：精确乘积和加数先在共同指数对齐，相加后只 pack 一次；禁止先舍入
  乘积。
- F32→F64、I32→F64 必须 exact，出现任何 flag 都是 fault。
- F64→F32 使用 RN-even 和 tininess-after，并采纳全部 flags。
- F64 round-integral 与 F64→I32 使用 RMM（ties-away）。round-integral 保留 `-0`；
  AOR profile 屏蔽转换本身的 `NX`，但 trace 记录 `discarded`。越过 I32 边界置 `NV`。
- `u32`、`u64`、EXP scale 加法/左移和 LOG 位运算在每个规定边界立即 modulo；LOG 的
  `k` 使用 signed 32-bit arithmetic shift right。

### 3.3 flags

`AOR_STEP_STICKY_V1` 把每个 F64 ADD/MUL/FMA 以及最终 F64→F32 的 step flags 累积成
API flags。F64→I32 的转换 `NX` 被屏蔽。trace 同时保留各步 `step_flags`，因此调用者可
区分单步异常与 API sticky 结果。

特殊路径固定为：

- `exp(-Inf)=+0`，无 flags；`exp(+Inf)=+Inf`，无 flags；
- 严格超过正溢出阈值才走 helper，得到 `+Inf, OF|NX`；
- 严格低于负下溢阈值才走 helper，得到 `+0, UF|NX`；
- `log(+1)=+0`，无 flags；`log(±0)=-Inf, DZ`；`log(+Inf)=+Inf`，无 flags。

阈值等号点必须走正常 DAG，不能误入 helper。

## 4. EXP32 固定 DAG

manifest 完整保存 32 项 table、所有 raw64 constants、raw32 thresholds、使用/未使用集合
及如下顺序：

1. F32→F64 exact；
2. 与 scaled `1/ln(2)` 相乘；
3. 对 `z` 独立执行 RMM round-integral 得到 `kd`，并且另以原始 `z` 为输入执行
   F64→I32 RMM 得到 `k`；绝不能把已经整数化的 `kd` 送入 conversion；
4. `r=z-kd`；
5. `idx=u64(k)&31`，并用 modulo-U64 的 `tab[idx] + (u64(k)<<47)` 构造 scale；
6. 严格按 manifest 的四个 FMA/MUL polynomial 节点求值；
7. 与 scale 相乘，最后 F64→F32。

该数据流逐字绑定固定 commit 的 `expf.c` 第 57--64 行：`z=InvLn2N*xd`、
`kd=roundtoint(z)`、`ki=converttoint(z)`。当 `k==0` 时 round-integral 的零符号继承
`z.sign`；这保证 `-0` 语义不被 Python 整数路径吞掉。trace 的 conversion 节点必须
记录 `source="z"`、`source_raw=z.raw` 和对 `z` 的 `discarded`；例如 `x=+1` 时该字段为
true，而对 `kd` 再转换会错误地变成 false。

## 5. LOG32 固定 DAG

manifest 完整保存 `OFF=0x3f330000`、16 对 `(invc,logc)`、polynomial constants 和所有
位常量。正 subnormal 先按 leading-one 位置精确规范化，再执行规定的 U32 exponent
adjust。主路径严格执行：

1. `tmp=u32(ix-OFF)`、`i=(tmp>>19)&15`、`k=asr32(tmp,23)`；
2. 位构造 `iz`，F32→F64 exact；
3. `r=fma(z,invc[i],-1)`；
4. `y0=fma(i32_to_f64(k),ln2,logc[i])`；
5. 按 manifest 顺序计算 `r2/q0/q1`；
6. `tail=add(y0,r)` 是独立舍入节点；
7. 最后一个 FMA 后 F64→F32。

## 6. NaN fail-closed 边界

manifest 中 compiler version、ISA revision、FPCR raw、disassembly SHA256 和 probe SHA256
均保持 JSON `null`。因此：

- qNaN 只保留“API 不置 NV”的语义；
- sNaN 与负数 LOG 只保留“API 置 NV”的语义；
- 任何上述路径都不得产生或写入具体 expected NaN raw；
- `emit-vectors --vector-profile full-special` 必须以
  `NAN_RAW_EVIDENCE_REQUIRED` 拒绝；
- qualified JSONL 以 rejection case 记录 recipe、语义 flags 与错误码，而不是猜
  `0x7fc00000`。

只有同时补齐并复核固定编译器、ISA/FPCR、反汇编和 probe 证据后，才允许另立新
manifest/profile 关闭该门禁；不得原地静默改变本 profile。

## 7. Manifest 与向量绑定

manifest loader 拒绝 duplicate key、JSON real/non-finite number、非小写或错误宽度 raw。
validator 绑定 schema、profile、source commit、DAG revision、table 长度、FP/flags
profile、NaN null evidence 以及完整 canonical content SHA256。任一项变化都 fail-closed。

JSONL 每行使用 key-sorted、无多余空白的 canonical JSON。metadata 与每个 case 都绑定：

- canonical manifest SHA256；
- generator 文件 SHA256；
- profile；
- source commit。

支持 raw 结果的 case 保存 expected raw、API flags 和逐步 trace SHA256；被 NaN evidence
门禁阻止的 case 只保存 error/flags/recipe。稳定向量中不写临时绝对路径。
`verify-vectors` 不只逐项验算：它重新构造 `build_vector_records(oracle,"qualified")` 的
完整 108-case payload，然后把 canonical JSONL（包括 metadata、membership、顺序、每个
字段、recipe 和末尾换行）与输入 bytes 逐字节比较。删换/重排 case、改 recipe、增加
未知字段、用 JSON boolean 冒充 integer 或删去末尾换行都会稳定拒绝。

源码的 integer-only 门禁由可对任意源码片段运行的 AST checker 实现。production import
集合必须与 exact allowlist 相等；Import/ImportFrom 绕过、`float`/`complex` 的 Name、
Attribute、builtins alias、complex literal、dynamic import/eval/exec/compile、true division
和 exponentiation 都被拒绝。`json.loads` 只允许直接调用，并必须恰好带受控的
`object_pairs_hook`、`parse_float`、`parse_constant` 三个 fail-closed hooks；捕获成别名也
被拒绝。所有外部 JSON/JSONL 先做 exact object/array/string/integer schema 检查，且
`type(value) is int` 明确排除 boolean。UTF-8、JSON、schema 或类型错误只产生一条
machine-readable FAIL JSON，返回码为 2，不泄露 traceback。

## 8. FMA/重结合 mutation audit

`audit-mutations` 只使用本 oracle 的整数 RN64 原语，对以下七个变换执行稳定有界搜索：

| ID | 变换 | 结果 | 首 witness raw | 已检查候选 |
|---|---|---|---|---:|
| M09 | EXP `p01` FMA 拆成 MUL+ADD | WITNESS | `0x3e7ff823` | 8230 |
| M10 | EXP `p2` FMA 拆成 MUL+ADD | WITNESS | `0x3a8000a7` | 6313 |
| M11 | EXP outer `p` FMA 拆成 MUL+ADD | GAP | 无 | 71698 |
| M12 | EXP parallel polynomial 改成 Horner | WITNESS | `0x3a7ff802` | 4100 |
| M23 | LOG `r` FMA 拆成 MUL+ADD | WITNESS | `0x3f32f800` | 1 |
| M24 | LOG `y0` FMA 拆成 MUL+ADD | WITNESS | `0x00000005` | 65557 |
| M26 | LOG final tail/FMA 重结合 | WITNESS | `0x3f32f812` | 19 |

六个 witness 均首先表现为被替换 F64 中间节点 raw 不同；当前 witness 的最终 F32 raw
和 sticky flags 恰好相同，因此它们只证明逐步 DAG 不可随意替换，不能声称已找到最终
输出反例。

M11 的 `GAP_NO_WITNESS_IN_BOUNDED_DOMAIN` 也不表示两种表达式等价。EXP 搜索域是九个
manifest anchors 及其 sign-bit twin 的 raw `±2048` 闭区间，union/dedup 后按 raw
升序，共 73,746 个 raw；过滤非有限与 special 直返后完整检查 71,698 个正常 DAG
候选。LOG 域是 16 个 `OFF+(j<<19)` table base 各 `±2048`，随后六个正 subnormal
seed 各 `±64`；按 `(domain_id, raw)` 稳定顺序，跨 domain overlap 保留。

manifest 固化所有 mutation 定义、域、候选计数、strict/mutant 中间 raw、最终 raw、
step/API flags、六个首 witness 和一个 GAP。将来扩大 M11 搜索域必须生成新证据并更新
profile/manifest，不能把本次普通单测通过替代为等价性证明。

## 9. CLI 与固定验证

从项目根目录运行：

```bash
python3 scripts/aor_f32_oracle.py validate-manifest
python3 scripts/aor_f32_oracle.py self-test
python3 scripts/aor_f32_oracle.py emit-vectors \
  --output tests/vectors/aor_f32_vectors.jsonl
python3 scripts/aor_f32_oracle.py verify-vectors \
  --input tests/vectors/aor_f32_vectors.jsonl
python3 scripts/aor_f32_oracle.py audit-mutations \
  --output tmp/logs/aor-f32-oracle/final-mutation-audit.json
python3 tests/test_aor_f32_oracle.py
python3 scripts/aor_f32_oracle.py verify-evidence \
  --evidence tmp/logs/aor-f32-oracle/final-evidence.json
```

工程运行时必须把 `PYTHONPYCACHEPREFIX` 指向
`tmp/build/aor-f32-oracle/pycache`，并用有界 `timeout` 包裹测试/生成命令。正式证据日志
位于 `tmp/logs/aor-f32-oracle/`。

定向集合覆盖 decode/encode、dyadic normalize、RN-even retained-even/odd/carry、
subnormal/normal/overflow/tininess-after、ADD half-ULP、MUL normal→subnormal、
fused/non-fused discriminator、RMM ties/I32 边界/`-0`、U32/U64 modulo、EXP/LOG
non-NaN special、阈值邻点、32/16 个 table index、23 种正 subnormal leading-one、manifest
mutation、NaN negative gate、AST/import gate 与 emit reproducibility。

tininess-after 定向集合另外固定 F64→F32 的最终 subnormal/minimum-normal 边界：
`0x380fffffdfffffff`、`0x380fffffe0000000` 及相邻 raw、官方 FAQ 的
`0x380fffffe1000000`，以及暂时 precision 舍入恰好进位的 `0x380ffffff0000000`；全部同时
检查正负镜像和暂时无界舍入的 integer significand/grid，避免用未经验证的“tie ±1”猜测替代
边界推导。

`final-evidence.json` 使用 `aor-f32-oracle-evidence-v2`，至少绑定 generator、test source、
manifest、vectors、本文档、mutation audit 以及七条最终命令日志的路径与 SHA256。
`verify-evidence` 独立重算 artifact/log hash，重验 manifest canonical identity、完整向量、
mutation audit、marker、schema 与新旧 semantic identity。命令返回码字段只表示 Codex exec
在命令边界观察到的 parent wait status；该返回码不能从日志 bytes 自行推导，因此 evidence
必须同时写明此 authority/语义，不得把手填数值冒充日志可证明事实。verify-evidence 自身
日志采用 bootstrap 后再绑定 hash 的两阶段流程；最终 receipt 必须在非 bootstrap 模式下
再次通过。
