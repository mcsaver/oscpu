# RV64 hardware wording incident V12

状态：recorded；RTL 父目标继续 active

## 观察事实

- 用户提供的 UI notice 已原样保存为 `evidence/ui-notice.png`，SHA-256
  `7977cc0796211fc7c714e3d67518c76f9858627b4ee4d602dbaa002d75a77996`。
- notice 是通用内容不可显示提示，不包含触发片段、分类特征或逐词诊断，因此不能从截图断言某个
  单词就是唯一原因。
- 发生时的工程对象是授权本地 RV64 Verilog/SystemVerilog 处理器、testbench 与 EDA 证据；
  RTL 目标和验证强度没有改变。

## 工程侧归因与纠偏

- 可操作归因是交互叙述曾把不同硬件性质压缩成缺少 signal/cycle/object 限定的多义简称；这是
  任务语义清晰度缺陷，不是 RTL 行为缺陷。
- 后续用户可见进度与子 agent 技术字段明确到 `ARADDR/ARSIZE/ARPROT`、READY/VALID 周期、
  2B EXEC PMP、PMEM 读取边界、lane0/lane1 PC/cause/tval owner 和指定 testbench oracle。
- file/module/signal/TB/log/schema 的真实标识符保持原样；协调状态只进入 dispatch/task-run，
  不进入 RTL 子任务 goal、deliverables、success criteria 或 supplied material。
- 纠偏不建立关键词黑名单，不减少工具、源码范围、负向 RTL 变体、断言、覆盖矩阵或推理出口。

## 验证

- task-contract self-test：25/25 PASS。
- task-contract CLI self-test：20/20 PASS。
- discovery/packaging wiring audit：PASS。
- skill quick validation：PASS。
- V9I 字段级 no-tools reviewer 合同 validate/render：PASS；独立审查结论 PASS。

该 incident 只记录交互与协作流程事实，不作为 RTL 正确性证据；V9I RTL 正确性仍由
`make -C npc/rv64 check-ifu-access` 的 current-design 结果独立证明。
