# GGML NPU Compiler、Host Runtime 与固定 RV64 Firmware 架构

## 1. 目标

本重构把当前的验证型执行路径：

```text
live ggml_tensor
  -> host 逐节点匹配 profile
  -> host 构造 30-word descriptor
  -> host 为该节点生成 30 x (LD + CONFIG) + LO/HI 的 RV64 程序
  -> 新建并 reset 一个 NpcTensorNpuSystemTop
  -> 执行一个节点后销毁
```

迁移为：

```text
llama.cpp / GGML graph
  -> NPU Compiler
       -> command.bin       版本化 macro descriptor template 列表
       -> weights.bin       immutable、对齐的常量区
       -> metadata.json     buffer、relocation、identity 与工作量合同
  -> Host Runtime
       -> 验证 bundle
       -> 分配 private device arena
       -> 在 command shadow 上完成 relocation
       -> 发布 submission
  -> 固定 RV64 Firmware
       -> 消费 resolved 30-word descriptor
       -> 静态 30 x CONFIG
       -> 固定相邻 LO/HI launch
       -> 写 completion
  -> TensorNpuCoprocessor
```

第一版的首要目标是改变软件边界和生命周期，而不是虚构硬件尚未实现的融合、异步队列或新 NPU ISA。
只把 1080 条 descriptor 放进一个 submission，仍然是 1080 次 NPU launch，不能记成一次融合 command。

当前完整模型实现为 `libggml-npu-model.so`：实际 GGML dispatch 的 1080 required nodes
经准离线 Compiler 生成独立 `npu-compiled-model-v1` 三件套，Host Runtime 重新装载并重定位，
同一个固定 RV64 Firmware/SystemTop 经真实 RTL DMA 与六类 NPU owner 执行。
详细边界、内存规划、真实 token 验收及运行方法见 [完整模型路径](NPU_COMPILED_MODEL.md)。

以下第 2～4 节保留此前 artifact v3 / P00 边界和自动绑定 API 的合同；它们继续作为兼容回归，
与全模型的 metadata schema 不混用。全模型 codegen 已生成 1080 条可执行 command，
当前正在执行真实 Qwen bootstrap → steady 的两 token 验收；在真实 token 全部闭合前，
组件、synthetic 或 P00 manifest 回放 PASS 都不代表模型完成。

## 2. 两条彼此独立的编译链

### 2.1 Host 与 firmware 的 RISC-V/C++ 编译链

`llama.cpp`、GGML backend 和 Host Runtime 是普通 C/C++ 程序。它们由目标平台的 C/C++ compiler
生成 host 机器码。若 host 是 x86-64，就生成 x86-64；若 llama.cpp 最终运行在 RV64，就生成标准 RV64。

固定 NPU service firmware 是另一份 freestanding RV64 程序。它由 stock GNU RISC-V
`riscv64-linux-gnu-gcc/as/ld/objcopy` 生成 ELF 和 flat binary。Tensor custom-2 指令暂时用 assembler
`.insn` 或 `.4byte` 表示，因此不需要先 fork GCC。compiler 仍负责普通 load/store/branch/fence 的
寄存器分配和指令选择，custom instruction 的位域只在一个已审计的 firmware 源文件中出现。

### 2.2 GGML graph 的 NPU 编译链

NPU Compiler 不把任意 C/C++ 重新编译成 RISC-V。它消费 GGML graph IR，并将受支持的 tensor op
lower 成 NPU macro descriptor：

1. graph import：验证 canonical manifest、拓扑和 tensor descriptor；
2. capability/lowering：以 canonical node identity 绑定现有 NPU kernel/profile；
3. graph optimization：当前基线只消除 metadata alias，不改变数值语义；
4. fusion：当前关闭，除非 RTL 已存在对应 fused kernel 和可审计 ledger；
5. tiling：当前使用冻结 profile 已选择的 local profile；
6. memory planning：当前使用确定性的线性 BufferId/offset 规划，不复用 live range；
7. scheduling：按 canonical topological order 串行；
8. code generation：生成 30 x little-endian `u64` descriptor template 和 relocation。

这里的 `command.bin` 是 NPU macro descriptor 数据，不是 RV64 machine code；真正执行 CONFIG/LO/HI
的 RV64 machine code只存在于固定 firmware。

### 2.3 当前真实 P00 编译入口

第一条真实 P00 slice 可由同一条命令重现：

```text
python3 -m compiler.npu_compile \
  --qwen-manifest <dispatch.manifest.json> \
  --canonical-node 1e3dac5ab4a21eb84d4d473de864ce2aa3129e1d4f248ee44d766549a51e6f3f \
  --model <Qwen3.5-0.8B-Q8_0.gguf> \
  --output-dir <bundle-dir>
```

该路径只接受 exact owner coverage 的 production manifest，不接受 structural fixture 冒充 codegen source；
它保留 node29 VIEW 与 node28 storage root 的双重来源，按 external index 8 和 tensor descriptor 精确查找
`blk.0.ssm_dt.bias`，并从 GGUF 声明的 file interval 原样读取 64 bytes，不做 host tensor arithmetic、cast
或重排。生成后立即调用 artifact loader 重新验证三件套。当前这是一条真实单节点 compiler acceptance，
不是完整模型执行入口。

## 3. v3 compiled bundle（artifact schema v3 / command ABI 1.1）

三个文件构成不可混用的 bundle。runtime 必须在发布 doorbell/submission 前验证全部文件，任何失败都
fail closed，且不得产生 NPU launch 或 GMEM request。

### 3.1 `command.bin`

文件头固定为 64 bytes、little-endian，随后是连续的 command payload：

```text
magic                   8 bytes
abi_major / abi_minor   u16 / u16  current = 1 / 1
header_bytes            u16        64
record_bytes            u16        240
command_count           u32
reserved                u32       must be zero
payload_bytes           u64
payload_sha256          32 bytes

payload:
  command_count x (30 x little-endian u64)
```

每条 240-byte record 使用现有 `npu_exact_command_contract` 的冻结映射。编译期未知的 IOVA 保存为零或
artifact-relative addend；runtime 只能在该 dispatch 私有的 command shadow 上重定位，禁止修改只读
artifact，也禁止在 firmware 已经观察到 READY 后继续 patch。

### 3.2 `weights.bin`

当前规则：

- 每个常量段至少 64-byte 对齐；
- Q8_0 默认保持 GGUF 原始 block layout；
- 相同 byte payload 可以按 content hash 去重；
- 每段的 offset、size、alignment、type 和 SHA-256 记录在 metadata；
- 尚未实现且未经 RTL kernel 验证的 weight reorder 不得用名称冒充已完成优化。

### 3.3 `metadata.json`

当前可执行的 `npu-artifact-bundle-v3` 使用 canonical JSON，并包含：

- schema、target command ABI、endianness 与 weight alignment；
- source graph schema `npu-compiler-graph-v3` 和 graph name；
- `command.bin` 和 `weights.bin` 的完整文件 hash；
- buffer table：BufferId、kind、bytes、alignment、permissions，以及 weight offset/content hash；
- command table：index、name、owner、node ids、node/descriptor hash、cycle upper bound；
- compiler 从最终 descriptor 模板派生并逐字段复核的十字段 identity；
- `f32-alu-v1` workload：request/response/read/write group、输入输出 word/byte、completion element 和
  `expected_starts`，包含算术闭合与 overflow 检查；
- relocation table：command index、word index、kind、BufferId、addend；
- `runtime.service_abi = 1.1`；
- `publication.mode = bundle_atomic` 及 publication entries；每个 output 的 source/target 区间都必须
  无 gap、无 overlap 地精确覆盖整个 buffer，而且每个 source byte 必须落在同一 BufferId 的合法
  destination relocation/window 写集合中，禁止发布未被任何 command 写入的 private bytes；
- bundle-id-covered provenance source：manifest schema/hash、raw source hash、GraphIR schema/hash、model
  profile、source commit 和 graph scope；
- node binding：artifact node id、canonical source ID、manifest graph index、source/artifact schedule position、
  source GGML descriptor hash、最终 command descriptor hash和 lowering profile；
- buffer binding：每个 artifact BufferId 的 logical origin、normalized storage origin、两侧 tensor descriptor
  hash、alias offset、logical size 与 storage size。VIEW 只形成一个 capability，不伪造第二个重叠 buffer。

v3 Python compiler 与 C++ loader 都使用 exact-key schema，会拒绝未知字段；未来扩展 model catalog、owner、
reorder 或 capability epoch 时必须显式升版，不能在不改变版本时静默扩大信任边界。

relocation 必须保持 descriptor capability 成对关系：

| IOVA word | window-base word | 语义 |
|---:|---:|---|
| 10 | 23 | src0 |
| 11 | 26 | src1 |
| 13 | 28 | dst |

`src2` word 12 当前只能显式 alias 一个已经声明的 src0/src1/dst window；`scratch` word 14 在没有
独立 scratch window ABI 前必须为零。runtime 必须先检查所有 relocation 的 word、BufferId、permission、
alignment、range 和 `base + addend` 溢出，全部成功后才原子替换 private shadow。

artifact 编译器和 C++ loader 还共同验证 transient 的 byte-level read-before-write。验证器按 command
顺序维护此前所有 transient destination window 的区间并集；当前 command 通过 src0、src1 读取的每个
transient window，必须已被严格更早的 destination window 完整覆盖，部分覆盖也会拒绝。同一 command
自己的 destination 要等全部 source 检查结束后才加入已写集合，因此不能用“边读边写”绕过初始化证明。
word 12 没有独立 window；若 `src2` alias 某个已声明 window，则该 alias 对应的 transient window 同样
作为读区间接受完整覆盖检查。该规则同时作用于 graph compile 和重新签名后的 bundle load，不能靠修改
metadata/hash 绕过。

## 4. GGML compiled backend 与 Host Runtime 边界

### 4.1 compiled-only GGML plan/admission

`libggml-npu-compiled.so` 是独立 GGML backend module，只直接链接 `ggml-base` 和
`npu-host-runtime`；它不链接 legacy `npu-verilator-runner`，也不依赖生成的 per-owner profile header。
legacy `libggml-npu.so` 仍保留作兼容路径，当前尚未被这个 module 替换。

versioned plan API 的生命周期是：

1. `plan_load_v1(backend, bundle_dir)` 严格读取并验证三件套；失败时 plan 不可 seal；
2. `plan_bind_node_v1(...)` 把 artifact node id 精确绑定到一个 GGML compute tensor 指针和它在完整图中的
   index；command 顺序必须与这些 index 严格一致；
3. `plan_bind_buffer_v1(...)` 必须绑定 metadata 中的每个 BufferId，包括 input、output、weight 和
   transient；offset/bytes 必须精确落在对应 tensor 的静态 byte range，不能只绑定图的外部 IO；
4. `plan_seal_v1(backend, full_graph)` 接收 scheduler 切分前的完整原图，验证 node/source edge、command
   顺序、relocation role、P00 tensor 语义和全图 consumer closure，并保存完整图的 node/source snapshot；
5. seal 成功后，`supports_op()` 才只对精确绑定的 compute tensor 指针返回 true；metadata op 可以继续由
   GGML 正常处理，未绑定 compute op 一律返回 false；
6. scheduler 分配 tensor storage 后，把对应 NPU split 交给 `graph_compute()`；它重新验证完整图 snapshot、
   split 中 compute tensor 的精确有序集合、实际 storage range、weight bytes 和 plan 合同，然后整批调用
   Host Runtime；
7. `plan_clear_v1()` 或 backend destruction 注销 admission 并销毁 runtime/session。

bind 和 seal 的静态检查不读取 `tensor->data`，因此 no-alloc graph 可以先建立 admission，GGML scheduler
随后再根据 `supports_op()` 形成 split 并分配 storage。seal 本身不构造 `SystemTop`。只有第一次合法
`graph_compute()` 在所有需要 storage 的检查通过后，才惰性构造一个 production `npu_host_runtime`；后续
generation 复用同一 runtime、固定 firmware 和 `SystemTop`。错误的完整图、partial bundle、错误 split、
storage/weight 篡改等 preflight 失败不会构造 runtime、不会消费 generation，也不会发布 output。

seal 的完整图检查还关闭 private transient 的消费者集合：每个 transient destination 必须由更晚的已绑定
bundle command 消费；任何 unbound/CPU node 对 private transient 的 fan-out 都会拒绝；没有后续 bundle
consumer 的 terminal command 必须写 output，不能把 private transient 留给 bundle 外读取。这是 GGML
拓扑层的 consumer closure，与 artifact 层按 byte window 验证的 transient read-before-write 互补。

当前 v1 backend 有意 fail closed 到一个很窄的可执行集合：local profile P00、dense contiguous F32 ADD、
只允许 exact T16 的 offset-zero metadata VIEW，不允许 broadcast、非零 offset、任意 shape VIEW 或独立
src2/scratch；现有 tiny fixture 是两个 16-element ADD command，其中第一个使用 P00-shaped VIEW 并写
private transient，第二个读取它并发布 output。该 fixture 只验证 descriptor/runtime/scheduler 合同，不携带
真实 Qwen canonical provenance。这一限制属于 backend capability，不能因为 artifact ABI 能表达其它
descriptor 就推断其它 owner 已可由 GGML 执行。

### 4.2 Host Runtime

Host Runtime 可以：

- 读取和验证 artifact 原始字节；
- 分配、注册和搬运未变换的 buffer bytes；
- 将 runtime tensor/address 绑定到 BufferId；
- 在 private shadow 中应用 relocation；
- 建立 launch descriptor/submission mailbox；
- 驱动仿真时钟、ready-valid 和 completion；
- 对 identity、generation、bytes/MAC/elements ledger 做闭合审计。

Host Runtime 不可以：

- 重新判断 GGML op 应由哪个 NPU kernel 执行；
- 执行量化、反量化、矩阵乘、elementwise、norm、softmax、RoPE 或其它 required tensor arithmetic；
- 在 artifact/runtime 验证失败后透明调用 CPU kernel；
- 在部分 command 成功后发布 dispatch-private destination arena。

当前实现采用 copy-on-submit：只读 `command.bin`/`weights.bin`/`metadata.json` 原始字节 -> 独立
revalidate 得到 canonical bundle -> mutable private command shadow 和 private tensor arena -> 完整
relocation -> 一个 submission。调用方能修改公开 C++ parsed struct，但这些 side table 不具有 authority；
production runtime 只从三份重新验证过的原始字节恢复 owner/workload/publication。completion 只有在
generation、完整 command cardinality、mailbox status、identity 和 ledger 全匹配后，才在唯一 commit point
按 publication plan 把 private output 拷贝到外部 buffer。任何 preflight、relocation、executor、固件或
协议失败均不得修改外部 output。

## 5. 固定 RV64 Firmware ABI 1.3

首个仿真 ABI 使用 CPU 的 non-cacheable SDRAM aperture `0x0000_0000_a000_0000`，而不是 cacheable
PMEM。mailbox 是单生产者/单消费者、depth-1 submission；command payload 位于同一 NC aperture。

```text
0xa0000000  submission header (64 bytes)
0xa0000100  resolved command records (N x 240 bytes)
0xa0100000  completion records
0xa0200000  pre/post DMA table (N x 48 bytes)
0xa0300000  RTL DMA MMIO registers
```

submission header 1.3 包含：magic、major/minor、state、command count、240-byte stride、generation、
command base、completion base、completed count、error 和 boot count。`reserved0` 的 bit 0 允许
pre/post DMA table，其余 bit 必须为零。Firmware 在 CONFIG 前完成 pre-DMA、NPU terminal
之后完成 post-DMA，再发布该命令 completion；DMA 由真实 `TensorNpuServiceDma` RTL 执行。
完整 ABI 见 [firmware/README.md](../firmware/README.md)。状态转换为：

```text
FREE/DONE
  -- host writes payload, strictly newer nonzero generation, release, then READY --> READY
READY
  -- firmware acquire + header validation --> RUNNING
RUNNING
  -- all commands succeed, payload first, release state last --> DONE
RUNNING
  -- validation or recoverable execution failure --> ERROR
```

firmware 对每条 record 执行固定、静态展开的 30 个 `LD + CONFIG`。descriptor index 位于 CONFIG
instruction `[24:20]`，因此不能用一个普通 runtime loop 变量替换这 30 个编码。随后执行固定且相邻的
LO/HI；CPU 现有 PairOwner 和 ROB sidecar 会把它们作为一个精确事务，在真实 terminal 之后才退休。

CPU/NPU precise-fault ABI 使用 `mcause=24` 和带版本的 `mtval v1`，completion 同时记录 fault tval、PC
和 cause。recoverable NPU fault 由 trap handler 保存原始 CSR、执行唯一允许的
CONFIG30 recovery clear，再发布 `ERROR / NPU_FAULT / status=1`，并以 `mret` 回到固定 daemon；同一 `SystemTop` 无 reset 即可接受下一代合法
submission。fatal fault 发布 `ERROR / NPU_FATAL / status=2` 后永久停机，Host Runtime 将 session 标为
poisoned，后续 generation 在无硬件活动的情况下 fail closed。RTL sticky error 期间，除 CONFIG30 外的
CONFIG 都只能得到精确错误，不能改写 descriptor/NPU 状态；错误不能用隐式 reset 掩盖。

## 6. 内存与发布顺序

当前 `mem_idle && mem_retire_quiet` 只证明 RV64 core 自己更老的访存已经排空，不代表 host、CPU cache
和 NPU DMA 一致。当前 ABI 因此要求 mailbox/descriptor 使用 NC shared aperture，tensor arena 使用显式注册的
NPU IOVA window。顺序合同为：

```text
host writes weights/inputs/descriptor shadow
  -> completes relocation and range checks
  -> DMA sync/cache clean where applicable
  -> release publishes READY

firmware acquire observes READY
  -> snapshots and validates header
  -> fence
  -> CONFIG + LO/HI

NPU drains all accepted memory requests
  -> terminal
  -> RV64 launch commits
  -> firmware writes completion payload
  -> release publishes DONE/ERROR

host acquire observes completion state
  -> validates generation/identity/ledger
  -> publishes destination arena
```

## 7. 分阶段迁移与可观察验收

Phase A/B/C 和既有 P00 vertical slice 保留直接回归。Phase D 新增完整模型 Compiler、全 owner
Host Runtime、Firmware ABI 1.3 的真实 DMA 和 llama.cpp 实际 token loop。完整 Qwen 两代生成已通过：
实际 token 为 `[283, 220]`，2160 个 required command 全部完成，constructor/reset/boot 均为 1，
CPU tensor fallback 为零。证据与复现入口见 [完整模型验收](NPU_COMPILED_MODEL.md#运行与可审计验收)。

### Phase A：artifact 与中性 command ABI

- 同一 tiny graph 两次编译生成 byte-identical 三件套；
- v3 provenance 对 source manifest/GraphIR、source/command descriptor、source/artifact schedule 和
  logical/storage buffer identity 做 exact-cover；Python 与 C++ trust boundary 对称拒绝 mutation；
- 30-word pack/unpack 与旧 runner 映射逐字相同；
- bad magic/version/truncation/hash/overlap/relocation/bounds 均在提交前拒绝；
- weights 对齐、hash、去重可验证；
- 现有 per-node runner 改用同一个 pack 函数，删除第二份 mapping。

### Phase B：固定 firmware、两命令单 boot

- stock GNU RV64 工具链生成 ELF + flat binary，entry 为 `0x80000000`；
- CONFIG 30 个 index 均存在，LO/HI 相邻；
- 一个 SystemTop constructor、一次 reset release；
- 两个有数据依赖的非空 command，60 CONFIG、2 launch、2 terminal、2 completion；
- 两条命令的 sequence/producer/generation 各自匹配；
- 输出与旧路径 bit-exact；
- 命令间 descriptor、sidecar、NPU、GMEM/portal outstanding 全部回到 clean state。

### Phase C：可恢复 persistent session

- 增加 firmware 可读 fault status；
- 增加只在无 outstanding/inflight 时生效的 CLEAR/ABORT；
- 第一条故意失败、第二条合法，无全局 reset，第二条仍成功；
- 失败 command destination 不发布，terminal exactly once。

### Phase D：GGML compiled subgraph runtime

当前已经完成并验证的 vertical slice：

- 独立 `libggml-npu-compiled.so` 经 GGML 动态 backend loader 加载，测试程序不直链 backend/runtime；
- 显式 load/bind/seal API；seal 接完整原图，并在 no-alloc 状态完成精确 compute admission；
- 完整图 transient consumer closure、scheduler split 精确匹配、实际 storage/weight 和 artifact 重验证；
- 第一次合法 `graph_compute` 惰性创建 Host Runtime，后续 generation 复用同一 persistent SystemTop；
- GGML scheduler 实际形成一个 CPU-prefix/NPU-bundle split，synthetic P00-shaped F32 ADD tiny bundle 连续
  两代成功；两个 NPU command 每代只触发一次整批 execute，required NPU 节点 CPU fallback 为零；
- partial/wrong split、图或 storage 篡改、weight identity 错误和 transient 向 bundle 外 fan-out 都在提交前
  fail closed，不消费 runtime generation；
- exact Qwen manifest 的 1080 required nodes 已按六个 owner family 无 gap/overlap 分类；第一个真实 P00
  已选择 graph index 30/source schedule position 15，保留 node29 VIEW -> node28 root，读取 external index 8
  的 `blk.0.ssm_dt.bias` 原始 64 bytes，并生成 Python/C++ loader 可重新验证的单 command v3 bundle；
- v2 从完整 manifest 自动解析 node/buffer，验证整图及 external descriptor、canonical/source schedule 和
  VIEW/storage root，未分配 storage 时完成 seal；两代真实 P00 执行共享一次 constructor/reset/boot；
- canonical v1 手工 binding 被禁止，完整图中未编译 required node 明确失败，不产生 CPU tensor fallback。
  入口和复验命令见 [compiler/README.md](../compiler/README.md#canonical-graph-binding-and-launch-api-v2)。

全模型路径新增的 Phase D 实现：

- `libggml-npu-model.so` 编译整个实际 dispatch，生成 1080 条 command 和完整原始权重产物；
- 六个 owner family 共享同一 persistent service，Host 不调用旧 per-node executor；
- 保留 GGML allocator alias、VIEW/storage root 和跨代 KV/recurrent state；
- command 地址模板归零，Runtime 读取 metadata 后重定位；所有中间结果留在 private arena；
- Firmware 配置真实 RTL DMA，在每命令 pre/post copy 完成后有序推进；
- 实际生成必须通过冻结 token oracle、两代 strict audit、2160 次有序 launch/terminal 和单 boot 校验。

当前生产验收剩余项为完整 bootstrap → steady 的真实 token 结果。
通用旧 runner 默认入口仍保留；新实际模型脚本显式选择 `libggml-npu-model.so`。
没有跨代 compiler cache、通用模型/shape 支持、graph fusion 或异步 queue。

### Phase E：优化

在基线可测之后才逐项加入：真正的 graph fusion、lifetime arena reuse、kernel tiling search、weight
reorder、ring queue、IRQ、异步 launch 或 descriptor-pointer ISA。每项必须有对应 RTL capability、数值
合同和 A/B 数据，不能仅修改 metadata 标志。

## 8. 不变量

1. required op 不支持、artifact 不匹配、runtime/firmware/NPU 错误时 fail closed，禁止 CPU tensor fallback；
2. firmware text 是固定、可审计的 RV64 binary，host 输入只是 descriptor 数据；
3. artifact struct 不用 C/C++ raw struct dump，所有整数显式 little-endian 编码；
4. command、weights、metadata 的 identity 必须一致，不允许跨 bundle 混用；
5. relocation 只作用于 dispatch-private shadow；
6. completion exact-once，且必须匹配完整 ProducerId/sequence/node identity；
7. 已 fire 的 NPU/GMEM transaction 不可取消，错误路径先 drain 再报告；
8. no-alloc `supports_op` 只表示完整图上已 seal 的静态 admission，不表示 storage、runtime 或 generation
   已经建立；
9. transient 必须同时满足 artifact byte-level read-before-write 和 GGML full-graph consumer closure；
10. 功能仿真结果只证明功能和协议，不外推综合、STA、PPA 或真实 silicon tokens/s。
