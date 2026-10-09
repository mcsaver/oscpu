# 第二轮架构实验：事实与版本绑定

工作区 /home/lyg/PA/ysyx-workbench，分支 ai，HEAD ec653b952ca3938c893f14d9696bcb6b05b65f60。
本轮开始时已有上一轮未提交修改，全部保留。本轮候选曾按网页 Pro 的方案C及修订合同实现，完整程序与同约束物理比较已完成；网页Pro基于取舍裁决淘汰，活动源码已恢复本轮前状态。最终结论见[RESULT.md](RESULT.md)。

## 独立网页设计

用户明确：网页 Pro 负责主要架构设计，Codex 负责采集事实、实现、验证，并按反证回访。
按用户要求新建[架构优化方案推导会话](https://chatgpt.com/c/6ac732fa-befc-83e8-a497-7bf8b3c72ff0)，
没有续用旧对话的方案讨论。UI 核实 GPT-6、Pro 第 5/5 档；7323 字符事实包实际发送一次。
[发送材料](request.md)和[发送截图](consultation-submitted.png)已保存。[完整设计回答](response.txt)和[源码反例后的修订合同](revised-contract.txt)已取回。

## 基线

当前生产代码是上一轮保留的普通 load response bypass 候选。92个 RTL/header 和两个 filelist
逐字节核对一致；108个 vsrc 文件仅 TOPOLOGY 文档不同。完整核对、sim/ref 连续性和固定镜像摘要见
[基线复用记录](../../../results/ai-cq-timing-20261008/baseline-reuse.json)。
冻结快照位于 npc/rv64/build/ai-cq-timing-20261008/baseline-vsrc。
该结果目录名是在用户明确本轮开放选型之前建立，仅作工程路径，不表示预选 CQ 方案。

| 负载 | 周期 | 退休 | CPI |
| --- | ---: | ---: | ---: |
| CoreMark 10 iterations | 8968518 | 3218537 | 2.786520087 |
| Dhrystone 10000 runs | 14267505 | 4260670 | 3.348652911 |

物理基线为上一轮 matched recovered candidate：area3144021.999995平方微米，
setupWNS -2.119304419ns、holdWNS -0.036660694ns，原1ns约束仍FAIL。
来源：[完整物理比较](../../../results/ai-architecture-20261008/mapped-export-recovery/PHYSICAL-COMPARISON.md)。
复用已验证基线不免除新候选的代码/输入/配置绑定，也不能拼接不同版本的有利数据。

## 执行资源和现有入口

固定完整程序runner已准备：
[run_benchmarks.py](../../../results/ai-cq-timing-20261008/run_benchmarks.py)。
新候选短验证通过后指定新sim及新输出路径，保留完整NEMU、R64_ASSERT、threads1和固定镜像。

标准物理入口为 make -C npc/rv64 sta STA_DESIGN=R64SystemTop，VSRCDIR指向候选冻结副本，
STA_RESULT_ROOT指向本轮独立candidate-sta目录；SYN_MEMORY_KIB与STA_MEMORY_KIB均12582912。
采用既有icsprout55 TT/1.2V/25C、1ns、uncertainty0.05ns、ABC600ps、fanout8，无blackbox或额外库。
工具失败与真实负slack区分记录。基于上一轮峰值，避免把原生综合限制为6GiB。
独立CPU仿真与EDA按实际内存安排，不并发冲突的同名输出或达到峰值的大型网表任务。

## 已确定和实现的完整候选

Pro独立比较提前交付确定load值、store地址/数据部分发射和完成/取消分层，选择第三项。
联合实现取消前六源候选、真实稀疏capture、固定CQ物理槽；正常结果不增加流水级，reset关闭预写，
当前flush/kill仅决定语义资格和owner，不决定宽payload路由。候选使用当前response VALID准备数据，
真实capture保留原raw_fire；这是[源码反例反馈](clarification-request.md)后由Pro修订的合同。

实验候选生产修改仅R64Lsu.v与R64LsuCompletion.v。测量用RTL/header冻结到
npc/rv64/build/ai-cq-timing-20261008/candidate-vsrc，清单为
[candidate-source.json](../../../results/ai-cq-timing-20261008/candidate-source.json)。
后续TOPOLOGY文档更新不改变冻结硬件。仿真构建和标准综合使用该冻结树。
本轮开始时另外保留189个sim/testbench支持源码（约1.78MB）及tracked diff，避免回退覆盖上轮修改。

## 已通过验证

- system-lint保持原Verilator规则与R64_ASSERT；修正了首次构建发现的旧event_two_w断言引用，改为新稀疏owner守恒，保留失败日志。
- CQ：4项直接测试；30,022拍独立FIFO owner scoreboard及双实例取消非干扰；reset预写不复活；冻结旧CQ无取消逐拍对比6,003拍。
- LSU仲裁：13,122组独立candidate/live/RR/credit oracle；原network四场景和真实RR公平/取消场景。
- 真实响应：RESPONSE_BYPASS=0/1 × 普通/背压全部PASS；新增同Q态切kill/flush路由不变，以及取消第一响应时真实稀疏10捕获。
- 14项相关模块回归通过；2项LSU负向合同测试按预期fatal。
- SystemTop：program、sv39、sdtrig、lsu_contention、backend_network、load_chain各普通/背压，共12项完整NEMU+ASSERT通过。
- load_chain普通114849、背压114893周期，与基线完全一致；普通lsu_contention29426周期也相同。

[整核短测](../../../results/ai-cq-timing-20261008/candidate/short-tests.json)、
[CQ证据](../../../results/ai-cq-timing-20261008/cq-modules/RESULT.txt)、
[仲裁证据](../../../results/ai-cq-timing-20261008/lsu-arbitration-tests/results.json)。

两个固定完整benchmark均已自然PASS且周期及全部共有计数不变；真实综合与STA完成，setup WNS退化45.238971ps，面积仅减少0.059375%，目标输入改善伴随CQ输出代价。Pro完整实测裁决为不保留，主代码和支持文件已恢复本轮前版本。候选源码、测试、完整指标、回访及恢复核对均见[最终报告](RESULT.md)。

