# RV64 V13J 性能测量合同报告

## 结果

本轮完成测量意图冻结与过时架构指针纠偏，裁决为
`CONTRACT_STRUCTURE_PASS / PERFORMANCE_BASELINE_GAP`。未修改 production RTL，未运行仿真、
综合、STA 或完整系统回放。

## R3.4 当前状态

`OooIntBackend.v=49ec3d7e…cca5a` 已具有两路 ordinary ALU、单一 `OooBitmanipGate` 和单一 `WBU`；
lane1 writeback 为 ALU/IMM 两路选择，capability assertion 未削弱。该结构在
`.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/` 已有 focused 3/3、
BITMANIP/WB_SEL_PC4 负向版本、lint 和 Yosys hierarchy 证据；V13I 输入再次绑定相同 backend。
因此 `ooo-int-issue-queue.md` 与 DB-backed memory 中的“下一步 R3.4”已纠正为历史完成项。

## 新合同

新增：

- `npc/rv64/design/arch/performance-measurement-contract-v1.json`
- `npc/rv64/design/arch/performance-measurement-contract.md`

合同冻结 CoreMark 10 与 Dhrystone 10000 的 binary/input、committed-PC region、编译/链接参数、
冷 cache/TLB/predictor、privilege/MMU/interrupt、deterministic latency、3 次 bit-exact repetition、
统计/权重/阈值及 counter qualification。合同明确：integer 2 terminal 与 FP 1 terminal 尚未形成
全局 slot ledger；固定百万周期 overlap buckets 不能相加为 CPI stack。

## 独立审查反例

审查结论为 `GAP`，并已写入机器合同：

1. 当前 region `RESULT` 在首次 end PC 提交时输出，不能证明 workload 结束时 total marker hits；
2. V13I `design_id` 是混合 configured RTL source closure，不是 production-only 或 elaborated identity；
3. 当前无 checker 强制绑定合同 ID、eligibility 与 counter qualification；
4. `cpi-neutral.json` 只是 whole-program intermediate checkpoint，不能晋级为 region baseline。

所以本轮保持 `performance_baseline_eligible=false`，且没有触发高成本完整系统运行。

## 轻量验证与留档

- `jq` 解析机器合同 PASS，并确认 contract state、eligibility=false、typed identity GAP 与
  fail-closed consumer GAP。
- 独立审查只使用合同允许的 `rg/sed`，无文件写入、无仿真/综合/STA 进程遗留。
- DB-backed `.github/memory/project-status.md` 与 `.github/memory/modules/npc.md` 已更新并生成 stored
  snapshot；兼容 shim 由数据库工具刷新，未手工改写。
- 机器结果见 `verification-result.json`，审查回执见 `reviewer-result.md`，派发输入见
  `subagent-contracts/v13j-performance-contract-review.json`。

## 下一主线

进入 `performance_counter_schema_v1`：先实现 termination-time authoritative `FINAL`、typed
identity manifest 与 fail-closed consumer，再实现 region-bound 互斥 first-blocking cause、
retire lost-slot、分离的 integer/FP terminal 以及 occupancy 守恒。上述门闭合前不选择 CPI 候选。
