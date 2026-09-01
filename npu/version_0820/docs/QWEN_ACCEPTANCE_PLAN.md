# Qwen3.5-0.8B 验收与短回归门禁

> **本文定义验收合同，不凭文档宣告 PASS。** 当前 strict runner 的默认目标是让真实 NPU/Verilator 连续生成 8 个 token，并提供真实 2-token 快速前缀。图 collector、CPU oracle、directed RTL 测试和 backend admission 都是必要的前置或诊断证据；只有实际 RTL 生成精确 token、逐 dispatch 账本与累计账本全部闭合，且 fallback/host tensor arithmetic 均为 0，才是 multi-token PASS。

## 1. 固定对象与验收边界

本计划只针对下列固定对象；任一字段不匹配都必须在加载模型或启动仿真前失败：

| 项目 | 固定值 |
| --- | --- |
| 模型仓库 | `ggml-org/Qwen3.5-0.8B-GGUF` |
| revision | `316dea3b5462fd5755862bcec45a2f901bc0ba6b` |
| 模型文件 | `models/Qwen3.5-0.8B-Q8_0.gguf` |
| 文件大小 | `833592096` bytes |
| SHA-256 | `37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f` |
| 量化格式 | GGUF `Q8_0`：每 32 个 int8 权重带 FP16 block scale；不能等同于普通 tensor-scale W8A8 |
| 测试集 ID | `qwen35-08b-q8_0-npu-gate-v1` |
| 设计 ID | `qwen35-08b-q8_0-npu-v1`；同时记录本次 RTL/source tree 的 SHA-256 清单 |
| 仿真器 | Verilator 功能仿真 |
| 性能模式 | 无 `--assert`、无 `--trace`/`--trace-fst`/waveform、Verilator `-O3`、C/C++ `-O3 -DNDEBUG` |

本目标只做 RTL/整模功能仿真与运行时吞吐采集，禁止执行或把任何综合、STA、PPA 流程纳入验收结论。

所有构建、日志、缓存、下载中间件和临时文件必须留在项目目录内。约定稳定测试向量放在 `tests/vectors/qwen35_08b_q8_0/`，临时构建放在 `tmp/build/`，临时日志和验收证据放在 `tmp/acceptance/`。运行器应显式设置 `TMPDIR`、`XDG_CACHE_HOME` 等到 `tmp/` 子目录，禁止落到系统临时目录或用户目录。

Qwen 的 required op 必须由 NPU 后端分配并由真实 Verilator RTL 结果完成。CPU 仅允许：

1. tokenizer/detokenizer；
2. scalar 控制流、shape/position/descriptor 生成、EOS 与流式输出；
3. NPU 已完成全词表归约、仅返回不超过 20 个候选之后的最终 sampling/RNG。

CPU 不允许执行 embedding/dequant、GEMM/GEMV、Q8_0 block dot、GDN、attention、KV 更新、softmax、norm/reduction、激活、RoPE、LM head 或全词表 top-k/argmax。若 required op 被调度到 CPU、被某个 CPU/BLAS kernel 执行，或 NPU 后端不支持该 op，进程必须返回非零；不能继续生成 token。

## 2. 统一 fail-closed 规则

三个层级共用以下规则：

- 每条固定命令只运行一次，并绑定 `command/input/design_id/model_sha256/testset_id/return_code/result/artifact`。只有随机性、并发、测量噪声、机器异常或明确的 A/B 目的才重复。
- 运行器采用 `set -Eeuo pipefail`，每个阶段都有明确 `stage`；`HUP/INT/TERM`、timeout、缺 marker、hash 不一致、计数不一致均写 `[QWEN-GATE][FAIL] stage=<stage> reason=<reason>` 并返回非零。
- 外层一律使用 `timeout --signal=TERM --kill-after=2s <limit>`。退出码 `124`、`137` 或任何信号退出都是 FAIL，不能因为清理 trap 最终返回 `0` 而改写成 PASS。
- 只有模型 hash、向量 hash、设计清单 hash、预期 marker、计数核对和清理状态全部满足后，才允许输出该层 PASS。长跑状态应复用仓库的 `scripts/task-run-status.sh` 语义，不能只以进程 `$?=0` 判定。
- 日志必须能区分成功完成、预期的负向拒绝和基础设施失败。`EXPECTED-UNSUPPORTED` 只证明 fail-closed 有效，不是整模验收 PASS。
- 任何 required-op 计数器缺失、为 `unknown`、溢出或被重置，都按失败处理。

最终整模门禁必须满足：

```text
required_seen > 0
required_seen == assigned_to_npu
assigned_to_npu == executed_by_verilator
executed_by_verilator == required_completed
required_cpu_fallback == 0
unsupported_required == 0
rtl_failures == 0
```

同时记录每个 required op class 的 `seen/assigned/executed/completed`。只记录总数而没有 per-opclass 明细，不足以通过最终门禁。

## 3. 第一层：RTL 微回归

### 3.1 目的与固定输入

第一层不加载 GGUF，固定输入就是仓库内的五个 directed testbench：

| case | 固定 testbench | 预期 marker/计数 |
| --- | --- | --- |
| `rtl-decoder-regfile-v1` | `tests/tb_decoder_regfile.sv` | `[NPU-DECODER-REGFILE][PASS] checks=61` |
| `rtl-local-memory-v1` | `tests/tb_local_memory.sv` | `[NPU-LMEM][PASS]` |
| `rtl-mm2-v1` | `tests/tb_mm2_engine.sv` | `[NPU-MM2][PASS] continuous NN signed/unsigned arithmetic, little-endian results, protocol, and negative guards` |
| `rtl-dma-v1` | `tests/tb_dma_engine.sv` | `[NPU-DMA][PASS]` |
| `rtl-coprocessor-v1` | `tests/tb_coprocessor.sv` | `[NPU-COPROCESSOR][PASS] checks=44 commands=8 completions=6 errors=2 required_issued=4 required_completed=3 tiu_cycles=29 dma_cycles=18 dma_bytes=32` |

这些测试的输入由 testbench 常量固定；验收记录还必须保存每个 testbench 与其引用 RTL 的 SHA-256。`tb_coprocessor` 中 `completions=6` 是成功完成数，另有两个定向错误；`required_issued=4` 与 `required_completed=3` 的差异是已固定的负向场景，不可套用整模“全成功”公式，也不可改写计数来掩盖错误测试。

### 3.2 构建与运行约束

每个 top 使用独立的 `tmp/build/rtl-<case>/`。其等价命令必须包含：

```text
verilator --binary --timing -O3 -Wall -Wno-fatal \
  -CFLAGS "-O3 -DNDEBUG -march=native" -Irtl \
  --Mdir tmp/build/rtl-<case> --top-module <top> \
  <testbench> <ordered-rtl-filelist> -o V<top>

timeout --signal=TERM --kill-after=2s 20s \
  tmp/build/rtl-<case>/V<top>
```

不得加入 `--assert`、`--trace`、`--trace-fst` 或任何 `$dump*` 路径。编译必须为零错误；当前目标还要求零新 warning。运行必须在 20 秒内结束，且每个期望 marker 恰好出现一次。

第一层总 marker 为：

```text
[QWEN-GATE][L1][PASS] cases=5 assertions=off waveform=off opt=O3
```

以下任一情况使 L1 失败：编译或运行非零、timeout/signal、marker 缺失或重复、计数偏离上表、出现未预期 error、生成 waveform、或构建/临时文件越出本项目目录。

## 4. 第二层：真实模型抽取的离线算子/层向量

### 4.1 向量冻结流程

向量必须从第 1 节固定的 GGUF 和 revision 抽取，不允许用随机同形矩阵代替“真实模型向量”。抽取器需要生成 `tests/vectors/qwen35_08b_q8_0/manifest.json`，至少冻结：

- 模型 SHA-256、revision、GGUF tensor 原名、byte offset、shape、type；
- token 序列、position、KV/GDN 初态和确定性 PRNG seed（如用到）；
- 输入、参考输出及每个文件 SHA-256；
- reference 软件及 commit、reference 生成命令；
- 每例的整数精确规则或明确的 FP32 `atol/rtol/ULP` 上限；不得在运行时放宽容差；
- `expected_required_ops`、per-opclass 计数、精确 `rtl_cycles` 和 `dma_bytes`；
- 设计 ID 与向量集 ID。

逻辑 tensor selector 必须唯一解析到 GGUF 的真实 tensor 名；缺失、重名或 shape/type 不符立即失败。reference 只用于离线生成 oracle，不参与候选 NPU 的验收执行，也不能成为运行时 fallback。

v1 固定为下面 10 个 case；每例是一个验收 required unit，因此期望 `required_seen=assigned_to_npu=executed_by_verilator=required_completed=1`，三个失败计数均为 0；层级合计四个 required 计数均为 10：

| case ID | 固定逻辑位置与覆盖点 |
| --- | --- |
| `vec-01-embed-q8-dequant` | embedding 的实际 Q8_0 blocks；验证 FP16 block scale、int8 解量化与 token gather |
| `vec-02-gemv-q8-block-dot` | 第 0 block 的一条真实投影行；验证 activation 动态分块量化、双 block-scale dot 与累加 |
| `vec-03-gemm-q8-block-dot` | 第 3 block 的真实 attention 投影 tile；验证 batched Q8_0 GEMM 与边界 tile |
| `vec-04-gdn-dwconv` | 第 0 个 GDN block 的真实 DWConv 输入窗口与权重 |
| `vec-05-gdn-scan-state` | 第 2 个 GDN block 的连续两段输入；验证有序 scan、跨段持久 FP32 state，禁止乱序 |
| `vec-06-rope-qk` | 第 3 个 attention block 的真实 Q/K slice、position 和 RoPE 参数 |
| `vec-07-gqa-qk-softmax-pv` | 第 3 个 attention block 的真实 GQA/KV slice；联合验证 QK、mask、稳定 softmax 与 PV |
| `vec-08-norm-residual` | 第 0 与最后一个 block 的真实 residual/norm slice；覆盖 reduction 与 rsqrt |
| `vec-09-activation-gating` | 第 0 个 GDN block 的真实 gate/up 输入；覆盖实际激活、逐元素乘与 residual |
| `vec-10-lm-head-topk` | 最终 norm/LM head 的真实 hidden slice；完成全词表归约并仅向 CPU 返回 `k <= 20` 候选 |

具体 tensor 原名、坐标、token IDs、reference 数值、容差、cycle 和 byte 数不能凭文档猜测，必须由上述 manifest 锁定。**当前 manifest 尚未生成，相关字段为空即拒绝运行；这本身是当前 L2 不能 PASS 的明确前置阻塞。**

### 4.2 执行模式、timeout 与 marker

每个 case 使用 Verilator `-O3`、C/C++ `-O3 -DNDEBUG`，无 assert、无 waveform；每例进程级 timeout 为 60 秒，整个 L2 套件 timeout 为 10 分钟，均带 `--kill-after=2s`。为防止前例的 GDN/KV/错误状态污染后例，每例使用 manifest 规定的 reset/init；需要验证持久 state 的 `vec-05` 只在该例内部连续运行两个 segment。

每例成功 marker：

```text
[QWEN-VECTOR][PASS] case=<case-id> required_seen=1 assigned_to_npu=1 executed_by_verilator=1 required_completed=1 required_cpu_fallback=0 unsupported_required=0 rtl_failures=0 rtl_cycles=<exact> dma_bytes=<exact>
```

L2 总 marker：

```text
[QWEN-GATE][L2][PASS] cases=10 required_seen=10 assigned_to_npu=10 executed_by_verilator=10 required_completed=10 required_cpu_fallback=0 unsupported_required=0 rtl_failures=0
```

L2 状态必须由上述 10 个真实向量的本次运行结果决定，不能仅从整图 backend 已能接管同名 op 推断 PASS。若任一向量仍缺少 required op，正确的负向结果是在执行前或后端二次能力检查时返回非零，并输出一次：

```text
[QWEN-GATE][L2][EXPECTED-UNSUPPORTED] case=<case-id> op=<required-op> cpu_fallback=0
```

该 marker 只允许出现在专门的负向测试中，并要求没有后续 token/结果写回；它不能与 `[QWEN-GATE][L2][PASS]` 同时出现，也不能被整模验收器当作成功。

L2 的其他失败条件包括：数值超出锁定 oracle、状态顺序错误、全词表或候选数组被导出到 host、CPU candidate scan 非零、cycle/bytes 与 manifest 不符、required op 数不等于 10、任何 CPU fallback、unsupported、RTL failure、timeout/signal、hash 不符或 marker 重复。

## 5. 第三层：最终 shell 对话 smoke

### 5.1 启动前门禁

只有 L1 和完整 L2 均 PASS 后才能启动 shell smoke。启动前依次检查：

1. 模型大小与 SHA-256 完全匹配；
2. 动态 NPU backend 是唯一承载 required op 的设备，且设备 ID 与 run manifest 固定；
3. scheduler 的 pre-split 能力检查和 backend `graph_compute` 二次检查均启用；
4. `required_expected` 及 per-opclass expected counters 已由 bootstrap/steady graph manifest bundle 锁定：reserve cohort 与 dispatch 1 使用 bootstrap，dispatch 2 及以后使用 steady。两相都保留 1714 个 node、1080 个 required owner 以及相同的 canonical ID/node-index 映射；字段缺失、运行时相位错误或 graph 与 bundle 不一致都拒绝启动；
5. 终端全词表 ARGMAX 已由 NPU backend 和 Verilator RTL 闭合；CPU sampler 只接收 4-byte token 标量。必须同时满足 `full_vocab_host_exports=0`、`full_vocab_host_export_bytes=0`、`cpu_candidate_scans=0`，不能把完整 logits 或候选数组交给 llama.cpp 的 CPU sampler。

### 5.2 固定短回归输入

自动 smoke 使用一个冻结的 raw prompt；它避免 chat template 的额外 token，并通过连续 decode 检查 token 反馈、position/KV 状态推进与每轮重新绑定：

| profile | 固定 prompt | `n_predict` | 固定 oracle |
| --- | --- | ---: | --- |
| `prefix-2` | `x` | 2 | prompt ID `[87]`，generated IDs `[283, 220]`，文本 ` = ` |
| `extended-8`（默认） | `x` | 8 | prompt ID `[87]`，generated IDs `[283, 220, 16, 15, 198, 88, 283, 220]`，文本 ` = 10\ny = ` |

prompt 保存在 `tests/vectors/qwen35_08b_q8_0/smoke.txt`，完整八 token CPU/reference oracle 冻结在 `tests/vectors/qwen35_08b_q8_0/strict-smoke-oracle.json`，两 token 档只接受它的精确前缀。oracle 由同一模型、同一 b10507/commit 的 fresh `llama-completion`、普通 CPU sampler 以及只观察 token ID 的 interposer 独立产生；NPU 候选运行不得调用 CPU 模型 kernel 重生成 oracle。每次 scripted 运行会重新执行一次 CPU 八 token oracle 校验，但这只能证明 reference 可复现，不能替代真实 NPU token 证据。固定 `seed=1`、`temperature=0`、`top-k=1`、`-b 1 -ub 1`、`--backend-sampling` 与 `--no-conversation`。

### 5.2.1 双阶段 graph collector、bundle 与 admission matrix

raw 模式下每个真实 dispatch 都必须覆盖 manifest bundle 中全部 1080 个 required compute/mover owner，且终端 ARGMAX 必须扫描 248320 个元素。运行器要求 dispatch ID 恰好为 `1..generated_tokens`，三次 reserve preflight 后每个生成 token 恰好出现一次 fresh dispatch preflight。reserve cohort 1/2/3 和 dispatch 1 必须逐项匹配 bootstrap manifest；dispatch 2 及以后必须逐项匹配 steady manifest。

启动 backend 前，runner 使用同一固定模型、raw `x`、严格 backend-greedy sampler 和 B1T1 配置逐个执行八次 CPU graph capture：

| capture | 目标 | 可证明内容 |
| --- | --- | --- |
| dispatch 1 | bootstrap manifest | 冻结首次 recurrent cache 初始化图 |
| dispatch 2 | steady manifest | 冻结第一次连续 decode 的稳态图 |
| dispatch 3..8 | 六份独立 steady-repeat manifest | 连续覆盖每一个中间 dispatch，证明 steady graph 无进一步 descriptor 漂移 |

target dispatch 之前的 dispatch 只在 collector 中由 CPU 执行以建立图状态；target graph 在 build 后、scheduler 前被捕获并受控退出。collector 必须没有 `[NPU-STRICT][PASS]`、System/raw32/sampler ledger 或 timing marker。因此 dispatch-1..8 capture 及其 bundle PASS 只证明图结构，不证明 token 经 NPU 计算。

bundle 审计要求两相都恰好有 1714 个 node 和 1080 个 required owner，canonical ID、node index 与 owner 分类不变。合法的 required-owner 相位差仅有 18 层 `cache_r` 和 18 层 `cache_s` 对应的 36 个 P17/P18 SCALE：bootstrap 为非空，steady 为 zero-cardinality。dispatch 3、4、5、6、7、8 必须各自存在、按序绑定，并全部与 dispatch 2 的 steady graph 一致；缺少任何中间 dispatch、重复、乱序或任一层漂移都 fail closed。

每次 strict runner 必须把本次刚采集的 bootstrap、steady 和六份 repeat manifest 显式传给 graph suite。该绑定运行固定为 39/39 PASS、`skipped=0`，且不允许 expected-failure/unexpected-success 修饰。普通开发者不提供 artifact 环境变量时，suite 是自包含的 27 项 unit/static PASS 加 12 项明确的 opt-in real-bundle skip；测试不得扫描或借用历史 `tmp/` artifact 来改变结果。

runner 启动的每个 `llama-completion` 子进程都必须先清除 ambient NPU 模式环境面，包括 required、admission-only、collector/target-dispatch、strict sampling、graph profile/numeric/source/model/fused identity 以及 backend-sampling alias，再只设置当前 phase 所拥有的变量。CPU oracle、graph capture、prompt-cache creation/replay、admission、interactive 和 scripted 路径都不得继承开发者 shell 中的 NPU 模式。

backend 构建后还必须执行 bootstrap/steady admission matrix：

| admission row | 图状态构造 | 精确结果 |
| --- | --- | --- |
| bootstrap | raw prompt `x` | nodes=1714，required_seen=1080，supported=1080，assigned=1080，unsupported=0，compute_started=0 |
| steady | CPU 新建 `[87,283]` session，在最后 token 前保存；随后只读加载 size=2、exact-match，再以 `x =` 绑定并尝试 replay | nodes=1714，required_seen=1080，supported=1080，assigned=1080，unsupported=0，compute_started=0 |

CPU prompt-cache 生成不得进入 NPU 路径，creation log 必须唯一证明 fresh session 和 `saved_before_last_token=1`。steady admission 必须按顺序证明 load attempt、`loaded_prompt_tokens=2`、exact prompt match、admission-only PASS 和 replay controlled stop；session SHA 在 creation/replay 间相同，只读文件不得变化，`replay_completed=0`、scheduler allocation 和 compute dispatch 都为 0。两行 admission 都在 scheduler/compute 前受控退出。该 matrix 证明两相 descriptor 与真实 steady session 均可被 backend 严格接管，但不构成 RTL 执行或 token PASS。

### 5.2.2 steady zero-cardinality 语义与 phase-aware 账本

steady graph 中的 36 个 P17/P18 SCALE 仍是 required SystemTop transaction：必须各自出现 command、success completion、required issued/completed 和 F32 owner transaction，不能被删除、改记为 metadata、落到 CPU 或 host arithmetic。它们的合法工作量为 0，因此由 SystemTop 直接完成，不启动 F32 child，不产生 raw32 portal request group、读写 word 或 payload byte。其余 331 个 F32 owner 仍走完整 child/portal 路径。

每相冻结账本如下：

| phase | required/SystemTop transactions | F32 owner transactions | zero F32 transactions | F32 nonempty / first holds | F32 raw read bytes | F32 raw write bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| dispatch 1 bootstrap | 1080 | 367 | 0 | 367 | 211292672 | 115820800 |
| each dispatch 2+ steady | 1080 | 367 | 36 | 331 | 191091200 | 95619328 |

因此 scripted 累计值必须按 `1 * bootstrap + (generated_tokens - 1) * steady` 计算：

| profile | dispatches | required completed | F32 owner transactions | zero F32 transactions | F32 first holds | F32 raw read bytes | F32 raw write bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `prefix-2` | 2 | 2160 | 734 | 36 | 698 | 402383872 | 211440128 |
| `extended-8` | 8 | 8640 | 2936 | 252 | 2684 | 1548931072 | 785156096 |

required completion、F32 owner transaction 和 sampler ARGMAX 等固定 cardinality 项仍按 dispatch 数累加；F32 first-hold 与 raw read/write byte 不能再用首 token 账本做简单线性倍乘。validator 必须同时拒绝 bootstrap/steady 互换、dispatch 2 后 steady 漂移、36-owner 集合改变，以及把 zero transaction 伪装成有物理 portal 流量。

strict log validator 对 `[NPU-STRICT][PASS]`、System ledger、functional-command ledger、raw32 ledger 和 sampler-ARGMAX ledger 使用整行封闭 grammar：marker 后只能是单空格分隔的 `lower_snake_case=<unsigned-decimal>`，且 observed field set 必须与该 marker 的冻结集合完全相等。未知字段即使为 0、重复/缺失字段、非字段尾巴、额外空白或其他未消费字符都必须失败，不能只抽取熟悉字段后忽略其余内容。

已测得一次真实 strict NPU/Verilator dispatch wall time 约 8218 秒，因此 `prefix-2` 与 `extended-8` 预计分别约 4.57 小时和 18.26 小时。旧三轮模板化向量合计 71 个 prompt token 和 35 个 generated token，仍保留在 `oracle.json` 供 CPU-only 语义研究，不属于 strict RTL smoke。scripted timeout 默认为 86400 秒并使用 `--kill-after=5s`。运行必须正常返回，输出 token IDs 与 CPU golden 的对应前缀完全一致，并输出：

L3 继续复用同一份无 assert、无 waveform、`-O3/-DNDEBUG` 的 Verilator backend；不得为整模 smoke 临时切换到调试构建或软件 reference backend。

```text
[NPU-STRICT-SCRIPTED][TURN-PASS] turn=smoke prompt_tokens=1 generated_tokens=<2-or-8> elapsed_s=<finite-positive> tokens_per_second=<finite-positive> prompt_tps=<finite-positive> generation_tps=<finite-positive> ttft_s=<finite-positive> prompt_ids=[87] generated_ids=<exact-oracle-prefix>
```

每次 full-graph dispatch 的 locked required 数为 1080；运行时动态降低 expected 值是失败。总 marker 还必须明确全词表未导出、CPU 未扫描候选、无 fallback、无 host tensor arithmetic：

```text
[NPU-STRICT-SCRIPTED][PASS] schema=qwen35-08b-q8_0-npu-strict-system-v4 profile=<prefix-2-or-extended-8> turns=1 prompt_mode=raw-no-conversation prompt=x generated_tokens=<2-or-8> dispatches=<same> bootstrap_dispatches=1 steady_dispatches=<1-or-7> required_completed=<2160-or-8640> admission_required_per_dispatch=1080 admission_supported_per_dispatch=1080 admission_unsupported_per_dispatch=0 system_transport=all-required cpu_fallback_attempts=0 host_tensor_arithmetic=0 token_ids=exact-cpu-oracle-prefix output=<result.json>
```

最终 artifact schema 固定为 `qwen35-08b-q8_0-npu-strict-system-v4`，必须同时包含 `ledger_phases.bootstrap/steady/total`、bootstrap/steady manifest 的 raw/manifest/artifact identity、含 ordered dispatch-3..8 repeats 的 bundle identity，以及 admission matrix artifact identity、两相 admission census 和 prompt-cache creation/replay identity。v4 envelope 还必须证明顶层 phase ledger 与 turn 内 ledger 完全相等，才能打印最终 marker。

该 marker 只有在模型进程真实调度全部 2/8 个 Verilator dispatch、输出精确 token oracle 前缀，并由 phase-aware log validator 核对上述每相与累计账本之后才能打印。CPU oracle、dispatch-1..8 collector、39/39 graph suite、manifest bundle、bootstrap/steady admission matrix 或 directed zero-cardinality 测试均不得代替它。本文描述的是 runner 的验收能力与待执行合同，不表示 8 个真实 RTL token 已经跑完。

交互验收使用 `scripts/run_qwen_strict_smoke.sh --interactive`。脚本必须连接真实 PTY，在输出 `npu> ` 后由 shell 自身用 `read` 接收用户输入，再以 raw `--no-conversation -p <input>` 启动同一强制 NPU 路径；模型子进程的 stdin 显式绑定 `/dev/null`，防止它重新夺取 PTY 或在自动 collector 阶段等待输入。这样保留“用户在 shell 中直接输入并得到模型实际生成”的可观察事实，同时避开 pinned `llama-completion` 在 raw 空 prompt 下直接退出、不会等待首轮输入的行为。默认 `n_predict=2`、timeout 86400 秒；可显式覆盖，但增加 token 会按完整 RTL dispatch 数线性增加耗时。对任意 raw prompt，严格 dispatch 总数必须等于 `prompt_tokens + generated_tokens - 1`；这与单-token scripted prompt 下恰好等于 `generated_tokens` 的特例不同。EOF/空输入、CPU fallback、host tensor arithmetic、unsupported、RTL failure、timeout 或 ledger 不闭合都必须失败。最终 PASS marker 必须包含 `prompt_mode=raw-shell`、token IDs、wall elapsed 与 tokens/s。

## 6. 建议的低开销运行旗标

下面是已按 pinned `llama-completion` b10507/commit 验证并由 strict 脚本锁定的低开销参数：

| 旗标/初值 | 用途与限制 |
| --- | --- |
| `-c 256` | 固定 raw smoke 的 context/KV 占用；不能运行时自动扩容并改变 manifest |
| `-b 1 -ub 1` | logical/physical batch 都固定为单 token，使实际 dispatch 与 B1T1 canonical graph profile 一致 |
| `-t 1` | CPU 只做允许的 tokenizer/控制任务；不能通过增加 CPU threads 承担 required model compute |
| `-n 8` / `-n 2` | scripted 默认 `extended-8`；`--scripted-prefix-2` 与默认 interactive 使用 2。每个生成 token 都增加一次约 8218 秒的完整 RTL dispatch |
| `--seed 1 --temp 0 --top-k 1 --backend-sampling` | 形成确定性 oracle，并强制终端全词表 ARGMAX 由 NPU/RTL 完成；CPU 仅接收 token 标量 |
| `--no-warmup` | 避免隐藏的额外整图 warm-up，缩短门禁并使实际执行次数可审计 |
| `--perf` | 输出 prompt processing、generation 与 total timing；脚本另用 monotonic token timestamp 和 `/usr/bin/time` 交叉记录 TTFT、wall time 与 wall tokens/s |
| `--no-conversation --simple-io` | 使用 raw prompt 并保持可审计的最小 I/O；交互模式由 shell 的 PTY `read` 接收输入 |
| `--no-display-prompt --reasoning off` | 不重复打印 prompt，不引入 reasoning/template token |
| `LLAMA_NPU_REQUIRED=1 GGML_BACKEND_PATH=<fresh-backend>` | 强制使用 fresh NPU backend；backend 缺失、owner 缺失或任何 CPU fallback 都直接失败 |

若 fused attention/GDN 尚不能由 NPU backend 正确接管，可在开发期显式使用 pinned CLI 支持的 decomposed 模式做定位；这不是最终吞吐结论，也不能借此把子算子落到 CPU。所有 flag 的最终拼写和值随完整命令写入证据，不使用“默认值大概相同”的表述。

## 7. tokens/s、cycle 与流量记录

每次 L3 运行必须分别记录：

- `prompt_tokens`、`prompt_time_s`、`prompt_tps = prompt_tokens / prompt_time_s`；
- `generated_tokens`、`generation_time_s`、`generation_tps = generated_tokens / generation_time_s`；
- 首 token 延迟、端到端 wall time；
- tokenizer、sampling 时间（只作为 CPU 允许范围的辅助分解）；
- `rtl_cycles`、按 TIU/DMA/opclass 分解的 cycle、`dma_bytes` 与 command/completion 数；
- `required_seen/assigned_to_npu/executed_by_verilator/required_completed` 及四个失败计数；
- 完整命令、CLI/llama.cpp commit、Verilator 版本、模型 SHA、design ID、source/RTL manifest SHA、test vector manifest SHA、返回码和 marker。

`llama-completion --perf` 的原始 timing、monotonic token timestamp 计算值和 `generated_tokens / wall_seconds` 都写入结果；面向用户报告时同时给出未舍入的内部口径与端到端 wall 口径，不能混用。pinned CLI 在 raw 模式下可能把 full-forward 计入 `eval time`，同时打印 `prompt eval time = 0 ms`、`inf tokens/s`，而极低的 eval 速率又会被两位小数打印为 `0.00`；后处理器因此用 `prompt_start_ns -> first generated_ns` 计算 prompt/TTFT 口径，用全部 `eval_runs / (eval_ms / 1000)` 计算未舍入 generation 口径，并保留 CLI 原值供审计。两个计算速率与 wall t/s 必须是有限正数。`llama-bench` 可以作为补充，但它可能不包含 tokenizer/sampling，不能替代 shell 口径。当前计划不虚构最低性能阈值。首次完整 PASS 得到的冷启动和稳态数据应分别保存，后续若设回归下限，要以同机器、同命令、同模型 SHA、同 design ID 的测量基线为依据。

建议每次生成一条机器可读记录，例如：

```json
{
  "testset_id": "qwen35-08b-q8_0-npu-gate-v1",
  "design_id": "qwen35-08b-q8_0-npu-v1",
  "model_sha256": "37ae482d336108d23516fa35e8e0c4126688d81018b87178a18d752a1357814f",
  "command": "<exact argv>",
  "return_code": 0,
  "prompt_tokens": "<integer>",
  "prompt_tps": "<finite number>",
  "generated_tokens": "<integer>",
  "generation_tps": "<finite number>",
  "required_seen": "<locked integer>",
  "assigned_to_npu": "<same integer>",
  "executed_by_verilator": "<same integer>",
  "required_completed": "<same integer>",
  "required_cpu_fallback": 0,
  "unsupported_required": 0,
  "rtl_failures": 0,
  "rtl_cycles": "<integer>",
  "dma_bytes": "<integer>",
  "result": "PASS",
  "artifact": "tmp/acceptance/<run-id>/"
}
```

占位字符串存在时记录不能被签为 PASS。

## 8. 解锁顺序与当前预期结果

门禁必须按 `L1 -> L2 -> L3 scripted smoke -> direct shell chat` 解锁，不能跳级：

1. L1 证明当前 decoder/register/local-memory/MM2/DMA/coprocessor 的定向功能与负向保护未退化。
2. L2 逐项补齐并验证真实 Q8_0、GDN、attention、norm、softmax、top-k 等 required kernels，同时建立精确 graph/cycle/byte oracle。
3. L3 用固定 prompt、golden token IDs 和完整 backend 审计证明整模所有 required op 真正经 Verilator 执行。
4. 最后才允许用户在 shell 中直接对话并收集 prompt processing 与 generation tokens/s。

当前 multi-token 实现已经具备 bootstrap/steady manifest、dispatch-3..8 连续 repeat bundle、绑定本次 artifact 的 39/39 graph suite、hermetic 子进程、两相 admission/prompt-cache replay 审计、P17/P18 zero-cardinality directed coverage 和 schema-v4 结果封装；这些只说明真实长跑具备启动条件。当前不得声称 8 个真实 RTL token 已执行完成。`prefix-2` 或 `extended-8` 的状态必须由各自本次实际 RTL artifact 决定：在全部 token IDs、phase-aware 账本、全词表 ARGMAX、`required_cpu_fallback=0` 和 `host_tensor_arithmetic=0` 同时满足前，保持未完成而不是借用 collector/test/admission PASS。L1/L2 的状态同样以各层自己的实际结果为准，不能由 L3 或文档反向替代。
