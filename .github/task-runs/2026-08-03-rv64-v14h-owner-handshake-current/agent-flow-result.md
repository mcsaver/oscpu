# Agent Flow Result

- `schema`: agent-flow-v1
- `task_id`: rv64-v14h-owner-handshake-current
- `task_class`: architecture
- `archive_mode`: compact
- `status`: PASS
- `production_rtl_change`: false
- `design_id`: `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
- `strict_guard`: `EXEMPT_MISSING_BROAD_NPC_DEV_PROFILE`
- `workflow_overhead_policy`: advisory; deterministic result gates run at delivery, no time quota gate
- `path_source`: explicit agent-flow log; Git used only for final scoped audit

## Delivered result

- 当前 RV64 产品配置的 `global_no_live_reuse=GREEN`。
- 44/44 holder semantic units PASS，50 个 unit×instance bindings 已绑定。
- V14G 4/4 baseline PASS，22/22 compile-success mutations 被拒绝。
- `dispatch1_optional` 在冻结 NpcTop elaboration 的 9 级连接链上为 constant-low。
- 完整 holder semantic 门禁的主测试组 145 tests PASS。
- 日常门禁消费耐久 receipt；只有 executable RTL/TB/runner、仿真器或产品 elaboration 绑定变化时才执行动态 refresh。

## Explicitly unpromoted

- `whole_architecture=RED`
- `system_recertification=REQUIRED`
- `ppa=UNPROMOTED`

`test_arch_stable_freeze` 的 53 项 current-workspace 测试中有 3 项保持失败，原因是 V9O/V9R
CONTROL-EVENT 证据仍绑定历史 design-id `882111fb…bed67b`，不是 V14H 回归。该 GAP 与 strict guard
缺少宽泛 `npc-dev` profile 的定向豁免均完整记录在 `verification-summary.json`；未通过削弱 checker
或覆写历史证据制造 PASS。

## Retained result surface

- 明确的变更路径和目录
- 可复核的证据指针与 SHA-256
- 实现者决策轨迹和独立审查纠偏记录
- 定向测试、完整 holder semantic gate 与严格收尾结果

不归档重复原始运行载荷、完整启动上下文或私有 token 级推理；工程判断以可审计的输入—决策—证据轨迹保留。
