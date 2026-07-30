# V11I independent pre-review result

RV64 RTL 结论｜对象=`OooMemOwnerTerminalCollector` →
`OooMemOwnerTracker` → `OooLoadQueue`｜周期/配置=edge-old tracker、
双 dequeue、32-token production 配置｜TB/EDA 观测=静态 RTL/TB 复核，
未运行仿真｜范围=GAP

- 裁决：**H1**。当前 production source RTL 的 holder 状态转移可排除
  accepted transfer 后的旧 terminal 重放；尚缺 LQ 清除、tracker free、完整
  token cursor 环回及新 LOAD 驻留期间的端到端动态证据。
- H3 排除：LQ terminal PID 在 dequeue/free 同沿读取 edge-old tracker table；
  allocator 只扫描 edge-old free token，death 同沿不能 birth 同 token。
- H2 局部反例保留：若 raw ingress 合同被破坏，token 复用后的旧
  `{LOAD,T,00}` 会匹配新 owner 并使 LQ 看到新 PID。该事件会破坏新 owner，
  不能用去重、吞事件或削弱断言处理。
- production one-shot 基础：bridge response/drop 离开相应 registered owner
  状态；reservation/buffer/retry terminal 同沿清 holder；parent
  `[V9Y-HOLDER-TERMINAL-NEXT]` 要求 accepted transfer 后下一拍无 active
  holder。
- 需要的最小矩阵：production assertions-on/off 2/2，加 compile-success
  stale-source variant assertions-on/off 2/2；后者分别由
  `[V9Y-HOLDER-TERMINAL-NEXT]` 和独立
  `[V11I-LATE-TUPLE-ABA][FAIL]` oracle 拒绝。
- 合同 JSON：
  `.github/task-runs/2026-07-30-rv64-v11i-terminal-lifecycle-after-lq-clear/subagent-contracts/v11i-terminal-lifecycle-pre-review-v1.json`；
  SHA-256
  `042b95c1eecf06ed77bca55d98c9b61d51ce2e79635849fd601975fa31bb3dd5`。
- reviewer 未修改文件，已停止只读命令并归还 WSL shell ownership。

