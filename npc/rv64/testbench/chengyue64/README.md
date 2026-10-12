# 承岳64 验证平台

## 自治域独立开发

公共接口和事务生命周期见[PROTOCOLS](../../vsrc/PROTOCOLS.md)。
以下入口仅编译目标域的显式源码依赖，mock peer不需要整核实现：

~~~sh
make -C npc/rv64/testbench/chengyue64 domain-lint
make -C npc/rv64/testbench/chengyue64 domain-run
make -C npc/rv64/testbench/chengyue64 domain-lint-execution
~~~

可单独lint的域为frontend、execution、fp、control、translation、physical、memory、backend。
domain-run涵盖Execution、Control、TranslationService、FP、Frontend与LSU网络。
新增三个domain合同TB也已列入常规run默认测试，完整集成仍使用system-run/system-throughput。
规则见[domain-tests.mk](domain-tests.mk)，实际源码集合见[domain-filelist.mk](../../vsrc/domain-filelist.mk)。


本目录维护当前承岳64 的具体测试用例与回归脚本。
命令由 RV64 根 [Makefile](../../Makefile) 转发到本目录的 [Makefile](Makefile)。

## 文件职责

| 目录 | 内容 |
| --- | --- |
| [modules/](modules/) | `tb_*.sv`：模块/组合子系统激励、协议断言和定向测试 |
| [oracles/](oracles/) | 独立的预期行为与对照实现 |
| [programs/](programs/) | `r64_core_*.S`：整核、特权、设备、吞吐与 Tensor 测试程序 |
| [scripts/](scripts/) | AM、官方 ISA、ACT4、系统回归的构建、运行及结果检查 |
| [generators/](generators/) | SoftFloat 浮点测试向量生成器 |
| [host/](host/) | 宿主镜像加载器的 C++ 单元测试 |

通用仿真运行设施见 [sim/](../../sim/README.md)，独立的参考模型及 CSR 比较实现见
[difftest/](../../difftest/README.md)。测试 Makefile 引用 [sim/build.mk](../../sim/build.mk)
构建 core/system/tensor 仿真器；NEMU 参考配置和构建脚本由 `difftest/` 管理。

## 常用命令

以下命令均从工作区根运行：

```sh
make -C npc/rv64 all difftest-ref
make -C npc/rv64 lint
make -C npc/rv64 test
make -C npc/rv64 core-test
make -C npc/rv64 device-test
make -C npc/rv64 tensor-test
make -C npc/rv64 software-test
make -C npc/rv64 regression
```

| 目标 | 实际范围 |
| --- | --- |
| `all` / `difftest-ref` | 构建系统仿真可执行文件 / NEMU 参考共享库 |
| `lint` | 整核与系统 lint |
| `test` | 当前模块测试、负向断言与选定配置矩阵，准确集合以根 Makefile 为准 |
| `core-test` | 整核、系统定向、系统 I/O 与理想吞吐测试 |
| `device-test` | block 设备读写、错误和 IRQ 定向测试 |
| `tensor-test` | Tensor 单元和原生 Tensor 系统定向对拍 |
| `software-test` | AM、官方 ISA、ACT4 非 OS 软件回归 |
| `regression` | `lint + test + core-test + software-test + device-test` |

`regression` 不包含 `tensor-test`、L2/L3 或完整 NPU 主工作流；这些入口分别见
[系统运行](../../sim/README.md)。模块测试结果不能替代整核或系统结论。
`core-test` 的理想吞吐检查在 I-cache 自然预热后，要求 7 个稳态窗口各退休 768 条 / 384 拍，
同时保留 NEMU 检查。该特定窗口的 CPI=0.5 不表示所有负载均达到此吞吐。
窗口起点由第 127/128 条是否在同拍退休唯一确定，只允许保持或后移一条；
后移时同时要求边界连续，防止固定指令切片截断双退休对，也不允许搜索更快子窗口。
完整 1024 条 PC 顺序、8 轮执行和 7 个窗口逐拍恰好双退休的检查仍保留。

默认构建输出位于 `npc/rv64/build/chengyue64/`：模块回归用 `regress/`，
整核、系统、Tensor 系统分别用 `core/`、`system/`、`tensor-system/`。
参考库默认位于 `nemu/build/rv64-rebuild-reference/`，通过 `CORE_REF` 选择。
`CORE_JOBS` 控制编译并行度，`CORE_THREADS` 控制 Verilator 宿主线程数；
后者不改变 RTL 时钟和流水拍数。

## 依赖与访存延迟回归（2026-10-11）

以下用例已加入默认 CPU 模块集合；配置矩阵、负向断言和独立域测试仍使用原入口。

| 新增用例 | 验证边界 |
| --- | --- |
| `tb_r64_alu_promise` | IQ 调度 promise 与真正数值就绪分离；普通整数生产者到消费者 Execute 间隔为 2 拍；错过promise的晚birth由token/init或保持head唤醒 |
| `tb_r64_rr_late_values` | 2 个 ingress、4 个 terminal 对晚到值的捕获；一次性 WB、背压、取消及 owner 转移；四路data/preg/qualified-valid共同history、首次read本地匹配、history优先、覆盖前转存、同拍transfer/refill |
| `tb_r64_data_bare_fast` | Bare 请求直接进入 outcome Q，保留有效特权计算、旧请求优先与背压 |
| `tb_r64_service_store_prepare` | 无副作用的 store 准备镜像、完整身份匹配、实际接受只发生一次及正常退路 |
| `tb_r64_store_commit_overlap` | 真实 store 终端与 head 退休重叠，B 错误和第二条退休限制 |
| `tb_r64_serial_retire_candidate` | 真实普通 store 后继 FENCE.I/SFENCE/CSR/xRET 的驻留退休资格；B 错误、Trace/恢复与陈旧 generation；`serial-retire-candidate-matrix` 覆盖 head-class 0/1 |
| `tb_r64_lsu_bind_translation` | canonical bind 与翻译队列分拍，旧项优先、身份/保护字段、取消和信用 |
| `tb_r64_lsu_prepared_reuse` | 部分转发、查询预写后取消、同槽直发 store 复用；新 owner 不继承旧有效字节 |

ResponseIngress 用例检查物理返回捕获后下一边沿进入 CQ，Dcache 用例增加当前驻留 way 的
成功写与错误写检查。Backend 嵌套恢复 fixture 使用真实 MUL 建立较老依赖，
保留年轻 redirect 候选不得越过较老恢复权威的检查。
RR晚到值用例另覆盖MEM双lane首次认证当拍不接受、捕获后供值、源head改变/背压/取消，
以及MDU/FP head因pending Q等待时仅允许后排ALU绕行。
首次read history另覆盖四路来源、仅一次WB、raw resident未经认证不得供值、history miss后当前命中，
以及首读取消/flush后同slot/preg复用；67次转移包含此前53次既有场景。
direct_mem_execute对20,000个共享资源向量分别切换local ALU valid为0/3，两次均与原oracle比较，
覆盖计数仍按每个原向量一次统计，用于确认快速认证不会改变共享资源实际接受集合。
全量 CPU/软件/L2 与同源综合、STA 的本批结果见
[2026-10-11 验证目录](../../build/dual-utilization-20261011/alu-experiment/v7-validation/)及
[全核拓扑](../../vsrc/TOPOLOGY.md)。

## 运行单个程序

```sh
make -C npc/rv64 run IMG=/absolute/guest.bin \
  RUN_ARGS="--maxcycles=20000000 --progress"
```

`run` 默认使用系统仿真封装。普通测试通过 `EBREAK` 且 `a0=0`，或 ELF 提供的 `tohost=1`
结束；也可用 `--tohost=0x...` 指定地址。系统模式使用真实 syscon 关机，参数及终态要求见
[sim/README.md](../../sim/README.md)。`--stalls` 可加入总线停顿，`--verbose` 打印提交与 trap 事件。

RR_COMPLETE_ADMIT 的 tb_r64_rr_complete_admit 与 tb_r64_rr_complete_admit_chain 覆盖完整值直接捕获、原信用/回退、FP 读口并发、恢复、代际复用及真实 response→Execute 延迟；域 filelist 包含非 owning R64ValueNoticeMerge。


第十三批新增默认 CPU 用例：

- tb_r64_issue_init_current / tb_r64_issue_init_execute：真实 Scoreboard 查询与 accepted-birth 独立身份 oracle；检查首次 IQ 与实际 Execute 提前一拍、同批 RAW、WB/new birth、取消和完整 tag 复用。
- tb_r64_rr_complete_branch_admit / tb_r64_rr_branch_owner：真实 load 返回到分支 Execute/resolve 延迟、六种 B 条件、JAL/JALR/link、两 lane 年龄反转、背压、恢复和旧 PRF 覆盖。
- tb_r64_ordinary_successor_control / tb_r64_ordinary_successor_lease：真实 ROB→Control→LSU→PhysicalMemory→AXIWrite 链，检查 ALU/BRANCH/load 退休到后继 store 接受的 2→1 拍、无 hint 的头部跳转、错误/Trace/恢复和相邻 store 翻译 fault。

上述局部延迟结果只证明对应链路。完整程序零发射低于 50% 仍由完整 CoreMark 10、Dhrystone 10000 和适用全量 CPU/软件/L2 回归共同验收。


写传输新增默认 CPU 用例 tb_r64_axi_command_flow、tb_r64_axi_command_fabric、
tb_r64_fabric_write_flow 和 tb_r64_fabric_write_owner，分别覆盖双 client/多 beat/独立 AW/W 背压、
真实 Fabric 与寄存端点、末 B 错误累积、双响应竞争、旧 holder 优先、同 ID 与 owner 满时回退。
最短延迟以实际 command/AW/W/B 接受边沿计算；不修改仿真端点的响应等待。

联合写传输 TB 默认开启三项路径；2×2×2 定向验证实际单拍 command→client B 为 5/4/4/3/4/3/3/2 拍（CMD/AW/B 二进制顺序），8 beat 全关/全开为 19/16 拍。此为真实 Writer→Fabric→寄存端点结果，不能替代完整程序收益。

2026-10-11 第十五批新增 tb_r64_lsu_response_forward、tb_r64_response_forward_pin、
tb_r64_response_forward_returns，覆盖翻译响应进入原 store-forward query Q 的 owner、
逐字节最年轻选择、同沿 pin/commit、Berror winner、取消、背压、复用和原 LSU 返回回归。
三个默认测试启用 RESPONSE_FORWARD_QUERY；独立 focused 记录保留关闭配置、
PREPARED_CANCEL 组合、四种长背压 pin 模式与随机响应入口。
[干净候选验证](../../build/zero-issue-20261011/response-forward-clean-focused/summary.json)
包含 22 项动态与 5 项 strict lint。短诊断仅为性能筛选，不替代完整程序和 L2 验收。

tb_r64_lsu_error_source_pin 默认要求错误后的被引用源保留在 PINNED，旧实现会失败；
独立 +witness 仅用于复现原生命周期缺口。tb_r64_store_error_pin_core 通过真实取指、
AXI Berror 和正常恢复链检查精确 store fault、年轻分配阻挡、字节稳定与引用排空，
没有强制内部状态或立即 flush。定向关闭/开启弹性返回、延迟 flush、late kill、
错误完成背压和 last-reference drain 结果见
[错误 source pin 验证](../../build/zero-issue-20261011/store-error-pin-local-focused/summary.json)。


2026-10-12 第十六批新增 tb_r64_dual_retire_candidate 和 tb_r64_dual_retire_lease：

- candidate 使用 N3 开关 × META_W 64/204 四种配置，覆盖普通与特殊 kind、写寄存器/串行、
  第三项真实成功或错误 WB、过时代际 WB、同沿第三条 birth、恢复、slot31 回绕与 generation 复用。
- lease 在真实 ROB→Control→LSU→PhysicalMemory→AXIWrite 链运行 N1/N2/N3
  的 000、001、110、111 四种配置；检查实际双退休后寄存许可、Trace 00/01/10/11、
  第三条同沿 fault、旧 store Berror、后缀恢复、未 bind 后继与真实 CSR 配置的 IRQ 排空。
  N3 开启时每配置 367 项检查、20 次真实双退休许可，已准备 store 的物理接受提前一拍。
- 20 个已有相关 TB/oracle 仅补充接口连接或确定性输入 tie0；
  原 N1/N2 参数矩阵、断言及 oracle 语义保留。

[双退休许可定向证据](../../build/zero-issue-20261011/dual-retire-lease-focused/summary.json)
包含 30 项相关动态配置、10 项独立域动态、10 项参数/Core 严格 lint 和 8 项独立域 lint。
第十六批 N3 与错误 source PINNED 修复的自然短诊断均通过真实 DiffTest，具体指标见
[分批诊断](../../build/zero-issue-20261011/diagnostic-progress.json)。
[第十六批完整验证](../../build/zero-issue-20261011/batch16-validation/validation-summary.json)
已覆盖 N3 与 PINNED：201 项默认模块、53 项配置、17 项负向、10 项独立域动态、
8 项域严格 lint、352 项软件、Core/System/IO/block、完整基准与 L2 all 全部通过。
完整 CoreMark/Dhrystone 的原 IQ 零发射占比仍为 51.5567%/56.1004%，阶段目标尚未达到。
隔离写回和分支预测实验不属于该冻结源，范围见
[第十六批状态](../../build/zero-issue-20261011/batch16-status.json)。

2026-10-12 第十七、十八批新增 12 项默认 CPU 用例：

- tb_r64_bind_translation_flow / tb_r64_bind_translation_service：旧翻译队列优先，
  空队列的真实 bind 接受、背压捕获、取消和身份复用；真实翻译服务覆盖 Sv39/PMP/MPRV、
  store A/D 授权与错误返回。
- tb_r64_direction_backend / tb_r64_direction_frontend_snapshot / tb_r64_direction_pipeline /
  tb_r64_direction_predictor：可选退休方向训练的完整 tag、双退休顺序、取消和保持快照；
  Core 当前默认关闭该可选训练，继续使用 resolve 训练。
- tb_r64_predictor_capacity / tb_r64_direction_capacity：方向表容量、索引冲突和首次有效训练的
  强状态，保留原两位计数器更新与已捕获预测快照。
- tb_r64_batch_rollback / tb_r64_batch_backend：独立逆序 birth ledger 与真实 Backend，
  覆盖 0–31 条后缀、重复目的寄存器、GPR x0/FPR f0、嵌套恢复、generation 回绕、
  旧指令 WB/存储完成、物理寄存器回收与迟到写回拒绝；同时测试串行与批量恢复。
- tb_r64_ftb_capacity / tb_r64_ftb_frontend：固定 PC[24:4] 签名下的 5/7/8 位索引、
  高索引 learn/resolve/repair、跨块 selected_next 与真实 Frontend 输出序列；
  32 项配置另与原 FetchStream 逐拍对照。

批量恢复仍先发布取消，下一沿应用登记的后缀；FTB 扩容不改变预测计划接口和事务所有权。
定向参数矩阵与短程序 A/B 见
[恢复与前端比较](../../build/zero-issue-20261011/recovery-ftb-preview-comparison.json)。
第十八批默认库存为 214 项，其中 Tensor 按用户范围排除，适用 CPU 库存为 213 项。
完整第十八批 CoreMark 10 / Dhrystone 10000 已通过原程序与真实 DiffTest，原 IQ 零发射
分别为 44.4174% / 48.3838%。213 项适用默认模块、53 项配置、17 项负向、10 项独立域动态、
8 项域严格 lint、352 项软件及 Core/System/IO/block 已通过；Core/System/Platform 严格 lint 通过。
L2 all 完成17阶段，6757074周期、6063076条提交、486次trap，并自然关机；运行源未变化。
默认模块原运行漏读 TESTS +=，已补齐12项；方向流水和乘法器的宿主超时经单项复验通过，
原失败与复验均保留。方向流水仅统一原 focused 的120秒预算；乘法器仍用原60秒，
没有改变 RTL、TB、断言或功能 oracle。

第十八批达到“两项完整原 IQ 零发射均低于50%、周期下降、适用全量功能和 L2 通过”的阶段线。
[完整验证汇总](../../build/zero-issue-20261011/batch18-validation/validation-summary.json)
同时保留原 runner 非零返回、补测与复验处置。该记录对应第十八批冻结源；
Tensor/NPU、L3 和综合/STA 不属于当时的零发射阶段验收。

当前工作区进一步合入第二十批保持周期的组合逻辑解耦，生产 RTL 和接口 TB 已更新。
[第二十批完整验证](../../build/zero-issue-20261011/batch20-validation/validation-summary.json)
包含原有适用默认 213 项、配置 53 项、负向 17 项、独立域动态 10 项、域严格 lint 8 项、
sum_equal、软件 352 项及 Core/System/IO/block/L2，全部自然通过，无补测或重试。
完整 CoreMark/Dhrystone 的周期、提交数和合计 314 行原始性能报告与第十八批完全一致。
在此冻结验证之后，新增 serial retire candidate 回归及其 HEAD_CLASS=0/1 两配置入口，
使用同一第二十批生产 RTL 单独通过，见[新测试入口结果](../../build/timing-preserve-20261012/test-entry-check/result.json)。
因此交付时默认总库存为 215 项，排除 Tensor 后为 214 项；验证覆盖是原全量 213 项加新增
1 项的两个配置，不能表述为冻结 runner 已执行 214 项。综合/STA 同源测量见
[时序比较](../../build/timing-preserve-20261012/timing-comparison.json)，不改变功能验证的判定范围。
