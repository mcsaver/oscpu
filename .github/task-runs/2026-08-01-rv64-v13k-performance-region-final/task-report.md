# RV64 V13K 性能区间终止事务报告

## 结果

本轮裁决为 `REGION_FINAL_CONSUMER_PASS / PERFORMANCE_BASELINE_GAP`。host harness 已把
committed-PC 区间的权威记录从首次 end 边界时刻移到仿真终止时刻；v4 checker 已绑定唯一
`FINAL`、终止返回码、全程 marker hit 总数、合同 ID/摘要与 baseline eligibility。未修改
production RTL，未启动完整 Linux/systemd 回放、综合或 STA。

## 实现

- `npc/rv64/csrc/cpu/cpu-exec.cpp`：边界观测只记录首次 start/end；`finish_exec(..., true)`
  在终止事务中输出一次 `npc-rv64-region-final-v1`，并保留最终累计 hit 数。
- `npc/rv64/eval/ppa/tools/check.py`：新增 `npc-rv64-performance-evidence-v4` 消费路径；拒绝
  缺失/重复 `FINAL`、提前 `RESULT` 冒充、post-end hit 漂移、incomplete、非零
  `termination_rc`、边界算术不一致及零周期性能样本。
- `proxy-200mhz-v1.json`：绑定测量合同 path、ID、SHA-256 和
  `termination_time_total_hits`；strict 检查会因当前
  `performance_baseline_eligible=false` 正确阻断 baseline 晋级。
- 测量合同与 README 已同步 v4 语义。本轮终审发现合同 `known_limitations` 中仍残留“没有
  fail-closed consumer”的旧句，已修正并重新绑定 policy 摘要。

## TB/EDA 观测

- 当前配置 CoreMark 单次：`FINAL complete=1 termination_rc=0 start_hits=1 end_hits=1`，
  region `cycles=5,395,310`、`retired=3,183,617`；随后出现 `HIT GOOD TRAP`，全程序
  `cycles=5,485,583`、`commits=3,218,532`。
- 2,000,000-cycle 限制反例：`FINAL complete=0 termination_rc=2 start_seen=1 end_seen=0`，
  随后 `ABORT`；证明未完成区间不会被包装为有效样本。
- 同周期 lane0→lane1 定向镜像：start/end 均在 cycle 173，`retired=1`、`complete=1`；该
  事务证明有序边界表达能力，而 v4 性能 checker 仍拒绝 `cycles=0` 的资格化样本。
- 当前配置 Verilator 编译 PASS，编译后二进制 SHA-256 为
  `9ee3f23c781b02e3d628a6263e9da01ae8480a85b9d1a70fbe01a65588ae9849`；验证后已清理
  227,078,944 bytes build/obj，仅保留三份原始日志。
- `test_policy_tools.py`：49/49 PASS。全 PPA discovery 还存在 143 failures + 20 errors / 540
  tests，定位为跨越多个既往 RTL 轮次的旧 source/mutation binding；不在本轮 claim scope，故
  记录为 suite-level GAP，未用局部 PASS 掩盖。

## 交付 guard

范围化 strict guard 正确要求 `npc-dev` profile。实际执行中五个静态合同节点均 PASS，但前置
`context-brief` 为 WARN，profile wrapper 按 fail-closed 规则写成 `status=blocked`；因此 strict
guard 没有 PASS。原始状态保留在
`.github/task-runs/2026-08-01-rv64-v13k-performance-region-final-guard/`，没有改写为成功，也没有重复
运行。该 GAP 属于 AI 环境 context recall/persist 路径，不是 RV64 RTL、编译或仿真失败；本轮以
已有当前配置编译、49 项 checker 变异和三份终端事务证据作为硬件交付范围，并把 guard 修复留作
独立环境债务，避免再次占用主线时间。

## 审查范围

交付前 reviewer 角色逐项核对 `finish_exec` 调用、唯一 `FINAL` 解析、合同摘要绑定及负向测试，
并发现、修正上述合同旧句。独立只读子节点未在限定时间内返回回执，已中断且未启动仿真/综合；
因此不把本轮称为“独立审查全通过”，其状态明确保留为
`INDEPENDENT_REVIEW_RECEIPT_GAP`。

## 保留的 GAP 与下一主线

当前只有一份新鲜 CoreMark v4 正向日志，没有 CoreMark/Dhrystone 各三次 bit-exact cohort；typed
production/elaboration/simulator/harness/workload identity、互斥 region CPI cause、retire lost-slot、
integer/FP issue terminal ledger、occupancy、overflow 与 instrumentation non-interference 仍未闭合。
所以下一轮进入 `performance_counter_schema_v1`，baseline 继续保持未资格化，不选择 CPI 优化候选。
