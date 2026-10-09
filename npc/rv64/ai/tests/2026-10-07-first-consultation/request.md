# RV64 架构决策咨询：首次 Codex ↔ 网页 6 Pro 工作流测试

请用中文做一次有证据边界的独立架构审查。本地 Codex 会核查你的结论。本轮只测试咨询与核查，不授权修改 RTL 或宣称已经提升性能。你无法直接访问下述本地路径，请根据给出的内容推理；不需要网上搜索。

## 要决定的问题
用户觉得 AI 一直局部微调、收益很小，希望从完整架构的角度判断下一笔工程投入。对下面这颗双发射 RV64，现有证据更支持先缩短依赖/访存完成延迟，还是扩大窗口与内存级并行？也可以提出优于两者的完整方案。不要只列“加大 ROB、增加 cache、加预测器”的愿望单。

## 当前源码事实
工程：ysyx-workbench/npc/rv64；本地主工作区 /home/lyg/PA/ysyx-workbench，分支 ai，HEAD ec653b952ca3938c893f14d9696bcb6b05b65f60。任务开始时干净；本轮只新增 ai 文档。正式新核在 vsrc，下述历史测量不等于今天重跑。
- 2 分配/发射/写回/退休；ROB32、IQ16、LSQ20、GPR/FPR 各64物理项；GPR4/FPR3读口；2 ALU，独立 MUL/DIV/CLMUL；9 个完成来源争用2个 WB 捕获口。
- BHT256 bimodal、间接目标64项、RAS8。I/D cache各8KiB、2路；D cache 2bank、64B line、write-through。
- D cache主要读/补行慢路径一次一个 owner；有受 bank/set/事务条件限制的 hit-under-miss；另有独立 store B owner，能与读取重叠。不是全面非阻塞 cache，也不是所有访存完全串行。
- Store 的真实副作用需 ROB head/effect permission；退休依赖真实请求接受和响应返回。R64Lsu.v 的注释原文：That head cannot finish or retire before this request is accepted and its response returns.
- Dcache 收到 write_response_fire_w 后才清 store_active、产生普通store完成；成功 AXI B 后才更新驻留cache行。错误响应需传播，不能把 store buffer 设计成丢掉精确错误的捷径。
- R64Lsu.v barrier_w 阻挡未绑定、未对齐、atomic、IO、尚未解析 RAM/IO 属性的普通 load，以及尚未完成翻译/必要A/D的store。已保护的RAM翻译响应可同拍释放相关屏障。
- 分支恢复以 youngest-first 每拍最多撤销2项，并暂停分配/退休；ALU提前唤醒/旁路、RR有限旁路、LSU提前申请 WB 端口已存在，不能当全新改进。

## 历史实测（2026-09-16 held-ready）
来自 results/rv64-cpi-timing-20260916/REPORT.md 与 held-ready/{coremark,dhrystone}-metrics.json。固定原生 SystemTop、真实 cache/翻译/AXI/设备、完整 NEMU DiffTest、R64_ASSERT；CoreMark 10次迭代，Dhrystone 10000次。

| 项目 | CoreMark | Dhrystone |
|---|---:|---:|
| cycles（自然结束）|9241964|14568135|
| commits|3218524|4260670|
| CPI|2.871491404|3.419212237|
| 无退休周期占profile区间|78.74%|82.66%|
| ROB非空且head未完成|74.74%|80.17%|
| decode IQ阻塞|40.35%|1.65%|
| decode ROB阻塞|14.38%|59.99%|
| WB背压|6.83%|9.56%|
| recover|4.22%|2.14%|
| store B owner驻留|6.41%|16.51%|

这些事件会重叠，不能相加，不能把占比直接叫可回收周期；profile比自然结束cycles多1个边界采样拍。缺少退休关键路径的原因分解、逐load依赖链、有效MLP、分支误预测损失等可归因数据。

独立ALU热窗口测得768条/384周期（CPI0.5），不代表整程序。同库/同约束历史 SystemTop prelayout STA：icsprout55 TT1.2V25℃、1ns周期、uncertainty0.05ns、ABC600ps、max fanout8、无blackbox、真实ICG；setup WNS=-2.173909903ns，hold=-0.036660694ns，FAIL。最差路径经过 flush/ROB cancel → Execute访存绑定 → LSQ row16 cause[4]。无布线后寄生，不可用这个WNS直接声称真实Fmax。

## 已做过的事及反证
- 此轮 descriptor同拍准备 + LSU提前申请WB 等联合修改让完整程序周期减少3.460367% / 4.529761%。WB背压下降，store B owner驻留计数不变；改善的是准备/完成等待。
- backend/TOPOLOGY.md记录另一个历史IQ16→32实验：CPI仅改善0.090241% / 0.310911%；IQ16同轮时序更好，保留16。它限制“只扩IQ”的论据，但不能直接否定同时改变ROB/PRF/LSU等的完整设计。
- 诊断模型/正确路径回放只用于区分假设，不能假定其cycles等于真实RTL，也不允许去掉正确性/异常/恢复/总线响应来做漂亮数字。

## 请交付
请把回答控制在便于执行的一次审查内（约1500–2500中文字，可略超）。
1. 明确当前可以判断什么、不能判断什么，指出摘要中你认为最危险的错误前提或遗漏。
2. 比较2–3个完整候选：联合改哪些机制，跨模块的owner/信用/取消/晚到响应/异常与副作用合同是什么，中间态为何可能暂时退步；不要把添加store buffer自动视作合法提前退休。
3. 给出3–5个按价值排序的下一步行动；每项写清区分哪个假设、最便宜实验、可观察结果、什么结果会否定它。成本按相对需要的仿真/RTL/综合工作量描述，不捏造运行分钟数。
4. 选一个最小、可反驳的首轮实验，并以“继续/淘汰/证据不足”裁决；没有新测量就不要承诺百分比收益。说明什么新证据能让你改变首选。
