# RV64 架构能力与 PPA 对抗合同

> **性质**：NORMATIVE，版本 v2（2026-07-16）。本合同是
> `ooo-core-architecture.md` §8.5 的可执行验收层。任何“性能/面积/功耗优化”只有先通过
> 本合同的功能、架构和 5 ns 门槛，才有资格进入 Pareto 比较。

## 1. 优化问题定义

本轮不是把一个数字压低，而是在固定产品能力下求解：

```text
feasible = functional && architecture && timing_tier_gate
best     = ParetoFront(feasible, maximize performance,
                                  minimize area,
                                  minimize power)
```

功能、双发射、真 OoO 和目标时序是硬约束，不是可与面积或功耗兑换的软分。单一综合分只用于
同一 Pareto front 内排序，不能把任一 hard-gate failure 洗成“总体更好”。

## 2. 固定产品与微架构底线

### 2.1 产品范围

- RV64IMAFDC + Zicsr + Zba/Zbb/Zbc/Zbs，M/S/U，Sv39，PMP×16，硬件 A/D；
- 单 hart，精确异常/中断，当前 AXI4 profile，CLINT/PLIC/UART/virtio-blk；
- ROB≥16、整数/FP IQ≥8、整数/FP PRF≥64、LQ≥4、SQ≥4；降低这些容量须以同等级架构测试证明
  无能力丢失并建立新 cohort，不能静默替换本基线；
- system/trap 可在 ROB 队头串行；branch/jump/load/store/AMO/FP 必须留在域 A 的正式 OoO 路径。

### 2.2 完整双发射门槛（DI）

- **DI-1 frontend II**：cache hit、无 redirect、下游持续 ready，预热后连续 64 包中每拍
  accept/produce 1 包；latency 任意，initiation interval 必须为 1。
- **DI-2 width continuity**：fetch/decode/rename/dispatch/issue/execute/retire 各边界都有
  64-cycle 非真空轨迹达到 2 uop/cycle；独立整数 ALU microbenchmark 稳态 IPC≥1.90
  （CPI≤0.526316）。可执行入口固定为
  `make -C npc/rv64 check-width-continuity`：以首个 fetch request fire 为唯一锚点，固定预热
  24 拍后连续采样 64 拍；focused 证据要求七边界各 `total=128/peak=2/dual=64`，并以
  PC、instruction payload、full ProducerId 生命周期及 RenameMap/ROB/IQ/EX/WB 独立 sink
  对账拒绝数量别名。该入口只裁决 DI-2；架构稳定冻结完成前不赋予 PPA 资格。
- **DI-3 complete pair matrix**：`ALU+ALU`、`ALU+branch`、`ALU+JAL/JALR`、
  `ALU+load`、`ALU+store` 均须通过，且两条在程序中的先后位置互换后仍能形成 pair；
  `load+load`、`load+store`、`store+load`、`store+store` 在地址独立、对齐、cacheable、
  TLB/cache hit、credit 充足且无 bank/端口冲突时，也必须同拍从 IQ 被两个独立 memory
  terminal owner 接纳。真实 alias、同 bank 或序列化属性可等待/replay，但必须由逐请求冲突事实
  约束，不能以单 LSU 为由静态串行全部双 memory pair。
  capability steering 若把 younger memory 放到 Universal terminal，则其 pop/reservation
  capture 必须蕴含 older partner 同拍 fire；不得产生 orphan memory owner。
- **DI-4 no static lane semantics**：程序位置/lane 编号不得决定 uop 是否永远可执行。
  物理 terminal 可以非对称，甚至可以有一个固定 simple-ALU terminal；但每个 IQ entry 必须
  保存能力元数据，并由 swap/promotion/steering 把 uop 动态送到有能力的 terminal。若把
  decode/dispatch lane1 永久绑定 simple-only 能力，或没有 swap/promotion 而只在两条都是
  simple ALU 时才称“双发射”，DI-4 失败。物理 ALU terminal 的 LSU tie-off 本身不判
  DI-4；双 memory 能力只由 DI-3/DI-5 的两路 owner/AGU/translation/order/cache 事实裁决。
- **DI-5 dual-memory datapath**：最终候选必须具有两路独立 AGU、每拍两路地址翻译接纳、
  两路 LSQ/SQ 物理字节消歧查询、两路 cache request admission 以及两路 memory issue
  credit；实现可以是两个 LSU，也可以是单个模块内部的真正双通道 LSU。64-cycle 独立、
  alternating-bank、cache-hit memory 轨迹的稳态 issue IPC 必须≥1.90。只有一个 AGU/翻译入口/
  请求 owner、第二条仅在 LSU 外排队，或以单端口 reservation 将全部 memory 串行化，均为
  `architecture_infeasible`。
  R3/R3.1 的单 Universal + simple-ALU terminal 方案在 capability metadata、动态 swap 与
  directed permutation 证据齐备时可通过 DI-4，并作为恢复 ALU+complex pairing 与
  reservation liveness 的阶段证据；但在补齐 DI-3 双 memory matrix 与 DI-5 前仍是
  `architecture_infeasible`，不得替换 canonical baseline。

### 2.3 真 OoO 门槛（OOO）

- **OOO-1 long-latency bypass**：一条老 load miss、Mul 或 Div 未完成期间，至少 8 条年轻、
  无依赖 ALU 在其前 exactly-once 完成，ROB peak occupancy≥9（老指令 + 8 younger）；
  最终 retire 顺序仍与程序序一致，ROB/IQ/free-list 全恢复。
- **OOO-2 selective scheduling**：资源阻塞只阻塞依赖项或争用同一资源的项；不得用任意
  older-valid、单 reservation 或 raw lane0 freeze 阻塞所有年轻可执行项。registered
  Universal owner 驻留时，IQ 中 sole ready ALU-capable uop 也必须能用独立 terminal 前进。
- **OOO-3 memory ordering**：non-alias younger load 可越过 older store；alias 情形必须
  forward、等待或 replay，绝不能读到旧值；flush/kill 不留 SQ/MIQ/LQ ghost。
  两路 store 可提前完成 AGU、翻译、权限检查、SQ 分配与无副作用 cache preview，但真实
  cache/AXI/device write 必须等该 store 到达 ROB head、所有更老异常与 recovery 已排除，取得
  `commit_authorized` 后才能 exactly-once fire。为保留 T4N 的 precise AXI-B 语义，该 store
  在聚合 B 成功前不得退休；`SLVERR/DECERR` 必须以该 store PC 精确陷阱。flush 只能 drain
  已 fire 事务，不能取消外部副作用或重复 fire。这里的 ROB-head authorization 是不可回滚的
  提交许可，不等同于已经退休；禁止把它误写成投机 store，也禁止以等待 B 为由串行化前端
  双 memory issue/AGU/翻译/物理消歧。
- **OOO-4 speculation/recovery**：多条控制流在飞、最老 mispredict 胜出、wrong-path
  uop/request selective squash；已 fire AXI 事务 drain；同一指令 exactly-once complete/retire。

### 2.4 禁止的“优化”

- 删除某个物理 terminal 的 control/memory/复杂整数能力，却不提供逐项 capability metadata
  与动态 swap/promotion，仍以端口数宣称完整双发射；
- 以“共享单 LSU”为理由免测双 memory pair，或把第二条 memory 只移出 IQ、却未被独立
  AGU/翻译/LSQ owner 同拍接纳；
- 将 memory 选择改成“只有 IQ 中没有任何更老 valid 才能晋升”；
- 把 fetch cache hit 稳态退化为 `RESP→CACHE_READ→LOOKUP` 三拍一包；
- 通过 false path、减少测试集合、换 benchmark image、复用旧网表或把 unknown macro 当 0
  获得更好的 PPA 数字；
- 以 CoreMark 单点改善替代全量/代表样本，或用 host wall time 替代 RTL cycles/retired。

## 3. 功能 hard gates

同一个 `design_id`、配置、仿真 binary 和 benchmark image 必须绑定以下证据：

- module TB required set 必须从当前 `npc/rv64/testbench/Makefile` 的 `TESTS` exact-membership
  动态推导并全过、failure=0（2026-07-21 清单为 109；任何仍固定历史 102 的 policy/aggregate
  均不得用于新 arch-stable 或 PPA promotion）；
- official/privileged riscv-tests 177/177；AM cpu-tests 59/59；适用范围 Difftest mismatch=0；
- CoreMark 10 iterations、`crcfinal=0xfcaf`、恰好一次 GOOD TRAP；
- Dhrystone 固定 10000 runs、恰好一次 GOOD TRAP；
- fixed image A/B 时，v3 选定 PC 区间的 retired instructions 必须完全一致；whole-program
  exit 计数只作语义、终止和动态尾段诊断，尾段可随设计变化，不得用于 CPI 或 retired
  equality。Linux 暂按用户要求延后，故本轮不得宣称 system-complete，但不影响
  microarchitecture/PPA candidate 的阶段裁决。

### 3.1 性能原始证据与计数域

promotion 性能证据固定为 `npc-rv64-performance-evidence-v3`；解析器可显式兼容历史 v2，
但本策略不得选择 v2。CoreMark 与 Dhrystone 各至少三次，每次 repetition 必须以不可复用的
artifact kind 和工作区相对 path 独立绑定一份原始日志；当前策略将六个 raw-log kind 全部列为
required artifact，candidate/accepted 的 `design_binding_manifest.artifacts` 必须逐项包含它们。
确定性运行允许不同 path/kind 的日志具有相同 SHA-256，但绝不允许多个 repetition 复用同一个
kind 或 path。

- CoreMark 的 `counter_scope=pc_bounded_region_v1`，start PC 固定
  `0x00000000800017a8`，stop PC 固定 `0x00000000800017b0`；start 必须采用
  `first_committed_hit`，RESULT 必须为 `start_hits=1`、`end_hits=1`。
- Dhrystone 的 `counter_scope=pc_bounded_region_v1`，start PC 固定
  `0x0000000080000334`，stop PC 固定 `0x000000008000047c`；start 必须采用
  `first_committed_hit`，RESULT 必须为 `start_hits=10000`、`end_hits=1`。
- 每份日志必须恰有一个已捕获的 start boundary、一个 `kind=end` stop boundary 和一个
  RESULT；boundary/RESULT 的 cycle/retired 必须互相一致，选定区间计数严格等于
  stop-start。benchmark summary 与三个 repetition 必须声明相同 scope，逐份匹配解析计数，
  且三份选定 cycles/retired pair bit-exact。
- whole-program exit 仍必须验证 PASS、恰好一次 GOOD TRAP、零退出、CoreMark
  iterations/CRC、Dhrystone runs，并确认区间未越出整程；region 后的 dynamic tail 仅作诊断，
  允许不同设计间变化。whole-program cycles/commits 不得用于 CPI、IPC、throughput 或选定
  retired equality。
- 全局 `performance.cpi_scope`、whole/region 混算、用整程计数冒充 v3 区间、只解析一份
  raw log 却复制三次计数，均为结构错误。

## 4. 基线集合

当前没有一个历史点同时满足全部目标，因此采用**合取式基线集合**，禁止把不同证据拼成一个
虚假的全绿 design：

| anchor | 作用 | 固定值 | 限制 |
| --- | --- | --- | --- |
| T4T provisional seed | current 功能、5 ns proxy、逻辑面积 seed | CoreMark `6556915/3218532`, CPI 2.037；Dhrystone10k CPI 2.797；5ns worst slack +0.179479554ns；logic area 1622367.04 | 功能/benchmark/synth 尚未跨域同源绑定；unknown macro；不是完整双发射/真 OoO 证明 |
| G2 performance anchor | 恢复吞吐的历史参考 | CoreMark `2852201/3218573`, CPI 0.886 | 旧 exact-5ns WNS≈-9.99ns；不能冒充当前 PPA baseline |
| R3.6 architecture-infeasible measurement anchor | 首个完整架构的固定恢复测量锚 | CoreMark `4904511/3183617`, CPI 1.540546805724；Dhrystone10k `9481620/4250000`, CPI 2.230969411765；5ns slack +0.131591633ns；logic area 1605803.92 | 只有一路完整 memory owner/AGU/translation/order/cache admission，九项架构 gate 均未闭合；永远不可 canonical、front accepted 或 champion |
| R4-P0A implementation floor | 本轮不可回退的 semantic/timing checkpoint | 两 benchmark 与 R3.6 cycle-exact；5ns slack +0.103599802ns；logic area 1606094.84 | 保留 R4-S0 final-PA/PBMT/PMA correctness 与 distributed WB-valid；九门仍全 RED、Power unqualified，只能列入 implementation checkpoint |
| architecture floor | 不可退化能力 | §2 DI/OOO 全部 PASS | 当前缺少完整 directed evidence，故 T4T 只可为 provisional seed |

canonical baseline 只能由一次 fresh 同源 run 产生：source/config→sim binary→benchmark image→
netlist→STA 全部 hash 绑定，并通过 §2/§3/§5。未完成前，任何候选都标为 recovery candidate，
不得宣称“最终最优”。

### 4.1 新一轮优化基线与单调约束

从 R4-P0A 开始，基线是合取而不是任选一个最有利的历史数字：

1. **能力/语义 floor**：候选必须保留 R4-S0 的 final-PA PMA/PBMT、SQ provenance、B-terminal
   cache maintenance，以及 R4-P0A 两路最终 WB owner write-valid；任何对应
   mutation-negative 未能杀死变异即拒绝，不能以面积或 CPI 改善抵消。
2. **性能 anchor**：在第一个 architecture-feasible seed 产生前，CoreMark 与 Dhrystone 分别以
   R3.6 固定镜像计数为基准，各自 throughput ratio≥0.995；不得用几何平均掩盖单项回退。
3. **时序 floor**：每个保留候选都必须在相同 partial-constraint cohort 下满足 5.000ns、
   worst slack≥+0.10ns、TNS=0、violations=0、loops=0。R4-P0A 的
   +0.103599802ns 是当前最小已验证 reserve，不是可被功能收益透支的软分。
4. **面积/Power**：首个完整架构只享受 §6.1 的一次性 1.10× logic-area ceiling；之后立即恢复
   0.999 area-efficiency 与 Pareto dominance。Power 在 activity coverage≥95% 且 macro
   internal/leakage 完整前保持 unqualified，不允许用 vectorless 数字决定三轴冠军。
5. **排名资格**：九项 DI/OOO、功能与 timing gate 全绿之前，所有 P/A 数字只用于候选诊断；
   不能进入 front。完整 Power 和 total area 闭合前，最多产生 architecture seed，不能产生
   canonical 或“PPA 三者最优”。

机器索引为 `npc/rv64/eval/ppa/baselines/index.json`：R3.6 保持
`engineering_recovery_baseline`，R4-S0/R4-P0A 只进入
`implementation_correctness_checkpoints`，`canonical` 与 `architecture_feasible_seed` 在真实
九门证据出现前必须保持 `null`。

性能里程碑固定为：先恢复 CoreMark CPI≤0.90，再到≤0.65，最终≤0.60；每级都须保持
DI/OOO、功能和 5 ns 门槛。

## 5. Timing、Area、Power 证据等级

### 5.1 Timing tier

1. `rtl_proxy_partial_constraints`：mapped netlist + exact 5ns、ideal clock、允许版本化 warning/
   placeholder macro；只能称“5 ns proxy met”。候选须 WNS≥0、TNS=0、violations=0、loops=0，
   且 worst slack≥0.10ns 才可替换 proxy champion。
2. `prelayout_constrained`：真实 macro liberty、完整 IO/generated clock/uncertainty、多 corner，
   所有内部 endpoint constrained；可称 pre-layout closure。
3. `postroute_physical_signoff`：P&R/CTS/SPEF/OCV、多 PVT/RC corner、setup/hold clean；只有
   此层可称 physical 200MHz。

T4T 属第 1 层，仍有 304 missing input、1906 missing output、1908 unconstrained endpoints。

### 5.2 面积与功耗口径

- 当前 `1622367.04` 只能叫 `logic_area_proxy_excluding_unknown_macros`；
  `Sram4096x199`、`Sram4096x113`、`OooFpArithGate`、`OooBranchDirectionPredictor`
  面积 unknown，故 total area 为空。
- 当前 `0.118 W` 是无 workload activity、macro=0 W 的 vectorless logic proxy，不能作为
  total power，也不参与 canonical promotion score。
- 面积比较要求相同 PDK/lib/blackbox inventory；功耗比较要求同一 workload SAIF/VCD、
  activity coverage≥95% 且 macro power 完整。条件未满足时该轴显示 `unqualified`，不能填 0。

## 6. PPA 三轴对抗与晋级

对同 cohort 候选，性能取 `q_i = qualified_mhz / CPI_i`，CoreMark/Dhrystone 默认各 0.5 权重：

```text
P_ratio = geometric_mean(q_candidate / q_baseline)
A_ratio = area_baseline / area_candidate
W_ratio = power_baseline / power_candidate
```

只有 qualified power 存在时才形成完整 Performance/Area/Power 三轴；当前阶段用
`Performance/Area + timing hard gate` 排序，时序不是可拿分补偿的第四软轴。epsilon 固定为
performance 0.1%、area 0.1%、power 0.5%。三轴均不劣且至少一轴显著更好才构成
Pareto dominance；互有得失则并列 Pareto front。

`proxy_champion` 允许宏面积/功耗仍为 unqualified，但只能称同口径 P/A 恢复候选；
`final_champion` 必须额外具备完整 total area、同 workload 活动覆盖≥95%的 macro-inclusive
power，且两端 manifest 均通过 checker。前者不得扩写成“PPA 三轴最优”。

同一 front 内可用等权几何平均分排序，但晋级仍须同时满足：所有 hard gate PASS、未被支配、
performance ratio≥0.995、area≤baseline×1.10、proxy slack≥0.10ns，且 score>100.2。
任何 architecture/functional/timing failure 直接拒绝。

### 6.1 一次性 `architecture_feasible_seed` 过渡

R3.6 是为恢复吞吐、面积和时序而冻结的**测量锚**，不是架构可行设计。若强迫第一个补齐
双 memory datapath、九项 DI/OOO gate 的实现同时满足相对 R3.6 的 Pareto dominance 和
`area_efficiency≥0.999`，则总增量上限仅约 `1607.41` area；当前 S0 correctness checkpoint
已用去 `619.36`，留给后续完整双 memory 架构约 `988.05`，形成不可实现的错误基线。
因此只允许一次、且只允许从 R3.6 发起以下过渡：

- 候选必须先由常规 checker 全量审计；§2 九项 architecture hard gate 和 §3 全部功能 gate
  均为 GREEN，不能用 manifest 自报布尔值替代可执行证据；
- CoreMark 与 Dhrystone10k 各自 throughput 不得低于 R3.6 的 `0.995`，固定镜像选定区间的
  retired instructions 必须相等；不允许几何平均掩盖单项回退；
- exact 5ns proxy 的 worst slack≥`+0.10ns`、WNS≥0、TNS=0、violations=0、loops=0；
- 同一逻辑面积口径下 `logic_area≤1605803.92×1.10=1766384.312`；
- **仅本过渡**不要求 candidate dominance，也不应用常规 `area_efficiency≥0.999`。该例外
  只补偿“恢复被 R3.6 删除的强制架构能力”，不得用于第二个候选或后续 PPA 取舍。

Power 采用分层 fail-closed 语义：优先要求同 workload、activity coverage≥95%、macro-inclusive
的 qualified power。若 power 仍 unqualified，候选最多登记为
`architecture_feasible_seed`，其 `front accepted=false`、`canonical=false`、
`PPA champion=false`；它只能证明“第一个架构可行点存在”。只有 power qualified 后，该 seed
才可作为初始 feasible front 的比较基线/canonical measurement reference，但 seed 本身仍不因
本过渡获得 champion 称号。若 total area 仍因 macro area 缺失而 unqualified，即使 power 已
qualified，也不得 front accepted/canonical。

首个 seed 写入 baseline index 后，第二次 seed 过渡必须拒绝。所有后续候选立即恢复常规
`candidate dominance`、`area_efficiency≥0.999`、per-benchmark≥`0.995`、全局 Pareto front
和三轴 power 资格规则；不得继续引用本节例外。若已记录的首 seed 仍缺 qualified power 或
total area，后续只能做 engineering comparison，formal front 必须等待该 seed 补齐资格，
不能借“再选一个 seed”绕过。机器裁决入口为
`npc/rv64/eval/ppa/tools/architecture_seed.py`。

## 7. A/B 可复现纪律

- A-B-B-A-A-B（每设计各 3 次），且 performance 的 cycles/retired 必须 bit-exact；
- fresh synth/STA 每设计至少 2 次，固定 seed/threads，优先要求 netlist SHA、area、path member set
  bit-exact；
- 独立输出目录 + 全局锁，禁止共用可变 `npc/sim` build；
- manifest 只引用工作区内、内容寻址且 hash 校验的证据；不得依赖系统 `/tmp`；
- 每刀同时记录保留/拒绝原因。负候选留 task-run 证据，不污染 canonical baseline。

机器策略、provisional seed 和 checker 位于 `npc/rv64/eval/ppa/`。
