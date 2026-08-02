# V13C A3 layered-evidence review

RV64 RTL 结论｜对象=`NpcSimTop` system-reset 终端事务、`c1b531→5f9dd068` elaborated RTL、`29c0afe8…f483`/`OooLoadQueue` production 绑定｜周期/配置=A3 5,071,521,696 cycles、1,223,536,213 commits；strict 16/17｜TB/EDA 观测=六类 terminal marker 各 1 次、RTL assertion failure 文件为空；`NpcTop` coarse cells 51,386→51,129、mux 15,720→15,471｜范围=GAP（A3 历史事务 APPROVE；中间语义层有界 APPROVE；当前 production 系统重认证 GAP）

## 三层判定

1. **A3 历史事务：APPROVE，但不改写原始状态。** A3 保持
   `FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`；strict
   16/17 的唯一失败仍是 `dmesg-no-critical`。内嵌 checker SHA-256 与 launch binding
   相等；旧未定界 `BUG:` 只命中两条 `printk: debug:`，当前定界正则在同一 console
   命中 0 条，恢复旧正则的 source mutation 可重现 false red。fresh checker 单测 3/3、
   canonical asset 9/9、fresh/canonical replay 语义字段比较均 PASS。因此历史事务分类为
   `A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE`，但 published gate 仍是 FAIL。
2. **`c1b531→5f9dd068`：冻结生成集内有界 APPROVE。** 51 个 generated 文件中 50 个
   exact match；唯一 exact 差异的 generated C++ 文件在 normalization 后无差异；八个
   device-model object 不变，仅 host `cpu-exec` diagnostic observation object 变化。该结论
   不等于整个 simulator executable、工具链或观测路径的逐字节身份。
3. **当前 `29c0afe8…f483` production 绑定：GAP。** V13B `OooLoadQueue` 局部变化精确
   传播到 `NpcTop` coarse，证明当前活跃 elaborated RTL 已离开 A3 设计绑定。A3 replay 不能
   promotion 当前 production；后者仍需 current fast-gate rebind、获授权的新 system attempt 和
   fail-closed status/evidence。

## 审查反例与边界

- focused regex fixture 不证明所有未来 console 拼写均完备；本轮只证明 A3 的两条旧命中是可重现的
  token-boundary false positive。
- 六类 terminal marker 各一次是原始事件计数，不使用去重；该计数不能单独证明 reset 后所有
  微架构状态。
- A3 binding 明确记录 `OOO_ASSERT=1` 与 `OOO_TERMINAL_HOLDER_ASSERT=1`；空 failure 文件证明
  没有记录到 assertion failure，不证明断言覆盖完备。
- `c1b531→5f9dd068` 的 normalization 规则不能扩大为最终链接二进制或工具链完全相同。
- `OooLoadQueue` PPA 差值可以来自功能等价优化；它足以使旧 system design binding 失效，但不证明
  功能回归。
- 合同 SHA-256 只绑定合同 JSON；A3 输入资产完整性由独立的 9/9 hash check 支撑，二者不可混用。

## 当前裁决

- A3 oracle correction：`full_system_rerun_required=NO`，
  `launch_authorization_state=NOT_REQUIRED`，A4 的 TERM/FAIL 原样保留。
- current production system promotion：`system_recertification_required=true`，
  `launch_authorization_state=REQUIRED_NOT_GRANTED`，本轮未启动任何长系统运行。
- 独立复核合同：
  `.github/task-runs/2026-08-01-rv64-v13c-a3-evidence-audit/subagent-contracts/v13c-a3-layered-evidence-review-v1.json`
  (`sha256:4e086360e190fb66ac46bf909b98c2213666455c7dd43bca9178b5e4cab10e26`)。
