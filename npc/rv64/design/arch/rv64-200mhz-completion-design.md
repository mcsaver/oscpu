# RV64 完整功能与 200 MHz 收敛设计

> **性质**：ACTIVE implementation-program plan。本文只定义收敛目标、依赖、架构边界与验收
> gate，不声明当前已经完成。全部 gate 达成后，本文件应归档到 `design/arch/history/`，仍有价值的
> 稳定原则提炼回架构宪法、active specs 与 DB-backed memory。
>
> **默认决策**：采用“功能与时序双门槛交替推进”。200 MHz 采用两级证据：5 ns pre-layout
> Yosys/OpenSTA 是阶段门槛；含 P&R/CTS/SPEF/OCV/真实宏的 200 MHz 是最终门槛。

## 1. 目标与完成定义

本计划保持用户原始目标不缩小：只有功能 gate 与最终物理时序 gate 同时成立，才能称整体完成。

### 1.1 功能范围

“完整功能”定义为当前产品定位下的 **Linux-capable 单 hart core**：

- RV64IMAFDC、Zicsr、Zba/Zbb/Zbc/Zbs；
- M/S/U、精确异常/中断、xRET、Sv39、PMP×16、硬件 A/D；
- cache、ready/valid、当前 AXI 子集、CLINT/PLIC/UART/virtio-blk 平台路径；
- 当前 RTL 的 Difftest、ACT4 声明范围、OpenSBI、Linux、Ubuntu rootfs/systemd 新鲜证据；
- 普通 FENCE、device ordering、WFI 可见语义必须与本产品合同一致，不能以“Linux 当前没触发”豁免。

以下不属于本轮功能完整度：H/V、Zfh、多 hart coherence、NMI、完整 debug/trigger、通用 AXI
多 ID/burst、L2。它们必须显式登记为范围外，不能描述成已经实现。BTB/LQ/MSHR 等性能结构也不是
功能 gate，但可在 200 MHz/吞吐收敛中按收益引入。

### 1.2 时序范围

| Gate | 完成条件 | 能证明什么 |
| --- | --- | --- |
| T-PRE | `STA_CLK_FREQ_MHZ=200` 正式重综合；5.000 ns OpenSTA WNS ≥ 0；宏合同与 provenance 完整 | 当前 pre-layout 模型下架构可达 200 MHz |
| T-PHYS | P&R、CTS、提取 SPEF、OCV/uncertainty、真实 SRAM/BPU/FP 宏；目标角落 WNS ≥ 0 且 hold clean | 最终 200 MHz 物理实现成立 |

T-PRE 不能替代 T-PHYS。当前 icsprout55 TT/1.2 V/25°C、ideal clock、无 SPEF 的结果只用于
架构排序。

### 1.3 性能守恒

每个保留的时序切片必须同时报告频率、CPI 与综合性能 `frequency / CPI`。正确性修复可以牺牲
性能；纯性能/时序改动若没有改善 200 MHz 可达性或综合性能，必须撤回并记录负实验。前端目标是
流水填满后 1 packet/cycle；若中间台阶暂时降低吞吐，只能作为可逆实验，不能作为最终架构。

## 2. 当前基线（2026-07-11）

### 2.1 功能

- official riscv-tests：177/177 逐项真实 PASS；
- AM：59/59 真实 PASS；`fp-difftest-probe` 在 Difftest ON 下 GOOD TRAP；
- module TB：86/86 真实 PASS，runner 已逐项检查编译/仿真 rc、测试自身 PASS marker 与
  failure marker；
- lint/build/style/contract：PASS；F0 验证使用 `default_defconfig` 开启 Difftest，验证后已把
  当前工作区 `.config` 三件套恢复到进入任务时的哈希；
- current RTL 没有新鲜 Linux L1+ 原始启动证据；历史最高为 rootfs/systemd 部分到达，不能外推。

F0 已于 2026-07-11 完成，证据见
`.github/task-runs/2026-07-11-rv64-f0-truthful-regression/`。任何新 RTL 切片都必须回跑该
真实结果门禁，不能只复用摘要文字。

### 2.2 时序

- 最新全核网表在 10.000 ns 下：WNS = −5.35 ns、TNS = −34779.97 ns；
- 最差路径 `pc_q[15] -> next_fetch_pc_o[16]`，arrival 约 15.32 ns；
- top40 全从 `pc_q[15]` 出发，终点分成 `next_fetch_pc_o` 与 FIFO `packet_next_pc_q`；
- 共同路径族：ITLB/context/PTE → PMP/fault/invalidate → cache response → RVC/predecode →
  branch/B-imm → next-PC；
- `dec1_branch_o` 单弧约 7.89 ns，但把该弧理想化为零后剩余仍约 7.43 ns，buffer 不是充分解；
- 同一 100 MHz 网表的 5 ns 重约束只作诊断。正式 T-PRE 必须以 5 ns 重新 ABC 映射。

## 3. 总体路线裁决

### 3.1 未采用：功能全部修完后再做时序

优点是边界清晰；缺点是前端、BPU 与 backend 重新流水化会改变 flush、预测和 retirement 时序，
功能证据仍需重跑，整体重复劳动最大。

### 3.2 未采用：时序优先重写前端

能最快看到 WNS 改善，但 F0 前 runner 存在假绿，架构重构产生的新错误可能被汇总 PASS 掩盖。

### 3.3 采用：双门槛交替推进

先恢复验证真实性；之后每个 correctness 或 timing slice 都走 RED → 实现 → focused GREEN →
全功能 gate → 5 ns STA → 保留/撤回。功能与时序共享同一 current RTL 基线，不建立两条长期分叉。

依赖图：

```text
F0 truthful regression
 ├─> F1 close correctness contracts ─> F2 ISA/priv proof ─> F3 Linux/rootfs proof
 └─> T0 reproducible 5ns flow ─> T1 frontend pipeline ─> T2 real BPU/macro
                                      └───────────────> T3 backend cuts ─> T4 physical signoff

每个 T1/T2/T3 切片 ──回边──> F0 + 已完成的 F1/F2 gates
T4 前必须同时具备 F3 和 T-PRE
```

## 4. 功能收敛轨

### F0：恢复回归真实性（首个实施子项目）

**状态：2026-07-11 完成。** module checker 17/17、AM checker 11/11、module 86/86、
AM 59/59（Difftest ON）、official 177/177 与 strict guard 均通过。FP 根因为 GPR 目的 FP
completion 误入 FPR busy/bypass/wakeup/write 域；现以 `valid && frd` 作为唯一 FPR 域资格。
实施计划已归档为 `history/f0-truthful-regression-implementation-plan.md`。

目标不是让日志变绿，而是让失败可靠地使顶层命令非零退出。

1. module TB runner 必须在原始日志包含 test failure、`$fatal`、非零 error count 或
   `$finish(1)` 语义时返回非零，禁止无条件追加 `[RESULT] PASS`；
2. AM `run` 必须聚合每个 `.result`，任一 `***FAIL***` 使 make 返回非零；
3. core-regress 必须分别记录 module/lint/build/AM/riscv 的真实 rc，不再把子层假绿提升为 PASS；
4. 针对现有四个失败建立 RED fixture，先证明旧 runner 会误判，再修 runner；
5. runner 修复后分别裁决三个 TB 是 DUT bug、TB 接线漂移还是期望过时；
6. `fp-difftest-probe` 必须区分“Difftest 未启用的配置合同”与 FP datapath 错误，不能改测试隐藏失败。

F0 完成条件已经满足：同一套 fixture 中真实失败使顶层非零，恢复正确 DUT/期望后
module/AM 才报告全绿。后续切片把这些 gate 作为回归基线，而不是重新解释旧日志。

### F1：关闭已知正确性合同

按独立 slice 顺序处理，每项必须有定向 RED、非真空断言、focused GREEN 与整核回归：

1. **FDG-G1（CLOSED 2026-07-12）**：arch trap 不得送 backend；旧 RTL 四类非法 FP
   精确 RED，修复后 focused 4/4、断言负探针、module 87/87、Difftest-ON AM 59/59、
   official 177/177 均通过；
2. **XRET-G1（CLOSED 2026-07-12）**：MRET/SRET current-mode 合法性；旧 RTL 三类反例
   精确 RED，修复后真实编码 head0/lane1 integration、module 87/87、AM 59/59、
   official 177/177 均通过；
3. **MEM-ISSUE-G1（CLOSED 2026-07-12）**：lane0 memory exception 与 lane1 normal
   memory 共享端口时，IQ dequeue、request mux 与 MIQ owner 必须同源；旧 RTL 精确出现
   `fire=1/request=0` 丢事务，审查又用 head-blocked LR 锁住首版 `request=1/fire=0`
   幽灵 MIQ。最终正反例、module 87/87、Difftest-ON AM 59/59、official 177/177 均通过；
4. IFU-AXI-G1：A/D partial write 遇 flush 必须排水；
5. IFU-FETCH-G2：page-end 16-bit 指令 fault 归属；
6. PTW-PMP-G1：A/D PTE write 独立 PMP WRITE check；
7. MIQ-G1：flush + 同拍 DRAIN pop 不得保留 ghost；
8. INSTRET-G1：唯一 ISA retirement 源；
9. store/device：late B error、翻译后地址分类、lane/size 与排序合同。

### F2：声明 ISA/特权范围证明

- current RTL 启用 Difftest，比较 PC/GPR/FPR/确定性 CSR/privilege；
- 重跑 official riscv-tests、ACT4 I/M 与已声明 RVA22S64 Sv 族；
- `make -C npc/rv64 check-contract`、lint、module TB、AM 全部使用已修复的真实 rc；
- 形成“已声明能力 / 明确范围外 / 尚未闭合”矩阵。

### F3：当前 RTL 的系统级证明

同一批 current artifacts 依次闭合：QEMU reference → NPC OpenSBI handoff → Linux kernel →
Ubuntu `/bin/sh` → ext4 `/dev/vda` rootfs/systemd → UART/CLINT/PLIC/virtio-blk → guest checks →
自然 poweroff。旧日志只能用于回归定位，不能替代 current evidence。

## 5. 时序收敛轨

### T0：可复现的 5 ns 门禁

1. 生产 200 MHz flow 使用 `STA_CLK_FREQ_MHZ=200`，使 `default.sdc` 生成 5 ns clock且 ABC
   按 5000 ps 重新映射；
2. 网表、SDC、lib、RTL filelist、Git commit/dirty hash 与生成命令写入 manifest；
3. 同网表 5 ns 重约束保留为快速诊断，文件名和报告必须显式标 `diagnostic-only`；
4. current BPU 0.5 ns placeholder、65 nm CACTI SRAM 近似、FP OOC 模型分别标注，不得冒充 signoff；
5. 每轮收集 WNS/TNS、top40 path-family、area 与宏合同结果。

### T1：前端控制回环重新流水化

当前长链不能靠单点 buffer 收敛。目标拓扑为：

```text
F0 request/ITLB/PMP/cache lookup
  -> R0 registered raw response + response-PC tag
  -> D0 RVC length/decompress/predecode + metadata register
  -> P0 predictor index/read request register
  -> P1 predictor response/decision + target + packet enqueue
  -> dispatch FIFO
```

关键设计选择：

- R0 是真正的寄存 valid/ready 边界，payload 至少包含 response PC、raw inst words、resp bits 与
  fault/context tag；禁止用 fall-through bypass 重新接回长数据链；
- 为恢复 1 packet/cycle，在 R0 捕获旧 response 的同拍，仅用 raw halfword 的长度位计算短
  `sequential_packet_pc`，允许发起至多一个顺序推测请求；完整 RVC/branch/BPU 判决不再组合回送；
- P1 若判 taken/control/fault，走统一 redirect/kill，丢弃或 drain 至多一个顺序 wrong-path 请求；
- 单一 `outstanding_pc_q` 必须演进为“bridge 当前请求 tag + R0 已完成 response tag”的明确 owner，
  不能让新请求覆盖尚未解码 response 的 PC；
- GHR snapshot/BHT index 随 packet 存储；resolve update 与 lookup 的时点必须通过 shadow equivalence
  和 accuracy 统计裁决；
- reset/flush 优先级固定为 `reset > committed redirect/trap > speculative redirect > stall > advance`；
- 已 fire AXI 不 kill，只 drain；committed store 不受前端 flush 影响；CSR commit 不回退。

时序预算（pre-layout 设计预算，不是 signoff 数字）：

| Stage | 目标最大组合延迟 |
| --- | ---: |
| F0 ITLB/PMP/cache decision | 4.0 ns |
| D0 RVC/predecode/metadata | 3.5 ns |
| P0 predictor index/read request | 2.5 ns |
| P1 predictor decision/target/queue D | 3.5 ns |
| redirect/credit/control fanout | 3.5 ns |

T1 先以 shadow/可逆台阶验证：旧路径仍驱动架构状态，新路径只计算并逐拍比较；等价、非真空和
STA 都成立后才切换 owner，随后删除旧路径，禁止长期双真源。T1 可先在 P0/P1 边界封装当前
FF predictor 的地址/结果协议；T2 只替换表存储实现，不再改变前端 packet/redirect 接口。

### T2：BPU 与宏真实性

- 将 gshare/local-history/local-PHT 的异步 FF 多读口改为可实现的同步 SRAM/宏接口；
- 两 slot 读带宽用真实双口宏或复制表解决，更新写入所有副本并有一致性断言；
- predictor lookup、GHR snapshot、update pipeline 和 clear 语义跨拍冻结；
- 真实宏 lib 不可得时，T-PRE 可继续做架构排序，但 T-PHYS 明确未闭合。

### T3：按新 top-path 切 backend

前端退出 top40 后才选择 backend 切点。候选包括 issue select → PRF → execute、PRF 多口扇出、
LSU/DTLB/cache、divider 与 CSR counter。每次只处理新报告中的共同 path family，不按旧排名盲切。

### T4：物理 200 MHz

使用真实 LEF/lib/macro、floorplan、placement、CTS、route、SPEF、setup/hold、OCV/uncertainty 和
DRC/LVS 可用证据。T4 若暴露新的结构性长链，回到 T1/T2/T3；不得用 false path 掩盖真实同步路径。

## 6. 验证策略

每个 slice 都执行：

1. TDD RED：最小定向 test/fixture 在旧实现上按预期失败；
2. focused GREEN：模块 TB/断言验证本 slice；
3. structural gates：`check-rtl-style`、`check-contract`、lint、宏合同；
4. functional gates：真实 module/AM rc、177 tests、适用的 Difftest/ACT4；
5. performance：全量加权 CPI、highest/lowest/near-average、CoreMark、等待来源；
6. timing：5 ns 正式重综合后的 WNS/TNS/top40/area；
7. reviewer：实现者给证据，独立审查者寻找协议洞、假绿、越级时序结论；
8. record：task-run、active spec、DB-backed project-status/npc/yosys-sta memory。

## 7. 退出条件

只有以下全部成立才关闭本计划：

- F0/F1/F2/F3 全部由 current RTL 新鲜证据闭合；
- T-PRE 与 T-PHYS 全部 WNS ≥ 0、hold clean；
- 不存在 placeholder 宏冒充真实 signoff；
- 功能矩阵无未裁决的“声明支持但无证据”项；
- strict guard、DB audits、文档生命周期检查通过；
- 本计划归档，current ground-truth/ROADMAP/spec/memory 更新为最终状态。
