# RV64 V13A current PPA hotspot / StoreQueue byte-CAM slice

Status: DEVELOPMENT CHECKPOINT PASS / full-core mapped+STA GAP / not promotable

## Completion definition

- Parent design: `sha256:882111fb3d58039cb7414e6331dac0c10d848463df2228dff93ae22dafbed67b`.
- Slice: keep `OooStoreQueue` state, ports, capacity and lifecycle unchanged; replace only the two duplicated final-PA physical-byte query cones.
- Complete when focused positive、故意错误 data-placement 控制和四态未知量反例均被检出，StoreQueue/ordering integration tests pass，synthesis reports no inferred latch or logic loop, and same-command structural or mapped evidence shows a reduction.
- This is an `intermediate_checkpoint`; full functional cohort, system recertification and promotion-grade two-run synth/STA remain round-delivery work.
- Stop/revert condition: any allow/forward/replay, youngest-byte, typed-class, IO, recovery, B-terminal or assertion semantic mismatch.

## 接口契约冻结（阶段 0）

| 契约 | 本切片冻结内容 |
| --- | --- |
| handshake | `query[01]` 无 valid/ready 状态；valid 仅限定当拍输出，两个 query 独立，不交叉借用 metadata。 |
| stall | 不新增 ready、credit 或 backpressure；不读取同拍 release/free 形成 query 判决。 |
| flush/priority | 查询只读 edge-old SQ Q-state；flush/release/request/B 的状态更新与优先级完全不改。 |
| exception order | 不改 terminal、ROB-head authorization、late-B completion 或 release。 |
| memory order | older valid non-terminal entry 参与；任何 older IO store 或 IO query 对 live older entry 均序列化；unknown/illegal/class mismatch/partial coverage replay；head→tail 后写覆盖保证 youngest older store wins。仿真中可能参与判定的 valid/age/terminal/fill/PA/type/strb/selected-data 未知量必须 replay，已知 invalid/younger/terminal entry 的无关 payload 不得造成过度 replay。 |
| recovery/source of truth | `valid_q/filled_q/terminal_q/paddr_q/class_q/data_q/strb_q/producer_id_q` 仍是唯一真源，不镜像任何跨拍 query 状态。 |

本次不新增接口断言，因为状态与协议边界不变；已有 `[V8T-SQ-*]`/`[V8V-*]` 断言保持且不得削弱。新增验证重点是字节映射反例与综合无 latch/loop。

## RTL 四段式推导

### 阶段 1 — 需求

- 功能：逐字节保持现有 final-PA allow/forward/replay 与 forward-data 结果。
- 性能/PPA：删除每 query 的 `4 × 8 × 8` 宽地址加法/比较阵列及过程循环反馈锥。
- 边界：只改 `OooStoreQueue` 内部组合查询；无端口、拍边界、容量或 owner 生命周期变化。
- Out of scope：SQ 分配/绑定/fill/terminal/release、双 memory admission、bridge、LQ、ROB、性能 counter 与系统事务。

### 阶段 2a — 协议规则

- query valid 为 1 时必须 onehot 产出 allow/forward/replay；valid 非精确 1 时全零。
- 每个 store byte `j` 的 PA 是 `store_base+j`，每个 load byte `i` 的 PA 是 `load_base+i`；仅相等且两边 mask 有效的字节 overlap。
- overlap 可由基址差对齐 store mask/data 得到；`|delta| >= 8` 等价于无 overlap。
- 任意 poison 优先于 coverage；有 overlap 但请求 mask 未全覆盖必须 replay。
- 四态仿真只允许已知 invalid、younger 或 terminal entry 忽略无关 payload；其它可能参与的未知事实不得产生 optimistic allow/forward。

### 阶段 2b — 状态机

无新增 FSM、寄存器或跨拍状态。查询是 edge-old SQ Q-state 到组合输出的 Mealy 只读网络。

### 阶段 2c — 不变量

1. `allow/forward/replay` onehot0；valid 且输入合法时必须 onehot。
2. aligned mask 的每一位与历史双循环 byte-address equality 等价。
3. 只有 overlap mask 对应的 byte lane 可写 forward-data；非 overlap lane 保持零或先前 younger-wins 合并结果。
4. head→tail 顺序不变，同一 byte 的最后一次命中获胜。
5. 两 query 使用各自 PA/PID/class/strb，禁止任何 cross-lane alias。
6. 组合块所有 temporary 与输出有全默认赋值；Yosys 不得出现 latch 或 combinational loop。
7. 四态 fail-closed 覆盖仅存在于非 `SYNTHESIS` 仿真；Yosys 所见二态 offset/mask 网络不得增加 cell/mux/wire-bit。

### 阶段 2d — 数据通路约束

- 每 entry、每 query：两个 64-bit modular base delta、`delta<8` 判定、8-bit strobe shift、64-bit byte-granular data shift、8-bit overlap。
- 每 query：4-entry head→tail coverage OR 与 8 路 byte-enable overwrite mux。
- poison/age/class/typed checks保持原式；不把 query 结果反馈到 SQ Q-state。
- 关键路径预期从 64 组宽地址 add/equality + procedural mux feedback，收敛为 base-delta/shift + 4-entry byte merge。

### 阶段 2e — RTL 级拓扑自审

1. Module/ports：`OooStoreQueue` 端口、时钟、复位完全不变；query 为纯组合。
2. Registers：无新增；现有 SQ arrays/head/tail/count 更新块不改。
3. Combinational blocks：每 query 一个 entry traversal；每 entry 先对齐 mask/data，再产生 overlap/poison/coverage。
4. FSM：无。
5. Pipeline/valid-ready：无新 pipeline；query valid 只门控输出。
6. reset/flush/stall/kill：查询无状态；只读 edge-old Q，现有 reset/flush priority不变。
7. Resources：两 query 必须物理独立；query 内每 entry 共享一次 base-delta 对齐结果，不能复制 8×8 宽地址比较。
8. Critical path：query PA/PID → age/offset → mask align → 4-entry merge → allow/forward/replay/data。
9. Function boundary：不把仲裁/ordering 封装进 function；保持显式 `always @(*)` 组合网络，小型 typed-attr helper不变。

拓扑自审结果：端口、状态、更新优先级与双 query 独立性自洽，可以进入阶段 3。

### 阶段 3 — RTL

`npc/rv64/vsrc/memory/OooStoreQueue.v` 的两个最终物理地址查询面保持端口、
SQ 状态和生命周期不变，只把每 entry 的 `8 × 8` byte-address 加法/比较矩阵
替换为基址双向差值、8-byte 有界移位、overlap mask 与全向量 byte overwrite。
head→tail traversal、youngest-older overwrite、typed/IO poison、partial coverage
replay 和 terminal 排除均保持原语义。两个 query 仍为物理独立组合锥。

首轮独立复核发现普通 `if` 会把内部参与判定中的 `X` 当作 false，从而在仿真中
错误 allow/forward。最终 RTL 在 `ifndef SYNTHESIS` 下加入精确已知量覆盖层：它只
提升 `poison_r`，不进入 Yosys 二态网络；已知 invalid/younger/terminal entry 仍
忽略无关 payload，避免把 fail-closed 实现成全局过度 replay。

`npc/rv64/testbench/tests/tb_ooo_store_queue.sv` 增加以下边界：

- store base 位于 load base 之后时的左移 byte placement；
- bank1 独立 cone 的同方向 placement；
- bank1 独立 cone 的反方向 placement；
- 恰好相隔 8 bytes 的相邻窗口不得误报 overlap；
- CACHED/NC overlap、IO query 与 older IO store 的 typed/ordering 反例；
- potentially participating entry 的 valid/terminal/age/fill/PA/strb/selected-data/head
  `X` 必须 replay，以及已知 terminal/younger entry 的无关 `X` payload 必须被忽略。

`yosys-sta/Makefile` 只新增可覆盖的 `YOSYS_ARGS`/`YOSYS_LOG_ARGS`，默认值保持
原有 `-g` 与完整 log 行为；本轮 compact synthesis 显式关闭大日志。

## 验证与 PPA 证据

最终候选 production RTL design-id：
`sha256:5a8333287115eb28f58e8a2712ab2e3836ebfe31e1b855fb15c6990f9acd9bd9`
（146 个 canonical production RTL 文件）。

首个二态优化候选为
`sha256:af81943cff7e332e6ce593654e28658928eed6b8bb359680713aa6c42ce32bba`；
它保留为首轮复核与 pre-fix 反例的历史绑定，不被改写成最终结果。

### 功能与反例

- `tb_ooo_store_queue`: PASS；marker 为
  `[V8T-F3-SQ-QUERY] allow/dual-offset/typed/merge/youngest/partial/x-poison/x-ignore3/terminal/dual PASS`；
  覆盖双 query 双方向 placement、youngest merge、partial、typed/IO、terminal、
  相邻窗口、八类 potentially-participating `X` replay 与 terminal/younger `X`-payload
  ignore（invalid/terminal/younger 三类）。pre-fix 原始日志保留八个 optimistic
  allow/forward 失败案例。
- `tb_ooo_int_backend`: PASS；`PAIR_MATRIX mask=7fff`，四种 memory pair 全覆盖。
- `tb_ooo_load_queue`: PASS；双 query conflict、lifecycle、wrap recovery。
- `tb_ooo_dual_memory_sustained_issue`: PASS；64 cycles，issue IPC 2.000，
  两路 AGU/translation/SQ-query/cache/completion 均 `64/64`。
- 负向 RTL 把 store-after-load 数据左移改成右移后，编译成功但被
  `F3 forward-start byte placement` 与 `F3 merged youngest bytes win` 拒绝。

### 结构与时序

同参数 local `OooStoreQueue` coarse 对比：

| 指标 | 父设计 | 候选 | 变化 |
| --- | ---: | ---: | ---: |
| generic cells | 7,657 | 1,831 | -76.08% |
| `$mux` | 5,068 | 724 | -85.71% |
| wire bits | 40,443 | 29,536 | -26.97% |

候选 local mapped synthesis 在 64.4 s 完成，面积 `46,684.96`，其中 sequential
area `7,274.96`；`synth_check=0 problems`，logic-loop/proc-latch 均为 0。父设计
同命令超过 8 分钟仍未形成网表，并在旧 byte-CAM block 产生 384 组
logic-loop/proc-latch 诊断，因此不存在可诚实使用的父设计 mapped-area 分母。

最终候选 `OooStoreQueue` 的 OpenSTA 仅作模块级诊断：5 ns ideal clock、zero I/O
external delay；按 slack 排序的首条 `snoop_head_o[0]_reg_p →
query0_forward_data_o_28_` 为最差路径，slack `+2.380463839 ns`，TNS/WNS
为 0，console warning 为 0。它不等于 full-core timing closure。

同配置 `NpcTop` coarse 对比证明局部降幅完整传导到全核：

| 指标 | 父设计 | 候选 | 变化 |
| --- | ---: | ---: | ---: |
| total generic cells | 57,212 | 51,386 | -10.18% |
| total `$mux` | 20,064 | 15,720 | -21.65% |
| total wire bits | 1,701,624 | 1,690,717 | -0.64% |

三项绝对差值分别为 `-5,826/-4,344/-10,907`，与 StoreQueue local 差值
完全一致，未观察到层级外成本转移。最终 design-id 重新执行 full-core coarse，
254.54 s 后由 fail-closed status runner 写入 `PASS`；`synth_check=0 problems`，
logic-loop/proc-latch 为 0。最终与 pre-fix 候选的 full-core `synth_stat.txt` 和
`synth_check.txt` SHA-256 逐字一致，证明仿真四态覆盖未进入综合结构。

首个二态候选的完整核 mapped synthesis 使用 compact log 运行至少 891 s 后仍未形成网表，
按 bounded window 发送 TERM 并核验整个 Yosys/ABC 进程组已退出；因此本轮状态
保持 `TIME_BOUNDED/GAP`，没有 full-core mapped area，也没有 full-core STA 结论；
该历史结果不重新绑定最终 raw-source design-id。

### 实现者 / 首轮审查冲突闭环

- 首轮 reviewer 结论为 `GAP`：二态 offset/mask 等价性成立，但内部 SQ 四态状态
  存在 optimistic admission 反例；spec 的 IO 描述弱于 RTL 的实际序列化策略；
  promotion evidence 尚不完整。
- 实现者用 pre-fix X 注入日志复现八个错误 allow/forward，再以仿真专用覆盖层修复；
  正向 ignore 测试证明没有把已知 terminal/younger entry 过度约束为 replay。
- spec 已明确 IO query/older IO store 对 live older entry 的强序列化，而非 overlap-only。
- promotion 缺口没有被掩盖：full-core mapped/STA、fresh producer/holder instance graph、
  完整 functional/system cohort 与 qualified Power 仍保持 `GAP`。

### 合同入口

- `npc/rv64/eval/check-contract.sh`: PASS，`--assert`、`OOO_ASSERT` 和立即断言
  `502 ≥ 89` 均成立，断言未削弱。
- canonical `make -C npc/rv64 check-contract`: 在进入 assertion checker 前，
  因 V12A frozen producer/holder instance graph 仍绑定父 design-id 而 fail-closed；
  19 个 graph checker 单测 PASS。该结果保留为新 design-id 的 evidence freshness
  GAP，不反写或伪装刷新旧 task-run。

### 最终独立复审

- 合同：`v13a-store-queue-ppa-rereview-v2.json`，SHA-256
  `db6d958194abaa3d69efdbac1e5063013e92f72a2fcfbefffd453e8cd3a3f953`。
- 复审结论：development checkpoint `PASS`。`opensta-top40.rpt` 首条最差路径、
  `summary.json` 与本报告均为 `+2.380463839 ns`；末条 `+2.500047445 ns`
  未被误当成最差值。
- 四态反例闭环：known-invalid payload `X` 必须被忽略；可能参与的
  valid/terminal/age/fill/PA/strb/data/head `X` 必须只产生 replay。源码 oracle、
  `x-ignore3/x-poison` PASS marker 与当前 design-id 三者一致。
- 复审范围不升级：full-core mapped netlist、full-core STA、重复综合与 qualified
  Power 仍缺失，所以 `promotion_eligible=false`。

## 范围裁决

实现者与独立 reviewer 均确认本切片满足 development checkpoint completion
definition：功能正向、compile-success 负向、四态正负向、局部 mapped/STA、
当前 design-id 完整核 coarse 传导均有证据。它不具备
Pareto/promotion 资格；full-core mapped/STA、完整 functional/system cohort、
producer/holder instance graph 新鲜度与 architecture freeze 仍待 round-delivery 闭合。

## 可再生 EDA 产物清理

- 最终证据完成哈希校验后，删除本轮 runtime 仿真/综合副本、192 个 testbench
  `build*` 目录、6 个 Verilator `build*` 目录、旧 `yosys-sta/result` 和误置的
  testbench-local `.github`，共释放 `3,150,390,468` bytes。
- `3,329` 个曾被 Git 跟踪的生成文件已从索引移除；`.gitignore` 统一覆盖
  `npc/rv64/build*/`、`npc/rv64/testbench/build*/` 和误置 task-run 根，避免复发。
- `npc-log.txt`、V9R SQ retry 最新 recheck 日志以及 T3L focused-initial
  logs/summary 已在删除前按 SHA-256 一致性迁入正式 task-run；T3Z request-mux
  旧副本未重复迁入，因为正式 T3Z task-run 已保留更新的 module-v1/v2/owner-chain
  日志。
- 删除清单、untrack 日志与迁移结果见本 task-run `evidence/cleanup-*`、
  `evidence/migrated-logs/` 和 `evidence/perf/`。
