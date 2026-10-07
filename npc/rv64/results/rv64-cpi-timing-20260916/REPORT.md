# rebuildcore：CPI 与控制路径优化（2026-09-16）

## 结果与范围

最终采用 **held-ready**，生产工作区 RTL/header 与该测试和 STA 快照一致，仅清除了一行空白分隔行上的空格；全部非空源码行逐行相同。
完整 CoreMark 的 CPI 从 **2.974417155 降到 2.871491404（−3.460367%）**；
完整 Dhrystone 从 **3.581443059 降到 3.419212237（−4.529761%）**。
两者分别减少 **331,269** 和 **691,212** 个周期，退休指令数保持一致。

同约束整核 setup slack 从 **-2.194192410 ns** 变为
**-2.173909903 ns**，相对基线改善 **20.282507 ps**，属于小幅时序改善。
1 ns 目标下的原始 STA 判定仍为 **FAIL**；本轮不宣称时钟已经收敛。
面积仅记录，不作为筛选目标。比较对象是本轮开始时实际 rebuildcore 工作区，不是旧 rv64core 或历史网表。

旧核提供的主要启发是提前准备、重叠等待、减少依赖链上的空拍。历史实现也存在 cache 返回、
写回前递、issue/执行和前端控制串联的问题。因此本轮保持真实寄存边界，并同时衡量 CPI 与整核时序。
参考：[旧核历史拓扑分析](../../design/arch/topology-analysis-2026-07-11.md)。

## 实际改动

### A. store/special 描述符与 owner 同拍准备

原 prepared holder 在边沿 E 保存身份，E+1 才读入完整 payload，E+2 才能进入 query。
现在 E 同时捕获 slot、tag、payload 和 valid，条件允许时 E+1 就能进入 query，减少一拍准备等待。

完整描述符由原始 one-hot 并行读取；kill 决定是否接受这次准备。被取消的替换候选不能覆盖仍有效的旧 owner。
真正 store/IO/AMO 的发出仍要求 head/effect_allow、成功翻译/权限检查与物理握手；store 退休继续依赖真实 AXI B 完成。

### B. LSU completion 提前申请下一拍 WB 端口

每个物理 CQ lane 用 front/skid 占用或本拍接受事件产生 out_request。
CQ 捕获冷结果的同一边沿，WB 可以登记下一拍 grant；结果变成寄存 VALID 后的第一拍就有机会被捕获。

提示只参与端口调度；实际结果 VALID/READY、tag/data、kill/flush 和 ROB owner certificate 仍决定接受。
取消或错误提示可以产生空 grant，但不能写 PRF 或完成指令。CQ 输入信用仍只依赖占用 Q。
CoreTop 显式启用 Backend.WB_REQUEST_HINTS；仅 LSU 两路连接提示，通用 Backend/Writeback 默认关闭。

### C. 完成数量与 owner 仲裁并行

六个完成来源的“至少一条/至少两条”直接由 valid 计算，避免先等 first/second winner 再归约数量。
owner、payload、来源 pop 与轮转优先级仍使用原选择器，不增加寄存级。

真实 LSU 组合切片已穷举 64 个 valid 组合 × 64 个优先级 bitmap × 4 个 credit 组合，共 16,384 例，
同时对照独立计数 oracle 与原 winner 数量。

### D. LSU bind 宽数据直接按行写入

原过程从各行 bind_mask 汇总 bind_take，再按 bind_slot 动态选择宽数据目标行。
现在每行直接使用已有接受位写入 VA、store、byte mask 和 misaligned。
reset、reserve/bind 顺序、lane1 优先级、FS=Off 的非法 FP 访存处理保持。
R64_ASSERT 用原动态索引写入过程逐拍比较全部行，包括无效行。

### E. Split 与 Service 的请求预选和实际接受分离

Split 保留原 out_valid 与慢路径接受事件，另输出未经过 pending-split 门控的 out_request。
Service 用它提前决定 CPU 配对与空槽 payload 准备，缩短 VALID → pending → VALID → ready 的串联。

这里的提示契约比 WB 提示更严格：只要任一 CPU lane 实际 VALID 为 1，两位提示必须与两位 VALID 完全一致。
pending split 时两位真实 VALID 均为 0，Split 输入 ready 只取慢路径 acquire 条件，Service 预先 ready 不能接受 CPU 请求。
实际 enqueue、aux 仲裁、轮转更新和已持有 owner 继续使用真实 VALID。
通用 Service.CPU_REQUEST_HINTS 默认关闭，LoadStore 显式启用。

### F. 按已占用 physical holder 化简 query ready

holder 为空时，原 query ready 已恒成立；holder 占用时，能否替换只由其自身保存的 descriptor/tag、
head 授权、kill 和下游 ready 决定。将这两种情况显式分开，减少待进入 query 经 mem_valid 绕回自身 ready 的依赖。
容量和接受边沿不变，断言逐拍对照原 !physical_hold_valid || mfire 公式。

## 完整程序 A/B

固定原生 R64SystemTop：ROB32、IQ16、LSQ20、GPR/FPR 各64项、真实 cache/翻译/AXI及设备。
所有版本使用同一镜像、完整 NEMU、R64_ASSERT 和宿主线程数2。
CPI = 自然结束时 cycles / commits，不以宿主运行耗时或理想吞吐窗口替代。

CoreMark 均为10次迭代、3,218,524条退休指令，CRC final=0xfcaf；
Dhrystone 均为10,000次、4,260,670条退休指令。

| 版本 | CoreMark cycles | CoreMark CPI | Dhrystone cycles | Dhrystone CPI |
| --- | ---: | ---: | ---: | ---: |
| 修改前基线 | 9,573,233 | 2.974417155 | 15,259,347 | 3.581443059 |
| A：同拍准备 | 9,524,520 | 2.959281957 | 14,919,001 | 3.501562196 |
| A+B：提前 WB 申请 | 9,241,964 | 2.871491404 | 14,568,135 | 3.419212237 |
| A+B+C：并行完成计数 | 9,241,964 | 2.871491404 | 14,568,135 | 3.419212237 |
| A+B+C+D：按行 bind | 9,241,964 | 2.871491404 | 14,568,135 | 3.419212237 |
| A+B+C+D+E：请求预选 | 9,241,964 | 2.871491404 | 14,568,135 | 3.419212237 |
| A+B+C+D+E+F：holder ready 化简（最终采用） | 9,241,964 | 2.871491404 | 14,568,135 | 3.419212237 |

A 单独使两项周期下降0.508846%、2.230410%；A+B 达到3.460367%、4.529761%。
C、D、E、F 的最终计数及全部26项 profile 与 A+B 精确一致，后续组合改写没有新增流水等待。

### 等待周期变化

| 整程序事件计数 | CoreMark 修改前 → 最终 | Dhrystone 修改前 → 最终 |
| --- | ---: | ---: |
| 无退休周期 | 7,603,385 → 7,276,835 | 12,723,188 → 12,041,970 |
| WB 背压 | 1,128,437 → 631,620 | 2,209,456 → 1,392,489 |
| ROB 非空且队头未完成 | 7,234,364 → 6,907,082 | 12,370,890 → 11,679,698 |
| 真实 store B owner 驻留 | 592,416 → 592,416 | 2,404,764 → 2,404,764 |

这些事件可能重叠，不能相加推算可节省周期。B owner 驻留保持相同，收益来自准备和完成等待减少。
profile 观察区间包含额外一个边界采样拍，CPI 始终使用自然结束的 cycles/commits。

## 同约束整核时序

完整 R64SystemTop，icsprout55 TT1.2V25℃，周期1ns、uncertainty0.05ns、ABC600ps、max fanout8，
无 blackbox，保留真实 ICG 检查。各版本使用相同约束和工具，reset/flush/ready 路径均保留。

| 版本 | 全局 setup slack / ns | hold slack / ns | 映射面积 / µm² |
| --- | ---: | ---: | ---: |
| 修改前基线 | -2.194192410 | -0.036660694 | 3,147,382.839995 |
| A+B：提前 WB 申请 | -2.335468769 | -0.036660694 | 3,145,549.399995 |
| A+B+C：并行完成计数 | -2.204200029 | -0.036660694 | 3,145,900.799995 |
| A+B+C+D：按行 bind | -2.303394079 | -0.036660694 | 3,140,956.559995 |
| A+B+C+D+E：请求预选 | -2.204507351 | -0.036660694 | 3,141,491.639995 |
| A+B+C+D+E+F：holder ready 化简（最终采用） | -2.173909903 | -0.036660694 | 3,141,304.599995 |

A+B 虽然改善 CPI，setup 却比基线退步141.276359ps。C 收回131.268740ps，D 的全局结果仍比基线差109.201669ps。
因此继续针对真实最差 ready 路径验证 E/F，而不是用局部路径改善代替整核结论。

- 基线最差：rst/Commit flush → ROB kill → lane1 physical offer → Split/Service ready → LSU mfire/query pop → query head。
- A+B 与 C：prepared cancel → Execute bind fire → 行接受归约与 slot 重译码 → LSQ VA 行。
- D：bind 宽写入退出最差路径，最差转到 query0 VALID → pending split → Service CPU1 VALID → pair 选择/CPU0 ready → query0 head。
- E：query-head 组改善到 −1.943ns，但最差返回 LSQ row15 VA bit0，整核仍比基线差10.314941ps。
- F：最差端点为 LSQ row16 的 cause bit4，路径经过 flush/ROB cancel、Execute 访存绑定和 row cause 写入。
  query-head 组为 −1.991ns，比 E 略差，但整核最差余量改善30.597448ps；最终采用 F。
- E/F 的逐单元路径分别见 [E关键路径](split-hint/sta/R64SystemTop-1000MHz/critical-path.json)、
  [F关键路径](held-ready/sta/R64SystemTop-1000MHz/critical-path.json)。最终选择以本次同约束实际数据为依据。

core_backend_execute_clmul_flush_i 是共享 flush 的网表别名，不表示正在进行 CLMUL 数值运算。

局部路径组沿用同一网表与约束，包含对应 D 端点及关联 ICG enable，不构成时序豁免：

| 路径组 | 修改前 / ns | 最终采用 / ns |
| --- | ---: | ---: |
| WB grant | -1.38800 | -1.95600 |
| prepared payload | 0.07143 | -1.51100 |
| query head | -2.19400 | -1.99100 |

提前准备和端口申请存在局部组合代价，不能将结果描述为所有路径都改善。
这些是布局前映射 STA，无提取线网寄生参数；负 slack 保留原 FAIL 判定。
当前 I/O 延迟随周期设置，不能直接用 1/(1−WNS) 推导实际 Fmax。
历史 −2.261837959ns 不是本轮基线。

## 验证结果

最终采用版本：

- 严格 CoreTop/SystemTop lint 和完整构建通过。
- 135项默认模块测试均有通过证据：候选完整134项回归，加正式接入的 Service request-hint 参数变体。
- pipeline、admission、store、LSU network、query pin、RR credit 等矩阵及原负向测试通过。
- 官方 ISA 177/177、ACT4 101/101、AM 74/74，共352项软件，保留完整 NEMU 与 RTL 断言。
- program、Sv39、sdtrig、LSU contention、backend network，各正常/随机 stalls，共10/10整机定向。
- 独立 ALU 的7个热窗口均768条/384拍，CPI0.5；冷启动窗口按原数据保留。
- 完整 CoreMark/Dhrystone 自然结束通过，最终计数和26项 profile 均与 A+B 精确一致。
- prepared 测试核对同拍完整描述符；真实 CQ→9源 WB 覆盖冷启动1/2结果、kill、flush、错误提示、持续竞争和51条精确一次 LSU 完成。
- 原 prepared 路径和关闭 WB 提示两个负向对照按预期检测出额外等待。
- event-count 真实组合切片穷举16,384组；bind 改写逐拍对照原过程。
- 非对齐测试覆盖113个 blocked 提示周期及627个 live 周期；Service 覆盖 CPU 无 VALID 时提示 mask1/2/3 与真实 PTE 请求竞争，返回 owner/data 与独立 scoreboard 一致。
- 错误 live Service 提示由契约断言拒绝；正/负入口已加入 Makefile，生产工作区定向重跑通过。

### 测试条件与中间问题

- 早期 AM 的 clint-manual 曾超过180秒宿主超时；保留原失败记录，同镜像重跑通过。
  最终候选临时 runner 将宿主等待设为1200秒，仍保持50,000,000 RTL周期上限；正式 runner 未修改。
- D 阶段的公平性夹具故意 force completion_fire=0，与新增实际 fire 断言冲突。
  改为比较未被 force 的新旧计数组合式；独立穷举仍检查实际 fire。E/F 所有最终测试均使用修正后的同一 RTL。
- E/F 基准并发时，仅将本任务四个仿真进程的宿主 CPU affinity 分开，保持线程数2、镜像、NEMU 和 RTL 不变。
  这是宿主测试调度；硬件性能数据始终来自模拟周期数，详见 simulation-affinity.json。
- Service 新测试最初缺少“只有辅助请求”的覆盖场景，随后补入真实 PTE 事务；原失败日志保留，没有通过削弱覆盖条件取得 PASS。

## 结论边界与证据

本轮没有重跑完整 Linux L2/L3、完整 NPU workload 或布线后 STA；此前系统通过结果不能记作本轮新 RTL 的复验。
性能收益只对应这两个固定完整程序，没有进行旧 rv64core 与最终 rebuildcore 的新鲜同镜像性能对照。

- [对照数据](comparison.json)、[功能验证汇总](verification.json)、本轮补丁 `task.patch`（迁移后未保留）。
- 各阶段目录保留 RTL、完整基准、综合/STA 与必要失败记录；最终阶段目录包含 software、direct、regression 和定向提示测试。
- [LSU 拓扑](../../vsrc/lsu/TOPOLOGY.md)、[Backend 拓扑](../../vsrc/backend/TOPOLOGY.md)同步实现。
- 补丁只包含本轮开始之后的改动，保留用户原有工作区内容。
